---
name: build-copilot-agent
description: Guides the design and construction of an agent in the new Copilot Studio experience, from requirements through to a routing-tested build. Activate when someone asks to build, create, design or scaffold a Copilot Studio agent, add child agents, decide between one agent and an orchestrator, or set up Dataverse grounding for an agent. Do not use for classic-experience bot topics, Power Virtual Agents migrations, or for authoring a skill package on its own.
---

# Build a Copilot Studio agent

Take a request for an agent and turn it into a working, routing-tested build in the new
Copilot Studio experience.

Work through the steps in order. Do not skip step 1 — nearly every failed agent build is a
scoping failure that was visible at the start.

## Step 1 — Decide the shape before building anything

Establish what the agent is for, then answer one question: **one agent, or an orchestrator
with children?**

Ask for, and do not assume:

- What questions users will actually type, in their words
- What data exists, and in which system
- Who the users are, and whether they should all see the same data
- What the agent must never do

Then apply this test.

**One agent** when:

- A single coherent instruction set covers the scope without contradicting itself
- Questions are broadly of one kind
- Data lives in a handful of related tables
- No workflow needs two domains at once

**Orchestrator with child agents** when *all* of these hold:

- Domains have genuinely different vocabulary, data and permissions
- You can name at least three workflows spanning two or more domains
- A single instruction set has started contradicting itself
- Different domains need different grounding or access control

If the user cannot name three cross-domain workflows, build one agent. Say so plainly and
explain why: every extra child agent is another description competing to answer the same
question, and routing accuracy is what you pay with.

Scale is not the trigger. A read-only lookup assistant serving thousands of people is still
one agent. Domain diversity is the trigger.

## Step 2 — Write the routing descriptions first

If there are child agents, write their `description` fields before writing any instructions.
The orchestrator routes on `description`. It matters more than the agent name and more than
the child's own instructions.

A description must contain:

1. **Concrete trigger phrases** — the words users actually type, not an abstract summary
2. **Explicit negative scope** — "Do not use for…", naming the sibling that owns it
3. **The ambiguous cases**, resolved — the ones that read like another domain but aren't
4. **No overlap on the same noun** with any sibling

Check every pair of descriptions against each other. If two could plausibly answer the same
question, the orchestrator will pick arbitrarily, and it will look like a model quality
problem when it is a specification problem.

## Step 3 — Decide where each rule belongs

Sort every business rule into one of three homes. Getting this wrong is the most common
structural mistake.

| Rule type | Home | Why |
|---|---|---|
| Tone, scope, escalation, privacy posture | Agent instructions | Applies to everything the agent says |
| Domain calculations, multi-step procedures, cross-domain workflows | A skill | Versioned, testable in isolation, reusable |
| Access control, table scoping | Tool configuration | Enforced, not requested |

If the fix you are reaching for is "add another sentence to the instructions", check whether
it is really a skill change or a configuration change.

Agent instructions cannot change system behaviour. Microsoft documents that instructions are
for tone and flow and specifically cannot modify how adaptive cards are triggered. Do not try
to solve structural problems by editing the prompt.

## Step 4 — Ground it

Add the Dataverse MCP server, scoped per agent to only the tables that agent owns. Narrower
grounding produces better answers and makes the domain boundary real rather than advisory.

```yaml
kind: McpTool
authMode: Maker
connectionReference: <connection reference>
connectorId: /providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps
operationId: InvokeMCP
```

**Read-only is not enforced by the tool.** The MCP tool will create, update and delete if
asked. If the agent must not write, you need both:

- an explicit instruction forbidding create, update and delete, and
- table scoping that does not grant more than the agent needs

State this to the user. Assuming the tool restricts writes is a real and common mistake.

If records are looked up by a natural identifier — an email address, a ticket number, an
order number — recommend an **alternate key** on that column. It keeps queries delegable at
scale and avoids GUIDs appearing in conversation.

## Step 5 — Write instructions

Keep them about tone, scope and escalation. Every agent should carry these, adapted:

- Never invent a number, date, name or status. If a lookup returns nothing, say so.
- Render choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.
- Format dates as "Thursday 30 July", not an ISO timestamp.
- Report exceptions, not everything. A list of things that are fine is noise.

Add a confirmation gate for anything that writes:

> Show a plain-language summary and get an explicit yes before creating anything. Never
> create a record silently, and never treat an ambiguous reply as consent.

Summarise back in the user's language, not in field names.

## Step 6 — Test routing before testing answers

Routing failures present as bad answers, so separate them. Build a table of representative
questions and the agent or skill each should reach. Confirm the right one picked it up
*before* judging any response text.

When a question lands in the wrong place, fix the **description**. Do not fix it in the
instructions — it will not hold.

## Step 7 — Tell them what still has to be done by hand

Be explicit about what cannot be automated, so nobody plans a pipeline around it:

- **Connection binding** — OAuth consent, once per environment, in the portal
- **Skill upload** — portal only, one zip at a time
- **Flow creation** — no `pac flow create` equivalent

`pac copilot create / clone / push / publish` provisions agents from source but cannot bind
connections.

## Rules

- Never invent table or column names. Ask, or read them from the environment.
- Do not produce a multi-agent design because it sounds more sophisticated. Recommend the
  simpler shape when it fits, and say why.
- If the requirements are too vague to write a routing description, that is the finding.
  Say so rather than generating a plausible-looking agent that will route badly.
- Do not claim a behaviour is configurable if you have not verified it.

## Finish with

The one thing most likely to go wrong in this specific build, and how they will know. For
most builds that is an overlapping pair of routing descriptions — name the pair.
