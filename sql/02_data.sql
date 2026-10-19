/* =====================================================================
   02_data.sql  -  GSHG test data
   Owner: M1 (shared base script; only Lim Qi Cai edits it)
   Run after 01_tables.sql. Valid data only: rows that must be REJECTED
   (overlaps, over-occupancy, maintenance clashes) belong in each
   member's own tests script, run after their trigger exists.

   Data assumptions (state them in the report):
   - All money is Malaysian ringgit (shown as RM; currency_code keeps the
     ISO code 'MYR'), the group's reporting currency, so totals
     across hotels can be compared.
   - "Active" stay = reservation status is not 'Cancelled'.
   - A no-show is stored as status 'Cancelled' plus a NO_SHOW row
     (no CANCELLATION row), so it never counts as a cancellation.
   - noshow_charge_pct is a % of the reservation's booked room charge.
   - IDs are fixed so scripts can refer to them: reservations 1001+,
     stays 5001+.

   Scenarios built in (reservation IDs):
   Completed stays ........ 1001-1008, 1017 (guest 1 has the most)
   Multi-room booking ..... 1003 (two rooms), 1021 (one room unassigned)
   Checked in now ......... 1009, 1010
   Future confirmed ....... 1019, 1020, 1022, 1023; pending 1021
   Back-to-back same room . 1019 checks out 14 Feb 2027 12:00, 1020 checks in 14:00
   Cancelled stay overlaps  1014 overlaps active 1005 in room 11 (allowed: cancelled)
   Children / infants ..... 1002 (child, infant + baby cot), 1003 (teen, child,
                            extra bed), 1021 (two children), 1023 (infant + cot)
   Age traps (DATEDIFF(YEAR) overstates age before the birthday):
                            guest 4 is 11 not 12, guest 5 and 34 are 1 not 2,
                            guest 16 turns 18 on the day of check-in (1009)
   Max occupancy reached .. 1001, 1009 (2/2), 1003 suite, 1023 suite (3/3)
   Accessible room ........ 1004, 1009, 1022 (accessible_requested = 1)
   Cancellation < 48 h .... 1011 (29 h), 1014 (18 h), 1015 (10 h) -> first night charged
   Cancellation >= 48 h ... 1012 (11 days), 1013 (exactly 48 h, boundary) -> no charge
   Guest cancelled twice .. guest 18 (1011, 1012)
   No-shows ............... 1016 (Bangkok, Non-Refundable 100%), 1018 (KL, Flexible 50%)
   Changes ................ 1005 dates moved, 1006 upgraded Deluxe->Suite,
                            1008 downgraded (negative difference), 1019 dates moved Oct 2026
   Highest cancel rate .... Bangkok 2026 (1 of 3 reservations cancelled)
   No confirmed res. ...... Singapore and Bangkok in Feb 2027
   Services never bought .. Penang airport transfer, Singapore parking, Bangkok transfer
   Top-5 service tie ...... range 2026: 1005 and 1009 tie 5th at 120.00 (TOP 5 WITH TIES)
   Outstanding balance .... 1002 (200.00), 1017 (146.00) checked out but not fully paid
   Refunds ................ 1003 (overpaid), 1012 (deposit back after early cancel)
   Maintenance ............ room 4 now (open), room 9 done late, room 14 done,
                            room 6 planned Feb 2027 (open but not started yet)
   ===================================================================== */

USE GSHG;
GO
SET NOCOUNT ON;

/* ---------- Reference data ---------- */

SET IDENTITY_INSERT HOTEL ON;
INSERT INTO HOTEL (hotel_id, name, country, city, currency_code, checkin_deadline) VALUES
 (1, N'GSHG Kuala Lumpur', N'Malaysia',  N'Kuala Lumpur', 'MYR', '22:00'),
 (2, N'GSHG Penang',       N'Malaysia',  N'George Town',  'MYR', '22:00'),
 (3, N'GSHG Singapore',    N'Singapore', N'Singapore',    'MYR', '23:00'),
 (4, N'GSHG Bangkok',      N'Thailand',  N'Bangkok',      'MYR', '21:00');
SET IDENTITY_INSERT HOTEL OFF;

