# Personal reflection report: Lim Qi Cai (M1, Reservations and room availability)

## 1. Introduction

The Global Stay Hotel Group (GSHG) database is our group's SQL Server design for a hotel chain operating in several countries. It covers rooms and rates, reservations, changes and cancellations, check-in and check-out, billing and room maintenance. The brief is written for five members. We are four, so the lecturer agreed that we drop the M3 slot (rates and services).

I took slot M1, reservations and room availability, and designed and built its constraint, optimisation, stored procedure, the triggers that stop double-booking, and queries i to vii. I also set up the shared base of the project: the GitHub repository, the scripts everyone runs first (`sql/01_tables.sql` and `sql/02_data.sql`), a starter folder for each member, the team guide (`README.md`) and the branch and pull-request workflow. This report covers both roles.

## 2. The system as a whole

The database has 21 tables. HOTEL, ROOM, ROOM_CATEGORY and ROOM_RATE describe what each hotel sells, with rates that vary by hotel, category, rate plan and date. A RESERVATION is made by one guest at one hotel and has one STAY row per room, and each STAY has one STAY_NIGHT row per night with the rate charged at booking time. STAY_OCCUPANT records who is in each room. Cancellations, no-shows and date or category changes have their own tables (CANCELLATION, NO_SHOW, RESERVATION_CHANGE), and BILL, PAYMENT and MAINTENANCE cover check-out, money and rooms out of service.

On 19 October 2026 the original diagram was reviewed against the brief, and the group agreed to fix eight gaps. For example, MAINTENANCE had only one end date where the queries needed an expected and an actual end. The revised ERD and logical design are in `design/erd.md`, which stays in 3NF except where a member justifies a denormalisation.

Each member owns one area, with one constraint, one stored procedure, one trigger, a distinct denormalisation strategy and seven queries:

| Slot | Member | Area | Main objects |
|---|---|---|---|
| M1 | Lim Qi Cai | Reservations and availability | `usp_CreateReservation`, `trg_Stay_NoOverlap`, `STAY.hotel_id` |
| M2 | Brosnan | Guests and occupancy | `usp_AddOccupant`, `trg_StayOccupant_Rules` |
| M4 | Melvin | Changes, cancellations, no-shows | `usp_CancelReservation`, `trg_Stay_LogChange` |
| M5 | Shawn | Billing, payments, maintenance | `usp_CheckOutAndBill`, `trg_Stay_BlockMaintenance` |

The parts meet at STAY. My procedure creates the reservation and its stays, M2 adds occupants to those stays, M4 changes or cancels them, and M5 bills them and blocks rooms under maintenance. Three of us put AFTER triggers on STAY, so the rules have to agree across members (section 4).

## 3. My element: M1

### Constraint and optimisation

The constraint `CK_STAY_dates` requires a stay's check-out to come after its check-in. A CHECK constraint is enough here because the rule compares two columns of the same row.

For the optimisation I duplicated a foreign key attribute in a 1:* relationship, copying `hotel_id` from RESERVATION into STAY. I chose it because STAY is the table my queries and trigger read most, and nearly every one of them filters or groups stays by hotel. ROOM cannot give the hotel for every stay, because a stay can be booked with no room assigned yet. The cost is that STAY is no longer in 3NF and the copy could drift. Two triggers keep it correct: `trg_Stay_SyncHotel` fills the copy on every insert and update of STAY, and `trg_Reservation_SyncStayHotel` updates the stays when a reservation moves hotel. I set `trg_Stay_SyncHotel` to fire first with `sp_settriggerorder`, so the other STAY triggers already see the value.

To check that the change paid off, query iv (most-booked category at a hotel) was run in both forms on a clean rebuild. The normalised version needed 47 logical reads, 36 of them on RESERVATION. The version that reads `STAY.hotel_id` needed 11, with one fewer join in the plan. Both returned the same answer. The test data is small, but the per-stay lookup into RESERVATION, the cost that grows with the number of stays, has gone.

