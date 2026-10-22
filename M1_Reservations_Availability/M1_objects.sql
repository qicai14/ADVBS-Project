/* =====================================================================
   M1_objects.sql  -  Reservations and room availability
   Owner: M1 Lim Qi Cai - Reservations and room availability
   Run after sql/01_tables.sql and sql/02_data.sql, and before the
   M2/M4/M5 objects (this script adds STAY.hotel_id).
   Rerunnable: every object is dropped or CREATE OR ALTERed first.
   Design: design/design-review.md, row M1 in tables 1b and 1c.

   Shared rules used below:
   - Active stay   = its reservation's status is not 'Cancelled'.
   - Overlap       = a.checkin < b.checkout AND b.checkin < a.checkout
                     (strict, so checking out at 12:00 and the next guest
                     checking in at 14:00 the same day is allowed).
   ===================================================================== */

USE GSHG;
GO

/* =====================================================================
   1. Constraint (M1): CK_STAY_dates
   Business rule: a stay must end after it starts. A CHECK constraint is
   enough because the rule only compares two columns of the same row.
   ===================================================================== */

ALTER TABLE STAY DROP CONSTRAINT IF EXISTS CK_STAY_dates;
ALTER TABLE STAY WITH CHECK
    ADD CONSTRAINT CK_STAY_dates CHECK (scheduled_checkout > scheduled_checkin);
GO

/* =====================================================================
   2. Optimisation strategy (M1, W10): duplicating FK attributes in 1:*
   RESERVATION 1:* STAY. hotel_id is copied from RESERVATION into STAY so
   queries that filter or group stays by hotel (most-booked category,
   occupancy) read STAY alone instead of joining RESERVATION.
   Cost: the copy must be kept equal to RESERVATION.hotel_id, which the
   two triggers below do. hotel_id stays nullable because an AFTER trigger
   fills it just after each insert.
   ===================================================================== */

IF COL_LENGTH('dbo.STAY', 'hotel_id') IS NULL
    ALTER TABLE STAY ADD hotel_id INT NULL;
GO

IF OBJECT_ID('FK_STAY_HOTEL', 'F') IS NULL
    ALTER TABLE STAY ADD CONSTRAINT FK_STAY_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id);
GO

-- Backfill existing stays.
UPDATE s
SET    s.hotel_id = r.hotel_id
FROM   STAY s
JOIN   RESERVATION r ON r.reservation_id = s.reservation_id
WHERE  s.hotel_id IS NULL OR s.hotel_id <> r.hotel_id;
GO

-- Owner: M1. Keeps STAY.hotel_id equal to its reservation's hotel when a stay is added or moved.
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

-- Run first, so the other STAY triggers (M1, M4, M5) see hotel_id already filled.
EXEC sp_settriggerorder @triggername = 'trg_Stay_SyncHotel', @order = 'First', @stmttype = 'INSERT';
EXEC sp_settriggerorder @triggername = 'trg_Stay_SyncHotel', @order = 'First', @stmttype = 'UPDATE';
GO

-- Owner: M1. Keeps STAY.hotel_id correct if a reservation is moved to another hotel.
-- (trg_Stay_NoOverlap then rejects the move if an assigned room belongs to the old hotel.)
CREATE OR ALTER TRIGGER trg_Reservation_SyncStayHotel
ON RESERVATION
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(hotel_id) RETURN;

    UPDATE s
    SET    s.hotel_id = i.hotel_id
    FROM   STAY s
    JOIN   inserted i ON i.reservation_id = s.reservation_id
    WHERE  s.hotel_id IS NULL OR s.hotel_id <> i.hotel_id;
END;
GO

