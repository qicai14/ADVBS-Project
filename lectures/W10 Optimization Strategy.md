# W10 Optimization Strategy


## Slide 1: 

- Optimization Strategy

## Slide 2: Objectives

- Meaning of denormalization.
- When to denormalize to improve performance.

## Slide 3: Introduction

- Result of normalization is a design that is structurally consistent with minimal redundancy.
- However, sometimes a normalized database does not provide maximum processing efficiency.
- May be necessary to accept loss of some benefits of a fully normalized design in favor of performance.

## Slide 4: Introduction

- Also consider that denormalization:
  - makes implementation more complex;
  - often sacrifices flexibility;
  - may speed up retrievals but it slows down updates.

## Slide 5: What is Denormalization

- Denormalization refers to a refinement to relational schema such that the degree of normalization for a modified relation is less than the degree of at least one of the original relations.
- Also use term more loosely to refer to situations where two relations are combined into one new relation, which is still normalized but contains more nulls than original relations.

## Slide 6: When to apply denormalization

- Consider denormalization in following situations, specifically to speed up frequent or critical transactions:
  - Combining 1:1 relationships
  - Duplicating non-key attributes in 1:* relationships to reduce joins
  - Duplicating foreign key attributes in 1:* relationships to reduce joins
  - Introducing repeating groups
  - Partitioning relations

## Slide 7: Sample Relation Diagram


## Slide 8: Sample Relations

*[image]*
*[image]*

## Slide 9: Combining 1:1 relationships

*[image]*

## Slide 10: Combining 1:1 relationships


## Slide 11: Duplicating non-key attributes in 1:* relationships to reduce joins

- SELECT p.*, o.lName
- FROM PropertyForRent p, PrivateOwner o
- WHERE p.ownerNo = o.ownerNo AND branchNo = ‘B003’;
*[image]*

## Slide 12: Duplicating non-key attributes in 1:* relationships to reduce joins

*[image]*
- SELECT p.*
- FROM PropertyForRent p
- WHERE branchNo = ‘B003’;

> Notes: Before copying owner Lname  SELECT p.*, o.lName FROM PropertyForRent p, PrivateOwner o WHERE p.ownerNo = o.ownerNo AND branchNo = ‘B003’;  based on the original relation diagram and sample relations shown in Figure 18.1. If we duplicate the lName attribute in the PropertyForRent relation, we can remove the PrivateOwner relation from the query, which in SQL becomes:  After copying Owner Lname SELECT p.* FROM PropertyForRent p WHERE branchNo = ‘B003’;

## Slide 13: Duplicating non-key attributes in 1:* relationships: Lookup Table


## Slide 14: Duplicating non-key attributes in 1:* relationships: Lookup Table


## Slide 15: Duplicating FK attributes in 1:* relationship to reduce joins

*[image]*

## Slide 16: Duplicating FK attributes in 1:* relationship to reduce joins


> Notes: If  an  owner  could  rent  properties  through  many  branches,  the  above  change  would  not work. In this case, it would be necessary to model a many-to-many (*:*) relation- ship between Branch and PrivateOwner. Note also that the PropertyForRent relation has the branchNo attribute because it is possible for a property not to have a member of staff allo- cated to it, particularly at the start when the property is ﬁrst taken on by the agency. If the PropertyForRent relation did not have the branch number, it would be necessary to join the PropertyForRent relation to the Staff relation based on the staffNo attribute to get the required branch number. The original SQL query would then become: SELECT o.lName FROM Staff s, PropertyForRent p, PrivateOwner o WHERE s.staffNo = p.staffNo AND p.ownerNo = o.ownerNo AND s.branchNo = ‘B003’;  Removing  two  joins  from  the  query  may  provide  greater  justiﬁcation  for  creating  a  direct relationship between PrivateOwner and Branch and thereby duplicating the foreign  key branchNo in the PrivateOwner relation.

## Slide 17: Introducing repeating groups


> Notes: In  general,  this  type  of  denormalization  should  be  considered  only  in  the  following  circumstances: n the absolute number of items in the repeating group is known (in this example there is a maximum of three telephone numbers); n the number is static and will not change over time (the maximum number of telephone lines is ﬁxed and is not expected to change); n the number is not very large, typically not greater than 10, although this is not as import- ant as the ﬁrst two conditions.

## Slide 18: Partitioning relations

- Rather than combining relations together, alternative approach is to decompose them into a number of smaller and more manageable partitions.
- Two main types of partitioning: horizontal and vertical.

## Slide 19: Partitioning relations


## Slide 20: Advantages and disadvantages of denormalization


## Slide 21: 

- Q & A