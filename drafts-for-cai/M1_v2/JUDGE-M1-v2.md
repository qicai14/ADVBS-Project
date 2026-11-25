# cai:judge on M1 v2 (Opus, fresh context, same rubric)
Same 34/40 on ordinal bands as v1; bands unchanged (1a 3, 1b 5, 1c 4, 2a 5, 2b 5, 2c 4, 2d 4, 2e 4). Not run: no SQL Server.
- TOP3 status: (1) erd/design-review not addressed (Lim-owned; proposal file only); (2) screenshots not addressed; (3) query vii double-count and GETDATE() fixed in code, procedure night-count check added in code.
- T-SQL read-through: recursive `days` CTE, MAXRECURSION 400 after ORDER BY, DISTINCT room-day derived table, @as_of DECLAREs, in-transaction RAISERROR inside TRY: all valid on reading.
- Regressions found and since fixed by hand: stale report prose for query vii; fixed-behaviour bullet left in limitations; new procedure logic undocumented.
- Still open: untested new logic (needs a test with two overlapping MAINTENANCE rows and a rate-gap test), 12 screenshots, KL Oct 165 figure unchecked.
