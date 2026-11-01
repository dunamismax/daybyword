# Editorial review

How a plan, and anything describing a tradition, is reviewed before it
reaches readers, and how readers' reports of errors are handled
(AGENTS.md §3, §4, and §6). Every plan file records its level in `review`
(docs/catalog-format.md), and release builds include only plans at
`reviewed` or above.

## Review levels

| Level | Means | Who |
|---|---|---|
| `checked` | Automated validation passed: `make catalog` read the file, checked every reference against the versification, verified the coverage claim, and found a rights entry. Every plan is at least here. | The compiler |
| `reviewed` | An editorial review against the plan's own rules and AGENTS.md §3, as below. Original plans may be approved at this level. | An agent or the owner |
| `expert` | A named reviewer who uses the source has reviewed it. Prayer-book plans need this after 1.0 (D15), and it is never claimed before it happens. | The owner, or a reviewer the owner names |

## What a review checks

A reviewer at `reviewed` works through the plan and records the result in
the commit that raises its level:

1. **The rules.** The schedule follows the rules the plan file states (for
   example, balanced by reading time, one chapter a day, canonical order),
   and nothing in it contradicts its `instructions`.
2. **The facts.** The computed coverage, repeats, omissions, and workload
   match what the plan page says, and the `limitations` name what the plan
   leaves out.
3. **The wording.** Every reader-facing field follows AGENTS.md §3: what the
   plan is, whom it suits, its workload and coverage, and its limitations,
   in plain and neutral words; no sermon, no claim about what God wants, no
   guilt, and no promise the product does not keep. Terms such as
   *lectionary* are explained where they appear.
4. **Traditions and labels.** A tradition, canon, or edition is described as
   its own members would recognize it, labeled precisely, and never ranked.
5. **Rights.** The `rights` entry in `catalog/SOURCES.md` is `cleared` for
   the readers the plan reaches, with its credit line in place.
6. **Transcriptions** (historic plans, after 1.0) are proofread twice
   against page images of the identified printing, and the source's own
   errors are kept visible as errata, never silently corrected.

A plan that fails any of these stays at `checked` until it is fixed.

## Readers' reports of errors

Readers report mistakes to support@daybyword.com (BUILD.md P16.2), naming
the plan, the reading, and what is wrong.

1. **Anonymize first.** Nothing that identifies the reader enters the
   repository: no name, address, or story (AGENTS.md §6). The report is
   restated as the plan, the assignment, and the problem.
2. **Check it.** Against the versification and the plan's rules for an
   original plan, or against the page images for a transcribed one.
3. **Correct it as a new version.** A confirmed error is fixed in the plan
   file with its `version` raised; assignment ids stay as they are
   (docs/catalog-format.md), so readers' history keeps its meaning. A fix
   to wording only follows the same path. The commit records what was wrong
   and why. How an enrollment then moves to the new version is P28.3.
4. **Keep a source's own errors visible.** In a transcribed plan, an error
   in the source itself is recorded as an erratum beside the original
   reading, never replaced by the "expected" reading.
5. **Reply plainly.** Say what was found and what changed, without claiming
   a review or a fix that has not happened.
