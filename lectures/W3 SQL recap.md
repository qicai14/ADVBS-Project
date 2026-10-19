# W3 SQL recap


## Slide 1: CT004-3.5-3 Advanced Database Systems

- SQL: Data Definition & Manipulation Language

## Slide 2: Topic & Structure of Lesson

- Purpose and importance of SQL.
- How to retrieve data from database using SELECT and:
  - Use compound WHERE conditions.
  - Sort query results using ORDER BY.
  - Use aggregate functions.

## Slide 3: Topic & Structure of Lesson

  - Group data using GROUP BY and HAVING.
  - Use subqueries
  - Join tables together.
- How to update database using INSERT, UPDATE, and DELETE.

## Slide 4: Key Terms you must be able to use

- If you have mastered this topic, you should be able to use the
- following terms correctly in your assignments and exams:
- DDL (Data Definition Language)
- DML (Data Manipulation Language)
- CREATE TABLE
- INSERT INTO …. VALUES
- SELECT … FROM …. WHERE
- GROUP BY, HAVING, ORDER BY
- DISTINCT
- IN, NOT IN, LIKE

## Slide 5: Key Terms you must be able to use

- If you have mastered this topic, you should be able to use the following terms correctly in your assignments and exams:
- NULL, IS NOT NULL
- COUNT, SUM, AVG, MIN, MAX
- JOIN
- EXISTS, NOT EXISTS
- UPDATE … FROM … WHERE

## Slide 6: Objectives of SQL

- Ideally, database language should allow user to:
  - create the database and relation structures;
  - perform insertion, modification, deletion of data from relations;
  - perform simple and complex queries.

## Slide 7: Objectives of SQL

- SQL is a transform-oriented language with 3 major components:
  - A DDL for defining database structure.
  - A DML for retrieving and updating data.
  - A DCL for control access to data in a database.

## Slide 8: Objectives of SQL

- Consists of standard English words:
- 1)  CREATE TABLE Staff(staffNo VARCHAR(5),
- lName VARCHAR(15),
  - salary DECIMAL(7,2));
- 2) INSERT INTO Staff VALUES (‘SG16’, ‘Brown’,   8300);
- 3) SELECT staffNo, lName, salary
- FROM Staff
- WHERE salary > 10000;

## Slide 9: SELECT Statement

  - SELECT [DISTINCT | ALL]
  - {* | [columnExpression [AS newName]] [,...] }
  - FROM		TableName [alias] [, ...]
  - [WHERE	condition]
  - [GROUP BY	columnList]  [HAVING	condition]
  - [ORDER BY	columnList]

## Slide 10: SELECT Statement

- SELECT		Specifies which columns are to
  - appear in output.
- FROM			Specifies table(s) to be used.
- WHERE		Filters rows.
- GROUP BY		Forms groups of rows with same
  - column value.
- HAVING		Filters groups subject to some
  - condition.
- ORDER BY 		Specifies the order of the output.

## Slide 11: SELECT Statement

- Order of the clauses cannot be changed.
- Only SELECT and FROM are mandatory.

## Slide 12: Example: All Columns, All Rows

- List full details of all staff.
- SELECT staffNo, fName, lName, position, gender, DOB, salary, branchNo
  - FROM Staff;
- Can use * as an abbreviation for ‘all columns’:
  - SELECT *
  - FROM Staff;

## Slide 13: Example: All Columns, All Rows


## Slide 14: Example: Specific Columns, All Rows

- Produce a list of salaries for all staff, showing only  staff number, first and last names, and salary.
  - SELECT staffNo, fName, lName, salary
  - FROM Staff;

## Slide 15: Example:  Specific Columns, All Rows


## Slide 16: Example: Use of DISTINCT

- List the property numbers of all properties that have been viewed.
- SELECT propertyNo
  - FROM Viewing;
*[image]*

## Slide 17: Example : Use of DISTINCT

- Use DISTINCT to eliminate duplicates:
- SELECT DISTINCT propertyNo
  - FROM Viewing;
*[image]*

## Slide 18: Example:  Calculated Fields

