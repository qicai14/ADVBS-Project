# W8 Database Security


## Slide 1: 

- Database Security
- CT004-3.5-3 Advanced Database Systems

## Slide 2: Objectives

- Scope of database security.
- Why database security is a serious concern for an organization.
- Type of threats that can affect a database system.
- DISCRETIONARY ACCESS CONTROL (SQL security)

## Slide 3: Database Security

- Mechanisms that protect the database against intentional or accidental threats.

## Slide 4: Database Security

- Data is a valuable resource that must be strictly controlled and managed, as with any corporate resource.
- Part or all of the corporate data may have strategic importance and therefore needs to be kept secure and confidential.
- Security considerations do not only apply to the data held in a database. Breaches of security may affect other parts of the system, which may in turn affect the database.

## Slide 5: Database Security

- Involves measures to avoid:
  - Theft and fraud
  - Loss of confidentiality (secrecy)
  - Loss of privacy
  - Loss of integrity
  - Loss of availability

> Notes: 542 | Chapter 19 z Security 19.1 In Section 19.1 we discuss the scope of database security and examine the types of threat that may affect computer systems in general. In Section 19.2 we consider the range of computer-based controls that are available as countermeasures to these threats. In Sec- tions  19.3  and  19.4  we  describe  the  security  measures  provided  by  Microsoft  Ofﬁce Access  2003  DBMS  and  Oracle9i DBMS.  In  Section  19.5  we  identify  the  security  measures associated with DBMSs and the Web. The examples used throughout this chapter are taken from the DreamHome case study described in Section 10.4 and Appendix A. Database Security In this section we describe the scope of database security and discuss why organizations must take potential threats to their computer systems seriously. We also identify the range of threats and their consequences on computer systems. Database The mechanisms that protect the database against intentional or acci- security dental threats. Security  considerations  apply  not  only  to  the  data  held  in  a  database:  breaches  of  security  may  affect  other  parts  of  the  system,  which  may  in  turn  affect  the  database. Consequently, database security encompasses hardware, software, people, and data. To effectively implement security requires appropriate controls, which are deﬁned in speciﬁc mission  objectives  for  the  system.  This  need  for  security,  while  often  having  been neglected or overlooked in the past, is now increasingly recognized by organizations. The reason for this turnaround is the increasing amounts of crucial corporate data being stored on computer and the acceptance that any loss or unavailability of this data could prove to be disastrous. A database represents an essential corporate resource that should be properly secured using  appropriate  controls.  We  consider  database  security  in  relation  to  the  following  situations: n theft and fraud; n loss of conﬁdentiality (secrecy); n loss of privacy; n loss of integrity; n loss of availability. These situations broadly represent areas in which the organization should seek to reduce  risk, that is the possibility of incurring loss or damage. In some situations, these areas are closely related such that an activity that leads to loss in one area may also lead to loss in another. In addition, events such as fraud or loss of privacy may arise because of either intentional or unintentional acts, and do not necessarily result in any detectable changes to the database or the computer system. Theft and fraud affect not only the database environment but also the entire organiza- tion. As it is people who perpetrate such activities, attention should focus on reducing the opportunities for this occurring. Theft and fraud do not necessarily alter data, as is the case for activities that result in either loss of conﬁdentiality or loss of privacy. Conﬁdentiality refers to the need to maintain secrecy over data, usually only that which is critical to the organization, whereas privacy refers to the need to protect data about in- dividuals. Breaches of security resulting in loss of conﬁdentiality could, for instance, lead to  loss  of  competitiveness,  and  loss  of  privacy  could  lead  to  legal  action  being  taken against the organization. Loss of data integrity results in invalid or corrupted data, which may seriously affect the operation of an organization. Many organizations are now seeking virtually continuous operation, the so-called 24/7 availability (that is, 24 hours a day, 7 days a week). Loss  of availability means that the data, or the system, or both cannot be accessed, which can seriously affect an organization’s ﬁnancial performance. In some cases, events that cause a system to be unavailable may also cause data corruption. Database  security  aims  to  minimize  losses  caused  by  anticipated  events  in  a  cost- effective manner without unduly constraining the users. In recent times, computer-based criminal activities have signiﬁcantly increased and are forecast to continue to rise over the next few years

## Slide 6: Threat

  - Any situation or event, whether intentional or unintentional, that will negatively affect a system and consequently an organization.

## Slide 7: List of threats and there effects

*[image]*

## Slide 8: Threats summary

*[image]*

## Slide 9: Representation of a typical multi-user computer environment.

*[image]*
- SQL security
- DISCRETIONARY ACCESS CONTROL

## Slide 10: Authorization & Authentication

- Authorization: The granting of a right or privilege that enables a user to have legitimate access to a system or a system’s object.
- Authentication: A mechanism that determines whether a user is who he or she claims to be.

## Slide 11: Database Security

- Authorization Rules																					Authentication Access
- Requests
- Database Security
- System
- Database
- DBA
- Users
- Database

