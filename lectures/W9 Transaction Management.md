# W9 Transaction Management


## Slide 1: CT004-3.5-3 Advanced Database Systems

- Transaction Management

## Slide 2: Learning objectives

- Function and importance of transactions.
- Properties of transactions.
- Concurrency Control
- Concurrency problem
  - - Meaning of serializability.
  - - How locking can ensure serializability.
  - - Deadlock and how it can be resolved.

## Slide 3: Transaction Support

  - Transaction
  - Action, or series of actions, carried out by user or application, which reads or updates contents of database.
- Logical unit of work on the database.
- Transforms database from one consistent state to another, although consistency may be violated during transaction.

## Slide 4: Example Transaction

*[image]*

## Slide 5: Transaction Support

- Can have one of two outcomes:
  - Success - transaction commits and database reaches a new consistent state.
  - Failure - transaction aborts, and database must be restored to consistent state before it started.
  - Such a transaction is rolled back or undone.
- Committed transaction cannot be aborted.
- Aborted transaction that is rolled back can be restarted later.

> Notes: A transaction can have one of two outcomes.  If it completes successfully, the transaction is said to have committed and the database reaches a new consistent state.  if the transaction does not execute successfully, the transaction is aborted.   If a transaction is aborted, the database must be restored to the consistent state it was in before the transaction started. Such a transaction is rolled back or undone.   A committed transaction cannot be aborted.   If we decide that the committed transaction was a mistake, we must perform another compensating transaction to reverse its effects.

## Slide 6: State Transition Diagram for Transaction

*[image]*

> Notes: Figure 20.2 shows the state transition diagram for a transaction. Note that in addition to the obvious states of ACTIVE, COMMITTED, and ABORTED, there are two other states: n PARTIALLY COMMITTED, which occurs after the ﬁnal statement has been executed. At this point, it may be found that the transaction has violated serializability (see Sec- tion 20.2.2) or has violated an integrity constraint and the transaction has to be aborted. Alternatively, the system may fail and any data updated by the transaction may not have been safely recorded on secondary storage. In such cases, the transaction would go into the FAILED state and would have to be aborted. If the transaction has been successful, any updates can be safely recorded and the transaction can go to the COMMITTED state. n FAILED, which occurs if the transaction cannot be committed or the transaction is aborted while in the ACTIVE state, perhaps due to the user aborting the transaction or as a result of the concurrency control protocol aborting the transaction to ensure serializability.

## Slide 7: Properties of Transactions

- Four basic (ACID) properties of a transaction are:
- Atomicity 	‘All or nothing’ property.
- Consistency	Must transform database from one consistent state to another.
- Isolation  	Partial effects of incomplete transactions should not be visible to other transactions.
- Durability	Effects of a committed transaction are permanent and must not be lost because of later failure.

> Notes: There  are  properties  that  all  transactions  should  possess.  The  four  basic,  or  so-called ACID, properties of a transaction are (Haerder and Reuter, 1983): n Atomicity The  ‘all  or  nothing’  property.  A  transaction  is  an  indivisible  unit  that  is either performed in its entirety or is not performed at all. It is the responsibility of the recovery subsystem of the DBMS to ensure atomicity. n Consistency A transaction must transform the database from one consistent state to another consistent state. It is the responsibility of both the DBMS and the application developers to ensure consistency. The DBMS can ensure consistency by enforcing all the constraints that have been speciﬁed on the database schema, such as integrity and enterprise constraints. However, in itself this is insufﬁcient to ensure consistency. For example, suppose we have a transaction that is intended to transfer money from one bank account to another and the programmer makes an error in the transaction logic and debits one account but credits the wrong account, then the database is in an inconsistent state. However, the DBMS would not have been responsible for introducing this incon- sistency and would have had no ability to detect the error.  n Isolation Transactions  execute  independently  of  one  another.  In  other  words,  the  partial effects of incomplete transactions should not be visible to other transactions. It is the responsibility of the concurrency control subsystem to ensure isolation.  n Durability The effects of a successfully completed (committed) transaction are per- manently recorded in the database and must not be lost because of a subsequent failure. It is the responsibility of the recovery subsystem to ensure durability.

## Slide 8: Concurrency Control

