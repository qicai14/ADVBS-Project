# M1 report sections: Reservations and room availability

M1 sections for the group report, numbered as in the scaffold.

## 2.5.1 M1: Duplicating foreign key attributes in 1:* relationships (Lim Qi Cai)

M1 uses the denormalisation strategy of duplicating foreign key attributes in a 1:* relationship to reduce joins. Connolly and Begg (2015) list it among five strategies for speeding up frequent or critical transactions.

In RESERVATION 1:* STAY, a reservation belongs to one hotel and has one STAY row per room. In the normalised design STAY has no hotel column, so any query that filters or groups stays by hotel has to join RESERVATION. M1 copies the hotel ID into STAY as a new column, `STAY.hotel_id`, with its own foreign key to HOTEL.

ROOM cannot supply the hotel for every stay. A stay's room is left empty until a room is assigned, as with the unassigned Deluxe room in test 1, and such a stay has no path to its hotel through ROOM. The textbook example of this strategy rests on the same point: a property with no staff allocated cannot reach its branch through Staff, so the branch number is copied onto the property (Connolly & Begg, 2015).

Two queries benefit directly. Query iv (most frequently booked category at a hotel) now reads STAY and ROOM_CATEGORY only, with no join to RESERVATION. Query vii (occupancy) groups room-nights sold by the hotel ID held on STAY. STAY is also the table M1 reads most often: room availability, the most-booked category, occupancy and the overlap check all read it.

Denormalisation makes implementation more complex and speeds up retrieval at the cost of slower updates (Ajayi et al., 2025; Connolly & Begg, 2015). Here it adds a transitive dependency, stay ID to reservation ID to hotel ID, so STAY is no longer in 3NF (Connolly & Begg, 2015), and the copy could drift from the hotel on the reservation. Two triggers stop that drift. `trg_Stay_SyncHotel` sets the copy from the stay's reservation every time a stay is inserted or updated, and it is set to fire before the other STAY triggers so that they already see the value. `trg_Reservation_SyncStayHotel` updates every stay of a reservation when that reservation moves to another hotel. The column has to be nullable, because the copy is filled by an AFTER trigger just after the row is written and a NOT NULL column would reject the row first. Stays that existed before the change were filled by a one-off update.

The trade-off is worth it here because the copy is written once, when the stay is created, and changes again only if a reservation moves hotel. The triggers handle every insert and update path, so no caller has to remember to set it (test 12a). With one write per stay against many reads, M1 accepts slower updates in exchange for faster reads (Ajayi et al., 2025). Section 3.3 measures the gain.

## 2.6.1 M1 (Lim Qi Cai)

**Constraint:** `CK_STAY_dates`

| Item | Description |
|---|---|
| Purpose | Stop a stay that ends before, or at the same moment as, it starts. |
| Business rule | A stay has a check-in and a later check-out. |
| Table | STAY |
| Definition | `CHECK (scheduled_checkout > scheduled_checkin)`, added `WITH CHECK` so existing rows are validated too. |
| Inputs and outputs | None; it is evaluated for every row written by an INSERT or UPDATE. |
| Error raised | SQL Server's CHECK constraint violation naming `CK_STAY_dates`; the statement is rejected (test 7). |

A CHECK constraint is enough here because the rule compares two columns of the same row (Connolly & Begg, 2015).

**Stored procedure:** `usp_CreateReservation`