SET IDENTITY_INSERT ROOM_CATEGORY ON;
INSERT INTO ROOM_CATEGORY (category_id, category_name) VALUES
 (1, N'Standard'), (2, N'Deluxe'), (3, N'Family'), (4, N'Suite');
SET IDENTITY_INSERT ROOM_CATEGORY OFF;

SET IDENTITY_INSERT ROOM ON;
INSERT INTO ROOM (room_id, hotel_id, category_id, room_no, max_occupancy, is_accessible) VALUES
 ( 1, 1, 1, N'101', 2, 0),
 ( 2, 1, 1, N'102', 2, 1),
 ( 3, 1, 2, N'201', 2, 0),
 ( 4, 1, 2, N'202', 2, 0),
 ( 5, 1, 3, N'301', 4, 0),
 ( 6, 1, 4, N'401', 3, 0),
 ( 7, 2, 1, N'101', 2, 0),
 ( 8, 2, 2, N'201', 2, 1),
 ( 9, 2, 3, N'301', 4, 0),
 (10, 3, 1, N'101', 2, 0),
 (11, 3, 2, N'201', 2, 0),
 (12, 3, 4, N'401', 3, 0),
 (13, 4, 1, N'101', 2, 0),
 (14, 4, 2, N'201', 2, 0);
SET IDENTITY_INSERT ROOM OFF;

SET IDENTITY_INSERT RATE_PLAN ON;
INSERT INTO RATE_PLAN (rate_plan_id, plan_name, noshow_charge_pct) VALUES
 (1, N'Flexible',       50.00),
 (2, N'Non-Refundable', 100.00),
 (3, N'Corporate',      25.00);
SET IDENTITY_INSERT RATE_PLAN OFF;

-- Rates: one row per hotel x category x plan x period.
-- Period 1: 2025-01-01..2026-06-30 at base rate; period 2: 2026-07-01..2027-12-31 at +10%.
-- Plan factor: Flexible 1.00, Non-Refundable 0.85, Corporate 0.90. Children 50%.
INSERT INTO ROOM_RATE (hotel_id, category_id, rate_plan_id, start_date, end_date, nightly_rate, child_rate_pct)
SELECT b.hotel_id, b.category_id, p.rate_plan_id, per.start_date, per.end_date,
       CAST(ROUND(b.base_rate * per.factor * p.factor, 2) AS DECIMAL(10,2)), 50.00
FROM (VALUES (1,1, 250.00), (1,2, 380.00), (1,3, 520.00), (1,4, 900.00),
             (2,1, 200.00), (2,2, 300.00), (2,3, 420.00),
             (3,1, 450.00), (3,2, 650.00), (3,4,1400.00),
             (4,1, 180.00), (4,2, 280.00)) AS b (hotel_id, category_id, base_rate)
CROSS JOIN (VALUES (1, 1.00), (2, 0.85), (3, 0.90)) AS p (rate_plan_id, factor)
CROSS JOIN (VALUES ('2025-01-01', '2026-06-30', 1.00),
                   ('2026-07-01', '2027-12-31', 1.10)) AS per (start_date, end_date, factor);

SET IDENTITY_INSERT SERVICE_TYPE ON;
INSERT INTO SERVICE_TYPE (service_type_id, type_name) VALUES
 (1, N'Airport transfer'), (2, N'Breakfast'), (3, N'Parking'), (4, N'Spa');
SET IDENTITY_INSERT SERVICE_TYPE OFF;

SET IDENTITY_INSERT SERVICE ON;
INSERT INTO SERVICE (service_id, hotel_id, service_type_id, service_name, charge_basis, unit_price) VALUES
 ( 1, 1, 1, N'KLIA airport transfer',   N'Per reservation', 120.00),
 ( 2, 1, 2, N'Breakfast buffet',        N'Per person',       45.00),
 ( 3, 1, 3, N'Valet parking (per day)', N'Per room',         30.00),
 ( 4, 1, 4, N'Signature spa massage',   N'Per person',      180.00),
 ( 5, 2, 2, N'Breakfast buffet',        N'Per person',       35.00),
 ( 6, 2, 4, N'Spa massage',             N'Per person',      150.00),
 ( 7, 2, 1, N'Airport transfer',        N'Per reservation',  90.00),
 ( 8, 3, 2, N'Breakfast buffet',        N'Per person',       60.00),
 ( 9, 3, 3, N'Parking (per day)',       N'Per room',         40.00),
 (10, 3, 1, N'Changi airport transfer', N'Per reservation', 150.00),
 (11, 4, 2, N'Breakfast buffet',        N'Per person',       25.00),
 (12, 4, 1, N'Airport transfer',        N'Per reservation',  70.00);
