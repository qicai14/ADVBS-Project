# M5 (Billing, payments, maintenance): options for Cai, decide by Mon 8 Dec 2026

Facts from the repo (main at 62a2a02, checked 2026-11-26)
- `M2_*`, `M4_*`, `M5_*` are still starter stubs (about 600-1,300 bytes per file, all headings and TODO comments, `<name>`/`<TP number>` placeholders). Nothing pushed since 23 Oct. Only M1 is real.
- `docs/status.md` lists M5 as Shawn's slot and says the lecturer's rule is "each member picks one slot, the unpicked slot is dropped" (M3 dropped). The 17 Nov recording says only that with fewer than five members you may choose any slots (06:07-06:26); it does not name M5. The lecturer's ruling on M5 is not in writing.
- M5 scope (design-review.md): CHECK on PAYMENT and MAINTENANCE, partitioning of PAYMENT (optimisation), `usp_CheckOutAndBill`, trigger `trg_Stay_BlockMaintenance`, queries xxix-xxxv (billing, outstanding balances, maintenance, rooms with no stays).
- What M1 already leans on from M5: the report (2.6.1 table row "Checks during the write", section 5 bullet 3) and `M1_objects.sql` comments (lines ~116, 216, 333) name `trg_Stay_BlockMaintenance`. M1 queries i and vii read the MAINTENANCE table directly, so they work whatever M5 does (the maintenance rows are in `02_data.sql`).
- Marks: M5 content sits inside rubric rows 2a-2e (implementation, 50%) and 1b/1c (design, 30%). Sub-weights are not given. Unexplained trigger/procedure = zero for that feature.

## Options

A. Drop M5 entirely
- Pros: 35 queries become 28 (28 = 4 x 7 less 7); one fewer procedure, trigger, constraint, strategy to build and defend; frees time for FYP (16 Dec) and DDAC.
- Cons: no billing/payment code, so the demo cannot show check-out and bill (the scenario is "Hotel Reservation and Payment"); the brief text still says five; M1 text must drop its M5 references; if Shawn is a contributing member this contradicts the group's own decision (status.md) and needs the group's agreement.
- Needs: the lecturer's confirmation in writing; Shawn's agreement.

B. Keep M5 with Shawn (status quo)
- Pros: full scope, no extra load on Cai; every member explains their own slot.
- Cons: 4 weeks of silence from M2/M4/M5 so far; highest schedule risk; if Shawn's trigger or procedure is not understood by the group in the viva, zero marks for that feature and group-wide queries lose marks.
- Cai's cost: review PRs, plus M1's trigger text depends on M5 landing.

C. Cai covers M5 (Claude drafts, Cai learns and explains)
- Pros: full demo including billing; Claude can draft procedure, trigger, partitioning and 7 queries test-first in about a day of work; M1/M5 interlock (maintenance blocking) is already designed in M1 terms.
- Cons: Cai defends two slots in the viva and 14 queries; December already holds FYP and DDAC; the zero-mark rule bites hardest here; takes a slot from Shawn without his consent.

D. Hybrid: keep M5 with Shawn, but Cai owns only `trg_Stay_BlockMaintenance` (the one piece M1 depends on) as an agreed swap
- Pros: M1 text stays true; small for Cai (one AFTER trigger, same pattern as `trg_Stay_NoOverlap`); Shawn keeps billing, payments and partitioning.
- Cons: still needs Shawn to deliver the rest; two owners on one slot makes the workload matrix and "who explains what" messier.

## Recommendation: A if Shawn is confirmed inactive, otherwise D
- Lean A when: by Mon 1 Dec Shawn has not pushed a branch AND the lecturer confirms in writing. Then merge M2 and M4 first (they are the real risk too) and revisit C only if both are merged and tested by 8 Dec (this is the revamp plan's own switch condition).
- Lean B or D when: Shawn replies and commits something by 1 Dec.
- What would change this: the lecturer insisting on five slots (forces B/C); M2 and M4 also stalling (then drop to a smaller scope or ask the lecturer about extra time rather than add M5 to Cai).
- Do not decide on Claude's say: the decision changes whose work is assessed.

## If A is chosen: M1 edits to make (about 30 minutes, not done yet)
1. `M1_report.md`: remove "and M5's `trg_Stay_BlockMaintenance`" from the 2.6.1 procedure table; rewrite section 5 bullet 3; drop "M5's rule" wording.
2. `M1_objects.sql` comments lines ~116, 216, 333: replace M5 references with "maintenance blocking is not enforced".
3. Query i and vii still honour maintenance by reading MAINTENANCE directly, so no query change.
4. `design/design-review.md` and README (Lim owns): mark M5 rows not implemented, as with M3. Reduce the query count in the workload matrix to 28.
