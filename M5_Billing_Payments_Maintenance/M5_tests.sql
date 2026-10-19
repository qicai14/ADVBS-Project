/* =====================================================================
   M5_tests.sql  -  demo of M5's procedure, trigger and constraint
   Owner: M5 <name> (<TP number>) - Billing, payments and maintenance
   Run after sql/01_tables.sql and sql/02_data.sql.
   Run after M5_objects.sql. Wrap each test in BEGIN TRAN ... ROLLBACK
   so the test data stays unchanged for everyone else.
   ===================================================================== */

USE GSHG;
GO

-- Test 1: valid call succeeds

-- Test 2: rule violation is rejected (trigger / constraint error expected)

