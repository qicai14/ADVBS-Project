# W1 ERD design recap


## Slide 1: Entity Relationship Modeling

- CT004-3.5-3 Advanced Database Systems

## Slide 2: Learning objectives

- At the end of the lecture, you should be able to know
- How to model of real world
    - Entities, Attributes & Relationship
    - ER Diagram

## Slide 3: Entity Relationship Diagram (ERD)

- An entity relationship diagram is a graphical representation of an organization’s data storage requirements.
- Entity relationship diagrams are abstractions of the real world that simplify the problem to be solved while retaining its essential features.

## Slide 4: Entity Relationship Diagram (ERD)

- ERDs are used to:
  - identify the data that must be captured, stored and retrieved in order to support the business activities performed by an organization; and identify the data required to derive and report on the performance measures that an organization should be monitoring.

## Slide 5: 

- The ‘data’ view of a system may be modeled by an Entity-Relationship Diagram (E-R Diagram).
- Provides a high-level,  conceptual view of a DB structure.

## Slide 6: Components of ERD

- Entity Relationship Diagrams have three different components:
  - ENTITIES
  - ATTRIBUTES
  - RELATIONSHIPS

## Slide 7: Entities

- These are the people, places, and things exist in
- an organization. In short, anything which an organization needs to store
- data about.
- An entity can be uniquely identified.
- Organisations collect and store data about entities:
  - if a bank stores data about you - you are an entity
  - if a business stores a piece of paper called an invoice - the invoice is an entity
  - a library stores data about a particular book - the book is an entity
- An actual, real thing or person about which data
- might be stored is referred to as an entity.

## Slide 8: Attributes

- Entities are further described by their attributes (sometimes called data elements). These are the smallest units of data that can be described in a meaningful manner.
- An attribute is a data element associated with an entity.
- The entity type SUPPLIER is likely to have attributes such as:
  - supplier_name
  - supplier_address etc.

## Slide 9: 

- Selecting Entities:
- Deciding upon entities is not always an easy process.
- The danger is in identifying attributes as entities and vice versa.
- Try and identify nouns in the narrative and decide whether or not data is likely to be stored about them.

## Slide 10: Example

- Each engineer is allocated one van (which is driven up to a certain mileage and then replaced). Each member has only one address but perhaps many vehicles. Each visit is to deal with only one vehicle.  A member can be visited more than once on any given date and there may be many visits to a member on different dates.  A member may only be covered for some of the vehicles they own and not for others.
- From the above what are likely entities and attributes?

## Slide 11: 

- The nouns are:
    - engineer,  van,  mileage,  member,  address,  vehicle,  visit and date.
- Entities:
    - engineer,  van, member,  vehicle,  visit.
- Attributes
    - mileage (van)
    - address (member)
    - date (visit)

## Slide 12: Relationships

- Entities are associated with each other via relationships.
- A relationship is a named association between two or more
- entity types.
- The relationship PLAY-FOR between the entity types
- PLAYER and TEAM.
  - The relationship CITIZEN-OF between the entity types 	PERSON and COUNTRY
  - EMPLOYEEs work in a DEPARTMENT
- LAWYERs advise CLIENTs
- EQUIPMENT is allocated to PROJECTs

## Slide 13: 


## Slide 14: Types of Relationships

- There are potentially three types of relationship that can exist between two different entities:
  - One-to-One Relationships
  - One-to-Many Relationships
  - Many-to-Many Relationships

## Slide 15: Types of Relationships

- One to One Relationship(1:1)
- This type of relationship takes place when a single occurrence
- of an entity is related to just one occurrence of a second entity.
- The relationship HEAD-OF between entity types MANAGER and
- DEPARTMENT.
- This means that a department has at most one head and that manager is head of at most one department.

> Notes: Semantic net used for clarification

## Slide 16: 

- One-to-Many Relationship(1:M)
- This type of relationship takes place when a single occurrence
- of an entity is related to many occurrences of a second entity.
- The relationship SUPERVISES between the entity types
- MANAGER and EMPLOYEE.
- This assumes that a manager may supervise any number of different employees but a given employee is supervised by at most one manager.

## Slide 17: 


## Slide 18: 

- Many-to-Many Relationship (M:N)
- This type of relationship takes place when many occurrences of an entity are related to many occurrences of a second entity.
- The relationship ASSIGNED-TO between the entity types EMPLOYEE and PROJECT.
- An employee may be assigned to many different projects and each project may have many employees assigned to it.

## Slide 19: Notation

- INVOICE
- is sent by
- A
- B
- A
- B
- A plain rectangle is used to
- represent the entity type.
- A labeled line to represent the
- relationship.
- 1 : 1
- 1 : N

> Notes: This is Information engineering notation

## Slide 20: Examples

- COURSE
- STUDENT
- has enrolled
- ONE course has enrolled on it ONE or MORE students.
- many students are enrolled on ONE course.
- LOAN
- BOOK
- refers to
- ONE loan refers to ONE book.
- ONE book is referred to on ONE loan.

## Slide 21: Many-to-Many Relationship Example

- Relational databases cannot support this relationship type.
- These relationships imply a missing or link entity.
- Suppose investigation and analysis has shown that:
  - any one supplier might supply more than one kind of part.
  - any one kind of part might be bought in from a number of different suppliers.
- SUPPLIER
- PART
- supplies

## Slide 22: Many to Many Example Cont’d

- The many-to-many relationship type is removed as follows:
- SUPPLIER
- PART
- X

## Slide 23: Many to Many Example Cont’d

- Thinking of an appropriate name for entity ‘X’ can be difficult.
- In such cases it is acceptable to form it from the names of the original two entities.
- SUPPLIER
- PART
- SUPPLIER_
- PART

## Slide 24: Guidelines for Drawing an E-R Diagram

- Select likely entities.
- Select an identifier for each of the entities.
- Produce an entity relationship grid.
- Identify relationships between the selected entities.
- Sketch an E-R Diagram based on the above.
- Decompose any N:M relationships.  (If N:M relationships are present,  2 ERDs will be required.)

## Slide 25: Example

- Simple Hospital System
- In a hospital system, each ward has many patients who
- are cared for by nurses assigned to the ward. Patients
- may have more than one disease, thus requiring
- treatment by more than one specialist doctor.
- Draw an ERD for the simple hospital system.

## Slide 26: ERD Example – Simple Hospital System

- WARD
- NURSE
- PATIENT
- DOCTOR
- treats
- accommodates
- has
- assigned
- Disease
- suffers
- from
- cares
- for

## Slide 27: Example

  - Small College Database
- A small college database has the following structure.
- A department has many lecturers.  A lecturer belongs to only one department.  The department offers many different courses, and many lecturers can teach on a single course.  Lecturers can also teach on more than one course.  Many students enrol for many courses.
- Draw an ERD for this system.

## Slide 28: Small College Database

- DEPARTMENT
- LECTURER
- STUDENT
- COURSE
- is_in
- enrols
- teaches_on
- offers

## Slide 29: Example of Chen Notation

*[image]*

## Slide 30: Example of Crow’s Feet Notation

*[image]*

## Slide 31: Q & A