/* =====================================================================
   3. Stored procedure (M1): usp_CreateReservation
   Business rule: a guest books one or more rooms under one reservation.
   All rooms are passed in one call (table-valued parameter) and saved in
   one transaction: either the whole booking is stored or none of it.

   Inputs : @hotel_id, @booker_id, @rate_plan_id,
            @rooms (one row per room: room_id or category_id, check-in,
            check-out, accessible_requested)
   Output : @reservation_id (NULL on failure); return code 0 = success.
   Tables : inserts RESERVATION (status Pending), STAY, STAY_NIGHT
            (one row per night, priced from ROOM_RATE at booking time).
   Checks : hotel, booker and rate plan exist; at least one room;
            check-out after check-in; at most 60 nights; room belongs to
            the hotel and matches the requested category; an accessible
            request gets an accessible room; every night has a rate.
            Overlaps and maintenance clashes are rejected by the STAY
            triggers (trg_Stay_NoOverlap, M5's trg_Stay_BlockMaintenance).
   ===================================================================== */

DROP PROCEDURE IF EXISTS usp_CreateReservation;
DROP TYPE IF EXISTS dbo.StayRequest;
GO

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

    DECLARE @bad_room INT;

    /* ---- Validation: fail fast with a clear message, before any write ---- */
    IF NOT EXISTS (SELECT 1 FROM HOTEL WHERE hotel_id = @hotel_id)
    BEGIN RAISERROR('Hotel %d does not exist.', 16, 1, @hotel_id); RETURN 1; END;

    IF NOT EXISTS (SELECT 1 FROM GUEST WHERE guest_id = @booker_id)
    BEGIN RAISERROR('Guest %d does not exist.', 16, 1, @booker_id); RETURN 1; END;

    IF NOT EXISTS (SELECT 1 FROM RATE_PLAN WHERE rate_plan_id = @rate_plan_id)
    BEGIN RAISERROR('Rate plan %d does not exist.', 16, 1, @rate_plan_id); RETURN 1; END;

    IF NOT EXISTS (SELECT 1 FROM @rooms)
    BEGIN RAISERROR('A reservation needs at least one room.', 16, 1); RETURN 1; END;

    IF EXISTS (SELECT 1 FROM @rooms WHERE checkout <= checkin)
    BEGIN RAISERROR('Check-out must be after check-in for every room.', 16, 1); RETURN 1; END;

    IF EXISTS (SELECT 1 FROM @rooms
               WHERE DATEDIFF(DAY, CAST(checkin AS DATE), CAST(checkout AS DATE)) > 60)
    BEGIN RAISERROR('A stay can be at most 60 nights.', 16, 1); RETURN 1; END;

    IF EXISTS (SELECT 1 FROM @rooms WHERE room_id IS NULL AND category_id IS NULL)
    BEGIN RAISERROR('Each room needs a room_id or a category_id.', 16, 1); RETURN 1; END;

    SELECT TOP (1) @bad_room = rq.room_id
    FROM   @rooms rq
    LEFT JOIN ROOM rm ON rm.room_id = rq.room_id AND rm.hotel_id = @hotel_id
    WHERE  rq.room_id IS NOT NULL AND rm.room_id IS NULL;
    IF @bad_room IS NOT NULL
    BEGIN RAISERROR('Room %d is not a room of hotel %d.', 16, 1, @bad_room, @hotel_id); RETURN 1; END;

    SELECT TOP (1) @bad_room = rq.room_id
    FROM   @rooms rq
    JOIN   ROOM rm ON rm.room_id = rq.room_id
    WHERE  rq.category_id IS NOT NULL AND rq.category_id <> rm.category_id;
    IF @bad_room IS NOT NULL
    BEGIN RAISERROR('Room %d is not in the requested category.', 16, 1, @bad_room); RETURN 1; END;

    SELECT TOP (1) @bad_room = rq.room_id
    FROM   @rooms rq
    JOIN   ROOM rm ON rm.room_id = rq.room_id
    WHERE  rq.accessible_requested = 1 AND rm.is_accessible = 0;
    IF @bad_room IS NOT NULL
    BEGIN RAISERROR('Room %d is not accessible, but an accessible room was requested.', 16, 1, @bad_room); RETURN 1; END;

    -- Every night of every room must have a rate for this hotel, category and rate plan.
    IF EXISTS (
        SELECT 1
        FROM   @rooms rq
        LEFT JOIN ROOM rm ON rm.room_id = rq.room_id
        CROSS APPLY (SELECT TOP (DATEDIFF(DAY, CAST(rq.checkin AS DATE), CAST(rq.checkout AS DATE)))
                            DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, CAST(rq.checkin AS DATE)) AS night_date
                     FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) a (n)
                     CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b (n)) AS d
        WHERE NOT EXISTS (SELECT 1 FROM ROOM_RATE rr
                          WHERE rr.hotel_id     = @hotel_id
                            AND rr.category_id  = COALESCE(rq.category_id, rm.category_id)
                            AND rr.rate_plan_id = @rate_plan_id
                            AND d.night_date BETWEEN rr.start_date AND rr.end_date))
    BEGIN RAISERROR('No room rate is set for at least one night of this booking.', 16, 1); RETURN 1; END;

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

        -- One row per night, priced from the rate valid on that night.
        INSERT INTO STAY_NIGHT (stay_id, night_date, rate_charged)
        SELECT s.stay_id, d.night_date, rr.nightly_rate
        FROM   STAY s
        CROSS APPLY (SELECT TOP (DATEDIFF(DAY, CAST(s.scheduled_checkin AS DATE), CAST(s.scheduled_checkout AS DATE)))
                            DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, CAST(s.scheduled_checkin AS DATE)) AS night_date
                     FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) a (n)
                     CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b (n)) AS d
        JOIN   ROOM_RATE rr ON rr.hotel_id     = @hotel_id
                           AND rr.category_id  = s.category_id
                           AND rr.rate_plan_id = @rate_plan_id
                           AND d.night_date BETWEEN rr.start_date AND rr.end_date
        WHERE  s.reservation_id = @reservation_id;

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
GO

