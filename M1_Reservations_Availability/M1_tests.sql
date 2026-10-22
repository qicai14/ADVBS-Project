/* =====================================================================
   M1_tests.sql  -  demo of M1's procedure, triggers and constraint
   Owner: M1 Lim Qi Cai - Reservations and room availability
   Run after sql/01_tables.sql, sql/02_data.sql and M1_objects.sql.
   Each test runs in its own transaction and is always rolled back, so
   the shared test data never changes. Every test prints PASS or FAIL.
   Rates used (period from 2026-07-01, Flexible plan):
   KL Standard 275.00, KL Deluxe 418.00, KL Family 572.00 per night.
   ===================================================================== */

USE GSHG;
GO
SET NOCOUNT ON;
GO

/* ---------- Test 1: valid 3-room booking in one call ----------
   Room 101 (Standard, 2 nights) + room 301 (Family, 3 nights) + an
   unassigned Deluxe room (2 nights). Expect: reservation Pending,
   3 stays, 7 nights, total 2 x 275 + 3 x 572 + 2 x 418 = 3102.00,
   hotel_id filled on every stay. */
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @rooms dbo.StayRequest, @rid INT, @rc INT;
    INSERT INTO @rooms (room_id, category_id, checkin, checkout, accessible_requested) VALUES
        (1,    NULL, '2027-04-01 14:00', '2027-04-03 12:00', 0),
        (5,    NULL, '2027-04-01 14:00', '2027-04-04 12:00', 0),
        (NULL, 2,    '2027-04-01 14:00', '2027-04-03 12:00', 0);
    EXEC @rc = usp_CreateReservation @hotel_id = 1, @booker_id = 24, @rate_plan_id = 1,
                                     @rooms = @rooms, @reservation_id = @rid OUTPUT;

    DECLARE @stays INT, @nights INT, @total DECIMAL(10,2), @no_hotel INT, @status NVARCHAR(20);
    SELECT @stays = COUNT(*), @no_hotel = SUM(CASE WHEN hotel_id = 1 THEN 0 ELSE 1 END)
    FROM STAY WHERE reservation_id = @rid;
    SELECT @nights = COUNT(*), @total = SUM(sn.rate_charged)
    FROM STAY s JOIN STAY_NIGHT sn ON sn.stay_id = s.stay_id WHERE s.reservation_id = @rid;
    SELECT @status = status FROM RESERVATION WHERE reservation_id = @rid;

    IF @rc = 0 AND @rid IS NOT NULL AND @stays = 3 AND @nights = 7 AND @total = 3102.00
       AND @no_hotel = 0 AND @status = N'Pending'
        PRINT 'PASS 1  valid 3-room booking: reservation ' + CAST(@rid AS VARCHAR(10)) + ', total RM ' + CAST(@total AS VARCHAR(20));
    ELSE
        PRINT 'FAIL 1  valid booking: stays=' + ISNULL(CAST(@stays AS VARCHAR(5)), 'NULL')
            + ' nights=' + ISNULL(CAST(@nights AS VARCHAR(5)), 'NULL') + ' total=' + ISNULL(CAST(@total AS VARCHAR(20)), 'NULL');
END TRY
BEGIN CATCH
    PRINT 'FAIL 1  valid booking raised: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 2: overlapping booking rejected (procedure path) ----------
   Room 201 at KL is held by reservation 1019 from 10 to 14 Feb 2027.
   Booking it for 11-13 Feb must fail, and nothing must be saved. */
DECLARE @before INT = (SELECT COUNT(*) FROM RESERVATION);
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @rooms dbo.StayRequest, @rid INT;
    INSERT INTO @rooms (room_id, checkin, checkout) VALUES (3, '2027-02-11 14:00', '2027-02-13 12:00');
    EXEC usp_CreateReservation 1, 1, 1, @rooms, @rid OUTPUT;
    PRINT 'FAIL 2  overlapping booking was accepted';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_MESSAGE() LIKE '%already booked%' AND (SELECT COUNT(*) FROM RESERVATION) = @before
        PRINT 'PASS 2  overlap rejected, nothing saved: ' + ERROR_MESSAGE();
    ELSE
        PRINT 'FAIL 2  unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 3: overlapping date change rejected (trigger on UPDATE) ----------
   Moving reservation 1020 (room 201, 14-16 Feb 2027) to start on 13 Feb
   would overlap 1019. */
BEGIN TRANSACTION;
BEGIN TRY
    UPDATE STAY SET scheduled_checkin = '2027-02-13 14:00' WHERE stay_id = 5021;
    PRINT 'FAIL 3  overlapping date change was accepted';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%already booked%'
        PRINT 'PASS 3  overlapping update rejected: ' + ERROR_MESSAGE();
    ELSE
        PRINT 'FAIL 3  unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 4: back-to-back stay accepted ----------
   1020 checks out of room 201 at 12:00 on 16 Feb 2027; a new guest
   checking in at 14:00 the same day does not overlap. */
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @rooms dbo.StayRequest, @rid INT;
    INSERT INTO @rooms (room_id, checkin, checkout) VALUES (3, '2027-02-16 14:00', '2027-02-18 12:00');
    EXEC usp_CreateReservation 1, 24, 1, @rooms, @rid OUTPUT;
    IF @rid IS NOT NULL PRINT 'PASS 4  back-to-back stay accepted (reservation ' + CAST(@rid AS VARCHAR(10)) + ')';
    ELSE PRINT 'FAIL 4  no reservation id returned';
