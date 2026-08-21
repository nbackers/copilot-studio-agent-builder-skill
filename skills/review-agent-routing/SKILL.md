---
name: review-agent-routing
description: Diagnoses why a Copilot Studio agent answers from the wrong domain, fires the wrong skill, or fails to activate a skill at all. Activate when someone says their agent is routing incorrectly, picking the wrong child agent, ignoring a skill, answering from the wrong data, or behaving inconsistently for similar questions. Do not use for problems with the answer's wording or tone, or for authentication and connection failures.
---

# Review agent routing

Routing failures look like answer-quality failures. The agent responds fluently and
confidently from the wrong place, so the instinct is to edit the prompt - which does not fix
it and usually makes it worse.

Diagnose the routing first.

## Step 1 - Establish what actually happened

Get the specific failing question, verbatim. Not a paraphrase - the exact text, because
routing is sensitive to wording.

Then determine:
- Which agent or skill **did** answer
- Which **should** have
- Whether it fails every time or intermittently

Intermittent routing on the same question almost always means two descriptions overlap, and
the model is picking between near-equivalent candidates.

## Step 2 - Read the descriptions, not the instructions

Collect the `description` of every child agent and every skill in scope. This is the router's
input. Ignore the instructions at this stage - they play no part in routing.

Lay them side by side and look for:

**Overlap on the same noun.** Two descriptions that both mention "stock", "orders" or
"tickets" will compete. Only one should claim each noun.

**Missing negative scope.** A description that only says what it covers will attract adjacent
questions. Each needs "Do not use for…", naming the sibling that owns it.

**Abstract summaries instead of trigger phrases.** "Handles inventory matters" gives the
router nothing to match. It needs the words users type.

**Unresolved ambiguity.** Questions that read like one domain and belong to another need
naming explicitly. Classic examples:
- "Damaged on arrival" reads like warranty, belongs to delivery
- "Is it in stock" belongs to availability even when the user already owns one
- "New starter needs a laptop" spans people and IT - usually a skill, not either agent

## Step 3 - Classify the failure

| Symptom | Cause | Fix |
|---|---|---|
| Consistently wrong domain | Target description lacks the trigger phrase; sibling claims it | Add phrasing to the right one, add negative scope to the wrong one |
| Alternates between two | Overlapping descriptions | Make them mutually exclusive on nouns |
| Skill never fires | Description too abstract, or a child agent answers first | Rewrite with concrete triggers; check the child isn't claiming it |
| Skill fires too eagerly | Description too broad | Narrow it, add "Requires…" and negative scope |
| Right domain, wrong data | Not routing - tool scoping or grounding | Check table scope, not descriptions |
| Cross-domain question answered from one domain | No cross-cutting skill exists | Add one; no child agent can join domains |

That last row matters. Once a build is split into child agents, **no child can answer a
cross-domain question by construction**. If the user expects one to, the design is missing a
skill.

## Step 4 - Fix in the right place

Fix routing in the `description`. Always.

Do not:
- Add routing rules to agent instructions - the router never reads them
- Rename agents to be more descriptive - the name is not the routing input
- Add trigger phrases to the orchestrator prompt - it routes on child descriptions

Rewrite the failing description with concrete trigger phrases, explicit negative scope, and
any ambiguous case resolved. Then check it against every sibling for overlap.

## Step 5 - Re-test the whole table, not just the fix

Changing one description shifts the boundary with its siblings. A fix for one question
routinely breaks another that used to work.

Keep a table of representative questions and their expected destination, and run all of it
after every description change. If the user does not have one, build it - it is the only way
to see regressions.

## Rules
- Never recommend an instruction change to fix a routing problem.
- Do not guess at the descriptions. Ask for them verbatim.
- If descriptions cannot be made non-overlapping, the domain split is wrong. Say so - the
  answer may be fewer agents.
- Distinguish routing failures from grounding failures. Right agent with wrong data is a
  scoping problem and needs a different fix.

## Finish with

The rewritten description, and the sibling it was overlapping with. Name both, so the user
understands the boundary that moved.
