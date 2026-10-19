# W2 Advanced Data Modeling


## Slide 1: Advanced Data Modeling

- CT004-3.5-3 Advanced Database Systems

## Slide 2: Topic & Structure of Lesson

- The relevance of data modelling to the relational model
- Problems with ER Models
- Developing Enhanced Entity Relationship Modelling
- Specialization/generalization hierarchies

## Slide 3: Learning Outcomes

- By the end of this lesson you should be able to:
- Explain the relevance of data modelling to the relational model
- Explain and develop enhanced Entity Relationship Modelling
- Describe specialization/generalization hierarchies

## Slide 4: ER Modelling

- ER Modelling is a very effective tool for standard relational DB tasks
- Provides semantic information but not always sufficient
- Less adapted for more complex semantics

## Slide 5: 

- The Database Design Process
- Requirements Definition
- Data Analysis
- Conceptual data model
- Logical data model
- Physical Design
- Database

## Slide 6: Problems with ER Models

- Problems may arise when designing a conceptual data model called connection traps.
- Often due to a misinterpretation of the meaning of certain relationships.
- Two main types of connection traps are called fan traps and chasm traps.

## Slide 7: Problems with ER Models

- Fan Trap
  - -	Where a model represents a relationship between entity types, but pathway between certain entity occurrences is ambiguous.
- Chasm Trap
  - -	Where a model suggests the existence of a relationship between entity types, but pathway does not exist between certain entity occurrences.

## Slide 8: An Example of a Fan Trap

*[image]*

> Notes: One or more than one staff can be located in one division only. One division only can operate one or more branches.

## Slide 9: Semantic Net of ER Model with Fan Trap

- At which branch office does staff number SG37 work?
*[image]*

## Slide 10: Restructuring ER model to remove Fan Trap

*[image]*

## Slide 11: Semantic Net of Restructured ER Model with Fan Trap Removed

- SG37 works at branch B003.
*[image]*

## Slide 12: An Example of a Chasm Trap

*[image]*

> Notes: One branch only has one or more than one staff Zero or one staff can oversees Zero or more than Zero property for rent Zero or more than Zero can be oversees by zero or one staff only

## Slide 13: Semantic Net of ER Model with Chasm Trap

- At which branch office is property PA14 available?
*[image]*

## Slide 14: ER Model restructured to remove Chasm Trap

*[image]*

## Slide 15: Semantic Net of Restructured ER Model with Chasm Trap Removed

*[image]*

## Slide 16: The Extended Entity Relationship Model

- Result of adding more semantic constructs to original entity relationship (ER) model
- Diagram using this model is called an EER diagram (EERD)

## Slide 17: Entity Supertypes and Subtypes

- Entity supertype
  - Generic entity type that is related to one or more entity subtypes
  - Contains common characteristics
- Entity subtypes
  - Contains unique characteristics of each entity subtype

## Slide 18: Entity Supertypes and Subtypes (continued)

- Database Systems: Design, Implementation, & Management, 7th Edition, Rob & Coronel

## Slide 19: Specialization Hierarchy

- Depicts arrangement of higher-level entity supertypes (parent entities) and lower-level entity subtypes (child entities)
- Relationships sometimes described in terms of “IS-A” relationships
- Subtype can exist only within context of supertype and every subtype can have only one supertype to which it is directly related
- Can have many levels of supertype/subtype relationships

## Slide 20: Specialization Hierarchy (continued)

- Database Systems: Design, Implementation, & Management, 7th Edition, Rob & Coronel

## Slide 21: Specialization Hierarchy (continued)

- Support attribute inheritance
- Define special supertype attribute known as subtype discriminator
- Define disjoint/overlapping constraints and complete/partial constraints

## Slide 22: Inheritance

- Enables entity subtype to inherit attributes and relationships of supertype
- All entity subtypes inherit their primary key attribute from their supertype
- At implementation level, supertype and its subtype(s) depicted in specialization hierarchy maintain a 1:1 relationship

## Slide 23: Inheritance (continued)

- Database Systems: Design, Implementation, & Management, 7th Edition, Rob & Coronel

## Slide 24: Subtype Discriminator

- The attribute in supertype entity that determines to which entity subtype each supertype occurrence is related
- The default comparison condition for subtype discriminator attribute is equality comparison

## Slide 25: Disjoint and Overlapping Constraints

- Disjoint subtypes
  - Also known as non-overlapping subtypes
  - Subtypes that contain unique subset of supertype entity set
- Overlapping subtypes
  - Subtypes that contain nonunique subsets of supertype entity set

## Slide 26: Disjoint and Overlapping Constraints (continued)

- Database Systems: Design, Implementation, & Management, 7th Edition, Rob & Coronel

## Slide 27: Disjoint and Overlapping Constraints (continued)

- Database Systems: Design, Implementation, & Management, 7th Edition, Rob & Coronel

## Slide 28: Completeness Constraint

- Specifies whether each entity supertype occurrence must also be member of at least one subtype
- Can be partial or total

## Slide 29: Completeness Constraint (continued)

- Database Systems: Design, Implementation, & Management, 7th Edition, Rob & Coronel

## Slide 30: Specialization and Generalization

- Specialization
  - Top-down process of identifying lower-level, more specific entity subtypes from higher-level entity supertype
  - Based on grouping unique characteristics and relationships of the subtypes

## Slide 31: Specialization and Generalization(continued)

- Generalization
  - Bottom-up process of identifying higher-level, more generic entity supertype from lower-level entity subtypes
  - Based on grouping common characteristics and relationships of the subtypes