END TRY
BEGIN CATCH
    PRINT 'FAIL 4  back-to-back stay rejected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 5: overlap with a CANCELLED stay accepted ----------
   Room 201 at Singapore (room_id 11) has cancelled reservation 1014 on
   2-4 Jul 2026. A cancelled stay does not hold the room. */
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @rooms dbo.StayRequest, @rid INT;
    INSERT INTO @rooms (room_id, checkin, checkout) VALUES (11, '2026-07-03 14:00', '2026-07-04 12:00');
    EXEC usp_CreateReservation 3, 20, 1, @rooms, @rid OUTPUT;
    IF @rid IS NOT NULL PRINT 'PASS 5  overlap with a cancelled stay accepted';
    ELSE PRINT 'FAIL 5  no reservation id returned';
END TRY
BEGIN CATCH
    PRINT 'FAIL 5  rejected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 6: room from another hotel rejected (trigger) ----------
   Reservation 1019 is at Kuala Lumpur; room_id 10 is in Singapore. */
BEGIN TRANSACTION;
BEGIN TRY
    UPDATE STAY SET room_id = 10 WHERE stay_id = 5020;
    PRINT 'FAIL 6  room from another hotel was accepted';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%is not a room of%'
        PRINT 'PASS 6  wrong-hotel room rejected: ' + ERROR_MESSAGE();
    ELSE
        PRINT 'FAIL 6  unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 7: check-out not after check-in rejected (constraint) ---------- */
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout)
    VALUES (1019, 1, 1, '2027-05-01 14:00', '2027-05-01 14:00');
    PRINT 'FAIL 7  zero-length stay was accepted';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%CK_STAY_dates%'
        PRINT 'PASS 7  CK_STAY_dates rejected check-out = check-in';
    ELSE
        PRINT 'FAIL 7  unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 8: one bad row rejects the whole statement ----------
   Two stays inserted in ONE statement: room 101 is free, room 201
   overlaps 1019. The trigger checks the whole set, so neither row stays. */
DECLARE @before INT = (SELECT COUNT(*) FROM STAY);
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout) VALUES
        (1019, 1, 1, '2027-02-10 14:00', '2027-02-12 12:00'),
        (1019, 3, 2, '2027-02-12 14:00', '2027-02-13 12:00');
    PRINT 'FAIL 8  multi-row insert with an overlap was accepted';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_MESSAGE() LIKE '%already booked%' AND (SELECT COUNT(*) FROM STAY) = @before
        PRINT 'PASS 8  whole multi-row insert rejected (valid row not kept either)';
    ELSE
        PRINT 'FAIL 8  unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 9: two new rows overlapping EACH OTHER rejected ----------
   Same room twice in one call: the AFTER trigger sees both rows in STAY. */
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @rooms dbo.StayRequest, @rid INT;
    INSERT INTO @rooms (room_id, checkin, checkout) VALUES
        (2, '2027-06-01 14:00', '2027-06-03 12:00'),
        (2, '2027-06-02 14:00', '2027-06-04 12:00');
    EXEC usp_CreateReservation 1, 24, 1, @rooms, @rid OUTPUT;
    PRINT 'FAIL 9  same room twice was accepted';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%already booked%'
        PRINT 'PASS 9  overlap inside one booking rejected';
    ELSE
        PRINT 'FAIL 9  unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 10: no rate for a night -> nothing saved ----------
   Rates end on 2027-12-31, so a stay over New Year 2028 cannot be priced. */
DECLARE @before INT = (SELECT COUNT(*) FROM RESERVATION);
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @rooms dbo.StayRequest, @rid INT;
    INSERT INTO @rooms (room_id, checkin, checkout) VALUES (1, '2027-12-30 14:00', '2028-01-02 12:00');
    EXEC usp_CreateReservation 1, 24, 1, @rooms, @rid OUTPUT;
    PRINT 'FAIL 10 booking without a rate was accepted';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_MESSAGE() LIKE '%No room rate%' AND (SELECT COUNT(*) FROM RESERVATION) = @before
        PRINT 'PASS 10 missing rate rejected before any write: ' + ERROR_MESSAGE();
    ELSE
        PRINT 'FAIL 10 unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 11: procedure input checks ----------
   Wrong-hotel room, category mismatch, accessible request on a
   non-accessible room, same-day stay with no night: each rejected
   with its own message. */