SET IDENTITY_INSERT SERVICE OFF;

SET IDENTITY_INSERT EXTRA_ITEM ON;
INSERT INTO EXTRA_ITEM (item_id, hotel_id, item_name, daily_charge, total_stock) VALUES
 (1, 1, N'Extra bed', 80.00, 2), (2, 1, N'Baby cot', 20.00, 2),
 (3, 2, N'Extra bed', 60.00, 2), (4, 2, N'Baby cot', 15.00, 1),
 (5, 3, N'Extra bed',120.00, 1), (6, 3, N'Baby cot', 30.00, 1),
 (7, 4, N'Baby cot', 10.00, 1);
SET IDENTITY_INSERT EXTRA_ITEM OFF;

/* ---------- Guests ---------- */

SET IDENTITY_INSERT GUEST ON;
INSERT INTO GUEST (guest_id, full_name, dob, email, phone) VALUES
 ( 1, N'Ahmad Faizal bin Rahman', '1980-04-12', N'ahmad.faizal@example.com', N'+60123456701'),
 ( 2, N'Nurul Aina binti Ahmad',  '1983-09-30', N'nurul.aina@example.com',   N'+60123456702'),
 ( 3, N'Tan Wei Ming',            '1985-02-14', N'tan.weiming@example.com',  N'+60123456703'),
 ( 4, N'Tan Xin Yi',              '2014-06-01', NULL, NULL),   -- 11 at check-in (child)
 ( 5, N'Tan Jun Hao',             '2024-11-20', NULL, NULL),   -- 1 at check-in (infant)
 ( 6, N'Priya Ramasamy',          '1990-07-07', N'priya.r@example.com',      N'+60123456706'),
 ( 7, N'Arjun Ramasamy',          '1989-03-21', NULL,                        N'+60123456707'),
 ( 8, N'Lim Chee Keong',          '1978-12-01', N'lim.ck@example.com',       N'+60123456708'),
 ( 9, N'Lim Hui Min',             '2010-08-15', NULL, NULL),   -- 15: not adult, not child
 (10, N'Lim Jia Le',              '2015-10-02', NULL, NULL),   -- 10 (child)
 (11, N'Siti Hajar binti Osman',  '1975-05-05', N'siti.hajar@example.com',   N'+60123456711'),
 (12, N'David Chen',              '1982-01-25', N'david.chen@example.com',   N'+6591234512'),
 (13, N'Sarah Wong',              '1991-11-11', N'sarah.wong@example.com',   N'+6591234513'),
 (14, N'Kumar Selvam',            '1987-06-18', N'kumar.s@example.com',      N'+60123456714'),
 (15, N'Ong Mei Ling',            '1995-02-02', N'ong.meiling@example.com',  N'+60123456715'),
 (16, N'Daniel Ong',              '2008-10-17', NULL,                        N'+60123456716'),  -- 18 on check-in day
 (17, N'James Taylor',            '1970-08-08', N'j.taylor@example.com',     N'+447700900117'),
 (18, N'Farah Nabila',            '1993-03-03', N'farah.nabila@example.com', N'+60123456718'),
 (19, N'Kenji Sato',              '1988-04-04', N'kenji.sato@example.com',   N'+81901234519'),
 (20, N'Emily Clark',             '1992-12-12', N'emily.clark@example.com',  N'+61401234520'),
 (21, N'Somchai Prasert',         '1984-07-19', N'somchai.p@example.com',    N'+66812345621'),
 (22, N'Anan Wongsakul',          '1979-09-09', N'anan.w@example.com',       N'+66812345622'),
 (23, N'Hafiz Iskandar',          '1996-01-15', N'hafiz.i@example.com',      N'+60123456723'),
 (24, N'Grace Lee',               '1990-05-20', N'grace.lee@example.com',    N'+60123456724'),
 (25, N'Rajesh Kumar',            '1983-10-10', N'rajesh.k@example.com',     N'+60123456725'),
 (26, N'Anjali Kumar',            '2016-08-01', NULL, NULL),   -- 10 (child)
 (27, N'Rohan Kumar',             '2020-12-25', NULL, NULL),   -- 6 (child)
 (28, N'Vikram Kumar',            '1955-02-28', NULL,                        N'+60123456728'),
 (29, N'Aisyah binti Zainal',     '1999-06-06', N'aisyah.z@example.com',     N'+60123456729'),
 (30, N'Michael Brown',           '1986-03-15', N'm.brown@example.com',      N'+6591234530'),
 (31, N'Osman bin Yusof',         '1972-01-30', NULL,                        N'+60123456731'),
 (32, N'Brian Lee',               '1989-11-02', NULL,                        N'+60123456732'),
 (33, N'Laura Brown',             '1988-07-22', N'laura.brown@example.com',  N'+6591234533'),
 (34, N'Noah Brown',              '2025-06-01', NULL, NULL);   -- 1 at check-in (infant)
