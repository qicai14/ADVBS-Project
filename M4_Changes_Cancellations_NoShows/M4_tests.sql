/* =====================================================================
   M4_tests.sql  -  demo of M4's procedure, trigger and constraint
   Owner: M4 <name> (<TP number>) - Changes, cancellations and no-shows
   Run after sql/01_tables.sql and sql/02_data.sql.
   Run after M4_objects.sql. Wrap each test in BEGIN TRAN ... ROLLBACK
   so the test data stays unchanged for everyone else.
   ===================================================================== */

USE GSHG;
GO

-- Test 1: valid call succeeds

-- Test 2: rule violation is rejected (trigger / constraint error expected)

