/* =====================================================================
   M5_objects.sql  -  Billing, payments and maintenance
   Owner: M5 <name> (<TP number>) - Billing, payments and maintenance
   Run after sql/01_tables.sql and sql/02_data.sql.
   Rerunnable: drop or CREATE OR ALTER each object before creating it.
   Design: design/design-review.md, row M5 in tables 1b and 1c.
   ===================================================================== */

USE GSHG;
GO

-- 1. Constraint (M5): CHECK (amount > 0 AND pay_type IN ('Payment','Refund')) on PAYMENT; CHECK (expected_end_date >= start_date) on MAINTENANCE

-- 2. Optimisation strategy (M5): Partitioning relations (horizontal) - PAYMENT by year/quarter

-- 3. Stored procedure / function (M5): usp_CheckOutAndBill

-- 4. Trigger (M5): trg_Stay_BlockMaintenance (AFTER INSERT, UPDATE on STAY)