SET IDENTITY_INSERT GUEST OFF;

/* ---------- Reservations and stays ---------- */

SET IDENTITY_INSERT RESERVATION ON;
INSERT INTO RESERVATION (reservation_id, hotel_id, booker_id, rate_plan_id, status, created_at) VALUES
 (1001, 1,  1, 1, N'Checked Out', '2025-11-01 10:00'),
 (1002, 1,  3, 1, N'Checked Out', '2025-12-15 09:30'),
 (1003, 1,  8, 1, N'Checked Out', '2026-02-01 20:00'),
 (1004, 2, 11, 1, N'Checked Out', '2026-03-20 11:00'),
 (1005, 3, 12, 3, N'Checked Out', '2026-06-01 08:45'),
 (1006, 3, 13, 1, N'Checked Out', '2026-07-15 13:00'),
 (1007, 1,  1, 1, N'Checked Out', '2026-08-20 19:00'),
 (1008, 2, 14, 2, N'Checked Out', '2026-09-01 12:00'),
 (1009, 1, 15, 1, N'Checked In',  '2026-09-28 10:00'),
 (1010, 3, 17, 3, N'Checked In',  '2026-10-10 09:00'),
 (1011, 1, 18, 1, N'Cancelled',   '2026-01-20 21:00'),
 (1012, 1, 18, 1, N'Cancelled',   '2026-03-30 10:00'),
 (1013, 2, 19, 1, N'Cancelled',   '2026-05-15 16:00'),
 (1014, 3, 20, 1, N'Cancelled',   '2026-06-20 12:00'),
 (1015, 4, 21, 1, N'Cancelled',   '2026-08-10 09:00'),
 (1016, 4, 22, 2, N'Cancelled',   '2026-07-30 14:00'),   -- no-show
 (1017, 4, 21, 1, N'Checked Out', '2026-09-15 10:00'),
 (1018, 1, 23, 1, N'Cancelled',   '2026-06-01 11:00'),   -- no-show
 (1019, 1, 24, 1, N'Confirmed',   '2026-09-30 15:00'),
 (1020, 1,  1, 1, N'Confirmed',   '2026-10-12 08:00'),
 (1021, 1, 25, 1, N'Pending',     '2026-10-18 22:00'),
 (1022, 2, 11, 2, N'Confirmed',   '2026-10-15 10:00'),   -- booked by guest 11 for guest 29
 (1023, 3, 30, 1, N'Confirmed',   '2026-10-16 17:30');
SET IDENTITY_INSERT RESERVATION OFF;

