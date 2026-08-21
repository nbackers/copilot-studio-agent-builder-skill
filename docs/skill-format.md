# SKILL.md format

The format and the upload rules, including the ones whose failure messages don't explain
themselves.

---

## Structure

```markdown
---
name: lowercase-kebab-case
description: What it produces, the phrases that activate it, what it is not for, and anything it requires.
---

# Skill Name

<One or two lines: what the user gets and why it beats asking piecemeal.>

## When to use this

<The narrower case that should NOT trigger it.>

## Step 1 - <Establish inputs>

## Step 2 - Gather

## Step 3 - Write the output

## Rules

## Finish with
```

## Upload requirements

These cause failures, and the errors rarely name the real cause.

| Requirement | Failure if wrong |
|---|---|
| File named `SKILL.md` | Not recognised as a skill |
| `SKILL.md` at the **archive root** | Upload rejected or skill empty |
| `name` lowercase letters, numbers, hyphens | Rejected |
| `name` matches the folder name | Rejected |
| UTF-8 **without BOM** | Front matter silently fails to parse |
| Front matter delimited by `---` | Treated as body text |

`Build-SkillPackage.ps1` checks all of these.

### The BOM

`Set-Content -Encoding UTF8` in Windows PowerShell writes a UTF-8 **BOM**. The BOM sits before the
opening `---`, so the front matter parser doesn't see a delimiter on line 1 and the whole block is
read as body - meaning the skill has no `name` and no `description`, and won't route.

Write without a BOM:

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### The archive root

```powershell
# Correct - contents of the folder
Compress-Archive -Path .\my-skill\* -DestinationPath .\my-skill.zip

# Wrong - nests SKILL.md inside my-skill/
Compress-Archive -Path .\my-skill -DestinationPath .\my-skill.zip
```

Verify:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead('.\my-skill.zip')
$z.Entries.FullName    # must be SKILL.md, not my-skill/SKILL.md
$z.Dispose()
```

## Writing the description

The `description` decides whether the skill ever runs. It is the router's only input.

**Weak:**

```yaml
description: Helps with stock questions.
```

Too abstract to match against, no negative scope, will overlap with anything stock-related.

**Strong:**

```yaml
description: Produces the pre-open operational briefing for a single store, pulling together
  stock exceptions, inbound purchase orders, open IT tickets and roster gaps into one
  prioritised summary. Activate when a team member asks for a morning briefing, daily huddle
  notes, a start-of-day summary, "what do I need to know today", or a store health check.
  Requires a store name.
```

It states what it produces, lists the phrases users actually type, and names a hard requirement.

Add negative scope where a sibling could compete:

```yaml
  Do not use for single-domain questions such as "what is low on stock" - answer those directly.
```

## Body conventions

**Give the output structure explicitly.** A fenced block showing the exact shape, with a length
limit. Unbounded output gets ignored.

**State the order of operations.** If all lookups should happen before any writing, say so - the
value of a cross-domain skill is the joined picture, not the individual facts.

**Put the reason next to the rule.** A rule with a reason survives editing; a bare instruction gets
dropped.

**Finish with a recommendation, not a summary.** "Finish with" should name the single most
important action and who owns it.

## Common mistakes

| Mistake | Why it hurts |
|---|---|
| Description restates the name | Nothing to match against |
| No negative scope | Overlaps with siblings, routing goes arbitrary |
| Agent instructions duplicated in the skill | Duplicates and drifts |
| Single lookup as a skill | Belongs in instructions |
| No output structure | Inconsistent formatting between runs |
| No demo hook | Can't tell if it works |
