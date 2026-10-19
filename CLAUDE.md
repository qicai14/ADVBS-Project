# GSHG hotel reservation database (APU CT004-3-3 Advanced Database Systems group assignment)

Due 3 Jan 2027. Group of 4; the brief assumes 5 (member slots M1–M5). Slots: M1 Lim Qi Cai, M2 Brosnan, M4 Melvin, M5 Shawn; M3 is dropped (lecturer agreed).
Target is Microsoft SQL Server / T-SQL only. Marking follows what the lectures teach, not general best practice (e.g. "optimisation strategy" = W10 denormalisation).

- Brief: `brief/assignment-brief.md` (text of the `.docx`)
- Lecture notes: `lectures/*.md`, text extracted from the `.pptx`; image-only slides are empty, so open the `.pptx` for those.
- Design (ERD, logical design, member allocation): `design/erd.md`, `design/design-review.md`. Mermaid is the source of truth; `design/legacy/` is the old excalidraw.
- Current state and open decisions: `docs/status.md`
- Writing the report: `docs/documentation-style.md`
- Writing SQL: `docs/sql-conventions.md`
- Team guide (who edits what, run order): `README.md`
- Deliverables: `submissions/`. The master report lives on OneDrive (hosting and version history); the local `.docx` is only a working draft.
- Commits: no `Co-Authored-By` or other Claude attribution lines.

Ownership:
- Only Lim Qi Cai (git user `LIM QI CAI`) edits the directive files (`CLAUDE.md`, `README.md`, `docs/`, `design/`, `.github/`, `.claude/`) and the shared scripts in `sql/`. For anyone else, do not edit them; suggest the change for Lim instead. Keep them lean.
- Every other member edits only their own `M#_*` folder.
- Everyone, Lim included, works on their own branch and merges to `main` only by a pull request with no conflicts; Lim approves. Never commit or push to `main`.

Delegation (the main session plans, writes the SQL and reviews; agents in `.claude/agents/`):
- `chore` (Haiku, low effort): searches, file listings, renames, moves, find-and-replace, running a script and reporting the output.
- `doc-writer`: all report prose, so drafts stay out of the main context. Brief it with section, owner slot, sources and where to save.
- Everything needing judgement (design, SQL logic, reviewing results) stays in the main session.
