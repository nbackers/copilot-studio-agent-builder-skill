---
name: package-agent-skill
description: Authors and packages a skill for upload to the new Copilot Studio experience, producing a correctly structured SKILL.md and a valid zip archive. Activate when someone asks to write a skill, create a skill package, fix a skill that will not upload, or convert a procedure or runbook into an agent skill. Do not use for diagnosing routing between existing skills, or for agent instructions.
---

# Package an agent skill

Turn a procedure into a skill the agent will activate at the right moment and follow
reliably.

## Step 1 — Confirm it should be a skill

A skill is right when the work is:

- **Multi-step**, with an order that matters
- **Cross-domain**, needing data an agent would otherwise gather separately
- **Rule-heavy**, with calculations or exclusions that must apply identically every time

It is the wrong home when the behaviour is tone, scope or a single lookup. That belongs in
agent instructions.

If the agent build has child agents, the strongest skills are the ones that span two or more
of them — those are the workflows no child agent can complete alone.

## Step 2 — Write the front matter

```markdown
---
name: lowercase-kebab-case
description: What it produces, then the phrases that should activate it, then what it is not for and anything it requires.
---
```

Requirements that cause upload failures if missed:

- `name` — lowercase letters, numbers and hyphens only
- `name` must **match the folder name exactly**
- File must be `SKILL.md`
- Encoding must be **UTF-8 without BOM** — a BOM breaks front matter parsing

**`description` drives activation.** It is what the router reads to decide whether this skill
runs. Write it before the body, and make it concrete: the phrases users type, what it is not
for, and any hard requirement such as "Requires a store name."

## Step 3 — Structure the body

```markdown
# Skill Name

<One or two lines: what the user gets, and why it beats asking piecemeal.>

## When to use this

<The narrower case that should NOT trigger it — steer to a direct answer instead.>

## Step 1 — <Establish the inputs>

<What must be known before doing anything. What to ask if it is missing.>

## Step 2 — Gather

<Each lookup, in order, with the filters and the exclusions. State when to gather
everything before writing anything.>

## Step 3 — Write the output

<Give the exact output structure in a fenced block. Include a length limit.>

## Rules

<The calculations, the exclusions, the never-invent rule, formatting.>

## Finish with

<What the user walks away with. A recommendation, not a summary.>
```

## Step 4 — Encode the rules that get got wrong

This is where a skill earns its place. Write down the domain rules that are commonly wrong,
with the reason:

- **Derived values.** If a figure must be calculated rather than read, state the arithmetic
  and say to lead with the result.
- **Exclusions.** What does not count. A delayed order is not cover.
- **Data errors.** What an impossible combination means, and what to do instead of showing it.
- **Never invent.** If a lookup returns nothing, say the section is clear rather than filling
  it in.
- **Labels not codes.** Never surface a raw option value, GUID, column name or table name.
- **Exceptions only.** A list of everything healthy does not get read.

Include a short "why" for each. A rule with a reason survives editing; a bare instruction
gets dropped.

## Step 5 — Give it a demo hook

Name one question that exercises the skill and lands on a real decision, with the data
conditions that make it work. A skill that returns "nothing urgent" against healthy data
demonstrates nothing — the seeded data has to contain the exception.

## Step 6 — Package

`SKILL.md` must sit at the **root** of the archive, not inside a folder:

```powershell
Compress-Archive -Path .\<skill-name>\* -DestinationPath .\<skill-name>.zip -Force
```

Verify before uploading:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead('.\<skill-name>.zip')
$z.Entries.FullName    # must show SKILL.md, not <skill-name>/SKILL.md
$z.Dispose()
```

Upload via **Copilot Studio → Build → Skills → Add skill → Upload a skill**, one at a time.

## Rules

- Never invent table or column names. Ask, or read them from the environment.
- Keep the output structure explicit and bounded. Unbounded output gets ignored.
- Do not restate agent instructions inside a skill — it duplicates and drifts.
- If the procedure is a single lookup, say so and put it in instructions instead.

## Finish with

The packaged zip path, and the one phrase most likely to activate it — so the user can test
activation immediately.