- Process of managing concurrent operations on the database without having them interfere with one another.
- Prevents interference when two or more users are accessing database concurrently and at least one is updating data.
- Although two transactions may be correct in themselves, interleaving of operations may produce an incorrect result.

## Slide 9: Need for Concurrency Control

- Three examples of potential problems caused by concurrency:
  - Lost update problem.
  - Uncommitted dependency problem.
  - Inconsistent analysis problem.

## Slide 10: Lost update problem

- Successfully completed update is overridden by another user.

## Slide 11: Lost Update Problem

- Loss of T2’s update avoided by preventing T1 from reading balx until after update.
*[image]*

> Notes: in which transaction T 1 is executing concurrently with transaction T 2 . T 1 is withdrawing £10 from an account with balance bal x , initially £100, and T 2 is depositing £100 into the same account. If these transactions are executed serially, one after the other with no inter- leaving  of  operations,  the  ﬁnal  balance  would  be  £190  no  matter  which  transaction  is  performed ﬁrst. Transactions T 1 and T 2 start at nearly the same time, and both read the balance as £100. T 2 increases bal x by £100 to £200 and stores the update in the database. Meanwhile, transac- tion T 1 decrements its copy of bal x by £10 to £90 and stores this value in the database, over- writing the previous update, and thereby ‘losing’ the £100 previously added to the balance. The loss of T 2 ’s update is avoided by preventing T 1 from reading the value of bal x until after T 2 ’s update has been completed.

## Slide 12: Lost Update Problem

- T1 withdrawing £10 from an account with balx, initially £100.
- T2 depositing £100 into same account.
- Serially, final balance would be £190.

## Slide 13: Uncommitted Dependency Problem

- Occurs when one transaction can see intermediate results of another transaction before it has committed.

## Slide 14: Uncommitted Dependency Problem

- Problem avoided by preventing T3 from reading balx until after T4 commits or aborts.
*[image]*

> Notes: using the same initial value for  balance  bal x as  in  the  previous  example.  Here,  transaction  T 4 updates  bal x to  £200,  but it aborts the transaction so that bal x should be restored to its original value of £100. However, by this time transaction T 3 has read the new value of bal x (£200) and is using  this value as the basis of the £10 reduction, giving a new incorrect balance of £190, instead of £90. The value of bal x read by T 3 is called dirty data, giving rise to the alternative name, the dirty read problem. The reason for the rollback is unimportant; it may be that the transaction was in error, perhaps crediting the wrong account. The effect is the assumption by T 3 that T 4 ’s update completed successfully, although the update was subsequently rolled back. This problem is avoided by preventing T 3 from reading bal x until after the decision has been made to either commit or abort T 4 ’s effects.

## Slide 15: Uncommitted Dependency Problem

- T4 updates balx to £200 but it aborts, so balx should be back at original value of £100.
- T3 has read new value of balx (£200) and uses value as basis of £10 reduction, giving a new balance of £190, instead of £90.

## Slide 16: Inconsistent Analysis Problem

- Occurs when transaction reads several values but second transaction updates some of them during execution of first.
- Sometimes referred to as dirty read or unrepeatable read.

## Slide 17: Inconsistent Analysis Problem

- Problem avoided by preventing T6 from reading balx and balz until after T5 completed updates.
*[image]*

> Notes: T5 (trans 5): mainly it withdraw 10 from (balx) and add it to (balz)  Final value suppose to be 195   The problem of inconsistent analysis occurs when a transaction reads several values from the database but a second transaction updates some of them during the execution of the ﬁrst.  For  example,  a  transaction  that  is  summarizing  data  in  a  database  (for  example,  totaling balances) will obtain inaccurate results if, while it is executing, other transactions are updating the database. One example is illustrated in Figure 20.6, in which a summary transaction  T 6 is  executing  concurrently  with  transaction  T 5 .  Transaction  T 6 is  totaling  the balances of account x (£100), account y (£50), and account z (£25). However, in the meantime, transaction T 5 has transferred £10 from bal x to bal z , so that T 6 now has the wrong result (£10 too high). This problem is avoided by preventing transaction T 6 from reading bal x and bal z until after T 5 has completed its updates.

## Slide 18: Inconsistent Analysis Problem

- T6 is totaling balances of account x (£100), account y (£50), and account z (£25).
- Meantime, T5 has transferred £10 from balx to balz, so T6 now has wrong result (£10 too high).

