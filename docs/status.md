# Status

As of 2026-10-23.

Done:
- Design reviewed and fixed; group agreed to all fixes (`design/design-review.md`, `design/erd.md`, SVG exports in `design/`).
- 1b and 1c allocated per member slot (tables in `design/design-review.md`).
- Report scaffold: `submissions/ADVBS Group Assignment - Documentation.docx` (headings, placeholders, all 35 queries, workload matrix, APA references).
- `sql/01_tables.sql` (21 tables, keys, defaults) and `sql/02_data.sql` (test data; scenario list in its header). Both run clean on SQL Server 2022 CU27; every 1c CHECK constraint accepts the data.
- Member folders `M1_…` to `M5_…` with starter files; team guide in `README.md`.
- M1 complete: objects, 16 tests (all PASS) and queries i–vii; report draft `M1_Reservations_Availability/M1_report.md` in the scaffold's numbering, with 10 verified citations (`M1_citations.json`).
- Tooling: academic-research-skills and humanizer plugins (project settings); agents `chore`, `doc-writer`, `citation-researcher`.

Next: M2, M4 and M5 build their `M#_objects.sql`, queries and tests. Lim copies the M1 sections into the OneDrive report and adds screenshots.

Decided:
- Lecturer: each of the 4 members picks one slot; the unpicked slot is dropped.
- Slots: M1 Lim Qi Cai, M2 Brosnan, M4 Melvin, M5 Shawn. M3 (rates and services) dropped; its folder removed.
- Teammates use SSMS 22.
- Everyone (Lim included) works on branches and merges by PR; Lim approves. `main` is protected.
- M1 rules other members must match: active stay = reservation not `Cancelled`; stays overlap when `a.checkin < b.checkout AND b.checkin < a.checkout`; a maintenance job blocks its room from `start_date` to `actual_end_date`, else `expected_end_date`, and indefinitely once `expected_end_date` has passed with no `actual_end_date`.
- STAY triggers: `trg_Stay_SyncHotel` (M1) runs first and updates STAY, so other AFTER UPDATE triggers on STAY must act only when their own columns changed.
- Test-data assumptions (state in report; may change if the logic needs it): money is Malaysian ringgit, shown as RM (`currency_code` keeps ISO `MYR`); no-show = status `Cancelled` + `NO_SHOW` row (not a cancellation); `noshow_charge_pct` is % of the booked room charge; "active" stay = reservation not `Cancelled`.

Open decisions:
- Full names, TP numbers; intake code; lecturer name (cover page). GitHub usernames to invite as collaborators.
- Lowest SQL Server engine version among teammates (`SELECT @@VERSION;`, not the SSMS version), which sets the T-SQL feature floor.
- Guests aged 12–17: not adult (rule) and not child (< 12). M2 decides their age category.
- Each member confirms or replaces their default additional query (`design/design-review.md`, last section).

Environment: teammates use SSMS 22 on Windows. Lim uses a Mac: VS Code + MSSQL extension, SQL Server 2022 in Docker (`docker-compose.yml`, amd64 image under Rosetta, which Microsoft does not support but which works; SA password in gitignored `.env`).
