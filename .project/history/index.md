# History

Everything under `history/` is History: what *happened*. Nothing here is current state — a reader who only wants to know what the project **is** today can skip this whole directory and lose nothing.

Nothing under `history/` is ever renamed, moved or deleted: the file path is the concept id, so moving it breaks every link to it. To correct a document, write a new one, mark the old one `status: deprecated`, and link the two.

## Sections

- [cycles/](cycles/index.md) — per-cycle `REPORT-*.md` and `pipeline-*.md` (`type: cycle-report`)
- [decisions/](decisions/index.md) — why we chose this, and what we discarded (`type: decision`)
- [changes/](changes/index.md) — what changed, where, under which decision (`type: change`)
- [incidents/](incidents/index.md) — what broke, how we found out, blast radius (`type: incident`)