SET IDENTITY_INSERT STAY ON;
INSERT INTO STAY (stay_id, reservation_id, room_id, category_id, scheduled_checkin, scheduled_checkout,
                  actual_checkin, actual_checkout, accessible_requested) VALUES
 (5001, 1001,    3, 2, '2025-12-01 14:00', '2025-12-04 12:00', '2025-12-01 15:10', '2025-12-04 11:30', 0),
 (5002, 1002,    5, 3, '2026-01-10 14:00', '2026-01-13 12:00', '2026-01-10 16:00', '2026-01-13 11:00', 0),
 (5003, 1003,    1, 1, '2026-03-05 14:00', '2026-03-08 12:00', '2026-03-05 14:30', '2026-03-08 10:45', 0),
 (5004, 1003,    6, 4, '2026-03-05 14:00', '2026-03-08 12:00', '2026-03-05 14:30', '2026-03-08 10:50', 0),
 (5005, 1004,    8, 2, '2026-04-15 14:00', '2026-04-18 12:00', '2026-04-15 13:45', '2026-04-18 11:15', 1),
 (5006, 1005,   11, 2, '2026-07-01 14:00', '2026-07-03 12:00', '2026-07-01 19:20', '2026-07-03 09:00', 0),
 (5007, 1006,   12, 4, '2026-08-10 14:00', '2026-08-12 12:00', '2026-08-10 15:00', '2026-08-12 11:40', 0),
 (5008, 1007,    4, 2, '2026-09-05 14:00', '2026-09-07 12:00', '2026-09-05 14:05', '2026-09-07 11:55', 0),
 (5009, 1008,    7, 1, '2026-09-20 14:00', '2026-09-22 12:00', '2026-09-20 17:30', '2026-09-22 10:00', 0),
 (5010, 1009,    2, 1, '2026-10-17 14:00', '2026-10-21 12:00', '2026-10-17 14:20', NULL,               1),
 (5011, 1010,   10, 1, '2026-10-18 14:00', '2026-10-20 12:00', '2026-10-18 18:05', NULL,               0),
 (5012, 1011,    3, 2, '2026-02-14 15:00', '2026-02-16 12:00', NULL, NULL, 0),
 (5013, 1012,    5, 3, '2026-05-01 14:00', '2026-05-03 12:00', NULL, NULL, 0),
 (5014, 1013,    9, 3, '2026-06-10 14:00', '2026-06-12 12:00', NULL, NULL, 0),
 (5015, 1014,   11, 2, '2026-07-02 14:00', '2026-07-04 12:00', NULL, NULL, 0),
 (5016, 1015,   13, 1, '2026-09-01 14:00', '2026-09-03 12:00', NULL, NULL, 0),
 (5017, 1016,   14, 2, '2026-08-15 14:00', '2026-08-17 12:00', NULL, NULL, 0),
 (5018, 1017,   13, 1, '2026-10-01 14:00', '2026-10-03 12:00', '2026-10-01 15:00', '2026-10-03 11:00', 0),
 (5019, 1018,    4, 2, '2026-06-20 14:00', '2026-06-22 12:00', NULL, NULL, 0),
 (5020, 1019,    3, 2, '2027-02-10 14:00', '2027-02-14 12:00', NULL, NULL, 0),
 (5021, 1020,    3, 2, '2027-02-14 14:00', '2027-02-16 12:00', NULL, NULL, 0),
 (5022, 1021, NULL, 3, '2027-03-01 14:00', '2027-03-04 12:00', NULL, NULL, 0),   -- room not yet assigned
 (5023, 1021,    1, 1, '2027-03-01 14:00', '2027-03-04 12:00', NULL, NULL, 0),
 (5024, 1022,    8, 2, '2027-02-20 14:00', '2027-02-22 12:00', NULL, NULL, 1),
 (5025, 1023,   12, 4, '2027-03-10 14:00', '2027-03-12 12:00', NULL, NULL, 0);
SET IDENTITY_INSERT STAY OFF;

-- One row per night from check-in date up to (not including) check-out date,
-- priced from ROOM_RATE for the reservation's hotel, the stay's category and the rate plan.
INSERT INTO STAY_NIGHT (stay_id, night_date, rate_charged)
SELECT s.stay_id, d.night_date, rr.nightly_rate
FROM STAY s
JOIN RESERVATION r ON r.reservation_id = s.reservation_id
CROSS APPLY (SELECT DATEADD(DAY, t.n, CAST(s.scheduled_checkin AS DATE)) AS night_date
             FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t (n)) AS d
JOIN ROOM_RATE rr ON rr.hotel_id = r.hotel_id
                 AND rr.category_id = s.category_id
                 AND rr.rate_plan_id = r.rate_plan_id
                 AND d.night_date BETWEEN rr.start_date AND rr.end_date
WHERE d.night_date < CAST(s.scheduled_checkout AS DATE);

INSERT INTO STAY_OCCUPANT (stay_id, guest_id) VALUES
 (5001, 1), (5001, 2),
 (5002, 3), (5002, 4), (5002, 5),
 (5003, 6), (5003, 7),
 (5004, 8), (5004, 9), (5004, 10),
 (5005, 11), (5005, 31),
 (5006, 12),
 (5007, 13),
 (5008, 1),
 (5009, 14),
 (5010, 15), (5010, 16),
 (5011, 17),
 (5012, 18),
 (5013, 18),
 (5014, 19),
 (5015, 20),
 (5016, 21),
 (5017, 22),
 (5018, 21),
 (5019, 23),
 (5020, 24), (5020, 32),
 (5021, 1), (5021, 2),
 (5022, 25), (5022, 26), (5022, 27),
 (5023, 28),
 (5024, 29),
 (5025, 30), (5025, 33), (5025, 34);

-- Extra beds / cots: charge = daily_charge x quantity x nights.
INSERT INTO STAY_EXTRA (stay_id, item_id, quantity, charge_amount)
SELECT x.stay_id, x.item_id, x.quantity,
       e.daily_charge * x.quantity * DATEDIFF(DAY, CAST(s.scheduled_checkin AS DATE), CAST(s.scheduled_checkout AS DATE))
FROM (VALUES (5002, 2, 1),    -- baby cot for infant (no extra room charge)
             (5004, 1, 1),    -- extra bed in suite
             (5025, 6, 1)) AS x (stay_id, item_id, quantity)
JOIN EXTRA_ITEM e ON e.item_id = x.item_id
JOIN STAY s ON s.stay_id = x.stay_id;

/* ---------- Optional services ---------- */
-- charge = unit_price x quantity, x occupants of the stay when 'Per person'.
INSERT INTO RESERVATION_SERVICE (reservation_id, service_id, stay_id, service_date, quantity, charge_amount)
SELECT x.reservation_id, x.service_id, x.stay_id, x.service_date, x.quantity,
       sv.unit_price * x.quantity *
       CASE sv.charge_basis
            WHEN N'Per person' THEN (SELECT COUNT(*) FROM STAY_OCCUPANT o WHERE o.stay_id = x.stay_id)
            ELSE 1
       END
FROM (VALUES (1001,  2, 5001, CAST('2025-12-02' AS DATE), 3),
             (1002,  1, NULL, '2026-01-10', 1),
             (1002,  2, 5002, '2026-01-11', 3),
             (1003,  3, 5003, '2026-03-05', 3),
             (1003,  4, 5004, '2026-03-06', 1),
             (1004,  6, 5005, '2026-04-16', 1),
             (1005,  8, 5006, '2026-07-02', 2),
             (1006,  8, 5007, '2026-08-11', 2),
             (1006, 10, NULL, '2026-08-10', 1),
             (1007,  2, 5008, '2026-09-06', 2),
             (1009,  3, 5010, '2026-10-17', 4),
             (1017, 11, 5018, '2026-10-02', 2),
             (1023, 10, NULL, '2027-03-10', 1)) AS x (reservation_id, service_id, stay_id, service_date, quantity)
JOIN SERVICE sv ON sv.service_id = x.service_id;

/* ---------- Changes ---------- */
-- price_difference = new room charge - old room charge, both priced from ROOM_RATE.
-- STAY already holds the new values; the old ones are only in this log.
WITH change_spec AS (
    SELECT x.*, r.hotel_id, r.rate_plan_id
    FROM (VALUES (5006, 2, 2, CAST('2026-06-28 14:00' AS DATETIME2(0)), CAST('2026-06-30 12:00' AS DATETIME2(0)), CAST('2026-06-15 10:00' AS DATETIME2(0))),
                 (5007, 2, 4, '2026-08-10 14:00', '2026-08-12 12:00', '2026-08-01 09:00'),
                 (5009, 2, 1, '2026-09-20 14:00', '2026-09-22 12:00', '2026-09-10 16:30'),
                 (5020, 2, 2, '2027-02-08 14:00', '2027-02-12 12:00', '2026-10-05 11:00'))
         AS x (stay_id, old_category_id, new_category_id, old_checkin, old_checkout, changed_at)
    JOIN STAY s ON s.stay_id = x.stay_id
    JOIN RESERVATION r ON r.reservation_id = s.reservation_id
)
INSERT INTO RESERVATION_CHANGE (stay_id, old_category_id, new_category_id, old_checkin, old_checkout,
                                new_checkin, new_checkout, price_difference, changed_at)
SELECT c.stay_id, c.old_category_id, c.new_category_id, c.old_checkin, c.old_checkout,
       s.scheduled_checkin, s.scheduled_checkout,
       (SELECT SUM(sn.rate_charged) FROM STAY_NIGHT sn WHERE sn.stay_id = c.stay_id)
     - (SELECT SUM(rr.nightly_rate)
        FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t (n)
        JOIN ROOM_RATE rr ON rr.hotel_id = c.hotel_id
                         AND rr.category_id = c.old_category_id
                         AND rr.rate_plan_id = c.rate_plan_id
                         AND DATEADD(DAY, t.n, CAST(c.old_checkin AS DATE)) BETWEEN rr.start_date AND rr.end_date
        WHERE DATEADD(DAY, t.n, CAST(c.old_checkin AS DATE)) < CAST(c.old_checkout AS DATE)),
       c.changed_at
FROM change_spec c
JOIN STAY s ON s.stay_id = c.stay_id;

/* ---------- Cancellations and no-shows ---------- */
-- Charge = first night's rate_charged when cancelled less than 48 h before scheduled check-in, else 0.
INSERT INTO CANCELLATION (reservation_id, cancelled_at, charge_amount)
SELECT x.reservation_id, x.cancelled_at,
       CASE WHEN x.cancelled_at > DATEADD(HOUR, -48, f.first_checkin)
            THEN (SELECT TOP (1) sn.rate_charged
                  FROM STAY s JOIN STAY_NIGHT sn ON sn.stay_id = s.stay_id
                  WHERE s.reservation_id = x.reservation_id
                  ORDER BY sn.night_date, s.stay_id)
            ELSE 0 END
FROM (VALUES (1011, CAST('2026-02-13 10:00' AS DATETIME2(0))),   -- 29 h before
             (1012, '2026-04-20 09:00'),                          -- 11 days before
             (1013, '2026-06-08 14:00'),                          -- exactly 48 h: no charge
             (1014, '2026-07-01 20:00'),                          -- 18 h before
             (1015, '2026-09-01 04:00'))                          -- 10 h before
     AS x (reservation_id, cancelled_at)
CROSS APPLY (SELECT MIN(s.scheduled_checkin) AS first_checkin
             FROM STAY s WHERE s.reservation_id = x.reservation_id) AS f;

-- Charge = rate plan's noshow_charge_pct of the booked room charge.
INSERT INTO NO_SHOW (reservation_id, recorded_at, charge_amount)
SELECT x.reservation_id, x.recorded_at,
       CAST(ROUND(rp.noshow_charge_pct / 100 *
            (SELECT SUM(sn.rate_charged) FROM STAY s JOIN STAY_NIGHT sn ON sn.stay_id = s.stay_id
             WHERE s.reservation_id = x.reservation_id), 2) AS DECIMAL(10,2))
FROM (VALUES (1016, CAST('2026-08-15 21:05' AS DATETIME2(0))),   -- Bangkok deadline 21:00
             (1018, '2026-06-20 22:30'))                          -- KL deadline 22:00
     AS x (reservation_id, recorded_at)
JOIN RESERVATION r ON r.reservation_id = x.reservation_id
JOIN RATE_PLAN rp ON rp.rate_plan_id = r.rate_plan_id;

/* ---------- Bills (checked-out reservations) ---------- */

INSERT INTO BILL (reservation_id, room_charge, service_charge, discount, extra_charge, issued_at)
SELECT r.reservation_id,
       (SELECT SUM(sn.rate_charged) FROM STAY s JOIN STAY_NIGHT sn ON sn.stay_id = s.stay_id
        WHERE s.reservation_id = r.reservation_id),
       ISNULL((SELECT SUM(rs.charge_amount) FROM RESERVATION_SERVICE rs
               WHERE rs.reservation_id = r.reservation_id), 0),
       CASE r.reservation_id WHEN 1006 THEN 50.00 ELSE 0 END,      -- goodwill discount
       ISNULL((SELECT SUM(se.charge_amount) FROM STAY s JOIN STAY_EXTRA se ON se.stay_id = s.stay_id
               WHERE s.reservation_id = r.reservation_id), 0),
       (SELECT MAX(s.actual_checkout) FROM STAY s WHERE s.reservation_id = r.reservation_id)
FROM RESERVATION r
WHERE r.status = N'Checked Out';

/* ---------- Payments and refunds ---------- */

-- Settled in full at check-out.
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at)
SELECT b.reservation_id, b.room_charge + b.service_charge + b.extra_charge - b.discount,
       m.method, N'Payment', b.issued_at
FROM BILL b
JOIN (VALUES (1001, N'Credit Card'), (1004, N'Bank Transfer'), (1005, N'Credit Card'),
             (1006, N'Credit Card'), (1007, N'Cash'), (1008, N'E-Wallet')) AS m (reservation_id, method)
  ON m.reservation_id = b.reservation_id;

-- 1002 and 1017: checked out with a balance still owing.
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at)
SELECT b.reservation_id, b.room_charge + b.service_charge + b.extra_charge - b.discount - 200.00,
       N'Credit Card', N'Payment', b.issued_at
FROM BILL b WHERE b.reservation_id = 1002;

INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at) VALUES
 (1017, 300.00, N'Cash', N'Payment', '2026-10-03 11:00');

-- 1003: deposit, overpaid at check-out by 100.00, then refunded.
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at) VALUES
 (1003, 500.00, N'Bank Transfer', N'Payment', '2026-02-02 09:00');
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at)
SELECT b.reservation_id, b.room_charge + b.service_charge + b.extra_charge - b.discount - 500.00 + 100.00,
       N'Credit Card', N'Payment', b.issued_at
FROM BILL b WHERE b.reservation_id = 1003;
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at) VALUES
 (1003, 100.00, N'Credit Card', N'Refund', '2026-03-09 10:00');

-- Deposits on current and future bookings; 1012 deposit refunded after early cancellation.
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at) VALUES
 (1009, 300.00, N'Credit Card',   N'Payment', '2026-09-28 10:05'),
 (1012, 200.00, N'Credit Card',   N'Payment', '2026-03-30 10:05'),
 (1012, 200.00, N'Credit Card',   N'Refund',  '2026-04-20 09:30'),
 (1019, 200.00, N'Bank Transfer', N'Payment', '2026-09-30 15:30'),
 (1020, 200.00, N'Credit Card',   N'Payment', '2026-10-12 08:10'),
 (1023, 500.00, N'Credit Card',   N'Payment', '2026-10-16 17:40');

-- Non-Refundable bookings prepaid in full when booked (1016 no-show, 1022 future).
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at)
SELECT r.reservation_id, SUM(sn.rate_charged), N'Credit Card', N'Payment', MIN(r.created_at)
FROM RESERVATION r
JOIN STAY s ON s.reservation_id = r.reservation_id
JOIN STAY_NIGHT sn ON sn.stay_id = s.stay_id
WHERE r.reservation_id IN (1016, 1022)
GROUP BY r.reservation_id;

-- Late-cancellation and Flexible no-show charges paid when recorded.
INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at)
SELECT c.reservation_id, c.charge_amount, N'Credit Card', N'Payment', c.cancelled_at
FROM CANCELLATION c WHERE c.charge_amount > 0;

INSERT INTO PAYMENT (reservation_id, amount, method, pay_type, paid_at)
SELECT n.reservation_id, n.charge_amount, N'Credit Card', N'Payment', n.recorded_at
FROM NO_SHOW n WHERE n.reservation_id = 1018;

/* ---------- Maintenance ---------- */

SET IDENTITY_INSERT MAINTENANCE ON;
INSERT INTO MAINTENANCE (maintenance_id, room_id, start_date, expected_end_date, actual_end_date, reason) VALUES
 (1,  4, '2026-10-10', '2026-10-30', NULL,         N'Bathroom leak repair'),
 (2,  9, '2026-01-05', '2026-01-15', '2026-01-18', N'Air-conditioning replacement (overran 3 days)'),
 (3, 14, '2026-09-25', '2026-09-28', '2026-09-28', N'Carpet replacement'),
 (4,  6, '2027-02-01', '2027-02-20', NULL,         N'Suite renovation (planned)');
SET IDENTITY_INSERT MAINTENANCE OFF;
GO

-- Quick check: row count per table.
SELECT t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;
GO
