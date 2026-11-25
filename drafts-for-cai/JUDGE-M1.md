# cai:judge on M1 (2026-11-26, Opus, fresh context, rubric.md pinned)

Ordinal bands 0-5 per row (not marks; the brief gives no sub-weights). No SQL was run: every PASS and measurement is unverified.

| Row | Band | Main reason |
|---|---|---|
| 1a ER model (M1 part) | 3/5 | `design/erd.md:98-108` STAY has no `hotel_id`, though M1 adds it; design-review.md:38 says the copy helps queries that still join RESERVATION (i, v). Only iv and vii use it |
| 1b Constraint, SP design | 5/5 | Full functional tables, report 21-49 |
| 1c Trigger, optimisation design | 4/5 | 3NF break justified (report 15), trade-off argued; weakened by the erd/design-review mismatch |
| 2a Constraints | 5/5 | `CK_STAY_dates` WITH CHECK, test 7 |
| 2b Triggers | 5/5 | Set-based, rollback before RAISERROR, re-activation gap closed. Untested: `trg_Stay_SyncHotel` UPDATE may nest-fire `trg_Stay_NoOverlap` once more (probably harmless) |
| 2c Stored procedure | 4/5 | Rate check (objects 192-206) runs outside the transaction; inner `JOIN ROOM_RATE` (232-235) would silently drop a night without a rate; nothing re-checks the night count |
| 2d Optimisation implemented | 4/5 | 47 -> 11 logical reads claimed, but the plan screenshot is a placeholder (report 151); no index on STAY.room_id; column nullable |
| 2e SQL queries | 4/5 | 7 present with explanations; query i depends on GETDATE(); query vii double-counts overlapping maintenance; result screenshots are placeholders |
| 3 Demo, group rows, reflection, "cannot explain" conditions | NOT ASSESSED | |

Total 34/40 on bands (not a percentage).

TOP3
1. Add `hotel_id` to STAY in `design/erd.md` and correct design-review.md:38 to name queries iv and vii (Lim-owned directive files, so Cai edits).
2. Replace the 12 screenshot placeholders, starting with the before/after plans (report 151).
3. Query vii: merge overlapping maintenance per room; queries i and vii: replace GETDATE() with a declared as-of date.

Optional extra from the judge: check that the rate check and the INSERT in `usp_CreateReservation` cannot disagree (move it inside the transaction or have the INSERT fail loudly on a missing rate).
