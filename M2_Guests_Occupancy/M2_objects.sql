/* =====================================================================
   M2_objects.sql  -  Guests and room occupancy
   Owner: M2 <name> (<TP number>) - Guests and room occupancy
   Run after sql/01_tables.sql and sql/02_data.sql.
   Rerunnable: drop or CREATE OR ALTER each object before creating it.
   Design: design/design-review.md, row M2 in tables 1b and 1c.
   ===================================================================== */

USE GSHG;
GO

-- 1. Constraint (M2): CHECK (dob <= GETDATE()) on GUEST

-- 2. Optimisation strategy (M2): Duplicating non-key attributes in 1:* - age_category on STAY_OCCUPANT

-- 3. Stored procedure / function (M2): usp_AddOccupant (or fn_AgeCategory)

-- 4. Trigger (M2): trg_StayOccupant_Rules (AFTER INSERT, DELETE on STAY_OCCUPANT)