### Stored procedure

`usp_CreateReservation` books any number of rooms in one call. The rooms arrive as a table-valued parameter (`dbo.StayRequest`), because a fixed list of scalar parameters cannot hold "one or more rooms". It validates the request before it writes (for example, each room must belong to the hotel, an accessible request must get an accessible room, and every night must have a rate), then inserts the RESERVATION, STAY and STAY_NIGHT rows in one transaction. If any room fails, nothing is saved. It returns the new ID through an OUTPUT parameter and a return code of 0 or 1.

### Triggers

`trg_Stay_NoOverlap` enforces the brief's rule that a room cannot be assigned to overlapping active stays. It also rejects a room from another hotel. It has to be a trigger because the rule compares a row with other STAY rows and reads RESERVATION, which a CHECK constraint cannot do. I used AFTER rather than INSTEAD OF because a table can have only one INSTEAD OF trigger per action, and M4 and M5 also need triggers on STAY. The trigger works on the whole `inserted` set, so a multi-row insert with one bad row is rejected as a whole.

My first version had a known gap: setting a cancelled reservation back to an active status made its stays active again without any STAY row changing, so the overlap trigger never fired. I decided to close the gap, and `trg_Reservation_NoOverlapOnReactivate` now re-checks overlaps when a status changes from Cancelled (tests 13a and 13b).

### Queries

Queries i to vii range from room availability (excluding overlapping active stays and maintenance) to a ROLLUP of confirmed reservations by hotel and category. For my additional query I chose occupancy rate by hotel and month, because it reuses the availability logic. Every result was checked by hand against the test data, for example that query i returns only room 202 for Kuala Lumpur Deluxe on 10 to 14 February 2027.

### What testing and review changed

`M1_tests.sql` grew from 13 checks to 16, each rolled back so the shared data does not change, and all 16 pass on two clean rebuilds. An SQL code review on 23 October led to three fixes:

- My triggers originally called RAISERROR before ROLLBACK, following the lecture pattern. If a caller wrapped the statement in TRY/CATCH, RAISERROR jumped straight to the caller's CATCH block and the rollback never ran, so a double booking could be kept or even committed. I swapped the two lines, and test 14 proves the trigger now rolls back even when the caller catches the error.
- A same-day booking from 14:00 to 18:00 produced a stay with zero priced nights. The procedure now requires at least one night per room, and test 11 has a fourth check for it.
- The night generator now uses an explicit ORDER BY, so it always returns nights 1 to n.

The review also flagged a possible race condition between two bookings. A test from the day before already answered it: two sessions booked the same room at the same time, the second waited about six seconds for the first to commit and was then rejected, and only one stay was saved. I therefore kept SQL Server's default locking and recorded the test in my report.

[Lim: confirm or rewrite in your own words] The rollback-order bug taught me the most. The original order worked when a statement was run on its own and failed only when a caller used TRY/CATCH, so ordinary testing would not have caught it.

## 4. Integration with the team

Because I wrote the base scripts, every member builds on the same 21 tables and test data. My `M1_objects.sql` adds the `STAY.hotel_id` column that other scripts may rely on, so the run order in `README.md` is: `01_tables.sql`, `02_data.sql`, `M1_objects.sql`, then each member's own objects, queries and tests.

For the parts to fit, everyone has to read "available" the same way. I recorded these rules in `docs/status.md`:

- An active stay is one whose reservation is not Cancelled.
- Two stays overlap when `a.checkin < b.checkout AND b.checkin < a.checkout`, so a 12:00 check-out and a 14:00 check-in on the same day do not clash.
- A maintenance job blocks its room from `start_date` to `actual_end_date`, otherwise to `expected_end_date`, and with no end once `expected_end_date` has passed without an `actual_end_date`.
- `trg_Stay_SyncHotel` runs first on STAY and updates STAY itself, so any other AFTER UPDATE trigger on STAY must act only when its own columns changed.

The last two rules affect Melvin and Shawn directly, so I prepared a note for each of them. Melvin's `trg_Stay_LogChange` would otherwise log my sync update as a change that never happened, so it must compare `inserted` with `deleted`. It also cannot be set to fire first, because only one trigger per action can be, and mine holds that place. Shawn's maintenance trigger must use the same maintenance window as my availability query, so that the trigger and query i agree.

Every member, including me, works on their own branch and merges into `main` only through a pull request. `main` is protected and I approve each request. My M1 work went in through pull requests #3, #4, #5 and #7. Members edit only their own `M#_` folder and ask me for changes to shared files.

At the time of writing, M1 is complete and merged, and M2, M4 and M5 are building their objects on top of it. [Lim: update this paragraph once the teammates' parts are merged, and describe how the final integration went.]

## 5. Tools and process

I work on a Mac, so I ran SQL Server 2022 in Docker (an amd64 image under Rosetta) and wrote the SQL in VS Code with the MSSQL extension. My teammates use SSMS 22 on Windows.

I used Claude Code, an AI coding assistant, throughout M1. It helped write and test the SQL, found and verified academic sources by DOI or ISBN, and drafted report text. The module sets no restriction on AI use. I directed and verified the work. After each unattended run the assistant left a written report listing every decision it had made without me, such as which review findings to leave as they were, and I reviewed those decisions before merging. No change reached `main` without my pull-request approval, and I spot-checked the cited sources on Google Scholar. Because the brief gives zero marks for triggers a group cannot explain, I need to be able to defend every M1 decision in the viva.

[Lim: confirm or rewrite in your own words] Working this way meant more of my time went into reviewing, testing and deciding than into typing SQL.

## 6. Challenges and what I learned

[Lim: confirm or rewrite in your own words; this section is drafted from the repo history, not from your own account.] The hardest design problem was keeping one rule true across several members' code. Double-booking can come from my procedure, from a direct UPDATE in another member's procedure, or from re-activating a cancelled reservation. Putting the rule in a trigger made it hold on every path, and the re-activation case showed me that a rule about STAY can be broken by a change to another table.

Trigger interaction was the second problem. Three members' AFTER triggers fire on the same STAY statement, and one of mine updates STAY again. I learned how trigger order works, why only one trigger per action can be first, and why an AFTER UPDATE trigger must compare `inserted` with `deleted` instead of assuming that something changed.

Measuring query iv before and after the optimisation, and running the two-session booking test, showed me that a claim about performance or concurrency needs a test behind it. I also learned that the report must cite academic sources found on Google Scholar, not the lecture slides my first draft had used.

[Lim: confirm or rewrite in your own words] Coordinating a team of four through branches and pull requests was new to me, and I set up the folders and run order before anyone wrote SQL to avoid conflicts later.

## 7. What I would improve

- Add a non-clustered index on `STAY(room_id, scheduled_checkin, scheduled_checkout)`. The overlap trigger and query i search STAY by room, so a real-sized table would need it. I left it out because indexing is not one of the Week 10 strategies.
- Merge overlapping maintenance jobs per room before counting them in query vii, which currently subtracts the shared days twice.
- Make queries i and vii take a reference date instead of `GETDATE()`, so their results do not change with the day they are run.
- Check maintenance clashes when a cancelled reservation is re-activated. That rule belongs to M5, so it needs agreement with Shawn.

[Lim: confirm or rewrite in your own words] If I started again, I would agree the shared rules with the team before writing any triggers, instead of writing them down after M1 was built.

## 8. Conclusion

M1 books one or more rooms in a single all-or-nothing call, stops double-booking on every path that writes to STAY and answers the seven reservation and availability queries, with 16 passing tests. Beyond my slot, I set up the scripts, repository and workflow the team builds on, and wrote down the rules the other members' code must follow. [Lim: confirm or rewrite in your own words] The project showed me that in a shared database, getting the rules to agree between members takes as much care as writing the SQL.