- Produce a list of monthly salaries for all staff, showing staff number, first and last names, and  salary details.
- SELECT staffNo, fName, lName,     salary/12
- FROM Staff;

## Slide 19: Example:  Calculated Fields


## Slide 20: Example:  Calculated Fields

- To name column, use AS clause:
- SELECT staffNo, fName, lName, salary/12
  - AS monthlySalary
  - FROM Staff;

## Slide 21: Example: Comparison Search Condition

- List all staff with a salary greater than 10,000.
- SELECT staffNo, fName, lName, position, salary
  - FROM Staff
  - WHERE salary > 10000;

## Slide 22: Example: Comparison Search Condition


## Slide 23: Example: Compound Comparison Search Condition

- List addresses of all branch offices in London or Glasgow.
- SELECT *
  - FROM Branch
  - WHERE city = ‘London’ OR city =   ‘Glasgow’;

## Slide 24: Example: Compound Comparison Search Condition


## Slide 25: Example:  Range Search Condition

- List all staff with a salary between 20,000 and 30,000.
- SELECT staffNo, fName, lName, position, salary
  - FROM Staff
  - WHERE salary BETWEEN 20000 AND 30000;
- BETWEEN test includes the endpoints of range.

## Slide 26: Example:  Range Search Condition


## Slide 27: Example:  Range Search Condition

- Also a negated version NOT BETWEEN.
- BETWEEN does not add much to SQL’s expressive power. Could also write:
- SELECT staffNo, fName, lName, position, salary
  - FROM Staff
  - WHERE salary>=20000 AND salary <= 30000;
- Useful, though, for a range of values.

## Slide 28: Example: Set Membership

- List all managers and supervisors.
  - SELECT staffNo, fName, lName, position
  - FROM Staff
  - WHERE position IN (‘Manager’, ‘Supervisor’);

## Slide 29: Example: Set Membership


## Slide 30: Example: Set Membership

- There is a negated version (NOT IN).
- IN does not add much to SQL’s expressive power.
- Could have expressed this as:
  - SELECT staffNo, fName, lName, position
  - FROM Staff
  - WHERE position=‘Manager’ OR
  - position=‘Supervisor’;
- IN is more efficient when set contains many values

## Slide 31: Example:  Pattern Matching

- Find all owners with the string ‘Glasgow’ in their address.
- SELECT clientNo, fName, lName,  address, telNo
  - FROM PrivateOwner
  - WHERE address LIKE ‘%Glasgow%’;

## Slide 32: Example:  Pattern Matching


## Slide 33: Example: Pattern Matching

- SQL has two special pattern matching symbols:
  - %: sequence of zero or more characters;
  - _ (underscore): any single character.
- LIKE ‘%Glasgow%’ means a sequence of characters of any length containing ‘Glasgow’.

## Slide 34: Example: NULL Search Condition

- List details of all viewings on property PG4 where a comment has not been supplied.
- There are 2 viewings for property PG4, one with and one without a comment.
- Have to test for null explicitly using special keyword IS NULL:
- SELECT clientNo, viewDate
  - FROM Viewing
  - WHERE propertyNo = ‘PG4’ AND
  - comment IS NULL;

## Slide 35: Example: NULL Search Condition

- Negated version (IS NOT NULL)   can test for non-null values.

## Slide 36: Example:  Single Column Ordering

- List salaries for all staff, arranged in descending order of salary.
- SELECT staffNo, fName, lName, salary
  - FROM Staff
  - ORDER BY salary DESC;

## Slide 37: Example:  Single Column Ordering


## Slide 38: Example:  Multiple Column Ordering

- Produce abbreviated list of properties in order of property type.
- SELECT propertyNo, type, rooms,rent	FROM PropertyForRent
  - ORDER BY type;

## Slide 39: Example:  Multiple Column Ordering


## Slide 40: Example: Multiple Column Ordering

- Four flats in this list - as no minor sort key specified, system arranges these rows in any order it chooses.
- To arrange in order of rent, specify minor order:
- SELECT propertyNo, type, rooms, rent
  - FROM PropertyForRent
  - ORDER BY type, rent DESC;

