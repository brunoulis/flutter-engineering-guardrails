# Refactor plan — [feature/file]

**Mode:** refactor | deep-refactor
**Behavior change allowed:** NO (if YES, reclassify as feature/migration)

## 1. Need and evidence
- Problem: [bug/duplication/coupling/ownership/UX/performance]
- Evidence with `path:line` or test/trace:
- Observable impact:
- Minimal measurable goal:

## 2. Preserved contracts
- Inputs / outputs:
- Loading/empty/error/success:
- Routes/back/deep links:
- API, serialization and persistence:
- Responsive/design/tokens/a11y:

## 3. Alternatives
| Option | Benefit | Risk | Decision |
|---|---|---|---|
| Do not modify yet | ... | ... | ... |
| Minimal in-place extraction | ... | ... | ... |
| Redesign feature/layer | ... | ... | ... |

## 4. Reversible slices
| Slice | Files | Isolated change | Prior test | PASS criterion | Rollback |
|---|---|---|---|---|---|
| 1 | ... | ... | ... | ... | ... |

## 5. Risk review
- Races/await/dispose/listeners:
- State/routing/provider scope:
- Data model/edge cases/errors:
- Web/desktop compatibility:
- New dependencies (justification):

## 6. Before → after
- Responsibilities removed:
- Responsibilities added:
- Net complexity and new classes:
- Debt still present by explicit decision:

## 7. Tests run (facts only)
- [ ] Format — command and result
- [ ] Analyzer — command and result
- [ ] Unit/widget tests — commands and result
- [ ] Integration/manual — actual conditions
- [ ] Before/after metrics — measurements or "not measured"

## 8. Regression surface (see `references/refactor-execution.md`)
- Existing files modified (with reason):
- Public contracts affected:
- New mutable state and its owner:
- Existing execution paths affected / verified:
