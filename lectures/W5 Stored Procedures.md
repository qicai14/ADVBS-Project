# W5 Stored Procedures


## Slide 1: CT004-3.5-3 Advanced Database Systems

- Implementing StoredProcedures

## Slide 2: Topic & Structure of Lesson

- Implementing Stored Procedures
- Creating Parameterized Stored Procedures

## Slide 3: Learning Outcomes

- By the end of this lesson you should
- be able to:
- Implement stored procedures.
- Create parameterized stored procedures.

## Slide 4: What Is a Stored Procedure?

  - A stored procedure is a group of Transact-SQL statements compiled into a single execution plan.
- Stored Procedures Can:
  - Contain statements that perform operations
  - Accept input parameters
  - Return status value to indicate success or failure
  - Return multiple output parameters

## Slide 5: Advantages of Using Stored Procedures

- Share Application Logic
  - All clients can use the same stored procedures to ensure consistent data access and modification.
- Shield Database Schema Details
  - Users never need to access the tables directly
- Provide Security Mechanisms
  - Users can be granted permission to execute a stored procedure even if they do not have permission to access the tables or views to which the stored procedure refers.

## Slide 6: Advantages of Using Stored Procedures

- Improve Performance
  - Stored procedures implement many tasks as a series of Transact-SQL statements. All these Transact-SQL statements become part of a single execution plan on the server.
- Reduce Network Traffic
  - Rather than sending hundreds of Transact-SQL statements over the network, users can perform a complex operation by sending a single statement, which reduces the number of requests that pass between client and server

## Slide 7: Syntax for Creating Stored Procedures

- Create in current database by using the CREATE PROCEDURE statement
- Use EXECUTE to run stored procedure
- CREATE { PROC | PROCEDURE } [schema_name.] procedure_name   [ { @parameter data_type }         [ VARYING ] [ = default ] [ [ OUT [ PUT ]   ] [ ,...n ]AS { <sql_statement> [;] [ ...n ]}
- EXECUTE  [schema_name.] procedure_name

## Slide 8: Example for Creating Stored Procedures

- Create in current database by using the CREATE PROCEDURE statement
- Use EXECUTE to run stored procedure
- CREATE PROCEDURE Production.LongLeadProducts
- AS
- SELECT	Name, ProductNumber
- FROM		Production.Product
- WHERE	DaysToManufacture >= 1
- GO
- EXECUTE Production.LongLeadProducts

## Slide 9: Guidelines for Creating Stored Procedures

- Qualify object names inside procedure
- ü
- Create one stored procedure for one task
- ü
- Create, test, and troubleshoot
- ü
- Avoid sp_ prefix in stored procedure names
- ü

## Slide 10: Syntax for Altering and Dropping Stored Procedures

- ALTER PROCEDURE
- DROP PROCEDURE
- ALTER PROC Production.LongLeadProducts
- AS
- SELECT	Name, ProductNumber, DaysToManufacture
- FROM		Production.Product
- WHERE	DaysToManufacture >= 1
- ORDER BY DaysToManufacture DESC, Name
- GO
- DROP PROC Production.LongLeadProducts

## Slide 11: Creating Parameterized Stored Procedures

- Input Parameters
- Output Parameters and Return Values

## Slide 12: Creating Parameterized Stored Procedures

- Input parameters
- Output parameters
- Return values
*[image]*
*[image]*
*[image]*
*[image]*
*[image]*
*[image]*
- Parameterized stored procedures contain 3 major components:

> Notes: On this slide, you will learn parameterized stored procedures, input, output and return values. Mention that to define a stored procedure that accepts input parameters, you declare one or more variables as parameters in the CREATE PROCEDURE statement. Mention that to use an output parameter within Transact-SQL, you must specify the OUTPUT keyword in both the CREATE PROCEDURE and the EXECUTE statements. Also mention that the RETURN statement is most commonly used to return a status result or an error code from a procedure.  Input ParameterParameters are used to exchange data between stored procedures and functions and the application or tool that called the stored procedure or function:  Input parameters allow the caller to pass a data value to the stored procedure or function.Output Parameters Output parameters allow the stored procedure to pass a data value or a cursor variable back to the caller. User-defined functions cannot specify output parameters.Return Values Every stored procedure returns an integer return code to the caller. If the stored procedure does not explicitly set a value for the return code, the return code is 0.  References: For more information about Parameterized Stored Procedures, see “Calling a Stored Procedure”, http://go.microsoft.com/fwlink/?LinkID=126188 For more information about using Parameterized Stored Procedures, see “Using Parameters in Stored Procedures and User-Defined Functions”, http://go.microsoft.com/fwlink/?LinkID=126189

## Slide 13: Input Parameters

- Provide appropriate default values
- Validate incoming parameter values, including null checks
- ALTER PROC Production.LongLeadProducts
- @MinimumLength int = 1 	-- default value
- AS
- IF (@MinimumLength < 0) 	-- validate
- BEGIN
- RAISERROR('Invalid lead time.', 14, 1)
- RETURN
- END
- SELECT	Name, ProductNumber, DaysToManufacture
- FROM	Production.Product
- WHERE	DaysToManufacture >= @MinimumLength
- ORDER BY DaysToManufacture DESC, Name
- EXEC Production.LongLeadProducts @MinimumLength=4

## Slide 14: Output Parameters and Return Values

- CREATE PROC HumanResources.AddDepartment
- @Name nvarchar(50), @GroupName nvarchar(50),
- @DeptID smallint OUTPUT
- AS
- INSERT INTO HumanResources.Department (Name, GroupName)
- VALUES	(@Name, @GroupName)
- SET @DeptID = SCOPE_IDENTITY()
- DECLARE @dept int
- EXEC AddDepartment 'Refunds', '', @dept OUTPUT
- SELECT @dept
- CREATE PROC HumanResources.AddDepartment
- @Name nvarchar(50), @GroupName nvarchar(50),
- @DeptID smallint OUTPUT
- AS
- IF ((@Name = '') OR (@GroupName = ''))
- RETURN -1
- INSERT INTO HumanResources.Department (Name, GroupName)
- VALUES	(@Name, @GroupName)
- SET @DeptID = SCOPE_IDENTITY()
- RETURN 0
- DECLARE @dept int, @result int
- EXEC @result = AddDepartment 'Refunds', '', @dept OUTPUT
- IF (@result = 0)
- SELECT @deptID
- ELSE
- SELECT 'Error during insert'

## Slide 15: Summary of Main Teaching Points

- Stored procedures definition.
- How to create and execute a simple stored procedures.
- How to create and execute a parameterized stored procedures.
- How to modify and remove existing stored procedures.

## Slide 16: Question and Answer Session

- Q & A

## Slide 17: Next Lesson

- Implementing Triggers