## Slide 41: Example: Multiple Column Ordering


## Slide 42: SELECT Statement - Aggregates

- ISO standard defines five aggregate functions:
- COUNT returns number of values in specified column.
- SUM	returns sum of values in specified column.
- AVG	returns average of values in specified column.
- MIN	returns smallest value in specified column.
- MAX	returns largest value in specified column.

## Slide 43: SELECT Statement - Aggregates

- Each operates on a single column of a table and returns a single value.
- COUNT, MIN, and MAX apply to numeric and non-numeric fields, but SUM and AVG may be used on numeric fields only.
- Apart from COUNT(*), each function eliminates nulls first and operates only on remaining non-null values.

## Slide 44: SELECT Statement - Aggregates

- COUNT(*) counts all rows of a table, regardless of whether nulls or duplicate values occur.
- Can use DISTINCT before column name to eliminate duplicates.
- DISTINCT has no effect with MIN/MAX, but may have with SUM/AVG.

## Slide 45: SELECT Statement - Aggregates

- Aggregate functions can be used only in SELECT list and in HAVING clause.
- If SELECT list includes an aggregate function and there is no GROUP BY clause, SELECT list cannot reference a column out with an aggregate function. For example, the following is illegal:
- SELECT staffNo, COUNT(salary)
  - FROM Staff;

## Slide 46: Example: Use of COUNT(*)

- How many properties cost more than £350 per month to rent?
- SELECT COUNT(*) AS count
  - FROM PropertyForRent
  - WHERE rent > 350;
*[image]*

## Slide 47: Example:  Use of COUNT(DISTINCT)

- How many different properties viewed in May ‘01?
- SELECT COUNT(DISTINCT propertyNo) AS count
- FROM Viewing
- WHERE viewDate BETWEEN ‘1-May-01’AND ‘31-May-01’;
*[image]*

## Slide 48: Example: Use of COUNT and SUM

- Find number of Managers and sum of their salaries.
- SELECT COUNT(staffNo) AS count,
  - SUM(salary) AS sum
  - FROM Staff
  - WHERE position = ‘Manager’;
*[image]*

## Slide 49: Example: Use of MIN, MAX, AVG

- Find minimum, maximum, and average staff salary.
- SELECT MIN(salary) AS min,
  - MAX(salary) AS max,
  - AVG(salary) AS avg
  - FROM Staff;
*[image]*

## Slide 50: SELECT Statement - Grouping

- Use GROUP BY clause to get sub-totals.
- SELECT and GROUP BY closely integrated: each item in SELECT list must be single-valued per group, and SELECT clause may only contain:
  - column names
  - aggregate functions
  - constants
  - expression involving combinations of the above.

## Slide 51: SELECT Statement - Grouping

- All column names in SELECT list must appear in GROUP BY clause unless name is used only in an aggregate function.
- If WHERE is used with GROUP BY, WHERE is applied first, then groups are formed from remaining rows satisfying predicate.
- ISO considers two nulls to be equal for purposes of GROUP BY.

## Slide 52: Example: Use of GROUP BY

- Find number of staff in each branch and their total salaries.
  - SELECT branchNo, COUNT(staffNo) AS count,
    - SUM(salary) AS sum
    - FROM Staff
    - GROUP BY branchNo
    - ORDER BY branchNo;

## Slide 53: Example: Use of GROUP BY


## Slide 54: Restricted Groupings – HAVING clause

- HAVING clause is designed for use with GROUP BY to restrict groups that appear in final result table.
- Similar to WHERE, but WHERE filters individual rows whereas HAVING filters groups.
- Column names in HAVING clause must also appear in the GROUP BY list or be contained within an aggregate function.

## Slide 55: Example – Use of HAVING

- For each branch with more than 1 member of staff,
- find number of staff in each branch and sum of
- their salaries.
  - SELECT branchNo,
  - COUNT(staffNo) AS count,
    - SUM(salary) AS sum
    - FROM Staff
    - GROUP BY branchNo
    - HAVING COUNT(staffNo) > 1
    - ORDER BY branchNo;

