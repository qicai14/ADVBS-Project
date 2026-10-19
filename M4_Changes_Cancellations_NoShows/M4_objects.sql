/* =====================================================================
   M4_objects.sql  -  Changes, cancellations and no-shows
   Owner: M4 <name> (<TP number>) - Changes, cancellations and no-shows
   Run after sql/01_tables.sql and sql/02_data.sql.
   Rerunnable: drop or CREATE OR ALTER each object before creating it.
   Design: design/design-review.md, row M4 in tables 1b and 1c.
   ===================================================================== */

USE GSHG;
GO

-- 1. Constraint (M4): CHECK (status IN ('Pending','Confirmed','Checked In','Checked Out','Cancelled')) on RESERVATION

-- 2. Optimisation strategy (M4): Combining 1:1 relationships - CANCELLATION / NO_SHOW into RESERVATION (or justify not)

-- 3. Stored procedure / function (M4): usp_CancelReservation

-- 4. Trigger (M4): trg_Stay_LogChange (AFTER UPDATE on STAY)

