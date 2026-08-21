# Copilot Studio Agent Builder Skill

Skills that build, review and package agents for the **new** Copilot Studio experience - codifying the patterns that decide whether an agent routes correctly, plus a validator that
catches the things which silently break a skill upload.

---

## The problem

The new Copilot Studio experience has limited file-based authoring support, and the Copilot Skills
extension does not cover it. So agents get built by hand, in the portal, from memory.

The consequence is not that building is slow. It is that **the patterns which decide whether an
agent works are not written down anywhere**, so every team rediscovers them the same way:
- They split into four child agents because it looks more mature, and routing degrades - because
  every extra child is another description competing for the same question.
- They fix a routing problem by editing the agent's instructions, which the router never reads.
- They assume the Dataverse MCP tool is read-only because the agent was told to be. It isn't.
- They put a domain calculation in agent instructions, where it can't be tested or reused.
- Their skill zip won't upload and the error doesn't say that `SKILL.md` is one folder too deep, or
  that the file has a UTF-8 BOM.

Each of these costs hours, and none of them are visible in the product.

## What this solves

| Problem | How this repo solves it |
|---|---|
| No guidance on one agent vs orchestrator | A decision test with the counter-example |
| Routing misfires and prompt edits don't help | Routing is driven by `description`; a diagnostic skill for when it fails |
| Rules end up in the wrong place | A three-way test: instructions, skill, or tool config |
| MCP assumed read-only | Documents that it is not, and what actually enforces it |
| Skill uploads fail with unhelpful errors | Validator catching BOM, name case, name/folder mismatch, archive root |
| Descriptions overlap silently | Validator warns on missing negative scope |
| No way to test routing | A routing test-table method that catches regressions |

---

## What's in this repo

**This is a skill set and a pattern reference, not a deployable solution.**

| Included | Not included |
|---|---|
| Three `SKILL.md` files, ready to upload | A packaged solution |
| Packaging validator (tested against malformed input) | A deployed agent |
| Pattern and format documentation | Automated agent provisioning |

The skills are prose instructions - that is what a Copilot Studio skill is. They are complete and
uploadable, and equally usable as prompts in any harness that reads markdown skills.

**Verification status:** the validator is tested. The three skills have **not** been uploaded to
Copilot Studio and activated as part of this repo, so their activation phrasing is untested. The
patterns they encode come from several real agent builds.

---

## The three skills

| Skill | Use when |
|---|---|
| **`build-copilot-agent`** | Designing and building an agent from requirements through to a routing-tested build |
| **`review-agent-routing`** | An agent answers from the wrong domain, or a skill won't fire |
| **`package-agent-skill`** | Writing a skill, or a skill package won't upload |

Each is a `SKILL.md`, uploadable to Copilot Studio, or usable directly as a prompt in any agent
harness that reads markdown skills.

## Quick start

```powershell
# Validate and package all three
.\scripts\Build-SkillPackage.ps1

# Validate without packaging
.\scripts\Build-SkillPackage.ps1 -ValidateOnly
```

Upload each `skills/*.zip` via **Copilot Studio → Build → Skills → Add skill → Upload a skill**.

---

## The patterns, in brief

The full set is in [docs/authoring-patterns.md](docs/authoring-patterns.md). The load-bearing ones:

**Routing is driven by `description`, not name or instructions.** The orchestrator reads each child
agent's description to decide where a question goes. It outweighs the child's own instructions
entirely. If routing misfires, that is the only thing worth changing.

**Descriptions need negative scope.** A description that only says what it covers will attract
adjacent questions. Each needs "Do not use for…", naming the sibling that owns it. Two descriptions
that both plausibly cover the same noun will route arbitrarily - and it looks like a model quality
problem when it is a specification problem.

**The Dataverse MCP tool is not read-only.** It will create, update and delete if asked. Read-only
needs an explicit instruction *and* table scoping. Assuming otherwise is common and wrong.

**Rules have three possible homes.** Tone and scope go in instructions. Domain calculations and
multi-step procedures go in skills, where they are versioned and testable. Access control goes in
tool configuration, where it is enforced rather than requested.

**Instructions cannot change system behaviour.** Microsoft documents that instructions are for tone
and flow and specifically cannot modify how adaptive cards are triggered. If your fix is another
sentence in the prompt, check whether it belongs somewhere else.

**Child agents cannot answer cross-domain questions.** Once you split into children, the joins have
to live in skills. A four-agent design with no cross-cutting skills has taken the cost of
orchestration without the benefit.

---

## Contents

| Path | Purpose |
|---|---|
| `skills/build-copilot-agent/` | Design and build an agent |
| `skills/review-agent-routing/` | Diagnose routing failures |
| `skills/package-agent-skill/` | Author and package a skill |
| `scripts/Build-SkillPackage.ps1` | Validate and package |
| `docs/authoring-patterns.md` | Full pattern reference |
| `docs/skill-format.md` | `SKILL.md` format and upload requirements |

---

## What is and isn't verified

**Verified** - the packaging rules are enforced by `Build-SkillPackage.ps1` and tested against
deliberately malformed input:
- `SKILL.md` must be at the archive root, not inside a folder
- `name` must be lowercase kebab case and match the folder name
- UTF-8 **without** BOM; a BOM breaks front matter parsing
- Skills upload one zip at a time through the portal

**Drawn from repeated practice** across several agent builds - consistent, but behavioural rather
than mechanically testable:
- Routing follows `description` over name and instructions
- Overlapping descriptions produce arbitrary routing
- Negative scope materially improves accuracy

**Not verified:**
- Whether routing behaviour is identical across all Copilot Studio regions and releases
- Exact model behaviour when three or more descriptions overlap

If your experience differs, please open an issue - the routing patterns are the part most worth
correcting.

---

## Licence

MIT - see [LICENSE](LICENSE).
