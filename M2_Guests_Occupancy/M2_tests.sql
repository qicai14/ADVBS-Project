/* =====================================================================
   M2_tests.sql  -  demo of M2's procedure, trigger and constraint
   Owner: M2 <name> (<TP number>) - Guests and room occupancy
   Run after sql/01_tables.sql and sql/02_data.sql.
   Run after M2_objects.sql. Wrap each test in BEGIN TRAN ... ROLLBACK
   so the test data stays unchanged for everyone else.
   ===================================================================== */

USE GSHG;
GO

-- Test 1: valid call succeeds

-- Test 2: rule violation is rejected (trigger / constraint error expected)

