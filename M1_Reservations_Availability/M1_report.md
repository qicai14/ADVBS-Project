# M1 report sections: Reservations and room availability

## 1. Optimisation strategy (Design 1b)

M1 - Lim Qi Cai

### Strategy: duplicating foreign key attributes in a 1:* relationship

M1 uses the W10 strategy "duplicating FK attributes in 1:* relationships to reduce joins", one of five denormalisation strategies for speeding up frequent or critical transactions (Connolly & Begg, 2009).

In RESERVATION 1:* STAY, a reservation belongs to one hotel and has one STAY row per room. Normalised, STAY has no hotel column, so any query that filters or groups stays by hotel must join RESERVATION. M1 copies `hotel_id` into STAY as a foreign key to HOTEL (`FK_STAY_HOTEL`).

ROOM cannot supply the hotel for every stay, because `STAY.room_id` is NULL until a room is assigned (the third room in test 1). W10 slide 16 makes the same point about `PropertyForRent.branchNo`: a property with no staff allocated cannot reach its branch through Staff.

### Queries that benefit

Query iv (most frequently booked category at a hotel) reads STAY alone. The before and after versions follow the layout of W10 slides 11 and 12. Before, using the normalised design (kept as a comment in `M1_queries.sql`):

```sql
SELECT TOP (1) WITH TIES rc.category_name, COUNT(*)
FROM STAY s
JOIN RESERVATION r ON r.reservation_id = s.reservation_id
JOIN ROOM_CATEGORY rc ON rc.category_id = s.category_id
WHERE r.hotel_id = @hotel_id
  AND CAST(s.scheduled_checkin AS DATE) <= @to_date
  AND CAST(s.scheduled_checkout AS DATE) > @from_date
GROUP BY rc.category_name
ORDER BY COUNT(*) DESC;
```

After, with `hotel_id` copied into STAY:

```sql
SELECT TOP (1) WITH TIES rc.category_name AS room_category, COUNT(*) AS rooms_booked
FROM STAY s
JOIN ROOM_CATEGORY rc ON rc.category_id = s.category_id
WHERE s.hotel_id = @hotel_id
  AND CAST(s.scheduled_checkin AS DATE) <= @to_date
  AND CAST(s.scheduled_checkout AS DATE) > @from_date
GROUP BY rc.category_name
ORDER BY COUNT(*) DESC;
```

The join to RESERVATION is gone. Query vii (occupancy) also groups room-nights sold by `s.hotel_id`.

### Cost and how it is controlled

W10 slide 4 warns that denormalisation makes implementation more complex and speeds up retrievals while slowing down updates. Here the cost is a transitive dependency: `stay_id -> reservation_id -> hotel_id`, so STAY is no longer in 3NF and the copy can drift from `RESERVATION.hotel_id`. Two triggers keep it consistent:

| Trigger | Fires on | What it does |
|---|---|---|
| `trg_Stay_SyncHotel` | AFTER INSERT, UPDATE on STAY | Sets `STAY.hotel_id` from the stay's reservation whenever it is missing or different. Set to fire first (`sp_settriggerorder`) so the other STAY triggers (M1, M4, M5) already see the value. |
| `trg_Reservation_SyncStayHotel` | AFTER UPDATE on RESERVATION | When a reservation's `hotel_id` changes, updates every one of its stays. `trg_Stay_NoOverlap` then rejects the move if an assigned room belongs to the old hotel (test 12b). |

`STAY.hotel_id` is nullable because an AFTER trigger fills it just after the insert; a NOT NULL column would reject the row before the trigger ran. Existing stays were backfilled with a one-off UPDATE.

### Why the denormalisation is justified

Availability, most-booked category, occupancy and the overlap check all read STAY, so it is the table M1 reads most. The copy is written once when the stay is created and changes only if a reservation moves hotel. The triggers set it on every insert and update path, so no caller has to remember it (test 12a). With one write per stay against many reads, W10's trade-off of faster reads for slower updates is worth taking.

## 2. Constraint, stored procedure and trigger (Design 1c)

M1 - Lim Qi Cai

### 2.1 Constraint: `CK_STAY_dates`

| Item | Description |
|---|---|
| Purpose | Stop a stay that ends before, or at the same moment as, it starts. |
| Business rule | A stay has a check-in and a later check-out. |
| Table | STAY |
| Definition | `CHECK (scheduled_checkout > scheduled_checkin)`, added `WITH CHECK` so existing rows are validated too. |
| Error | SQL Server's CHECK constraint violation naming `CK_STAY_dates`; the INSERT or UPDATE is rejected (test 7). |

A CHECK constraint is enough because the rule compares two columns of the same row (W6 slide 6, domain constraints).

### 2.2 Stored procedure: `usp_CreateReservation`

| Item | Description |
|---|---|
| Purpose | Create a reservation for one or more rooms in a single call. |
| Business rule | A guest can book one or more rooms under one reservation; a new reservation starts as Pending. |
| Inputs | `@hotel_id`, `@booker_id`, `@rate_plan_id`, `@rooms`: a table-valued parameter of user-defined type `dbo.StayRequest`, one row per room with `room_id` (NULL if not assigned yet), `category_id` (NULL to take the room's category), `checkin`, `checkout` and `accessible_requested` (default 0). |
| Outputs | `@reservation_id OUTPUT` (NULL on failure); return code 0 for success, 1 for failure. |
| Tables affected | Inserts into RESERVATION (status Pending), STAY (one row per room) and STAY_NIGHT (one row per night, `rate_charged` taken from ROOM_RATE at booking time). |
| Checks before writing | Hotel, booker and rate plan exist; at least one room; check-out after check-in for every room; at most 60 nights; each room has a `room_id` or a `category_id`; a given room belongs to the hotel; it matches the requested category; an accessible request gets an accessible room; every night of every room has a rate for the hotel, category and rate plan. |
| Checks during the write | The STAY triggers fire on the insert: `trg_Stay_SyncHotel`, `trg_Stay_NoOverlap` and M5's `trg_Stay_BlockMaintenance`. |
| Errors | `RAISERROR` severity 16 with a specific message, for example "Room %d is not a room of hotel %d." or "No room rate is set for at least one night of this booking." Errors raised inside the transaction are caught, the transaction is rolled back and the message is re-raised as "Reservation not created: ...". |

As W5 slide 13 advises, the procedure validates its parameters first and returns early with RAISERROR, so a bad request never opens a transaction. The three INSERTs run inside `BEGIN TRY ... BEGIN TRANSACTION ... COMMIT`, and the CATCH block rolls back if `@@TRANCOUNT > 0`. The OUTPUT parameter and `SCOPE_IDENTITY()` follow W5 slide 14.

The procedure does not repeat the overlap check. That rule sits in the trigger, so it holds for every path that writes to STAY, including direct UPDATEs by other members' procedures (tests 3, 6 and 8 use plain DML, not the procedure).

### 2.3 Trigger: `trg_Stay_NoOverlap`

| Item | Description |
|---|---|
| Purpose | Stop double-booking a room. |
| Business rules | (1) A room cannot be assigned to overlapping active stays. (2) A stay can only use a room of its reservation's hotel. |
| Table and timing | STAY, AFTER INSERT, UPDATE. Returns at once unless `room_id`, `scheduled_checkin`, `scheduled_checkout`, `reservation_id` or `hotel_id` changed (`IF UPDATE(...)`, W6 slide 29). |
| Rule 1 check | Joins `inserted` to RESERVATION, ROOM and HOTEL and looks for a room whose hotel differs from the reservation's hotel. |
| Rule 2 check | Joins `inserted` to other STAY rows in the same room (`s.stay_id <> i.stay_id`) where neither reservation is Cancelled and `i.checkin < s.checkout AND s.checkin < i.checkout`. |
| Errors | "Room %s (%s) is not a room of %s, the hotel of this reservation." or "Room %s at %s is already booked from %s to %s (stay %d)." followed by `ROLLBACK TRANSACTION`, the pattern on W6 slide 26. |

The trigger works on the whole `inserted` set, so a multi-row INSERT is checked row by row and one bad row rejects the whole statement (test 8). Because it is an AFTER trigger, STAY already contains the new rows when it runs, so two new rows in the same statement are checked against each other (test 9).

Overlap is strict: a guest checking out at 12:00 and the next checking in at 14:00 the same day do not clash (test 4; reservations 1019 and 1020 in the test data).

This rule has to be a trigger. W6 slide 22 states that a CHECK constraint can reference only the columns of the row it is defined on, and that cross-table business rules must be defined as triggers. The overlap rule compares a new stay with other rows of STAY and reads the status from RESERVATION. The hotel rule reads ROOM and RESERVATION. A CHECK constraint can see neither.

W6 slide 15 notes that rolling back in an AFTER trigger is expensive, since the data is changed twice. INSTEAD OF would avoid that, but a table allows only one INSTEAD OF trigger per action (W6 slide 31) and M4 and M5 also have triggers on STAY, so AFTER lets all of them run.

## 3. T-SQL feature justification (Implementation)

M1 - Lim Qi Cai

M1's T-SQL feature is the stored procedure `usp_CreateReservation`. A booking writes to three tables: one RESERVATION row, one STAY row per room and one STAY_NIGHT row per night (test 1 writes 1, 3 and 7).

The procedure wraps those writes in one transaction. W9 defines atomicity as the "all or nothing" property: a transaction is performed in its entirety or not at all (Connolly & Begg, 2009). If the second room of a booking clashes with another stay, the trigger rolls back and the first room's STAY row and the RESERVATION row are undone too. Test 2 checks that the RESERVATION row count is unchanged after a rejected booking, and test 10 checks the same for a booking with an unpriced night.

The table-valued parameter is what makes one call per booking possible. A scalar parameter list can only describe a fixed number of rooms, but the case study says a guest can book one or more rooms under a single reservation. `dbo.StayRequest` carries any number of rooms in one call, and the procedure inserts them with one set-based INSERT.

| Alternative | Why M1 did not use it |
|---|---|
| The application sends the INSERTs itself | Every client would repeat the validation, pricing and transaction handling. W5 slides 5 and 6 give shared application logic, a hidden schema and less network traffic as reasons for procedures. |
| One procedure call per room | Each call would be a separate transaction unless the caller wrapped them in one. If room 3 failed, rooms 1 and 2 would already be saved under a reservation the guest never completed, which breaks atomicity. |
| A user-defined function | A function cannot insert into tables, so it cannot create the booking. W5's notes also say functions cannot specify output parameters, which the procedure uses to return `@reservation_id`, alongside a return code (0 success, 1 failure) the caller can branch on. |

## 4. Testing summary

M1 - Lim Qi Cai

`M1_tests.sql` runs 13 checks, each in its own transaction that is always rolled back, so the shared test data does not change. Each prints PASS or FAIL. Prices use the Kuala Lumpur Flexible rates from 1 July 2026: Standard RM 275.00, Deluxe RM 418.00, Family RM 572.00 per night.

| # | Scenario | Object tested | Expected outcome |
|---|---|---|---|
| 1 | Book rooms 101 (Standard, 2 nights), 301 (Family, 3 nights) and an unassigned Deluxe (2 nights) in one call | Procedure, sync trigger | Pending reservation, 3 stays, 7 nights, total RM 3,102.00, `hotel_id` filled on every stay |
| 2 | Book room 201 for 11-13 Feb 2027 while reservation 1019 holds it 10-14 Feb | Procedure and overlap trigger | "already booked"; RESERVATION count unchanged |
| 3 | Move reservation 1020's check-in to 13 Feb 2027 | Overlap trigger on UPDATE | Rejected as "already booked" |
| 4 | Book room 201 from 14:00 on 16 Feb 2027, after 1020 checks out at 12:00 | Strict overlap rule | Accepted |
| 5 | Book Singapore room 201 over cancelled reservation 1014 (2-4 Jul 2026) | Active-stay rule | Accepted |
| 6 | Change stay 5020 (Kuala Lumpur) to a Singapore room | Hotel rule in trigger | Rejected as "is not a room of" |
| 7 | Insert a stay with check-out equal to check-in | `CK_STAY_dates` | Rejected by the constraint |
| 8 | Insert two stays in one statement, one free and one overlapping | Trigger, set-based | Whole statement rejected; STAY count unchanged |
| 9 | Book the same room twice with overlapping dates in one call | AFTER trigger sees both new rows | Rejected as "already booked" |
| 10 | Book across New Year 2028, after the rates end on 31 Dec 2027 | Procedure rate check | "No room rate"; nothing saved |
| 11 | Wrong-hotel room, wrong category, accessible request on a non-accessible room | Procedure input checks | Three separate rejections, each with its own message |
| 12a | Insert a stay without `hotel_id` | `trg_Stay_SyncHotel` | `hotel_id` set to 1 automatically |
| 12b | Move reservation 1019 to Singapore | `trg_Reservation_SyncStayHotel` then overlap trigger | Rejected because its assigned room is in Kuala Lumpur |

Tests 2, 8 and 10 also compare row counts before and after, which shows that nothing was saved.

## 5. Queries i to vii

M1 - Lim Qi Cai

Three rules run through all seven queries (stated at the top of `M1_queries.sql`):

- An active stay is one whose reservation status is not Cancelled.
- A confirmed reservation has status Confirmed only.
- A stay occupies the nights from its check-in date up to, but not including, its check-out date. It overlaps a period when `checkin_date < period_end AND checkout_date > period_start`.

### i. Available rooms

Lists rooms of the hotel and category with two `NOT EXISTS` subqueries: no overlapping active stay and no overlapping maintenance job. `NOT EXISTS` asks directly whether any clashing row exists and, unlike `NOT IN`, is not affected by NULLs.

A maintenance job blocks its room from `start_date` to its effective end date, inclusive: `actual_end_date` if finished, otherwise `expected_end_date`, or no end at all once that date has passed, because overdue work keeps the room out of service.

Expected result: Kuala Lumpur, Deluxe, 10 to 14 Feb 2027 lists only room 202, because room 201 is held by reservation 1019. Room 202 has a maintenance job expected to end on 30 Oct 2026. If that job is still open after 30 Oct 2026, it is overdue and room 202 is excluded too. The same dates for Suite return no rooms because of a planned renovation.

### ii. Confirmed reservations at a hotel

Joins RESERVATION, GUEST (the booker), STAY and ROOM_CATEGORY, filtered by hotel and `status = 'Confirmed'`, with one row per room so a multi-room booking shows each room's dates. The category comes from `STAY.category_id`, which is known before a room is assigned; ROOM is LEFT JOINed and an unassigned room shows "(not assigned)". Expected result for Kuala Lumpur: reservations 1019 and 1020.

### iii. Status descriptions

A searched `CASE` turns each status into a sentence. A no-show is stored as status Cancelled plus a NO_SHOW row, so the first `WHEN` tests for that row with `EXISTS` and describes it as a no-show before the general Cancelled branch. An `ELSE 'Unknown status'` catches any value outside the list.

### iv. Most frequently booked category

Counts stays per category at the hotel whose nights fall in the date range, and uses `TOP (1) WITH TIES` so that categories sharing first place are all listed instead of one picked arbitrarily. It counts bookings later cancelled as well, because the question asks about demand, not completed stays. It reads `STAY.hotel_id`, the M1 optimisation (section 1). Expected result for Kuala Lumpur in 2026: Deluxe, with 3 bookings.

### v. Confirmed reservations by hotel and category with ROLLUP

`GROUP BY ROLLUP (h.name, rc.category_name)` produces the detail rows, one subtotal per hotel and a grand total. `GROUPING()` replaces the NULLs ROLLUP leaves in the summary rows with the labels "Hotel subtotal", "All hotels" and "Grand total", and the ORDER BY uses `GROUPING()` to put each subtotal after its hotel's rows and the grand total last.

The count is `COUNT(DISTINCT r.reservation_id)`. A reservation with rooms in two categories counts once in each category row but only once in its hotel subtotal; a plain `COUNT(*)` would count rooms, not reservations, and inflate the subtotals. ROLLUP was chosen over CUBE because the brief asks for hotel subtotals and a grand total, not category totals across hotels.

### vi. Hotels with no confirmed reservations in a month

Selects from HOTEL with `NOT EXISTS` over confirmed stays that have at least one night in the month. Starting from HOTEL means a hotel with no reservations at all is still returned. The month runs from `@month_start` to the first day of the next month (exclusive), which handles months of any length. Expected result for February 2027: GSHG Singapore and GSHG Bangkok.

### vii. Additional query: occupancy rate by hotel and month

Occupancy is a core demand measure: it shows how much of each hotel's room capacity was sold in each month of the year. The formula used:

- occupancy % = room-nights sold / room-nights available x 100
- room-nights sold = nights of active stays in the month, counted from STAY_NIGHT
- room-nights available = rooms x days in the month, minus days rooms were under maintenance

A recursive CTE generates the 12 months; `maintenance_days` clips each job to the month with query i's effective-end rule, and `nights_sold` counts STAY_NIGHT rows by `STAY.hotel_id`. LEFT JOINs keep months with no sales at 0%, `NULLIF` avoids division by zero, and the year filter is a date range rather than `YEAR(night_date)` so an index on the date could be used.

## 6. Assumptions and known limitations

M1 - Lim Qi Cai

Assumptions:

- Active means any status except Cancelled, so a Pending booking already holds its room while it waits for confirmation.
- "Confirmed" (queries ii, v and vi) excludes Checked In and Checked Out reservations.
- A reservation counts for a period when any of its stays has a night in it.
- A no-show is stored as Cancelled plus a NO_SHOW row, so it frees the room.
- All money is in Malaysian ringgit (RM), the group's reporting currency, so totals across hotels in different countries can be compared.
- The guest named on a reservation is the booker.

Known limitations:

- Overdue open maintenance keeps blocking the room with no end date. Queries i and vii compare `expected_end_date` with `GETDATE()`, so their results depend on the day they are run. Query i's result for room 202 changes after 30 Oct 2026.
- Re-activating a cancelled reservation (changing RESERVATION.status from Cancelled back to an active status) is not re-checked for overlaps. `trg_Stay_NoOverlap` fires on STAY changes, and a status change touches only RESERVATION. A trigger on `RESERVATION.status` would close this gap.
- Concurrency relies on SQL Server's default locking under READ COMMITTED. Exclusive locks are held until commit (W9), so a second booking's trigger waits for the first booking's uncommitted STAY row. Two simultaneous bookings of one room have not been tested, and W9 notes that locking does not prevent deadlocks, where SQL Server rolls one transaction back.
- There is no index on `STAY.room_id`. The overlap trigger and query i search STAY by room, so a larger STAY table would need a non-clustered index on `STAY(room_id, scheduled_checkin, scheduled_checkout)`.
- `STAY.hotel_id` is nullable (section 1), so only the triggers, not the column definition, guarantee it is filled.
- The procedure accepts at most 60 nights per room. Its night generator builds up to 64 dates, so longer stays would need a larger generator.

## References

Connolly, T., & Begg, C. (2009). *Database systems: A practical approach to design, implementation and management* (5th ed.). Addison-Wesley.

[REF?] Lecture slides W5 Stored Procedures, W6 Triggers, W9 Transaction Management and W10 Optimization Strategy, CT004-3-3 Advanced Database Systems, Asia Pacific University. Lecturer name and year needed for the APA entry.
