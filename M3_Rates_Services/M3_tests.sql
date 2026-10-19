/* =====================================================================
   M3_tests.sql  -  demo of M3's procedure, trigger and constraint
   Owner: M3 <name> (<TP number>) - Room rates and optional services
   Run after sql/01_tables.sql and sql/02_data.sql.
   Run after M3_objects.sql. Wrap each test in BEGIN TRAN ... ROLLBACK
   so the test data stays unchanged for everyone else.
   ===================================================================== */

USE GSHG;
GO

-- Test 1: valid call succeeds

-- Test 2: rule violation is rejected (trigger / constraint error expected)

