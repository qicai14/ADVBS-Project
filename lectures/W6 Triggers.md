# W6 Triggers


## Slide 1: 

- Implementing Triggers

## Slide 2: Topic & Structure of Lesson

- Integrity Enhancement Features
- What Are Triggers?
- Syntax for Creating Triggers
- How an INSERT Trigger Works
- How a DELETE Trigger Works
- How an UPDATE Trigger Works
- How an INSTEAD OF Trigger Works
- Syntax for Altering and Dropping Triggers

## Slide 3: Learning Outcomes

- By the end of this lesson you should
- be able to:
- Implement Triggers

## Slide 4: Integrity Enhancement Features

- Consider five types of integrity constraints:
  - Required data.
  - Domain constraints.
  - Entity integrity.
  - Referential integrity.
  - Enterprise constraints

## Slide 5: Required Data

- Example, every member of staff must have an associated job position (for example, Manager, Assistant, and so on)
- Alter Table Staff
- alter column position varchar (50) Not Null

> Notes: There is no “Create Domain” statement in SQL SERVER 2008 only check constraint

## Slide 6: Domain Constraints

- example, the gender of a member of staff is either ‘M’ or ‘F’, so the domain of the column gender of the Staff table is a single character string consisting of either ‘M’ or ‘F’
- Alter Table Staff WITH NOCHECK
- ADD CONSTRAINT CK1 check (gender = 'm' OR gender = 'f')

## Slide 7: Entity Integrity

- Primary key of a table must contain a unique, non-null value for each row.
- ISO standard supports FOREIGN KEY clause in CREATE and ALTER TABLE statements:
  - PRIMARY KEY(staffNo)
  - PRIMARY KEY(clientNo, propertyNo)
- Can only have one PRIMARY KEY clause per table. Can still ensure uniqueness for alternate keys using UNIQUE: UNIQUE (telNo)

## Slide 8: Referential Integrity

- Foreign Key (FK) is column or set of columns that links each row in child table containing foreign FK to row of parent table containing matching Primary Key (PK).
- Referential integrity means that, if FK contains a value, that value must refer to existing row in parent table.
- ISO standard supports definition of FKs with FOREIGN KEY clause in CREATE and ALTER TABLE:
  - FOREIGN KEY(branchNo) REFERENCES Branch (branchNo)

## Slide 9: Referential Integrity

- Any INSERT/UPDATE that attempts to create FK value in child table without matching candidate key value in parent is rejected.
- Action taken that attempts to update/delete a candidate key value in parent table with matching rows in child is dependent on referential action specified using ON UPDATE and ON DELETE subclauses:
  - CASCADE			-  SET NULL
  - SET DEFAULT		-  NO ACTION

## Slide 10: Referential Integrity

- CASCADE: Delete row from parent and delete matching rows in child, and so on in cascading manner.
- SET NULL: Delete row from parent and set FK column(s) in child to NULL. Only valid if FK columns are NOT NULL.
- SET DEFAULT: Delete row from parent and set each component of FK in child to specified default. Only valid if DEFAULT specified for FK columns
- NO ACTION: Reject delete from parent. Default

## Slide 11: Referential Integrity Examples

- FOREIGN KEY (staffNo) REFERENCES Staff  ON DELETE SET NULL
- FOREIGN KEY (ownerNo) REFERENCES Owner  ON UPDATE CASCADE

## Slide 12: Enterprise Constraints “Business rules”

- Can be applied using triggers
- DreamHome may have a rule that prevents a member of staff from managing more than 100 properties at the same time.
- DreamHome may have a rule that If job position is manager the salary must not exceed 30000

## Slide 13: What areTriggers?

- Triggers are a powerful tool that enables you to enforce domain, entity, referential data integrity and enterprise constraints or ‘Business rules’.
- A trigger is a special kind of stored procedures.
- Three categories of triggers: Data Manipulation Language (DML) triggers, Data Definition Language (DDL) triggers, and logon triggers.
- Data Manipulation Language (DML) triggers can’t be called directly. Instead, they are configured on individual tables or views and respond to the following DML commands:  INSERT, UPDATE, or DELETE statements.

## Slide 14: Insert, Update, Delete

- INSERT: When an INSERT command is executed on a table, an INSERT trigger on the table fires. For example, when an order is placed (inserting data into the Orders table), you might like to update the on-hand inventory column in the Products table.
- UPDATE: When an UPDATE command is executed on a table, an UPDATE trigger on the table fires. For example, management might want to know if anyone ever modifies data (such as the Salary column) in the Employees table.
- DELETE: When a DELETE command is executed on a table, a DELETE trigger on the table fires. For example, the company you work at might not want to ever delete a customer from the Customers table. Instead, customers should be marked as inactive.

