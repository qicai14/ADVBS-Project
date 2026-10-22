/* =====================================================================
   M1_queries.sql  -  Reservations and room availability
   Owner: M1 Lim Qi Cai - Reservations and room availability
   Run after sql/01_tables.sql, sql/02_data.sql and M1_objects.sql.
   One block per query; parameters are DECLAREd at the top of each block.

   Shared rules:
   - Active stay: reservation status is not 'Cancelled'.
   - "Confirmed reservation": status = 'Confirmed' only.
   - A stay uses the nights from its check-in date up to (not including)
     its check-out date, so a stay overlaps a period when
     checkin_date < period_end AND checkout_date > period_start.
   - A maintenance job blocks its room from start_date to its effective
     end date (inclusive): actual_end_date when finished; otherwise
     expected_end_date, or no end at all once that date has passed
     (overdue work keeps the room out of service).
   ===================================================================== */

USE GSHG;
GO

/* ---------------------------------------------------------------------
   i. Available rooms for a hotel, check-in date, check-out date and room
      category. Excludes rooms with an overlapping active stay or a
      maintenance period.
   Example: KL Deluxe 10-14 Feb 2027 -> room 201 is held by reservation
   1019, so only room 202 is listed (202's maintenance ends 30 Oct 2026;
   if that job is still open after 30 Oct 2026 it is overdue and 202 is
   excluded too). KL Suite in the same dates -> none (planned renovation).
   --------------------------------------------------------------------- */
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
GO

/* ---------------------------------------------------------------------
   ii. Reservation ID, guest name, room category, check-in and check-out
       dates for all confirmed reservations at a hotel (one row per room;
       the guest is the booker).
   Example: Kuala Lumpur -> 1019 and 1020.
   --------------------------------------------------------------------- */
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
GO

/* ---------------------------------------------------------------------
   iii. Every reservation with a textual description of its status.
        A cancelled reservation with a NO_SHOW row is described as a no-show.
   --------------------------------------------------------------------- */
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
GO

/* ---------------------------------------------------------------------
   iv. Room category most frequently booked at a hotel during a date range.
       Counts every room booked (stay) whose nights fall in the range,
       including bookings later cancelled, because the question is about
       demand. WITH TIES lists every category sharing first place.
       Uses STAY.hotel_id (M1's W10 optimisation): no join to RESERVATION.
   Example: Kuala Lumpur, 2026 -> Deluxe (3 bookings).
   --------------------------------------------------------------------- */
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

-- Same result without the W10 copy, for comparison: needs the extra join.
-- SELECT TOP (1) WITH TIES rc.category_name, COUNT(*)
-- FROM STAY s
-- JOIN RESERVATION r ON r.reservation_id = s.reservation_id
-- JOIN ROOM_CATEGORY rc ON rc.category_id = s.category_id
-- WHERE r.hotel_id = @hotel_id
--   AND CAST(s.scheduled_checkin AS DATE) <= @to_date
--   AND CAST(s.scheduled_checkout AS DATE) > @from_date
-- GROUP BY rc.category_name
-- ORDER BY COUNT(*) DESC;
GO

/* ---------------------------------------------------------------------
   v. Number of confirmed reservations by hotel and room category, with
      hotel subtotals and a grand total (ROLLUP).
      A reservation with rooms in two categories counts once in each
      category, but once only in its hotel subtotal (COUNT DISTINCT).
   --------------------------------------------------------------------- */
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
GO

/* ---------------------------------------------------------------------
   vi. Hotels with no confirmed reservations for a month: no confirmed
       stay has a night in that month.
   Example: February 2027 -> GSHG Singapore and GSHG Bangkok.
   --------------------------------------------------------------------- */
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
GO

/* ---------------------------------------------------------------------
   vii. Additional query (reservation demand): occupancy rate by hotel and
        month for a year.
        occupancy % = room-nights sold / room-nights available x 100
        room-nights sold      = nights of active stays in the month
        room-nights available = rooms x days in month
                                - days rooms were under maintenance
   --------------------------------------------------------------------- */
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
      AND sn.night_date <  DATEFROMPARTS(@year + 1, 1, 1)   -- range, not YEAR(), so an index could be used
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
GO