| Item | Description |
|---|---|
| Purpose | Create a reservation for one or more rooms in a single call. |
| Business rule | A guest can book one or more rooms under one reservation, and a new reservation starts as Pending. |
| Inputs | `@hotel_id`, `@booker_id`, `@rate_plan_id`, and `@rooms`, a table-valued parameter of the user-defined type `dbo.StayRequest` with one row per room: `room_id` (NULL if not assigned yet), `category_id` (NULL to take the room's category), `checkin`, `checkout` and `accessible_requested` (default 0). |
| Outputs | `@reservation_id OUTPUT` (NULL on failure); return code 0 for success, 1 for failure. |
| Tables affected | Inserts into RESERVATION (status Pending), STAY (one row per room) and STAY_NIGHT (one row per night, with `rate_charged` taken from ROOM_RATE at booking time). |
| Checks before writing | Hotel, booker and rate plan exist; at least one room; every room booked for at least one full night, so check-out falls on a later date than check-in (a same-day 14:00 to 18:00 booking is rejected); at most 60 nights; each room has a `room_id` or a `category_id`; a given room belongs to the hotel and matches the requested category; an accessible request gets an accessible room; every night of every room has a rate for the hotel, category and rate plan. |
| Checks during the write | The STAY triggers fire on the insert: `trg_Stay_SyncHotel`, `trg_Stay_NoOverlap` and M5's `trg_Stay_BlockMaintenance`. |
| Errors raised | `RAISERROR` at severity 16 with a specific message, for example "Room %d is not a room of hotel %d.", "Each room must be booked for at least one night (check-out on a later date than check-in)." or "No room rate is set for at least one night of this booking." An error inside the transaction is caught, the transaction is rolled back and the message is raised again as "Reservation not created: ...". |

The procedure validates its parameters first and returns early with RAISERROR, so a bad request never opens a transaction. The three INSERTs run inside `BEGIN TRY ... BEGIN TRANSACTION ... COMMIT`, and the CATCH block rolls back if `@@TRANCOUNT > 0`. The OUTPUT parameter, filled from `SCOPE_IDENTITY()`, returns the new reservation ID.

The procedure does not repeat the overlap check. That rule lives in the trigger, so it holds for every path that writes to STAY, including direct UPDATEs from other members' procedures. Tests 3, 6 and 8 use plain DML rather than the procedure for this reason.

**Trigger:** `trg_Stay_NoOverlap`

| Item | Description |
|---|---|
| Purpose | Stop a room being double-booked. |
| Business rules | (1) A stay can only use a room of its reservation's hotel. (2) A room cannot be assigned to overlapping active stays. |
| Table and timing | STAY, AFTER INSERT, UPDATE. It returns at once unless `room_id`, `scheduled_checkin`, `scheduled_checkout`, `reservation_id` or `hotel_id` changed (`IF UPDATE(...)`; Microsoft, n.d.-b). |
| Inputs | The `inserted` rows. |
| Rule 1 check | Joins `inserted` to RESERVATION, ROOM and HOTEL and looks for a room whose hotel differs from the reservation's hotel. |
| Rule 2 check | Joins `inserted` to other STAY rows in the same room (`s.stay_id <> i.stay_id`) where neither reservation is Cancelled and `i.checkin < s.checkout AND s.checkin < i.checkout`. |
| Behaviour on violation | `ROLLBACK TRANSACTION` first, then `RAISERROR` with "Room %s (%s) is not a room of %s, the hotel of this reservation." or "Room %s at %s is already booked from %s to %s (stay %d)." |

The trigger rolls back before it raises the error. If a caller wraps the statement in TRY/CATCH, RAISERROR passes control straight to the caller's CATCH block, so a rollback placed after it would never run. With the rollback first, the bad row is always undone, even when a caller catches the error and forgets to roll back itself (test 14).

The trigger works on the whole `inserted` set. A multi-row INSERT is checked row by row, and one bad row rejects the whole statement (test 8). Because it runs AFTER the write, STAY already holds the new rows, so two new rows in the same statement are checked against each other (test 9). Overlap is strict: a guest checking out at 12:00 and the next guest checking in at 14:00 on the same day do not clash (test 4; reservations 1019 and 1020 in the test data).

This rule has to be a trigger. A CHECK constraint can reference only the columns of its own row, so business rules that span rows or tables are enforced by triggers, which fire automatically when the data changes (Connolly & Begg, 2015; Paton & Díaz, 1999). The overlap rule compares a new stay with other STAY rows and reads the status from RESERVATION, and the hotel rule reads ROOM and RESERVATION. A CHECK constraint can see none of these.

An AFTER trigger runs once the rows are written, so rejecting them means undoing work already done. An INSTEAD OF trigger would avoid that, but a table can have only one INSTEAD OF trigger per INSERT, UPDATE or DELETE (Microsoft, n.d.-b). M4 and M5 also have triggers on STAY, and AFTER lets all of them run.

Three smaller M1 triggers support the main one.

| Trigger | Fires on | What it does |
|---|---|---|
| `trg_Stay_SyncHotel` | AFTER INSERT, UPDATE on STAY | Sets `STAY.hotel_id` from the stay's reservation when it is missing or different (section 2.5.1). It is set to fire first (`sp_settriggerorder`), so the M1, M4 and M5 STAY triggers already see the value. |
| `trg_Reservation_SyncStayHotel` | AFTER UPDATE on RESERVATION | When a reservation's `hotel_id` changes, updates all of its stays. `trg_Stay_NoOverlap` then rejects the move if an assigned room belongs to the old hotel (test 12b). |
| `trg_Reservation_NoOverlapOnReactivate` | AFTER UPDATE on RESERVATION | A cancelled stay does not hold its room, so the room can be rebooked. If the cancelled reservation is later set back to an active status, its stays become active again without any STAY row changing, and `trg_Stay_NoOverlap` never fires. This trigger runs only when `status` changes from Cancelled to another value, applies the same overlap test to that reservation's stays, and on a clash rolls back and raises "Reservation %d cannot be re-activated: ..." (tests 13a and 13b). |

## 3.3 Optimisation Strategy Implementation - M1 (Lim Qi Cai)

The strategy from section 2.5.1 is implemented in `M1_objects.sql`. The excerpt below leaves out the rerun guards (`IF COL_LENGTH ...`, `IF OBJECT_ID ...`).

```sql
-- 1. Copy the parent's key into the child table, with its own foreign key
ALTER TABLE STAY ADD hotel_id INT NULL;
ALTER TABLE STAY ADD CONSTRAINT FK_STAY_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id);

-- 2. Backfill existing stays
UPDATE s
SET    s.hotel_id = r.hotel_id
FROM   STAY s
JOIN   RESERVATION r ON r.reservation_id = s.reservation_id
WHERE  s.hotel_id IS NULL OR s.hotel_id <> r.hotel_id;

-- 3. Keep the copy equal to the reservation's hotel on every insert or update
CREATE OR ALTER TRIGGER trg_Stay_SyncHotel
ON STAY
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    UPDATE s
    SET    s.hotel_id = r.hotel_id
    FROM   STAY s
    JOIN   inserted i    ON i.stay_id = s.stay_id
    JOIN   RESERVATION r ON r.reservation_id = s.reservation_id
    WHERE  s.hotel_id IS NULL OR s.hotel_id <> r.hotel_id;
END;
GO

-- Run first, so the other STAY triggers (M1, M4, M5) see hotel_id already filled
EXEC sp_settriggerorder @triggername = 'trg_Stay_SyncHotel', @order = 'First', @stmttype = 'INSERT';
EXEC sp_settriggerorder @triggername = 'trg_Stay_SyncHotel', @order = 'First', @stmttype = 'UPDATE';
```

`trg_Reservation_SyncStayHotel` (section 2.6.1) covers the other direction, when a reservation moves hotel.

To measure the effect, query iv (most-booked category at Kuala Lumpur in 2026) was run twice on SQL Server 2022 after a clean rebuild of the database: once in its final form, which filters on `s.hotel_id` (section 3.6.1), and once in the normalised form kept as a comment in `M1_queries.sql`, which needs the join to RESERVATION:

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

`SET STATISTICS IO ON` gave the logical reads and `SET SHOWPLAN_TEXT ON` the plans.

*Table 3.3.1: Query iv before and after the M1 optimisation (SQL Server 2022, test data).*

| Measure | Before (normalised, joins RESERVATION) | After (reads `STAY.hotel_id`) |
|---|---|---|
| Result | Deluxe, 3 | Deluxe, 3 |
| Logical reads: STAY | 9 | 9 |
| Logical reads: RESERVATION | 36 | not read |
| Logical reads: ROOM_CATEGORY | 2 | 2 |
| Logical reads: total | 47 | 11 |
| Join operators in the plan | 2 Nested Loops | 1 Nested Loops |
| Access to RESERVATION | Clustered Index Seek on `PK_RESERVATION`, repeated for each qualifying STAY row (outer reference `s.reservation_id`) | none |
| Hotel filter | residual predicate `hotel_id = 1` on the RESERVATION seek, checked once per STAY row | predicate `hotel_id = 1` in the Clustered Index Scan of STAY |

Both versions return the same answer. The optimised plan drops a whole Nested Loops join and the seek into RESERVATION, and total logical reads fall from 47 to 11, about 77% fewer. The test data is small, so the absolute numbers are small too. What the comparison shows is that the per-stay lookup into RESERVATION has gone, and that lookup is the cost that grows with the number of stays.

[Screenshot: execution plans of query iv before/after, SSMS]

## 3.4 Constraints and Triggers - M1 (Lim Qi Cai)

### Constraint `CK_STAY_dates`

```sql
ALTER TABLE STAY DROP CONSTRAINT IF EXISTS CK_STAY_dates;
ALTER TABLE STAY WITH CHECK
    ADD CONSTRAINT CK_STAY_dates CHECK (scheduled_checkout > scheduled_checkin);
```

Rejected (test 7): a stay whose check-out equals its check-in.

```sql
INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout)
VALUES (1019, 1, 1, '2027-05-01 14:00', '2027-05-01 14:00');
```

```
PASS 7  CK_STAY_dates rejected check-out = check-in
```

Accepted (test 12a): a direct insert of a one-night stay passes the constraint, and `trg_Stay_SyncHotel` fills its hotel.

```sql
INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout)
VALUES (1019, 1, 1, '2027-05-10 14:00', '2027-05-11 12:00');
```

```
PASS 12a hotel_id filled automatically on insert
```

[Screenshot: test 7 and test 12a output, SSMS Messages tab]

### Trigger `trg_Stay_NoOverlap` (core)

Rule 1 (room belongs to the reservation's hotel) has the same shape and is left out here; the full trigger is in `M1_objects.sql`.

```sql
CREATE OR ALTER TRIGGER trg_Stay_NoOverlap
ON STAY
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF NOT (UPDATE(room_id) OR UPDATE(scheduled_checkin) OR UPDATE(scheduled_checkout)
            OR UPDATE(reservation_id) OR UPDATE(hotel_id))
        RETURN;
    -- ... declarations and Rule 1 ...

    -- Rule 2: no overlap with another active stay in the same room.
    SELECT TOP (1) @room_no = rm.room_no, @hotel = h.name, @other_stay = s.stay_id,
                   @from = CONVERT(VARCHAR(16), s.scheduled_checkin, 120),
                   @to   = CONVERT(VARCHAR(16), s.scheduled_checkout, 120)
    FROM   inserted i
    JOIN   RESERVATION ri ON ri.reservation_id = i.reservation_id
    JOIN   STAY s         ON s.room_id = i.room_id AND s.stay_id <> i.stay_id
    JOIN   RESERVATION rs ON rs.reservation_id = s.reservation_id
    JOIN   ROOM rm        ON rm.room_id = i.room_id
    JOIN   HOTEL h        ON h.hotel_id = rm.hotel_id
    WHERE  ri.status <> N'Cancelled'
      AND  rs.status <> N'Cancelled'
      AND  i.scheduled_checkin < s.scheduled_checkout
      AND  s.scheduled_checkin < i.scheduled_checkout;

    IF @other_stay IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Room %s at %s is already booked from %s to %s (stay %d).', 16, 1,
                  @room_no, @hotel, @from, @to, @other_stay);
        RETURN;
    END;
END;
```

Rejected (test 3): reservation 1020 holds room 201 at Kuala Lumpur from 14 to 16 Feb 2027, and reservation 1019 holds it from 10 to 14 Feb. Moving 1020's check-in to 13 Feb would overlap 1019. Typed in SSMS without TRY/CATCH, the statement gives:

```sql
UPDATE STAY SET scheduled_checkin = '2027-02-13 14:00' WHERE stay_id = 5021;
```

```
Msg 50000, Level 16: Room 201 at GSHG Kuala Lumpur is already booked from 2027-02-10 14:00 to 2027-02-14 12:00 (stay 5020).
Msg 3609, Level 16: The transaction ended in the trigger. The batch has been aborted.
```

Msg 3609 confirms that the trigger's rollback ended the transaction. In the test script the same statement prints:

```
PASS 3  overlapping update rejected: Room 201 at GSHG Kuala Lumpur is already booked from 2027-02-10 14:00 to 2027-02-14 12:00 (stay 5020).
```

Accepted (test 4): a new booking of room 201 from 14:00 on 16 Feb 2027, two hours after 1020 checks out at 12:00.

```sql
INSERT INTO @rooms (room_id, checkin, checkout) VALUES (3, '2027-02-16 14:00', '2027-02-18 12:00');
EXEC usp_CreateReservation 1, 24, 1, @rooms, @rid OUTPUT;
```

```
PASS 4  back-to-back stay accepted (reservation 1031)
```

[Screenshot: test 3 rejected (Msg 50000 and Msg 3609) and test 4 accepted, SSMS Messages tab]

### Test summary

`M1_tests.sql` runs 16 checks. Each runs in its own transaction, which is always rolled back so the shared test data does not change, and prints PASS or FAIL. Prices use the Kuala Lumpur Flexible rates from 1 July 2026: Standard RM 275.00, Deluxe RM 418.00 and Family RM 572.00 per night. All 16 passed on SQL Server 2022.

*Table 3.4.1: M1 test results.*

| # | Scenario | Object tested | Expected outcome | Result |
|---|---|---|---|---|
| 1 | Book room 101 (Standard, 2 nights), room 301 (Family, 3 nights) and an unassigned Deluxe room (2 nights) in one call | Procedure, sync trigger | Pending reservation, 3 stays, 7 nights, total RM 3,102.00, `hotel_id` filled on every stay | PASS (reservation 1029, RM 3,102.00) |
| 2 | Book room 201 for 11 to 13 Feb 2027 while reservation 1019 holds it 10 to 14 Feb | Procedure and overlap trigger | "already booked"; RESERVATION count unchanged | PASS |
| 3 | Move reservation 1020's check-in to 13 Feb 2027 | Overlap trigger on UPDATE | Rejected as "already booked" | PASS |
| 4 | Book room 201 from 14:00 on 16 Feb 2027, after 1020 checks out at 12:00 | Strict overlap rule | Accepted | PASS (reservation 1031) |
| 5 | Book Singapore room 201 over cancelled reservation 1014 (2 to 4 Jul 2026) | Active-stay rule | Accepted | PASS |
| 6 | Change stay 5020 (Kuala Lumpur) to a Singapore room | Hotel rule in trigger | Rejected as "is not a room of" | PASS |
| 7 | Insert a stay with check-out equal to check-in | `CK_STAY_dates` | Rejected by the constraint | PASS |
| 8 | Insert two stays in one statement, one free and one overlapping | Trigger, set-based | Whole statement rejected; STAY count unchanged | PASS |
| 9 | Book the same room twice with overlapping dates in one call | AFTER trigger sees both new rows | Rejected as "already booked" | PASS |
| 10 | Book across New Year 2028, after the rates end on 31 Dec 2027 | Procedure rate check | "No room rate"; nothing saved | PASS |
| 11 | Four bad requests: a room of another hotel, a room not in the requested category, an accessible request on a non-accessible room, and a same-day 14:00 to 18:00 stay | Procedure input checks | Four separate rejections, each with its own message | PASS (4 of 4) |
| 12a | Insert a stay without `hotel_id` | `trg_Stay_SyncHotel` | `hotel_id` set to 1 automatically | PASS |
| 12b | Move reservation 1019 to Singapore | `trg_Reservation_SyncStayHotel`, then overlap trigger | Rejected because its assigned room is in Kuala Lumpur | PASS |
| 13a | Set cancelled reservation 1014 back to Confirmed while 1005 used the same room | `trg_Reservation_NoOverlapOnReactivate` | Rejected as "cannot be re-activated" | PASS |
| 13b | Set cancelled reservation 1012 back to Confirmed (no clash) | `trg_Reservation_NoOverlapOnReactivate` | Allowed | PASS |
| 14 | Insert an overlapping stay inside a caller's TRY/CATCH that catches the error and does not roll back | Rollback-first order in the trigger | No open transaction afterwards and STAY count unchanged | PASS |

Tests 2, 8, 10 and 14 also compare row counts before and after, which shows that nothing was saved. The full printed output:

```
PASS 1  valid 3-room booking: reservation 1029, total RM 3102.00
PASS 2  overlap rejected, nothing saved: Reservation not created: Room 201 at GSHG Kuala Lumpur is already booked from 2027-02-10 14:00 to 2027-02-14 12:00 (stay 5020).
PASS 3  overlapping update rejected: Room 201 at GSHG Kuala Lumpur is already booked from 2027-02-10 14:00 to 2027-02-14 12:00 (stay 5020).
PASS 4  back-to-back stay accepted (reservation 1031)
PASS 5  overlap with a cancelled stay accepted
PASS 6  wrong-hotel room rejected: Room 101 (GSHG Singapore) is not a room of GSHG Kuala Lumpur, the hotel of this reservation.
PASS 7  CK_STAY_dates rejected check-out = check-in
PASS 8  whole multi-row insert rejected (valid row not kept either)
PASS 9  overlap inside one booking rejected
PASS 10 missing rate rejected before any write: No room rate is set for at least one night of this booking.
PASS 11 procedure input checks (wrong hotel, wrong category, not accessible, same-day stay)
PASS 12a hotel_id filled automatically on insert
PASS 12b moving a reservation away from its room's hotel rejected
PASS 13a overlapping re-activation rejected: Reservation 1014 cannot be re-activated: room 201 at GSHG Singapore is already booked from 2026-07-01 14:00 to 2026-07-03 12:00 (stay 5006).
PASS 13b re-activation without a clash accepted
PASS 14 trigger rolled back even though the caller caught the error
```

[Screenshot: full M1_tests.sql output, SSMS Messages tab]

## 3.5 T-SQL Features (Stored Procedure) - M1 (Lim Qi Cai)

M1's T-SQL feature is the stored procedure `usp_CreateReservation` (functional description in section 2.6.1). The excerpt shows the table type, the signature, one of the input checks and the transaction; the other checks and the night generator are in `M1_objects.sql`.

```sql
CREATE TYPE dbo.StayRequest AS TABLE (
    room_id               INT           NULL,   -- NULL = not assigned yet
    category_id           INT           NULL,   -- NULL = take the room's category
    checkin               DATETIME2(0)  NOT NULL,
    checkout              DATETIME2(0)  NOT NULL,
    accessible_requested  BIT           NOT NULL DEFAULT 0
);
GO

CREATE OR ALTER PROCEDURE usp_CreateReservation
    @hotel_id        INT,
    @booker_id       INT,
    @rate_plan_id    INT,
    @rooms           dbo.StayRequest READONLY,
    @reservation_id  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @reservation_id = NULL;

    /* ---- Validation before any write (other checks omitted) ---- */
    IF EXISTS (SELECT 1 FROM @rooms WHERE CAST(checkout AS DATE) <= CAST(checkin AS DATE))
    BEGIN RAISERROR('Each room must be booked for at least one night (check-out on a later date than check-in).', 16, 1); RETURN 1; END;
    -- ... hotel, guest, rate plan, 60-night limit, room/category/accessibility, rate for every night ...

    /* ---- Write: all or nothing ---- */
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO RESERVATION (hotel_id, booker_id, rate_plan_id, status)
        VALUES (@hotel_id, @booker_id, @rate_plan_id, N'Pending');
        SET @reservation_id = SCOPE_IDENTITY();

        -- STAY triggers fire here (hotel_id sync, overlap, maintenance).
        INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout, accessible_requested)
        SELECT @reservation_id, rq.room_id, COALESCE(rq.category_id, rm.category_id),
               rq.checkin, rq.checkout, rq.accessible_requested
        FROM   @rooms rq
        LEFT JOIN ROOM rm ON rm.room_id = rq.room_id;

        -- INSERT INTO STAY_NIGHT ...: one row per night, priced from the ROOM_RATE valid on that night.

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @reservation_id = NULL;
        DECLARE @msg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR('Reservation not created: %s', 16, 1, @msg);
        RETURN 1;
    END CATCH;
END;
```

Example call (test 1): three rooms at Kuala Lumpur in one call. Room ID 1 is room 101, room ID 5 is room 301, and the third row asks for any Deluxe room (category 2) without assigning one.

```sql
DECLARE @rooms dbo.StayRequest, @rid INT, @rc INT;
INSERT INTO @rooms (room_id, category_id, checkin, checkout, accessible_requested) VALUES
    (1,    NULL, '2027-04-01 14:00', '2027-04-03 12:00', 0),
    (5,    NULL, '2027-04-01 14:00', '2027-04-04 12:00', 0),
    (NULL, 2,    '2027-04-01 14:00', '2027-04-03 12:00', 0);
EXEC @rc = usp_CreateReservation @hotel_id = 1, @booker_id = 24, @rate_plan_id = 1,
                                 @rooms = @rooms, @reservation_id = @rid OUTPUT;
```

```
PASS 1  valid 3-room booking: reservation 1029, total RM 3102.00
```

The call created reservation 1029 with 3 STAY rows and 7 STAY_NIGHT rows, totalling RM 3,102.00 (2 x RM 275.00 + 3 x RM 572.00 + 2 x RM 418.00).

[Screenshot: example call and test 1 output, SSMS]

### Why a stored procedure

A booking writes to three tables: one RESERVATION row, one STAY row per room and one STAY_NIGHT row per night. The procedure wraps those writes in one transaction. Atomicity is the "all or nothing" property of a transaction: it is performed in its entirety or not at all (Haerder & Reuter, 1983). If the second room of a booking clashes with another stay, the trigger rolls back, and the first room's STAY row and the RESERVATION row are undone with it. Test 2 checks that the RESERVATION row count is unchanged after a rejected booking, and test 10 checks the same for a booking with an unpriced night.

The table-valued parameter makes one call per booking possible. A list of scalar parameters can only describe a fixed number of rooms, while the case study says a guest can book one or more rooms under a single reservation. `dbo.StayRequest` carries any number of rooms in one call, and the procedure inserts them with one set-based INSERT.

*Table 3.5.1: Alternatives to the stored procedure.*

| Alternative | Why M1 did not use it |
|---|---|
| The application sends the INSERTs itself | Every client would repeat the validation, pricing and transaction handling. A stored procedure keeps that logic in one place in the database, and stored procedures can improve query performance and reduce security gaps at the interface level (Hartono & Erfina, 2021). Running the logic inside the database also saves network round trips between the application and the server, which lowers latency (Hu et al., 2024). |
| One procedure call per room | Each call would be a separate transaction unless the caller wrapped them in one. If room 3 failed, rooms 1 and 2 would already be saved under a reservation the guest never completed, which breaks atomicity. |
| A user-defined function | A user-defined function cannot modify database state (Microsoft, n.d.-a), so it cannot insert the booking. The CREATE FUNCTION syntax also has no OUTPUT option for parameters (Microsoft, n.d.-a). The procedure uses an output parameter to return `@reservation_id`, alongside a return code (0 success, 1 failure) that the caller can branch on. |

## 3.6.1 M1: Reservations and Room Availability (Lim Qi Cai)

Three rules run through all seven queries and are stated at the top of `M1_queries.sql`. An active stay is one whose reservation status is not Cancelled. A confirmed reservation has status Confirmed only. A stay occupies the nights from its check-in date up to, but not including, its check-out date, so it overlaps a period when `checkin_date < period_end AND checkout_date > period_start`. The results below were captured on SQL Server 2022 on 23 October 2026 with the default parameters in the file.

**(i)** Available rooms for a specified hotel, check-in date, check-out date and room category, excluding overlapping active reservations and maintenance periods.

```sql
DECLARE @hotel_id INT = 1,
        @checkin_date DATE = '2027-02-10',
        @checkout_date DATE = '2027-02-14',
        @category NVARCHAR(30) = N'Deluxe';

SELECT h.name AS hotel, rm.room_no, rc.category_name AS category, rm.max_occupancy,
       CASE rm.is_accessible WHEN 1 THEN 'Yes' ELSE 'No' END AS accessible
FROM   ROOM rm
JOIN   HOTEL h          ON h.hotel_id = rm.hotel_id
JOIN   ROOM_CATEGORY rc ON rc.category_id = rm.category_id
WHERE  rm.hotel_id = @hotel_id
  AND  rc.category_name = @category
  AND  NOT EXISTS (SELECT 1
                   FROM   STAY s
                   JOIN   RESERVATION r ON r.reservation_id = s.reservation_id
                   WHERE  s.room_id = rm.room_id
                     AND  r.status <> N'Cancelled'
                     AND  CAST(s.scheduled_checkin AS DATE) < @checkout_date
                     AND  CAST(s.scheduled_checkout AS DATE) > @checkin_date)
  AND  NOT EXISTS (SELECT 1
                   FROM   MAINTENANCE m
                   WHERE  m.room_id = rm.room_id
                     AND  m.start_date < @checkout_date
                     AND  COALESCE(m.actual_end_date,
                                   CASE WHEN m.expected_end_date < CAST(GETDATE() AS DATE)
                                        THEN '9999-12-31' ELSE m.expected_end_date END) >= @checkin_date)
ORDER BY rm.room_no;
```

| hotel | room_no | category | max_occupancy | accessible |
|---|---|---|---|---|
| GSHG Kuala Lumpur | 202 | Deluxe | 2 | No |

[Screenshot: result of query i]

The query lists rooms of the hotel and category that pass two `NOT EXISTS` subqueries: no overlapping active stay and no overlapping maintenance job. `NOT EXISTS` asks directly whether any clashing row exists, and unlike `NOT IN` it is not affected by NULLs. A maintenance job blocks its room from `start_date` to its effective end date, inclusive. That date is `actual_end_date` if the job is finished, otherwise `expected_end_date`; once the expected date has passed with the job still open, the job has no end, because overdue work keeps the room out of service.

For Kuala Lumpur Deluxe rooms from 10 to 14 Feb 2027, only room 202 is listed, because reservation 1019 holds room 201. Room 202 has a maintenance job expected to end on 30 Oct 2026. If that job is still open after 30 Oct 2026, it becomes overdue and room 202 drops out of the result too. The same query for Suite rooms on those dates returns no rows, because Suite room 401 is out of service for a planned renovation from 1 to 20 Feb 2027.

**(ii)** Reservation ID, guest name, room category, check-in and check-out dates for all confirmed reservations at a specified hotel.

```sql
DECLARE @hotel_id INT = 1;

SELECT r.reservation_id,
       g.full_name                        AS guest_name,
       rc.category_name                   AS room_category,
       ISNULL(rm.room_no, N'(not assigned)') AS room_no,
       CAST(s.scheduled_checkin AS DATE)  AS check_in_date,
       CAST(s.scheduled_checkout AS DATE) AS check_out_date
FROM   RESERVATION r
JOIN   GUEST g          ON g.guest_id = r.booker_id
JOIN   STAY s           ON s.reservation_id = r.reservation_id
JOIN   ROOM_CATEGORY rc ON rc.category_id = s.category_id
LEFT JOIN ROOM rm       ON rm.room_id = s.room_id
WHERE  r.hotel_id = @hotel_id
  AND  r.status = N'Confirmed'
ORDER BY check_in_date, r.reservation_id;
```

| reservation_id | guest_name | room_category | room_no | check_in_date | check_out_date |
|---|---|---|---|---|---|
| 1019 | Grace Lee | Deluxe | 201 | 2027-02-10 | 2027-02-14 |
| 1020 | Ahmad Faizal bin Rahman | Deluxe | 201 | 2027-02-14 | 2027-02-16 |

[Screenshot: result of query ii]

The query joins RESERVATION, GUEST (the booker), STAY and ROOM_CATEGORY, filtered by hotel and `status = 'Confirmed'`. It returns one row per room, so a multi-room booking shows each room's dates. The category comes from `STAY.category_id`, which is known before a room is assigned. ROOM is LEFT JOINed, and an unassigned room shows "(not assigned)".

**(iii)** Every reservation with a textual description of its status.

```sql
SELECT r.reservation_id,
       h.name      AS hotel,
       g.full_name AS booked_by,
       r.status,
       CASE
           WHEN r.status = N'Cancelled' AND EXISTS (SELECT 1 FROM NO_SHOW n WHERE n.reservation_id = r.reservation_id)
                THEN 'No-show: the guest did not arrive by the check-in deadline'
           WHEN r.status = N'Pending'     THEN 'Pending: booking received, not yet confirmed'
           WHEN r.status = N'Confirmed'   THEN 'Confirmed: rooms are held for the guest'
           WHEN r.status = N'Checked In'  THEN 'Checked in: the guest is staying now'
           WHEN r.status = N'Checked Out' THEN 'Checked out: the stay is finished'
           WHEN r.status = N'Cancelled'   THEN 'Cancelled: the booking was called off'
           ELSE 'Unknown status'
       END AS status_description
FROM   RESERVATION r
JOIN   HOTEL h ON h.hotel_id = r.hotel_id
JOIN   GUEST g ON g.guest_id = r.booker_id
ORDER BY r.reservation_id;
```

The query returns 23 rows. One row per distinct description is shown here; the screenshot has the full result.

| reservation_id | hotel | booked_by | status | status_description |
|---|---|---|---|---|
| 1001 | GSHG Kuala Lumpur | Ahmad Faizal bin Rahman | Checked Out | Checked out: the stay is finished |
| 1009 | GSHG Kuala Lumpur | Ong Mei Ling | Checked In | Checked in: the guest is staying now |
| 1011 | GSHG Kuala Lumpur | Farah Nabila | Cancelled | Cancelled: the booking was called off |
| 1016 | GSHG Bangkok | Anan Wongsakul | Cancelled | No-show: the guest did not arrive by the check-in deadline |
| 1019 | GSHG Kuala Lumpur | Grace Lee | Confirmed | Confirmed: rooms are held for the guest |
| 1021 | GSHG Kuala Lumpur | Rajesh Kumar | Pending | Pending: booking received, not yet confirmed |

[Screenshot: result of query iii (23 rows)]

A searched `CASE` turns each status into a sentence. A no-show is stored as status Cancelled plus a NO_SHOW row, so the first `WHEN` tests for that row with `EXISTS` and describes the reservation as a no-show before the general Cancelled branch is reached. Reservations 1016 and 1018 are the two no-shows in the result; they share status Cancelled with 1011 to 1015 but get a different description. An `ELSE 'Unknown status'` catches any value outside the list.

**(iv)** Room category most frequently booked at a specified hotel during a given date range.

```sql
DECLARE @hotel_id INT = 1,
        @from_date DATE = '2026-01-01',
        @to_date DATE = '2026-12-31';   -- inclusive

SELECT TOP (1) WITH TIES
       rc.category_name AS room_category,
       COUNT(*)         AS rooms_booked
FROM   STAY s
JOIN   ROOM_CATEGORY rc ON rc.category_id = s.category_id
WHERE  s.hotel_id = @hotel_id
  AND  CAST(s.scheduled_checkin AS DATE) <= @to_date
  AND  CAST(s.scheduled_checkout AS DATE) > @from_date
GROUP BY rc.category_name
ORDER BY COUNT(*) DESC;
```

| room_category | rooms_booked |
|---|---|
| Deluxe | 3 |

[Screenshot: result of query iv]

The query counts stays per category at the hotel whose nights fall in the date range. `TOP (1) WITH TIES` lists every category that shares first place, where plain `TOP (1)` would pick one of them arbitrarily. Bookings that were later cancelled are counted too, because the question is about demand and a cancelled booking still shows a guest wanted that category. The filter reads `STAY.hotel_id`, the M1 optimisation, so the query needs no join to RESERVATION (section 3.3).

**(v)** Number of confirmed reservations by hotel and room category with hotel subtotals and grand total (ROLLUP or CUBE).

```sql
SELECT CASE WHEN GROUPING(h.name) = 1 THEN 'All hotels' ELSE h.name END AS hotel,
       CASE WHEN GROUPING(h.name) = 1 THEN 'Grand total'
            WHEN GROUPING(rc.category_name) = 1 THEN 'Hotel subtotal'
            ELSE rc.category_name END AS room_category,
       COUNT(DISTINCT r.reservation_id) AS confirmed_reservations
FROM   RESERVATION r
JOIN   STAY s           ON s.reservation_id = r.reservation_id
JOIN   HOTEL h          ON h.hotel_id = r.hotel_id
JOIN   ROOM_CATEGORY rc ON rc.category_id = s.category_id
WHERE  r.status = N'Confirmed'
GROUP BY ROLLUP (h.name, rc.category_name)
ORDER BY GROUPING(h.name), h.name, GROUPING(rc.category_name), rc.category_name;
```

| hotel | room_category | confirmed_reservations |
|---|---|---|
| GSHG Kuala Lumpur | Deluxe | 2 |
| GSHG Kuala Lumpur | Hotel subtotal | 2 |
| GSHG Penang | Deluxe | 1 |
| GSHG Penang | Hotel subtotal | 1 |
| GSHG Singapore | Suite | 1 |
| GSHG Singapore | Hotel subtotal | 1 |
| All hotels | Grand total | 4 |

[Screenshot: result of query v]

`GROUP BY ROLLUP (h.name, rc.category_name)` produces the detail rows, one subtotal per hotel and a grand total (Gray et al., 1997). ROLLUP leaves NULLs in the summary rows, and `GROUPING()` replaces them with the labels "Hotel subtotal", "All hotels" and "Grand total". The ORDER BY also uses `GROUPING()`, which puts each subtotal after its hotel's rows and the grand total last. CUBE would add category totals across all hotels, which the brief does not ask for, so ROLLUP was used.

The count is `COUNT(DISTINCT r.reservation_id)`. A reservation with rooms in two categories counts once in each category row but only once in its hotel subtotal. A plain `COUNT(*)` would count rooms instead of reservations and inflate the subtotals.

**(vi)** Hotels with no confirmed reservations for a specified month.

```sql
DECLARE @month_start DATE = '2027-02-01';
DECLARE @month_end DATE = DATEADD(MONTH, 1, @month_start);   -- exclusive

SELECT h.hotel_id, h.name AS hotel, h.city
FROM   HOTEL h
WHERE  NOT EXISTS (SELECT 1
                   FROM   RESERVATION r
                   JOIN   STAY s ON s.reservation_id = r.reservation_id
                   WHERE  r.hotel_id = h.hotel_id
                     AND  r.status = N'Confirmed'
                     AND  CAST(s.scheduled_checkin AS DATE) < @month_end
                     AND  CAST(s.scheduled_checkout AS DATE) > @month_start)
ORDER BY h.name;
```

| hotel_id | hotel | city |
|---|---|---|
| 4 | GSHG Bangkok | Bangkok |
| 3 | GSHG Singapore | Singapore |

[Screenshot: result of query vi]

The query selects from HOTEL with `NOT EXISTS` over confirmed stays that have at least one night in the month. Because it starts from HOTEL, a hotel with no reservations at all is still returned. The month runs from `@month_start` to the first day of the next month (exclusive), which works for months of any length. For February 2027, Kuala Lumpur (reservations 1019 and 1020) and Penang have confirmed stays, so only Bangkok and Singapore are returned.

**(vii)** Additional query: reservation demand.

M1's additional query reports the occupancy rate by hotel and month for a year. Occupancy rate is one of the standard measures of hotel performance, alongside average daily rate and revenue per available room (Pereira-Moliner et al., 2021). It shows how much of each hotel's room capacity was sold in each month.

```sql
DECLARE @year INT = 2026;

WITH months AS (
    SELECT DATEFROMPARTS(@year, 1, 1) AS month_start
    UNION ALL
    SELECT DATEADD(MONTH, 1, month_start) FROM months WHERE MONTH(month_start) < 12
),
hotel_months AS (
    SELECT h.hotel_id, h.name, m.month_start,
           DATEADD(MONTH, 1, m.month_start) AS month_end,
           (SELECT COUNT(*) FROM ROOM rm WHERE rm.hotel_id = h.hotel_id)
             * DATEDIFF(DAY, m.month_start, DATEADD(MONTH, 1, m.month_start)) AS room_days
    FROM HOTEL h CROSS JOIN months m
),
maintenance_days AS (
    SELECT hm.hotel_id, hm.month_start,
           SUM(DATEDIFF(DAY,
                   CASE WHEN mt.start_date > hm.month_start THEN mt.start_date ELSE hm.month_start END,
                   CASE WHEN me.end_excl < hm.month_end THEN me.end_excl ELSE hm.month_end END)) AS days_out
    FROM hotel_months hm
    JOIN ROOM rm ON rm.hotel_id = hm.hotel_id
    JOIN MAINTENANCE mt ON mt.room_id = rm.room_id
    CROSS APPLY (SELECT DATEADD(DAY, 1, COALESCE(mt.actual_end_date,
                        CASE WHEN mt.expected_end_date < CAST(GETDATE() AS DATE)
                             THEN '9999-12-30' ELSE mt.expected_end_date END)) AS end_excl) me
    WHERE mt.start_date < hm.month_end AND me.end_excl > hm.month_start
    GROUP BY hm.hotel_id, hm.month_start
),
nights_sold AS (
    SELECT s.hotel_id, DATEFROMPARTS(YEAR(sn.night_date), MONTH(sn.night_date), 1) AS month_start,
           COUNT(*) AS nights
    FROM STAY s
    JOIN STAY_NIGHT sn  ON sn.stay_id = s.stay_id
    JOIN RESERVATION r  ON r.reservation_id = s.reservation_id
    WHERE r.status <> N'Cancelled'
      AND sn.night_date >= DATEFROMPARTS(@year, 1, 1)
      AND sn.night_date <  DATEFROMPARTS(@year + 1, 1, 1)
    GROUP BY s.hotel_id, DATEFROMPARTS(YEAR(sn.night_date), MONTH(sn.night_date), 1)
)
SELECT hm.name AS hotel,
       CONVERT(CHAR(7), hm.month_start, 120) AS [month],
       ISNULL(ns.nights, 0) AS room_nights_sold,
       hm.room_days - ISNULL(md.days_out, 0) AS room_nights_available,
       CAST(ROUND(100.0 * ISNULL(ns.nights, 0)
                  / NULLIF(hm.room_days - ISNULL(md.days_out, 0), 0), 1) AS DECIMAL(5,1)) AS occupancy_pct
FROM hotel_months hm
LEFT JOIN maintenance_days md ON md.hotel_id = hm.hotel_id AND md.month_start = hm.month_start
LEFT JOIN nights_sold ns      ON ns.hotel_id = hm.hotel_id AND ns.month_start = hm.month_start
ORDER BY hm.name, hm.month_start;
```

The query returns 48 rows (4 hotels x 12 months). The Kuala Lumpur rows for 2026 are shown; the screenshot has the full result.

| hotel | month | room_nights_sold | room_nights_available | occupancy_pct |
|---|---|---|---|---|
| GSHG Kuala Lumpur | 2026-01 | 3 | 186 | 1.6 |
| GSHG Kuala Lumpur | 2026-02 | 0 | 168 | 0.0 |
| GSHG Kuala Lumpur | 2026-03 | 6 | 186 | 3.2 |
| GSHG Kuala Lumpur | 2026-04 | 0 | 180 | 0.0 |
| GSHG Kuala Lumpur | 2026-05 | 0 | 186 | 0.0 |
| GSHG Kuala Lumpur | 2026-06 | 0 | 180 | 0.0 |
| GSHG Kuala Lumpur | 2026-07 | 0 | 186 | 0.0 |
| GSHG Kuala Lumpur | 2026-08 | 0 | 186 | 0.0 |
| GSHG Kuala Lumpur | 2026-09 | 2 | 180 | 1.1 |
| GSHG Kuala Lumpur | 2026-10 | 4 | 165 | 2.4 |
| GSHG Kuala Lumpur | 2026-11 | 0 | 180 | 0.0 |
| GSHG Kuala Lumpur | 2026-12 | 0 | 186 | 0.0 |

[Screenshot: result of query vii (48 rows)]

The formula is:

- occupancy % = room-nights sold / room-nights available x 100
- room-nights sold = nights of active stays in the month, counted from STAY_NIGHT
- room-nights available = rooms x days in the month, minus the days rooms were under maintenance

A recursive CTE generates the 12 months. `maintenance_days` clips each maintenance job to the month, using the same effective-end rule as query i, and `nights_sold` counts STAY_NIGHT rows by `STAY.hotel_id`. In October 2026, Kuala Lumpur has 165 room-nights available instead of 186 because of maintenance. LEFT JOINs keep months with no sales at 0%, and `NULLIF` avoids division by zero. The year filter is a date range rather than `YEAR(night_date)`, so an index on the date could be used.

## M1 input for group sections

### 1.3 Assumptions (M1)

- Active means any status except Cancelled, so a Pending booking already holds its room while it waits for confirmation.
- "Confirmed" in queries ii, v and vi excludes Checked In and Checked Out reservations.
- A reservation counts for a period when any of its stays has a night in it.
- A no-show is stored as Cancelled plus a NO_SHOW row, so it frees the room.
- All money is in Malaysian ringgit (RM), the group's reporting currency, so totals across hotels in different countries can be compared.
- The guest named on a reservation is the booker.
- A booking covers at least one full night; same-day use of a room is not a reservation.

### 5. Conclusion (M1 limitations and possible improvements)

M1's objects support booking one or more rooms in a single atomic call, stop double-booking on every path that writes to STAY, and answer the seven reservation and availability queries. Its known limitations are:

- Overlapping maintenance rows are double-counted in query vii. `maintenance_days` adds up each job's days separately, so two jobs on the same room over the same dates subtract those days twice from room-nights available. Merging overlapping jobs per room before counting would fix this.
- Overdue open maintenance keeps blocking the room with no end date. Queries i and vii compare `expected_end_date` with `GETDATE()`, so their results depend on the day they are run; query i's result for room 202 changes after 30 Oct 2026.
- `trg_Reservation_NoOverlapOnReactivate` checks only stay overlaps. A clash with maintenance when a cancelled reservation is re-activated is M5's rule and is not checked by M1.
- Concurrency relies on SQL Server's default locking under READ COMMITTED (READ_COMMITTED_SNAPSHOT is off, the default). Exclusive locks are held until the transaction commits, so a second booking's trigger waits for the first booking's uncommitted STAY row. This was tested with two sessions booking room 102 for overlapping dates: the second booking waited about 6 seconds until the first committed, was then rejected as "already booked", and only one stay was saved. Locking does not prevent deadlocks (Eswaran et al., 1976); when one occurs, SQL Server rolls one of the transactions back.
- There is no index on `STAY.room_id`. The overlap trigger and query i search STAY by room, so a larger STAY table would need a non-clustered index on `STAY(room_id, scheduled_checkin, scheduled_checkout)`.
- `STAY.hotel_id` is nullable (section 2.5.1), so the triggers, not the column definition, guarantee it is filled.
- The procedure accepts at most 60 nights per room. Its night generator builds up to 64 dates, so longer stays would need a larger generator.

### Appendix A (M1 scripts)

The full M1 code is submitted as three files, run in this order after `sql/01_tables.sql` and `sql/02_data.sql`:

- `M1_Reservations_Availability/M1_objects.sql`: the `CK_STAY_dates` constraint, the `STAY.hotel_id` optimisation with its backfill and sync triggers, the `dbo.StayRequest` type, `usp_CreateReservation`, `trg_Stay_NoOverlap` and `trg_Reservation_NoOverlapOnReactivate`.
- `M1_Reservations_Availability/M1_tests.sql`: the 16 checks summarised in Table 3.4.1.
- `M1_Reservations_Availability/M1_queries.sql`: queries i to vii.

## References

Ajayi, W., Okesola, K. I., Nteziryayo, D., Odo, C., & Akpan, U. (2025). Relational database normalization vs denormalization: A performance perceptive. *Asian Journal of Electrical Sciences, 14*(2), 53-66. https://doi.org/10.70112/ajes-2025.14.2.4291

Connolly, T., & Begg, C. (2015). *Database systems: A practical approach to design, implementation, and management* (6th ed.). Pearson.

Eswaran, K. P., Gray, J. N., Lorie, R. A., & Traiger, I. L. (1976). The notions of consistency and predicate locks in a database system. *Communications of the ACM, 19*(11), 624-633. https://doi.org/10.1145/360363.360369

Gray, J., Chaudhuri, S., Bosworth, A., Layman, A., Reichart, D., Venkatrao, M., Pellow, F., & Pirahesh, H. (1997). Data cube: A relational aggregation operator generalizing group-by, cross-tab, and sub-totals. *Data Mining and Knowledge Discovery, 1*(1), 29-53. https://doi.org/10.1023/A:1009726021843

Haerder, T., & Reuter, A. (1983). Principles of transaction-oriented database recovery. *ACM Computing Surveys, 15*(4), 287-317. https://doi.org/10.1145/289.291

Hartono, N., & Erfina, E. (2021). Comparison of stored procedures on relational database management system. *Tech-E, 4*(2), 8-15. https://doi.org/10.31253/te.v4i2.529

Hu, G., Wang, Z., Tang, C., Shen, J., Dong, Z., Yao, S., & Chen, H. (2024). WeBridge: Synthesizing stored procedures for large-scale real-world web applications. *Proceedings of the ACM on Management of Data, 2*(1), 1-29. https://doi.org/10.1145/3639319

Microsoft. (n.d.-a). *CREATE FUNCTION (Transact-SQL)*. Microsoft Learn. Retrieved October 22, 2026, from https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql

Microsoft. (n.d.-b). *CREATE TRIGGER (Transact-SQL)*. Microsoft Learn. Retrieved October 22, 2026, from https://learn.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql

Paton, N. W., & Díaz, O. (1999). Active database systems. *ACM Computing Surveys, 31*(1), 63-103. https://doi.org/10.1145/311531.311623

Pereira-Moliner, J., Molina-Azorín, J. F., Tarí, J. J., López-Gamero, M. D., & Pertursa-Ortega, E. M. (2021). How do dynamic capabilities explain hotel performance? *International Journal of Hospitality Management, 98*, Article 103023. https://doi.org/10.1016/j.ijhm.2021.103023
