/* =====================================================================
   M3_objects.sql  -  Room rates and optional services
   Owner: M3 <name> (<TP number>) - Room rates and optional services
   Run after sql/01_tables.sql and sql/02_data.sql.
   Rerunnable: drop or CREATE OR ALTER each object before creating it.
   Design: design/design-review.md, row M3 in tables 1b and 1c.
   ===================================================================== */

USE GSHG;
GO

-- 1. Constraint (M3): CHECK (charge_basis IN (...) AND unit_price >= 0) on SERVICE

-- 2. Optimisation strategy (M3): Lookup table - SERVICE_TYPE / charge basis; copy unit_price into RESERVATION_SERVICE

-- 3. Stored procedure / function (M3): usp_AddServiceToReservation

-- 4. Trigger (M3): trg_RoomRate_NoOverlap (AFTER INSERT, UPDATE on ROOM_RATE)