## Slide 19: Serializability

- Objective of a concurrency control protocol is to schedule transactions in such a way as to avoid any interference.
- Could run transactions serially, but this limits degree of concurrency or parallelism in system.
- Serializability identifies those executions of transactions guaranteed to ensure consistency.

## Slide 20: Serializability

  - Schedule
  - Sequence of reads/writes by set of concurrent transactions.
  - Serial Schedule
  - Schedule where operations of each transaction are executed one after the other without any interleaved operations from other transactions.

## Slide 21: Nonserial Schedule

- Schedule where operations from set of concurrent transactions are interleaved.
- Objective of serializability is to find nonserial schedules that allow transactions to execute concurrently without interfering with one another.
- In other words, want to find nonserial schedules that are equivalent to some serial schedule. Such a schedule is called serializable.

## Slide 22: Serializability

- In serializability, ordering of read/writes is important:
- (a)  If two transactions only read a data item, they do not conflict and order is not important.
- (b)  If two transactions either read or write completely separate data items, they do not conflict and order is not important.
- (c) If one transaction writes a data item and another reads or writes same data item, order of execution is important.

## Slide 23: Example of Conflict Serializability

*[image]*

> Notes: Schedule S 3 is a serial schedule and, since S 1 and S 2 are equivalent to S 3 , S 1 and S 2 are  serializable schedules.  This type of serializability is known as conﬂict serializability. A conﬂict serializable schedule orders any conﬂicting operations in the same way as some serial execution.

## Slide 24: Serializability

- Conflict serializable schedule orders any conflicting operations in same way as some serial execution.

## Slide 25: Concurrency Control Techniques

- Two basic concurrency control techniques:
  - Locking,
  - Timestamping.
- Both are conservative approaches: delay transactions in case they conflict with other transactions.
- Optimistic methods assume conflict is rare and only check for conflicts at commit.

## Slide 26: Locking

- Transaction uses locks to deny access to other transactions and so prevent incorrect updates.
- Most widely used approach to ensure serializability.
- Generally, a transaction must claim a shared (read) or exclusive (write) lock on a data item before read or write.
- Lock prevents another transaction from modifying item or even reading it, in the case of a write lock.

## Slide 27: Locking - Basic Rules

- If transaction has shared lock on item, can read but not update item.
- If transaction has exclusive lock on item, it can read and update item.
- Reads cannot conflict, so more than one transaction can hold shared locks concurrently on same item.
- Exclusive lock gives transaction exclusive access to that item.

## Slide 28: Locking - Basic Rules

- Some systems allow transaction to upgrade read lock to an exclusive lock, or downgrade exclusive lock to a shared lock.

## Slide 29: Locking

|  | S | X |
|---|---|---|
| S | true | false |
| X | false | False |
- Ti
- Tj
- Locks must be held for a duration of access

> Notes: S , S true because we allow two shared locks on the tuple

## Slide 30: Two-Phase Locking (2PL)

- Transaction follows 2PL protocol if all locking operations precede first unlock operation in the transaction.
- Two phases for transaction:
  - Growing phase - acquires all locks but cannot release any locks.
  - Shrinking phase - releases locks but cannot acquire any new locks.

## Slide 31: Two-Phase Locking (2PL)

- The protocol has a growing phase and a shrinking phase
- Ensures serialisability, but not the freedom from deadlocks
- May seriously reduce parallelism
- Number of locks acquired
- Growing phase
- Shrinking phase
- Commit point

## Slide 32: Preventing Lost Update Problem using 2PL

*[image]*

> Notes: A solution to the lost update problem is shown in Figure 20.15. To prevent the lost update problem occurring, T 2 ﬁrst requests an exclusive lock on bal x . It can then proceed to read the value of bal x from the database, increment it by £100, and write the new value back to the database. When T 1 starts, it also requests an exclusive lock on bal x . However, because the data item bal x is currently exclusively locked by T 2 , the request is not immediately granted and T 1 has to wait until the lock is released by T 2 . This occurs only once the commit of T 2 has been completed.

## Slide 33: Preventing Uncommitted Dependency Problem using 2PL

*[image]*

> Notes: A solution to the uncommitted dependency problem is shown in Figure 20.16. To prevent this problem occurring, T 4 ﬁrst requests an exclusive lock on bal x . It can then proceed to read the value of balx from the database, increment it by £100, and write the new value back to the database. When the rollback is executed, the updates of transaction T 4 are undone and the value of bal x in the database is returned to its original value of £100. When T 3 starts, it also requests an exclusive lock on bal x . However, because the data item bal x is currently  exclusively  locked  by  T 4 ,  the  request  is  not  immediately  granted  and  T 3 has  to wait until the lock is released by T 4 . This occurs only once the rollback of T 4 has been completed.

## Slide 34: Preventing Inconsistent Analysis Problem using 2PL

*[image]*

> Notes: A solution to the inconsistent analysis problem is shown in Figure 20.17. To prevent this problem occurring, T 5 must precede its reads by exclusive locks, and T 6 must precede its reads with shared locks. Therefore, when T 5 starts it requests and obtains an exclusive lock on bal x . Now, when T 6 tries to share lock bal x the request is not immediately granted and T 6 has to wait until the lock is released, which is when T 5 commits. It  can  be  proved  that  if  every transaction  in  a  schedule  follows  the  two-phase  lock- ing protocol, then the schedule is guaranteed to be conﬂict serializable (Eswaran et al., 1976).

## Slide 35: Database Recovery

- Process of restoring database to a correct state in the event of a failure.
- Need for Recovery Control
  - Two types of storage: volatile (main memory) and nonvolatile.
  - Volatile storage does not survive system crashes.
  - Stable storage represents information that has been replicated in several nonvolatile storage media.

## Slide 36: Types of Failures

- System crashes, resulting in loss of main memory.
- Media failures, resulting in loss of parts of secondary storage.
- Application software errors.
- Natural physical disasters.
- Carelessness or unintentional destruction of data or facilities.

## Slide 37: Transactions and Recovery

- Transactions represent basic unit of recovery.
- Recovery manager responsible for atomicity and durability.
- If failure occurs between commit and database buffers being flushed to secondary storage then, to ensure durability, recovery manager has to redo (rollforward) transaction’s updates.

## Slide 38: Transactions and Recovery

- If transaction had not committed at failure time, recovery manager has to undo (rollback) any effects of that transaction for atomicity.
- Partial undo - only one transaction has to be undone.
- Global undo - all transactions have to be undone.

## Slide 39: Example

*[image]*

## Slide 40: Example

- DBMS starts at time t0, but fails at time tf. Assume data for transactions T2 and T3 have been written to secondary storage.
- T1 and T6 have to be undone. In absence of any other information, recovery manager has to redo T2, T3, T4, and T5. if there is no check point

> Notes: In case the checkpoint is not exists the recovery manager must redo: T2, T3, T4, and T5 Undo: T1 and T6  In case the checkpoint exists the recovery manager must  redo: T4 and T5 undo: T1 and T6  T2 and T3 will not be effected since they have been committed earlier

## Slide 41: Recovery Facilities

- DBMS should provide following facilities to assist with recovery:
  - Backup mechanism, which makes periodic backup copies of database.
  - Logging facilities, which keep track of current state of transactions and database changes.
  - Checkpoint facility, which enables updates to database in progress to be made permanent.
  - Recovery manager, which allows DBMS to restore database to consistent state following a failure.

## Slide 42: Log File

- Contains information about all updates to database:
  - Transaction records.
  - Checkpoint records.
- Often used for other purposes (for example, auditing).

## Slide 43: Log File

- Transaction records contain:
  - Transaction identifier.
  - Type of log record, (transaction start, insert, update, delete, abort, commit).
  - Identifier of data item affected by database action (insert, delete, and update operations).
  - Before-image of data item.
  - After-image of data item.
  - Log management information.

## Slide 44: Sample Log File

*[image]*

## Slide 45: Checkpointing

  - Checkpoint
  - Point of synchronization between database and log file. All buffers are force-written to secondary storage.
- Checkpoint record is created containing identifiers of all active transactions.
- When failure occurs, redo all transactions that committed since the checkpoint and undo all transactions active at time of crash.

## Slide 46: Checkpointing

- In previous example, with checkpoint at time tc, changes made by T2 and T3 have been written to secondary storage.
- Thus:
  - only redo T4 and T5,
  - undo transactions T1 and T6.

## Slide 47: 

- Q & A