/* =====================================================================
   4. Trigger (M1): trg_Stay_NoOverlap
   Business rule: a room cannot be assigned to overlapping active stays,
   and a stay can only use a room of its reservation's hotel.
   Why a trigger: the rule compares a row with OTHER rows (and other
   tables), which a CHECK constraint cannot see (W6).
   Fires: AFTER INSERT, UPDATE on STAY, only when the room, dates,
   reservation or hotel change. Works on the whole inserted set (multi-row safe),
   and because it is AFTER, STAY already holds the new rows, so two new
   rows in the same statement are also checked against each other.
   On violation: RAISERROR + ROLLBACK TRANSACTION (W6 pattern).
   ===================================================================== */

CREATE OR ALTER TRIGGER trg_Stay_NoOverlap
ON STAY
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF NOT (UPDATE(room_id) OR UPDATE(scheduled_checkin) OR UPDATE(scheduled_checkout)
            OR UPDATE(reservation_id) OR UPDATE(hotel_id))   -- hotel_id: reservation moved hotel
        RETURN;

    DECLARE @room_no NVARCHAR(10), @hotel NVARCHAR(100), @room_hotel NVARCHAR(100),
            @other_stay INT, @from VARCHAR(16), @to VARCHAR(16);

    -- Rule 1: the room must belong to the reservation's hotel.
    SELECT TOP (1) @room_no = rm.room_no, @room_hotel = rh.name, @hotel = h.name
    FROM   inserted i
    JOIN   RESERVATION r ON r.reservation_id = i.reservation_id
    JOIN   ROOM rm       ON rm.room_id = i.room_id
    JOIN   HOTEL rh      ON rh.hotel_id = rm.hotel_id
    JOIN   HOTEL h       ON h.hotel_id = r.hotel_id
    WHERE  rm.hotel_id <> r.hotel_id;

    IF @room_no IS NOT NULL
    BEGIN
        RAISERROR('Room %s (%s) is not a room of %s, the hotel of this reservation.', 16, 1,
                  @room_no, @room_hotel, @hotel);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

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
        RAISERROR('Room %s at %s is already booked from %s to %s (stay %d).', 16, 1,
                  @room_no, @hotel, @from, @to, @other_stay);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO
