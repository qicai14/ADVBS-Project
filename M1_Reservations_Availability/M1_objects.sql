/* =====================================================================
   M1_objects.sql  -  Reservations and room availability
   Owner: M1 Lim Qi Cai - Reservations and room availability
   Run after sql/01_tables.sql and sql/02_data.sql.
   Rerunnable: drop or CREATE OR ALTER each object before creating it.
   Design: design/design-review.md, row M1 in tables 1b and 1c.
   ===================================================================== */

USE GSHG;
GO

-- 1. Constraint (M1): CHECK (scheduled_checkout > scheduled_checkin) on STAY

-- 2. Optimisation strategy (M1): Duplicating FK attributes in 1:* - copy hotel_id into STAY

-- 3. Stored procedure / function (M1): usp_CreateReservation

-- 4. Trigger (M1): trg_Stay_NoOverlap (AFTER INSERT, UPDATE on STAY)

