# W4 Join types


## Slide 1: CT004-3.5-3 Advanced Database Systems

- SQL Join Types

## Slide 2: Topic & Structure of Lesson

- Simple join
- Three Tables join
- Multigrouping columns
- Left outer join
- Right outer join
- Full outer join

## Slide 3: Learning Outcomes

- By the end of this lesson you should be able to:
- Use simple join to retrieve information from more than one table
- Understand the different types of joins, INNER JOIN, LEFT OUTER JOIN, RIGHT OUTER JOIN
- AND FULL OUTER JOIN.

## Slide 4: Simple Join

- List names of all clients who have viewed a property along with any comment supplied.
- SELECT c.clientNo, fName, lName,
  - propertyNo, comment
  - FROM Client c, Viewing v
  - WHERE c.clientNo = v.clientNo;

## Slide 5: Simple Join

- Only those rows from both tables that have identical values in the clientNo columns (c.clientNo = v.clientNo) are included in result.
- Equivalent to equi-join in relational algebra.
*[image]*

## Slide 6: Alternative JOIN Constructs

- SQL provides alternative ways to specify joins:
- FROM Client c JOIN Viewing v ON c.clientNo = v.clientNo
- FROM Client JOIN Viewing USING clientNo
- FROM Client NATURAL JOIN Viewing
- In each case, FROM replaces original FROM and WHERE. However, first produces table with two identical clientNo columns.

## Slide 7: Sorting a join

- For each branch, list numbers and names of staff who manage properties, and properties they manage.
- SELECT s.branchNo, s.staffNo, fName, lName,
  - propertyNo
  - FROM Staff s, PropertyForRent p
  - WHERE s.staffNo = p.staffNo
  - ORDER BY s.branchNo, s.staffNo, propertyNo;

## Slide 8: Sorting a join

*[image]*

## Slide 9: Three Table Join

- For each branch, list staff who manage properties, including city in which branch is located and properties they manage.
- SELECT b.branchNo, b.city, s.staffNo, fName, lName, propertyNo
  - FROM Branch b, Staff s, PropertyForRent p
  - WHERE b.branchNo = s.branchNo AND
  - s.staffNo = p.staffNo
  - ORDER BY b.branchNo, s.staffNo, propertyNo;

## Slide 10: Three Table Join

- Alternative formulation for FROM and WHERE:
  - FROM (Branch b JOIN Staff s USING branchNo) AS bs JOIN PropertyForRent p USING staffNo
*[image]*

## Slide 11: Multiple Grouping Columns

- Find number of properties handled by each staff member.
- SELECT s.branchNo, s.staffNo, COUNT(*) AS  myCount
  - FROM Staff s, PropertyForRent p
  - WHERE s.staffNo = p.staffNo
  - GROUP BY s.branchNo, s.staffNo
  - ORDER BY s.branchNo, s.staffNo;

## Slide 12: Multiple Grouping Columns


## Slide 13: Computing a Join

- Procedure for generating results of a join are:
- 1. Form Cartesian product of the tables named in  FROM clause.
- 2. If there is a WHERE clause, apply the search condition to each row of the product table, retaining those rows that satisfy the condition.
- 3. For each remaining row, determine value of each item in SELECT list to produce a single row in result table.

## Slide 14: Computing a Join

- 4. If DISTINCT has been specified, eliminate any duplicate rows from the result table.
- 5. If there is an ORDER BY clause, sort result table as required.
- SQL provides special format of SELECT for Cartesian product:
  - SELECT	[DISTINCT | ALL]	{* | columnList}
  - FROM Table1 CROSS JOIN Table2

## Slide 15: Outer Joins

- If one row of a joined table is unmatched, row is omitted from result table.
- Outer join operations retain rows that do not satisfy the join condition.
- Consider following tables:
*[image]*

## Slide 16: Outer Joins

- The (inner) join of these two tables:
  - SELECT b.*, p.*
    - FROM Branch1 b, PropertyForRent1 p
    - WHERE b.bCity = p.pCity;
*[image]*

## Slide 17: Outer Joins

- Result table has two rows where cities are same.
- There are no rows corresponding to branches in Bristol and Aberdeen.
- To include unmatched rows in result table, use an Outer join.

## Slide 18: Left Outer Join

- List branches and properties that are in same city along with any unmatched branches.
- SELECT b.*, p.*
  - FROM Branch1 b LEFT JOIN
  - PropertyForRent1 p ON b.bCity = p.pCity;

## Slide 19: Left Outer Join

- Includes those rows of first (left) table unmatched with rows from second (right) table.
- Columns from second table are filled with NULLs.
*[image]*

## Slide 20: Right Outer Join

- List branches and properties in same city and any unmatched properties.
- SELECT b.*, p.*
  - FROM Branch1 b RIGHT JOIN
  - PropertyForRent1 p ON b.bCity = p.pCity;

## Slide 21: Right Outer Join

- Right Outer join includes those rows of second (right) table that are unmatched with rows from first (left) table.
- Columns from first table are filled with NULLs.
*[image]*

## Slide 22: Full Outer Join

- List branches and properties in same city and any unmatched branches or properties.
- SELECT b.*, p.*
  - FROM Branch1 b FULL JOIN
  - PropertyForRent1 p ON b.bCity = p.pCity;

## Slide 23: Full Outer Join

- Includes rows that are unmatched in both tables.
- Unmatched columns are filled with NULLs.
*[image]*

## Slide 24: References

- Connolly & Begg chapter 5 p. 140