DECLARE @passes INT = 0;
DECLARE @rooms1 dbo.StayRequest, @rooms2 dbo.StayRequest, @rooms3 dbo.StayRequest, @rooms4 dbo.StayRequest, @rid INT;
INSERT INTO @rooms1 (room_id, checkin, checkout) VALUES (10, '2027-05-01 14:00', '2027-05-02 12:00');
INSERT INTO @rooms2 (room_id, category_id, checkin, checkout) VALUES (1, 4, '2027-05-01 14:00', '2027-05-02 12:00');
INSERT INTO @rooms3 (room_id, checkin, checkout, accessible_requested) VALUES (1, '2027-05-01 14:00', '2027-05-02 12:00', 1);
INSERT INTO @rooms4 (room_id, checkin, checkout) VALUES (1, '2027-05-01 14:00', '2027-05-01 18:00');
BEGIN TRY EXEC usp_CreateReservation 1, 24, 1, @rooms1, @rid OUTPUT; END TRY
BEGIN CATCH IF ERROR_MESSAGE() LIKE '%is not a room of hotel%' SET @passes += 1; END CATCH;
BEGIN TRY EXEC usp_CreateReservation 1, 24, 1, @rooms2, @rid OUTPUT; END TRY
BEGIN CATCH IF ERROR_MESSAGE() LIKE '%requested category%' SET @passes += 1; END CATCH;
BEGIN TRY EXEC usp_CreateReservation 1, 24, 1, @rooms3, @rid OUTPUT; END TRY
BEGIN CATCH IF ERROR_MESSAGE() LIKE '%not accessible%' SET @passes += 1; END CATCH;
BEGIN TRY EXEC usp_CreateReservation 1, 24, 1, @rooms4, @rid OUTPUT; END TRY
BEGIN CATCH IF ERROR_MESSAGE() LIKE '%at least one night%' SET @passes += 1; END CATCH;
IF @passes = 4 PRINT 'PASS 11 procedure input checks (wrong hotel, wrong category, not accessible, same-day stay)';
ELSE PRINT 'FAIL 11 only ' + CAST(@passes AS VARCHAR(2)) + ' of 4 input checks fired';
GO

/* ---------- Test 12: hotel_id copy kept in sync (W10 optimisation) ----------
   a) A stay inserted without hotel_id gets it from its reservation.
   b) Moving reservation 1019 to another hotel is rejected, because its
      assigned room belongs to Kuala Lumpur. */
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout)
    VALUES (1019, 1, 1, '2027-05-10 14:00', '2027-05-11 12:00');
    IF (SELECT hotel_id FROM STAY WHERE stay_id = SCOPE_IDENTITY()) = 1
        PRINT 'PASS 12a hotel_id filled automatically on insert';
    ELSE
        PRINT 'FAIL 12a hotel_id not filled';
END TRY
BEGIN CATCH
    PRINT 'FAIL 12a raised: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE RESERVATION SET hotel_id = 3 WHERE reservation_id = 1019;
    PRINT 'FAIL 12b reservation moved away from its assigned room''s hotel';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%is not a room of%'
        PRINT 'PASS 12b moving a reservation away from its room''s hotel rejected';
    ELSE
        PRINT 'FAIL 12b unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 13: re-activating a cancelled reservation ----------
   a) Reservation 1014 (Singapore room 201, 2-4 Jul 2026) was cancelled,
      and checked-out reservation 1005 used the same room on 1-3 Jul.
      Setting 1014 back to Confirmed would create an overlap: rejected.
   b) Reservation 1012 (KL room 301, 1-3 May 2026) clashes with nothing,
      so re-activating it is allowed. */
BEGIN TRANSACTION;
BEGIN TRY
    UPDATE RESERVATION SET status = N'Confirmed' WHERE reservation_id = 1014;
    PRINT 'FAIL 13a overlapping re-activation was accepted';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%cannot be re-activated%'
        PRINT 'PASS 13a overlapping re-activation rejected: ' + ERROR_MESSAGE();
    ELSE
        PRINT 'FAIL 13a unexpected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE RESERVATION SET status = N'Confirmed' WHERE reservation_id = 1012;
    IF (SELECT status FROM RESERVATION WHERE reservation_id = 1012) = N'Confirmed'
        PRINT 'PASS 13b re-activation without a clash accepted';
    ELSE
        PRINT 'FAIL 13b status not changed';
END TRY
BEGIN CATCH
    PRINT 'FAIL 13b rejected: ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- Test 14: the trigger's rollback always runs ----------
   A caller catches the overlap error but does NOT roll back itself.
   Because the trigger rolls back before raising the error, the
   transaction is already closed and the overlapping row is gone, so a
   careless caller cannot keep (or later commit) a double booking. */
DECLARE @before INT = (SELECT COUNT(*) FROM STAY);
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO STAY (reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout)
    VALUES (1020, 3, 2, '2027-02-11 14:00', '2027-02-13 12:00');   -- overlaps 1019
END TRY
BEGIN CATCH
    -- deliberately no ROLLBACK here
END CATCH;
IF @@TRANCOUNT = 0 AND (SELECT COUNT(*) FROM STAY) = @before
    PRINT 'PASS 14 trigger rolled back even though the caller caught the error';
ELSE
    PRINT 'FAIL 14 open transactions: ' + CAST(@@TRANCOUNT AS VARCHAR(5));
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO
