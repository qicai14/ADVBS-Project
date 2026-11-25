import sys,io
src, dst = sys.argv[1], sys.argv[2]
def rw(name, fn):
    s = open(f"{src}/{name}", encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in s else "\n"
    s = s.replace("\r\n", "\n")
    s = fn(s)
    open(f"{dst}/{name}", "w", encoding="utf-8", newline="").write(s.replace("\n", nl))

OLD_I = "CASE WHEN m.expected_end_date < CAST(GETDATE() AS DATE)"
NEW_I = "CASE WHEN m.expected_end_date < @as_of"

VII_START = "maintenance_days AS ("
VII_END = "nights_sold AS ("
NEW_MD = """days AS (
    SELECT DATEFROMPARTS(@year, 1, 1) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM days WHERE d < DATEFROMPARTS(@year, 12, 31)
),
maintenance_days AS (
    -- one row per room and calendar day under maintenance, so overlapping jobs on a room count once
    SELECT x.hotel_id, DATEFROMPARTS(YEAR(x.d), MONTH(x.d), 1) AS month_start, COUNT(*) AS days_out
    FROM (SELECT DISTINCT rm.hotel_id, rm.room_id, dy.d
          FROM   ROOM rm
          JOIN   MAINTENANCE mt ON mt.room_id = rm.room_id
          JOIN   days dy ON dy.d >= mt.start_date
                        AND dy.d <= COALESCE(mt.actual_end_date,
                                             CASE WHEN mt.expected_end_date < @as_of
                                                  THEN '9999-12-31' ELSE mt.expected_end_date END)) x
    GROUP BY x.hotel_id, DATEFROMPARTS(YEAR(x.d), MONTH(x.d), 1)
),
"""
def fix_vii(s):
    a = s.index(VII_START); b = s.index(VII_END)
    s = s[:a] + NEW_MD + s[b:]
    s = s.replace("DECLARE @year INT = 2026;", "DECLARE @year INT = 2026,\n        @as_of DATE = '2026-10-23';   -- reference date for \"overdue\"; use CAST(GETDATE() AS DATE) for live use", 1)
    s = s.replace("ORDER BY hm.name, hm.month_start;", "ORDER BY hm.name, hm.month_start\nOPTION (MAXRECURSION 400);", 1)
    return s

def queries(s):
    s = s.replace(OLD_I, NEW_I)
    s = s.replace("        @category NVARCHAR(30) = N'Deluxe';", "        @category NVARCHAR(30) = N'Deluxe',\n        @as_of DATE = '2026-10-23';   -- reference date for \"overdue\"; use CAST(GETDATE() AS DATE) for live use", 1)
    return fix_vii(s)

def report(s):
    s = queries(s)  # code blocks in the report mirror the query file
    s = s.replace("- Overdue open maintenance keeps blocking the room with no end date. Queries i and vii compare `expected_end_date` with `GETDATE()`, so their results depend on the day they are run; query i's result for room 202 changes after 30 Oct 2026.",
      "- Overdue open maintenance keeps blocking the room with no end date. Queries i and vii compare `expected_end_date` with the `@as_of` date (set to 23 Oct 2026 in the examples so results can be reproduced; use `CAST(GETDATE() AS DATE)` live). With `@as_of` after 30 Oct 2026, query i no longer lists room 202.")
    a = s.index("- Overlapping maintenance rows are double-counted in query vii.")
    b = s.index("\n", a)
    s = s[:a] + "- Query vii counts each room-day under maintenance once: it lists the distinct days per room, so two jobs covering the same dates do not subtract the days twice." + s[b:]
    return s

def objects(s):
    old = "        COMMIT TRANSACTION;\n        RETURN 0;"
    new = """        -- Safety net inside the transaction: every night of every stay must have been priced.
        IF (SELECT COUNT(*) FROM STAY_NIGHT sn JOIN STAY s ON s.stay_id = sn.stay_id
            WHERE s.reservation_id = @reservation_id)
           <> (SELECT SUM(DATEDIFF(DAY, CAST(scheduled_checkin AS DATE), CAST(scheduled_checkout AS DATE)))
               FROM STAY WHERE reservation_id = @reservation_id)
            RAISERROR('A night of this booking could not be priced (the rates changed during the booking).', 16, 1);

        COMMIT TRANSACTION;
        RETURN 0;"""
    assert old in s
    return s.replace(old, new, 1)

rw("M1_queries.sql", queries)
rw("M1_report.md", report)
rw("M1_objects.sql", objects)
