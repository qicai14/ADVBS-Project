# GSHG hotel database (ADVBS group assignment)

## Where you work

Each member edits **only their own folder**:

| Folder | Role | Who |
|--------|------|-----|
| `M1_Reservations_Availability/` | Reservations and room availability | Lim Qi Cai |
| `M2_Guests_Occupancy/` | Guests and room occupancy | Brosnan |
| `M4_Changes_Cancellations_NoShows/` | Changes, cancellations and no-shows | Melvin |
| `M5_Billing_Payments_Maintenance/` | Billing, payments and maintenance | Shawn |

We are 4, so M3 (rates and services) is not done (lecturer agreed).

Your folder has three files (plus `M#_report.md` for your report sections, in Markdown):
- `M#_objects.sql`: your constraint, optimisation, stored procedure (or function) and trigger.
- `M#_queries.sql`: your 7 queries (already listed in the file).
- `M#_tests.sql`: shows your procedure, trigger and constraint working and rejecting bad data.

What to build for your role: `design/design-review.md` (your M# row in tables 1b and 1c).

## Read-only for you

Everything outside your folder. If something there is wrong or missing (a table, a column, test data), tell Lim; don't change it yourself.

## How to run (SSMS 22)

1. Open and run `sql/01_tables.sql` (creates the `GSHG` database from scratch).
2. Run `sql/02_data.sql` (test data; the header lists every test scenario).
3. Run `M1_Reservations_Availability/M1_objects.sql` (it adds a column your scripts may rely on), then your own `M#_objects.sql`, then your queries and tests.

Rerun steps 1–3 any time to get a clean database.

## Saving your work (Git)

Nobody commits or pushes to `main` (it is protected, Lim included). Work on your own branch and merge through a pull request:

1. `git checkout main` then `git pull` (get the latest).
2. `git checkout -b m2-guests` (your own branch, once; use your slot and area).
3. Commit only files in your folder, then `git push -u origin m2-guests`.
4. On GitHub, open a pull request into `main`.
5. Lim reviews and approves. Merge only when GitHub says there are no conflicts; if it shows conflicts, ask Lim.

Before each new piece of work: `git checkout main`, `git pull`, `git checkout m2-guests`, `git merge main`.

## Rules

- SQL style: `docs/sql-conventions.md`. Report style: `docs/documentation-style.md`.
- Using Claude Code? The repo turns on two plugins (`academic-research-skills`, `humanizer`). Accept the folder-trust prompt and they load in your next session; nothing to install.
