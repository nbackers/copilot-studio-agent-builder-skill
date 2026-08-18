# Authoring patterns

Patterns for building agents in the new Copilot Studio experience, accumulated across several
builds. Ordered by how much time they save.

---

## 1. Routing is driven by `description`

The orchestrator reads each child agent's **`description`** to route. Not the name. Not the child's
instructions. The same is true of skills — front matter `description` is what the router matches.

Consequences:

- **Tune descriptions first.** A misrouted question is a description problem.
- **Never fix routing in instructions.** The router does not read them.
- **Renaming an agent does nothing** for routing.

A description needs four things:

1. **Concrete trigger phrases** — the words users type, not an abstract summary. "Handles inventory
   matters" gives the router nothing.
2. **Explicit negative scope** — "Do not use for…", naming the sibling that owns it.
3. **Ambiguous cases resolved** — the ones that read like another domain.
4. **No overlap on the same noun** with any sibling.

### Ambiguity worth encoding

Cases that consistently route wrong unless named:

| Question | Reads like | Actually belongs to |
|---|---|---|
| "Damaged on arrival" | Warranty | Delivery — broke in transit ≠ failed in service |
| "Is it in stock" when they already own one | Warranty or orders | Availability |
| "New starter needs a laptop" | IT | A cross-domain skill |

## 2. When to orchestrate

Multi-agent is not the default. It costs routing accuracy — every additional child is another
description competing for the same question.

**One agent** when a single instruction set stays coherent, questions are of one kind, and no
workflow needs two domains at once.

**Orchestrator** when *all* hold: domains differ in vocabulary, data and permissions; you can name
three or more cross-domain workflows; a single instruction set has begun contradicting itself; and
domains need different grounding or access control.

**Scale is not the trigger.** A read-only lookup assistant serving thousands is still one agent.
Domain diversity is the trigger.

### The corollary most builds miss

Once split, **no child agent can answer a cross-domain question** — by construction. The joins have
to live in skills. Four agents with no cross-cutting skills has the cost of orchestration and none
of the benefit.

## 3. Where a rule belongs

| Rule | Home | Why |
|---|---|---|
| Tone, scope, escalation, privacy posture | Instructions | Applies to everything said |
| Domain calculations, multi-step procedures, cross-domain workflows | Skill | Versioned, testable in isolation, reusable |
| Access control, table scoping | Tool configuration | Enforced, not requested |

If the fix is "add another sentence to the instructions", check whether it is really a skill or
configuration change.

**Instructions cannot change system behaviour.** Microsoft documents that instructions are for tone
and flow and specifically *cannot* modify how adaptive cards are triggered. Do not attempt to solve
structural problems with prompt wording.

## 4. Grounding with the Dataverse MCP server

```yaml
kind: McpTool
authMode: Maker
connectionReference: <connection reference>
connectorId: /providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps
operationId: InvokeMCP
```

**The tool is not read-only.** It will create, update and delete if asked. Read-only requires:

1. An explicit instruction forbidding create, update and delete, **and**
2. Table scoping that grants no more than the agent needs

Scope each agent to its own tables rather than everything. Narrower grounding gives better answers
and makes the domain boundary real rather than advisory.

### Alternate keys

Where records are looked up by a natural identifier — email, ticket number, order number — add an
**alternate key** on that column. Keeps queries delegable at scale and avoids GUIDs appearing in
conversation.

## 5. Instruction patterns worth reusing

Every agent benefits from these:

```
Never invent a number, date, name or status. If a lookup returns nothing, say so.

Render choice fields as their labels. Never show a raw option value, GUID, column name
or table name.

Dates as "Thursday 30 July", not 2026-07-30T00:00:00Z.

Report exceptions, not everything. A list of things that are fine is noise.
```

### Confirmation gate for anything that writes

```
Show a plain-language summary and get an explicit yes before creating anything. Never
create a record silently, and never treat an ambiguous reply as consent.
```

Summarise back in the user's language, not in field names. A confirmation full of schema names does
not get read, which defeats the point of asking.

## 6. Test routing before testing answers

Routing failures present as answer-quality failures. Separate them.

Build a table of representative questions and their expected destination. Confirm the right agent
or skill handled each **before** judging the response.

Changing one description moves its boundary with siblings, so a fix for one question routinely
breaks another. Re-run the whole table after every description change — it is the only way to see
regressions.

## 7. What cannot be automated

Plan around these:

- **Connection binding** — OAuth consent, once per environment, portal only
- **Skill upload** — portal only, one zip at a time
- **Flow creation** — no `pac flow create`

`pac copilot create / clone / push / publish` provisions agents from source but cannot bind
connections.

## 8. Adaptive cards

Applies to card-capable topics, not to generative child agents — which cannot contain actions and
therefore cannot send cards at all. Plan for that before designing guided journeys.

Where cards are supported, `cardContent` takes a **Power Fx object literal, not JSON**:

- Omit `$schema` — it breaks Power Fx parsing
- Interpolate with `$"text {Global.Var}"`
- Avoid emoji — encoding risk through JSON
- Use `ColumnSet` for layout; three stacked containers read as a list, three columns read as
  designed

### Card buttons need `__isBotFrameworkCardAction`

A button that does nothing when clicked is usually this. WebChat's renderer branches on the shape
of `data`:

```
typeof data === 'string'         -> imBack (sends the string as a message)
data.__isBotFrameworkCardAction  -> performCardAction(data.cardAction)
otherwise                        -> postBack (activity has a value but NO text)
```

The Teams `{ msteams: { type: "messageBack" } }` convention is a **Teams-client** thing. WebChat
does not read it, so those buttons fall into `postBack` and produce a textless activity — nothing
for a trigger phrase to match, and no visible user message.

Shape that works on both channels:

```
data: {
  __isBotFrameworkCardAction: true,
  cardAction: { type: "messageBack", text: "Start order tracking", displayText: "Track an order" },
  msteams:    { type: "messageBack", text: "Start order tracking", displayText: "Track an order" }
}
```

`text` must equal a trigger phrase. `displayText` is what appears in the transcript.

### Suppressing the duplicate generated reply

Under generative orchestration, a topic that ends by sending a card does not end the turn — the
orchestrator then answers the same message itself, so the user sees a card and an equivalent text
reply below it.

`CancelAllDialogs` does **not** fix this. It cancels remaining planned steps, but the generated
summary is produced *after* the topic finishes. It also has a side effect: the next user message is
treated as a new conversation, which breaks follow-up cards.

The documented mechanism is the `OnGeneratedResponse` trigger with `System.ContinueResponse = false`:

```yaml
kind: AdaptiveDialog
beginDialog:
  kind: OnGeneratedResponse
  id: main
  condition: =Global.SuppressResponse
  actions:
    - kind: SetVariable
      variable: System.ContinueResponse
      value: =false
    - kind: SetVariable
      variable: Global.SuppressResponse
      value: =false
```

Each card-only topic sets `Global.SuppressResponse = true` as its final action. The trigger is
global, so the flag is what makes it selective — free-text questions still get a generated answer.
**Clearing the flag inside the trigger is essential**; without the reset it silences the agent for
the rest of the conversation.

Note the UI label and YAML `kind` differ, and the `kind` is not in the documentation — it is
`OnGeneratedResponse`. The variables take a `System.` prefix the docs omit.