> Notes: INSERT: When an INSERT command is executed on a table, an INSERT trigger on the table fires. For example, when an order is placed (inserting data into the Orders table), you might like to update the on-hand inventory column in the Products table. You could create an INSERT trigger on the Orders table to do this. When someone orders five glossy widgets, the INSERT trigger would fire and would reduce the on-hand inventory value by five. ✦ UPDATE: When an UPDATE command is executed on a table, an UPDATE trigger on the table fires. For example, management might want to know if anyone ever modifies data (such as the Salary column) in the Employees table. You could create an UPDATE trigger on the Employees table to record into an Auditing table who made the change and when he made the change. Now, if someone enters the database and updates his salary (perhaps by doubling it), the UPDATE trigger on the Employees table would fire and record in the Auditing table who did it and when. ✦ DELETE: When a DELETE command is executed on a table, a DELETE trigger on the table fires. For example, the company you work at might not want to ever delete a customer from the Customers table. Instead, customers should be marked as inactive. You could create a DELETE trigger on the Customers table to roll back the deletion, and change the value of the Status column to Inactive. If someone ever tried to delete a customer, the DELETE trigger would fire and undo the deletion (by rolling back the DELETE statement) and changing the value of the Status column.

## Slide 15: After trigger

- DML triggers can be programmed to perform either after the data modification or instead of the data modification. When a trigger is created, one of these choices is specified:
- AFTER: An AFTER trigger fires after the data modification. In other words, the data modification occurs, and then the trigger fires in response to the data modification. Therefore, an after trigger that rolls back a data modification becomes an expensive operation because the data is changed twice when it shouldn’t be changed at all.

> Notes: DML triggers can be programmed to perform either after the data modifica- tion or instead of the data modification. When a trigger is created, one of these choices is specified: ✦ AFTER: An AFTER trigger fires after the data modification. In other words, the data modification occurs, and then the trigger fires in response to the data modification. Therefore, an after trigger that rolls back a data modification becomes an expensive operation because the data is changed twice when it shouldn’t be changed at all. AFTER is the default for triggers. AFTER triggers can only be specified on tables; they can’t be specified on views. ✦ INSTEAD OF: An INSTEAD OF trigger fires before the data modification. In other words, the data modification is prevented from occurring, and instead, the trigger is executed. INSTEAD OF triggers are commonly created on updateable views. For example, if a view is created by using the UNION clause, an UPDATE on DML Triggers: Letting Your Database Look After Itself 351 the view would fail because the UPDATE statement won’t be able to determine which table to update. The INSTEAD OF trigger can include logic to determine which table to update, and instead of updating the view, it would update the underlying table.

## Slide 16: Instead of trigger

- INSTEAD OF: An INSTEAD OF trigger fires before the data modification. In other words, the data modification is prevented from occurring, and instead, the trigger is executed.
- INSTEAD OF triggers are commonly created on updateable views.

## Slide 17: Inserted and Deleted tables

- Triggers use two special tables that are only accessible to triggers. The data in these tables is available immediately after an INSERT, UPDATE or DELETE statement.
- Inserted table: The inserted table holds data from the last INSERT or UPDATE statement.
- Deleted table: The deleted table holds data from the last DELETE or UPDATE statement.

## Slide 18: Insert Operation

- If one or more rows are added with an INSERT statement, the row(s) are held in the inserted table.
*[image]*

> Notes: The use of INSERT and DELETE statements in these tables is straightfor- ward. If one or more rows are added with an INSERT statement, the row(s) are held in the inserted table. If one or more rows are deleted with a DELETE statement, the row(s) are held in the deleted table.

## Slide 19: Delete Operation

- If one or more rows are deleted with a DELETE statement, the row(s) are held in the deleted table.
*[image]*

## Slide 20: Update Operation

- When an UPDATE statement is executed, the database engine actually deletes the existing row (and holds it in the deleted table) and then adds a new row (and holds it in the inserted table).
*[image]*

> Notes: When an UPDATE statement is executed, the database engine actually deletes the existing row (and holds it in the deleted table) and then adds a new row (and holds it in the inserted table). The new row has all the same column data as the deleted row, except for the column (or columns) that were modified. Although it appears as though the existing row was modified, it was actually deleted and inserted with the modified data.

## Slide 21: When DML triggers are used?

- Make changes to other columns (in the same table or other tables within the database) in response to a data modification.
- Perform auditing by recording who made a data modification and when.
- Roll back or undo data modifications.
- Provide specialized error messages.

## Slide 22: Some facts about triggers

- CHECK constraints can reference only the columns on which the column-level or table-level constraint is defined, any cross-table constraints (business rules) must be defined as triggers.
- Triggers can use to enforce complex business logic that is difficult or impossible to enforce by using other data integrity mechanisms.
- Triggers can cascade changes through related tables in the database.
- Triggers can evaluate the state of a table before and after a data modification and take actions based on that difference.

## Slide 23: Syntax for Creating triggers

- Create in current database by using the CREATE TRIGGER statement
- CREATE TRIGGER [ schema_name. ] trigger_name
- ON { table | view }
- { FOR | AFTER | INSTEAD OF }
- { [ INSERT ] [ , ] [ UPDATE ] [ , ] [ DELETE ] }
- AS
- { sql_statement [ ; ] [ ...n ] }

## Slide 24: How an INSERT Trigger Works