## Slide 12: Database Security

- Three main issues in DB Security:
- 1. Legal and Ethical considerations: who has the right to read what information?
- 2. Policy issues: Who should enforce security (government, corporations, department)?
- 3. System level issues: where should security be enforced in the System and How?

## Slide 13: Database Security

- ACCESS CONTROL
- Who should be allowed access to which databases.
- Typically enforced using system level accounts with passwords.

## Slide 14: DISCRETIONARY ACCESS CONTROL

- Authorization rules take into accounts a THREE concepts:
- 1. Users: Individuals who perform some activity on the database.
- 2. Objects: Database units that require authorization in order to manipulate, eg. Table, columns, and rows.
- 3. Privileges: Any action that might be performed on an object by a user. Eg. Read, update, Insert, Delete.

> Notes: SQL security is centered around three concepts or ideas: ❑ Users: Users, or more correctly user IDs, represent people or programs performing actions on objects in the database. Whenever the DBMS creates a new table, inserts or deletes records in that table, or modifies the records in that table, it does so on behalf of a user ID. The DBMS grants user IDs privileges to perform specific actions on specific tables. ❑ Objects: The SQL standards define specific objects in the database that users can manipulate. Originally the only objects were tables and views, but the standard has been expanded to include specific columns in tables as well as domains and character sets, and the individual DBMS often adds its own objects that it allows users to manipulate. ❑ Privileges: The third leg of SQL security comprises privileges that allow users to manipulate objects. These privileges start with SELECT, INSERT, DELETE, and UPDATE for tables and views but have been expanded to include privileges appropriate to non-data objects.

## Slide 15: 

| USER | OBJECT | Privilege |
|---|---|---|
| Ed | Employee | Read |
| Ed | Employee | Insert |
| Ed | Employee | Modify |
| Ed | Employee | Grant |
| Bill | Employee | Read |
| Sally | Purchase Order | Insert |
| Sally | Purchase Order | Modify |
| Clerks | Employee | Read |
- authorization table

## Slide 16: DISCRETIONARY ACCESS CONTROL

- User-Based Security
- Users are individually defined in the DBMS and each object and Privilege is specified.
- Eg . User SMITH
|  | Objects |  |  |  |
|---|---|---|---|---|
| Privileges | Employees | Orders | Products | …….. |
| Read | Y | Y | Y | …. |
| Insert | N | Y | N | …. |
| Modify | N | Y | Y | …. |
| Delete | N | N | N | …. |
| Grant | N | N | N | …. |

## Slide 17: DISCRETIONARY ACCESS CONTROL

- Object Based Security
- Objects are individually defined in the DBMS and each subject and action is specified.
- Eg. The EMPLOYEES table has the following authorizations:
|  | Users |  |  |  |  |
|---|---|---|---|---|---|
| Privilege | SMITH | JONES | GREEN | DBA | ….. |
| Read | Y | Y | N | Y | … |
| Insert | N | N | N | Y | … |
| Modify | N | N | N | Y | … |
| Delete | N | N | N | Y | … |
| Grant | N | N | N | Y | … |

## Slide 18: GRANT and REVOKE Statements

- SQL provides two main statements for setting up authorization.
- GRANT is used to grant an action on an object to a user.
- GRANT action1, action2,…..
- ON object1, object2, …..
- TO subject1, subject2, ….
- Another option of the GRANT Statement is WITH GRANT OPTION. This allows grantee to propagate the authorization to another subject.
- Eg. A database with
- Tables: employees, departments, orders,  products.
- Users: Smith, Jones, Green, Dba.
- GRANT INSERT, DELETE, UPDATE, SELECT ON employees, departments TO Smith;

## Slide 19: GRANT and REVOKE Statements

- GRANT INSERT, SELECT ON orders To Smith;
- GRANT SELECT ON products To Smith;
- GRANT SELECT
- ON employees, departments To Jones;
- GRANT INSERT, DELETE, UPDATE,
- SELECT ON employees, departments, orders,
- products To DBA
- WITH GRANT OPTION;
- Grants can also be done on specific columns in a table:
- GRANT SELECT ON products To Jones;
- GRANT UPDATE ON products (price) to Jones;
- If no GRANT statement is issued, it is assumed that no authorization is given (eg. User Green).

## Slide 20: GRANT and REVOKE Statements

- REVOKE is used to revoke authorization from Subjects.
- REVOKE action1, action2, ….
- ON object1, object2, ….
- FROM   subject1, subject2, ….
- If  Smith leaves the company, then we should REVOKE INSERT, DELETE, UPDATE, SELECT ON employees, departments FROM Smith;
  - REVOKE INSERT, SELECT ON orders FROM Smith;
- REVOKE SELECT ON products FROM Smith;
- Many RDBMS have all PRIVILEGES option that will revoke all of the privileges on an object from a Subject.
- REVOKE ALL PRIVILEGES ON employees, departments, orders, products FROM Smith;

## Slide 21: 

- Q & A