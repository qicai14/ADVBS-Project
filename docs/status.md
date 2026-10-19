# Status

As of 2026-10-19.

Done:
- Design reviewed and fixed; group agreed to all fixes (`design/design-review.md`, `design/erd.md`, SVG exports in `design/`).
- 1b and 1c allocated per member slot (tables in `design/design-review.md`).
- Report scaffold: `submissions/ADVBS Group Assignment - Documentation.docx` (headings, placeholders, all 35 queries, workload matrix, APA references).

Next: implementation SQL in `sql/` (tables, test data, then each member's constraint, SP, trigger, optimisation, queries).

Open decisions:
- Lecturer: is M5 (billing, payments, maintenance) dropped or shared, given a group of 4?
- Member names, TP numbers and slot assignment; intake code; lecturer name (cover page).
- Lowest SQL Server version among teammates (`SELECT @@VERSION;`), which sets the T-SQL feature floor.
- Whether the lecturer expects journal papers in references, or textbooks and Microsoft docs are enough.

Environment: teammates use SSMS on Windows; one member uses a Mac with VS Code + MSSQL extension and SQL Server in Docker (amd64 image under Rosetta, which Microsoft does not support but which generally works).