- When an INSERT trigger fires, new rows are added to both the trigger table and the inserted table.
- The inserted table is a temporary table that holds a copy of the rows that have been inserted.
- The inserted table allows you to reference logged data from the initiating INSERT statement.
- The trigger can examine the inserted table to determine whether, or how, the trigger actions should be executed.

## Slide 25: How an INSERT Trigger Works

- CREATE TRIGGER [insrtWorkOrder] ON [Production].[WorkOrder]AFTER INSERT ASBEGIN  SET NOCOUNT ON;  INSERT INTO [Production].[TransactionHistory](    [ProductID],[ReferenceOrderID],[TransactionType]    ,[TransactionDate],[Quantity],[ActualCost])  SELECT inserted.[ProductID],inserted.[WorkOrderID]    ,'W',GETDATE(),inserted.[OrderQty],0 FROM inserted;End
- INSERT statement executed
- 1
- AFTER INSERT trigger statements executed
- 3
- INSERT statement logged
- 2

## Slide 26: Example of an INSERT Trigger

- CREATE TRIGGER LowCredit
- ON Purchasing.PurchaseOrderHeader
- AFTER INSERT
- AS
- DECLARE @creditrating int
- SELECT @creditrating = v.CreditRating
- FROM Purchasing.PurchaseOrderHeader p INNER JOIN inserted i ON p.PurchaseOrderID = i.PurchaseOrderID JOIN Purchasing.Vendor v on v.VendorID = i.VendorID
- IF @creditrating = 5
- BEGIN
- RAISERROR ('This vendor''s credit rating is too low to accept new purchase orders.', 16, 1)
- ROLLBACK TRANSACTION
- END
- This trigger checks to make sure the credit rating for the vendor is good when an attempt is made to insert a new purchase order.

## Slide 27: How a DELETE Trigger Works

- When a DELETE trigger is fired, deleted rows from the affected table are placed in a special deleted table.
- The deleted table is a logical table that holds a copy of the rows that have been deleted.
- The deleted table enables you to reference logged data from the initiating DELETE statement.
- Consider the following facts when you use the DELETE trigger:
  - When a row is appended to the deleted table, it no longer exists in the database table; therefore, the deleted table and the database tables have no rows in common.
  - Space is allocated from memory to create the deleted table. The deleted table is always in the cache.

## Slide 28: How a DELETE Trigger Works

- CREATE TRIGGER [delCategory] ON [Categories]AFTER DELETE ASBEGIN  UPDATE P SET [Discontinued] = 1  FROM [Products] P INNER JOIN deleted as d  ON  P.[CategoryID] = d.[CategoryID] END;
- DELETE statement executed
- AFTER DELETE trigger statements executed
- DELETE statement logged
- 1
- 3
- 2

## Slide 29: How an UPDATE Trigger Works

- When an UPDATE statement is executed on a table that has a trigger defined on it, the original rows (before image) are moved into the deleted table, and the updated rows (after image) are inserted into the inserted table.
- The trigger can examine the deleted and inserted tables, as well as the updated table, to determine whether multiple rows have been updated and how the trigger actions should be carried out.
- You can define a trigger to monitor data updates on a specific column by using the IF UPDATE statement.

## Slide 30: How an UPDATE Trigger Works

- CREATE TRIGGER [updtProductReview] ON [Production].[ProductReview]AFTER UPDATE NOT FOR REPLICATION AS BEGIN    UPDATE [Production].[ProductReview]    SET [Production].[ProductReview].[ModifiedDate] =       GETDATE() FROM inserted    WHERE inserted.[ProductReviewID] =       [Production].[ProductReview].[ProductReviewID];END;
- UPDATE statement executed
- AFTER UPDATE trigger statements executed
- UPDATE statement logged
- 1
- 3
- 2

## Slide 31: How an INSTEAD OF Trigger Works

- This trigger executes instead of the original triggering action.
- INSTEAD OF triggers increase the variety of types of updates that you can perform against a view.
- Each table or view is limited to one INSTEAD OF trigger for each triggering action (INSERT, UPDATE, or DELETE).
- They enable you to code logic that can reject parts of a batch while allowing other parts of a batch to succeed.

## Slide 32: How an INSTEAD OF Trigger Works

- CREATE TRIGGER [delEmployee] ON [HumanResources].[Employee] INSTEAD OF DELETE NOT FOR REPLICATION AS BEGIN    SET NOCOUNT ON;    DECLARE @DeleteCount int;    SELECT @DeleteCount = COUNT(*) FROM deleted;    IF @DeleteCount > 0     BEGIN    …    END;END;
- UPDATE, INSERT, or DELETE statement executed
- INSTEAD OF trigger statements executed
- Executed statement does not occur
- 1
- 3
- 2

## Slide 33: Syntax for Altering and Dropping Triggers

- ALTER TRIGGER
- DROP TRIGGER
- ALTER TRIGGER [ schema_name. ] trigger_name
- ON { table | view }
- { FOR | AFTER | INSTEAD OF }
- { [ INSERT ] [ , ] [ UPDATE ] [ , ] [ DELETE ] }
- AS
- { sql_statement [ ; ] [ ...n ] }
- DROP TRIGGER [ schema_name.] trigger_name

## Slide 34: Next Lesson

- Database Administration