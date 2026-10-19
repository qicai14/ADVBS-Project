# SQL conventions

- T-SQL only: `TOP`/`OFFSET FETCH` not `LIMIT`, `IDENTITY` not `AUTO_INCREMENT`, `GETDATE()`, `DATEDIFF`, `GROUP BY ROLLUP(...)`.
- Table and column names match `design/erd.md` exactly (UPPER_SNAKE tables, lower_snake columns).
- Name objects: `PK_TABLE`, `FK_CHILD_PARENT`, `CK_TABLE_rule`, `usp_Verb`, `trg_Table_Rule`, `fn_Name`.
- Every member's constraint, procedure and trigger starts with a comment: owner slot (M1–M5) and the business rule it enforces.
- Scripts must run unchanged in SSMS (team, Windows) and VS Code + MSSQL extension against SQL Server in Docker (Mac): no file paths in `CREATE DATABASE`, no SQLCMD-mode commands, batches split with `GO`.
- Lowest SQL Server version in the team: TBD. Until confirmed, avoid 2022+ functions (`GREATEST`, `LEAST`, `DATETRUNC`, `GENERATE_SERIES`).
- Run order: `sql/01_tables.sql` (rebuilds the database from scratch), `sql/02_data.sql`, then each member's `M#_*/M#_objects.sql`, then their queries and tests.
- Member scripts are rerunnable: `CREATE OR ALTER` for procedures, functions and triggers; `DROP CONSTRAINT IF EXISTS` before adding a constraint.
- Tests that insert or change data run inside `BEGIN TRAN … ROLLBACK` so the shared test data stays the same.
- ASCII only in `.sql` files (SSMS may misread other characters).
- Triggers must handle multi-row `inserted`/`deleted` sets (no scalar variable from `inserted`).
- Money in query output is labelled RM (e.g. `AS [Total (RM)]`).