## Slide 56: Example: Use of HAVING


## Slide 57: Subqueries

- Some SQL statements can have a SELECT embedded within them.
- A subselect can be used in WHERE and HAVING clauses of an outer SELECT, where it is called a subquery or nested query.
- Subselects may also appear in INSERT, UPDATE, and DELETE statements

## Slide 58: Example: Subquery with Equality

- List staff who work in branch at ‘163 Main St’.
- SELECT staffNo, fName, lName, position
  - FROM Staff
  - WHERE branchNo =
  - (SELECT branchNo
  - FROM Branch
  - WHERE street = ‘163 Main St’);

## Slide 59: Example: Subquery with Equality

- Inner SELECT finds branch number for branch at ‘163 Main St’ (‘B003’).
- Outer SELECT then retrieves details of all staff who work at this branch.
- Outer SELECT then becomes:
  - SELECT staffNo, fName, lName, position
    - FROM Staff
    - WHERE branchNo = ‘B003’;

## Slide 60: Example: Subquery with Equality


## Slide 61: Example: Subquery with Aggregate

- List all staff whose salary is greater than the average salary, and show by how much.
  - SELECT staffNo, fName, lName, position,
  - salary – (SELECT AVG(salary) FROM Staff) As SalDiff
  - FROM Staff
  - WHERE salary >(SELECT AVG(salary)
    - FROM Staff);

## Slide 62: Example: Subquery with Aggregate

- Cannot write ‘WHERE salary > AVG(salary)’
- Instead, use subquery to find average salary (17000), and then use outer SELECT to find those staff with salary greater than this:
  - SELECT staffNo, fName, lName, position,
  - salary – 17000 As salDiff
  - FROM Staff
  - WHERE salary > 17000;

## Slide 63: Example: Subquery with Aggregate


## Slide 64: Subquery Rules

- ORDER BY clause may not be used in a subquery (although it may be used in outermost SELECT).
- Subquery SELECT list must consist of a single column name or expression, except for subqueries that use EXISTS.
- By default, column names refer to table name in FROM clause of subquery. Can refer to a table in FROM using an alias.

## Slide 65: Subquery Rules

- When subquery is an operand in a comparison, subquery must appear on right-hand side.
- A subquery may not be used as an operand in an expression.

## Slide 66: Example: Nested subquery: use of IN

- List properties handled by staff at ‘163 Main St’.
  - SELECT propertyNo, street, city, postcode, type, rooms, rent
  - FROM PropertyForRent
  - WHERE staffNo IN
    - (SELECT staffNo
    - FROM Staff
    - WHERE branchNo =
    - (SELECT branchNo
    - FROM Branch
    - WHERE street = ‘163 Main St’));

## Slide 67: Example: Nested subquery: use of IN


## Slide 68: Multi-Table Queries

- Can use subqueries provided result columns come from same table.
- If result columns come from more than one table must use a join.
- To perform join, include more than one table in FROM clause.
- Use comma as separator and typically include WHERE clause to specify join column(s).

## Slide 69: Multi-Table Queries

- Also possible to use an alias for a table named in FROM clause.
- Alias is separated from table name with a space.
- Alias can be used to qualify column names when there is ambiguity

## Slide 70: Example: Simple Join

- List names of all clients who have viewed a property along with any comment supplied.
- SELECT c.clientNo, fName, lName, propertyNo, comment
  - FROM Client c, Viewing v
  - WHERE c.clientNo = v.clientNo;

## Slide 71: Example: Simple Join

- Equivalent to equi-join in relational algebra.
- Only those rows from both tables that have identical values in the clientNo columns (c.clientNo = v.clientNo) are included in result.

## Slide 72: Example: Simple Join


## Slide 73: Alternative JOIN Constructs

- SQL provides alternative ways to specify joins:
- FROM Client c JOIN Viewing v ON c.clientNo = v.clientNo
- FROM Client JOIN Viewing USING clientNo
- FROM Client NATURAL JOIN Viewing
- In each case, FROM replaces original FROM and WHERE. However, first produces table with two identical clientNo columns.

## Slide 74: Example:  Sorting a join

