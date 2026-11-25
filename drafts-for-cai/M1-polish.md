# M1 checked against the 17 Nov lecture tips

Source of tips: `Cai-Claude-Vault/reports/academic/ADVBS-lecture-tips-2026-11-17.md` (whisper transcript, rough). Checked files on main 62a2a02: `M1_report.md` (7,453 words), `M1_objects.sql`, `M1_tests.sql`, `M1_queries.sql`, `M1_reflection.md` (2,261 words). No M1 file was edited by this draft. Not run: SQL cannot be executed here (no SQL Server), so the "16 tests PASS" claim from status.md is unverified.

| Tip | M1 status | Action for Cai |
|---|---|---|
| ERD diagram only; no data dictionary, no attribute tables | M1 report has none. The 2.6.1 tables describe a constraint, procedure and trigger (purpose, rule, inputs), not attributes | None |
| No normalisation walkthrough; keep a one-line justification for deliberate denormalisation | 2.5.1 states STAY drops below 3NF through the stay -> reservation -> hotel dependency and why that is accepted | None. Optional: trim 2.5.1 paragraph 4 (about 130 words on nullable column and backfill) if the group document runs long |
| Each member: one procedure + one trigger (may do more); a trigger may call a procedure | `usp_CreateReservation`, `CK_STAY_dates`, `trg_Stay_NoOverlap` plus 3 supporting triggers | None |
| Test your own procedure and trigger, supply test data, label your name | 16 tests in `M1_tests.sql`, "(Lim Qi Cai)" on every M1 heading | None |
| Seven queries plain: SELECT, JOIN, window functions; no procedures or triggers in them | All seven are plain SELECTs. Parameters use `DECLARE @x` at the top of each block, query vii uses a CTE (`WITH months AS`), v uses `ROLLUP`, iv `TOP WITH TIES`. No procedure or trigger calls | Decide: `DECLARE` is a variable, not a procedure, and is shown in the lectures. If the lecturer's "plain" is strict, replace variables with literals in the report copy only. Low risk. No window function (LAG etc.) used; not required |
| Optimisation uses a separate database (garbled in audio) | M1's strategy is applied to the shared GSHG database (adds `STAY.hotel_id`, `trg_Stay_SyncHotel`) and measured on query iv (47 -> 11 logical reads) | Ask the lecturer what "separate database" means before the demo. If a copy is required: one script that restores GSHG as `GSHG_Opt` and runs `M1_objects.sql` there. The shared schema is then untouched by M1's column |
| One group document, ERD first, optimisation later | M1 text is numbered to the scaffold (2.5.1, 2.6.1, 3.3, 3.4, 3.5, 3.6.1). Lim copies sections into the OneDrive master | None |
| M5 dependency (see `M5-options.md`) | Report and script comments name M5's `trg_Stay_BlockMaintenance` | Edit only after the M5 decision |

Open items in the M1 text (not changed): 12 `[Screenshot: ...]` placeholders (lines 151, 185, 257, 305, 385, 441, 473, 511, 538, 569, 598, 675) need SSMS/Docker runs by Cai; the reference list has 12 entries (checked), several dated 2021-2025, so no change needed. The reflection draft is Cai's own wording and is left untouched; the zero-mark rule means Cai should be able to explain each object aloud: an explain-back sheet per object could be drafted if wanted.