- For each branch, list numbers and names of staff who manage properties, and properties they manage.
- SELECT s.branchNo, s.staffNo, fName,  lName,propertyNo
  - FROM Staff s, PropertyForRent p
  - WHERE s.staffNo = p.staffNo
  - ORDER BY s.branchNo, s.staffNo, propertyNo;

## Slide 75: Example:  Sorting a join


## Slide 76: Example: Three Table Join

- For each branch, list staff who manage properties, including city in which branch is located and properties they manage.
- SELECT b.branchNo, b.city, s.staffNo, fName, lName,
  - propertyNo
  - FROM Branch b, Staff s, PropertyForRent p
  - WHERE b.branchNo = s.branchNo AND
  - s.staffNo = p.staffNo
  - ORDER BY b.branchNo, s.staffNo, propertyNo;

## Slide 77: Example: Three Table Join

- Alternative formulation for FROM and WHERE:
  - FROM (Branch b JOIN Staff s USING branchNo) AS
  - bs JOIN PropertyForRent p USING staffNo
*[image]*

## Slide 78: Example :  Multiple Grouping Columns

- Find number of properties handled by each staff member.
- SELECT s.branchNo, s.staffNo, COUNT(*) AS count
  - FROM Staff s, PropertyForRent p
  - WHERE s.staffNo = p.staffNo
  - GROUP BY s.branchNo, s.staffNo
  - ORDER BY s.branchNo, s.staffNo;

## Slide 79: Example :  Multiple Grouping Columns


## Slide 80: Computing a Join

- Procedure for generating results of a join are:
- 1. Form Cartesian product of the tables named in  FROM clause.
- 2. If there is a WHERE clause, apply the search condition to each row of the product table, retaining those rows that satisfy the condition.
- 3. For each remaining row, determine value of each item in SELECT list to produce a single row in result table.

## Slide 81: Computing a Join

- If DISTINCT has been specified, eliminate any duplicate rows from the result table.
- 5. If there is an ORDER BY clause, sort result table as required.
- SQL provides special format of SELECT for Cartesian product:
  - SELECT	[DISTINCT | ALL]	{* | columnList}
  - FROM Table1 CROSS JOIN Table2

## Slide 82: EXISTS and NOT EXISTS

- EXISTS and NOT EXISTS are for use only with subqueries.
- Produce a simple true/false result.
- True if and only if there exists at least one row in result table returned by subquery.
- False if subquery returns an empty result table.
- NOT EXISTS is the opposite of EXISTS.

## Slide 83: EXISTS and NOT EXISTS

- As (NOT) EXISTS check only for existence or non-existence of rows in subquery result table, subquery can contain any number of columns.
- Common for subqueries following (NOT) EXISTS to be of form:
  - (SELECT * ...)

## Slide 84: Example:  Query using EXISTS

- Find all staff who work in a London branch.
- SELECT staffNo, fName, lName, position
  - FROM Staff s
  - WHERE EXISTS
  - (SELECT *
  - FROM Branch b
  - WHERE s.branchNo = b.branchNo AND
  - city = ‘London’);

## Slide 85: Example:  Query using EXISTS


## Slide 86: Example:  Query using EXISTS

- Note, search condition s.branchNo = b.branchNo is necessary to consider correct branch record for each member of staff.
- If omitted, would get all staff records listed out because subquery:
  - SELECT * FROM Branch WHERE city=‘London’
- would always be true and query would be:
  - SELECT staffNo, fName, lName, position FROM Staff
  - WHERE true;

## Slide 87: Example:  Query using EXISTS

- Could also write this query using join construct:
  - SELECT staffNo, fName, lName, position
  - FROM Staff s, Branch b
  - WHERE s.branchNo = b.branchNo AND
  - city = ‘London’;

## Slide 88: INSERT

- dataValueList must match columnList as follows:
  - number of items in each list must be same;
  - must be direct correspondence in position of items in two lists;
  - data type of each item in dataValueList must be compatible with data type of corresponding column.

## Slide 89: Example: INSERT … VALUES

- Insert a new row into Staff table supplying data for all columns.
- INSERT INTO Staff
  - VALUES (‘SG16’, ‘Alan’, ‘Brown’, ‘Assistant’, ‘M’, Date‘1957-05-25’, 8300, ‘B003’);

## Slide 90: Example: INSERT using Defaults

- Insert a new row into Staff table supplying data for all mandatory columns.
- INSERT INTO Staff (staffNo, fName, lName,
  - position, salary, branchNo)
  - VALUES (‘SG44’, ‘Anne’, ‘Jones’,
  - ‘Assistant’, 8100, ‘B003’);
- Or
  - INSERT INTO Staff
  - VALUES (‘SG44’, ‘Anne’, ‘Jones’, ‘Assistant’, NULL,
  - NULL, 8100, ‘B003’);

## Slide 91: INSERT … SELECT

- Second form of INSERT allows multiple rows to be copied from one or more tables to another:
- INSERT INTO TableName [ (columnList) ]
  - SELECT ...

## Slide 92: Example: INSERT … SELECT

- Assume there is a table StaffPropCount that contains names of staff and number of properties they manage:
  - StaffPropCount(staffNo, fName, lName, propCnt)
- Populate StaffPropCount using Staff and PropertyForRent tables.

## Slide 93: Example: INSERT … SELECT

  - INSERT INTO StaffPropCount
  - (SELECT s.staffNo, fName, lName, COUNT(*)
  - FROM Staff s, PropertyForRent p
  - WHERE s.staffNo = p.staffNo
  - GROUP BY s.staffNo, fName, lName)
  - UNION
  - (SELECT staffNo, fName, lName, 0
  - FROM Staff
  - WHERE staffNo NOT IN
  - (SELECT DISTINCT staffNo
  - FROM PropertyForRent));

## Slide 94: Example: INSERT … SELECT

- If second part of UNION is omitted, excludes those staff who currently do not manage any properties.
*[image]*

## Slide 95: UPDATE

  - UPDATE TableName
  - SET columnName1 = dataValue1
  - [, columnName2 = dataValue2...]
  - [WHERE searchCondition]
- TableName can be name of a base table or an updatable view.
- SET clause specifies names of one or more columns that are to be updated.

## Slide 96: UPDATE

- WHERE clause is optional:
  - if omitted, named columns are updated for all rows in table;
  - if specified, only those rows that satisfy searchCondition are updated.
- New dataValue(s) must be compatible with data type for corresponding column.

## Slide 97: Example:  UPDATE All Rows

- UPDATE Staff
  - SET salary = salary*1.03;
- Give all Managers a 5% pay increase.
- UPDATE Staff
  - SET salary = salary*1.05
  - WHERE position = ‘Manager’;

## Slide 98: Example:  UPDATE Multiple Columns

- Promote David Ford (staffNo=‘SG14’) to Manager and change his salary to £18,000.
- UPDATE Staff
  - SET position = ‘Manager’, salary = 18000
  - WHERE staffNo = ‘SG14’;

## Slide 99: DELETE

  - DELETE FROM TableName
  - [WHERE searchCondition]
- TableName can be name of a base table or an updatable view.
- searchCondition is optional; if omitted, all rows are deleted from table. This does not delete table. If search_condition is specified, only those rows that satisfy condition are deleted.

## Slide 100: Example:  DELETE Specific Rows

- Delete all viewings that relate to property PG4.
- DELETE FROM Viewing
  - WHERE propertyNo = ‘PG4’;
- Delete all records from the Viewing table.
  - DELETE FROM Viewing;

## Slide 101: Quick Review Questions

- List the objectives of SQL.
- Describe the importance of SQL.
- What are literals?
- List the SQL commands used for a range search   condition.
- List the SQL command used for pattern matching.
- List the SQL command used for single column ordering.
- Name all possible aggregates used in a SELECT statement.
- List the rules used in subqueries.
- Differentiate between EXISTS and NOT EXISTS.

## Slide 102: Summary

- Basic DML commands.
- How to update database using INSERT, UPDATE, and DELETE.

## Slide 103: Question and Answer Session

- Q & A