# W11 Data warehouse and olap


## Slide 1: 

- Data Warehouse and OLAP
- Optimization Strategy

## Slide 2: Learning Outcomes

- By the end of this lecture, YOU should be able to:
- Explain data warehouse and OLAP concepts
- Explain the data warehouse architecture and schemes
- Introduce the concept of OLAP

## Slide 3: Key Terms you must be able to use

- If you have mastered this topic, you should be able to use the following terms correctly in your assignments and exams:
  - OLTP
  - OLAP
  - Data Cube
  - Star Scheme
- Data Mining: Concepts and Techniques

## Slide 4: Data Warehousing and OLAP

- What is a data warehouse?
- A multi-dimensional data model

## Slide 5: What is Data Warehouse?

- Defined in many different ways, but not strictly.
  - A decision support database that is maintained separately from the organization’s operational database
  - Support information processing by providing a solid platform of consolidated, historical data for analysis.
- “A data warehouse is a subject-oriented, integrated, time-variant, and nonvolatile collection of data in support of management’s decision-making process.”—W. H. Inmon
- Data warehousing:
  - The process of constructing and using data warehouses

> Notes: “Then, what exactly is a data warehouse?” Data warehouses have been deﬁned in many ways, making it difﬁcult to formulate a rigorous deﬁnition. Loosely speaking, a data warehouse refers to a database that is maintained separately from an organization’s oper- ational databases. Data warehouse systems allow for the integration of a variety of appli- cation systems. They support information processing by providing a solid platform of consolidated historical data for analysis.  In sum, a data warehouse is a semantically consistent data store that serves as a phys- ical implementation of a decision support data model and stores the information on which an enterprise needs to make strategic decisions. A data warehouse is also often viewed as an architecture, constructed by integrating data from multiple heterogeneous sources to support structured and/or ad hoc queries, analytical reporting, and decision making.

## Slide 6: Data Warehouse—Subject-Oriented

- Organized around major subjects, such as customer, product, sales.
- Focusing on the modeling and analysis of data for decision makers, not on daily operations or transaction processing.
- Provide a simple and concise view around particular subject issues by excluding data that are not useful in the decision support process.

## Slide 7: Data Warehouse—Integrated

- Constructed by integrating multiple, heterogeneous data sources
  - relational databases, flat files, on-line transaction records
- Data cleaning and data integration techniques are applied.
  - Ensure consistency in naming conventions, encoding structures, attribute measures, etc. among different data sources
    - E.g., Hotel price: currency, tax, breakfast covered, etc.
  - When data is moved to the warehouse, it is converted.

## Slide 8: Data Warehouse—Time Variant

- The time horizon for the data warehouse is significantly longer than that of operational systems.
  - Operational database: current value data.
  - Data warehouse data: provide information from a historical perspective (e.g., past 5-10 years)
- Every key structure in the data warehouse
  - Contains an element of time, explicitly or implicitly
  - But the key of operational data may or may not contain “time element”.

## Slide 9: Data Warehouse—Non-Volatile

- A physically separate store of data transformed from the operational environment.
- Operational update of data does not occur in the data warehouse environment.
  - Does not require transaction processing, recovery, and concurrency control mechanisms
  - Requires only two operations in data accessing:
    - initial loading of data and access of data.

## Slide 10: How are organizations using the information from data warehouses ?

- Many organizations use this information to support business decision making activities:
- Increasing customer focus, which includes the analysis of customer buying patterns (such as buying preference, buying time, budget cycles, and appetites for spending).
- Repositioning products and managing product portfolios by comparing the performance of sales by quarter, by year, and by geographic regions in order to ﬁne-tune production strategies.
- Data Mining: Concepts and Techniques

## Slide 11: OLTP vs. OLAP


## Slide 12: Why Separate Data Warehouse?

- High performance for both systems
  - DBMS— tuned for OLTP: access methods, indexing, concurrency control, recovery
  - Warehouse—tuned for OLAP: complex OLAP queries, multidimensional view, consolidation.
- Different functions and different data:
  - missing data: Decision support requires historical data which operational DBs do not typically maintain
  - data consolidation:  DS requires consolidation (aggregation, summarization) of data from heterogeneous sources
  - data quality: different sources typically use inconsistent data representations, codes and formats which have to be reconciled

## Slide 13: Data Warehousing and OLAP

- What is a data warehouse?
- A multi-dimensional data model
- Data warehouse architecture

## Slide 14: A 2-D view of sales data for AllElectronics

- Data Mining: Concepts and Techniques
*[image]*

> Notes: A 2-D view of sales data for AllElectronics according to the dimensions time and item, where the sales are from branches located in the city of Vancouver. The measure dis- played is dollars sold (in thousands).

## Slide 15: 3-D view of sales data for AllElectronics

- Data Mining: Concepts and Techniques

> Notes: Now, suppose that we would like to view the sales data with a third dimension. For instance, suppose we would like to view the data according to time and item, as well as location for the cities Chicago, New York, Toronto, and Vancouver.

## Slide 16: From Tables and Spreadsheets to Data Cubes

- A data warehouse is based on a multidimensional data model which views data in the form of a data cube
- A data cube, such as sales, allows data to be modeled and viewed in multiple dimensions
  - Dimension tables, such as item (item_name, brand, type), or time(day, week, month, quarter, year)
  - Fact table contains measures (such as dollars_sold) and keys to each of the related dimension tables
- In data warehousing literature, an n-D base cube is called a base cuboid. The top most 0-D cuboid, which holds the highest-level of summarization, is called the apex cuboid.  The lattice of cuboids forms a data cube.

## Slide 17: Conceptual Modeling of Data Warehouses

- Modeling data warehouses: dimensions & measures
  - Star schema: A fact table in the middle connected to a set of dimension tables
  - Snowflake schema:  A refinement of star schema where some dimensional hierarchy is normalized into a set of smaller dimension tables, forming a shape similar to snowflake
  - Fact constellations:  Multiple fact tables share dimension tables, viewed as a collection of stars, therefore called galaxy schema or fact constellation

## Slide 18: Star schema

- The most common modeling paradigm is the star schema, in which the data warehouse contains :
- (1) a large central table (fact table) containing the bulk of the data, with no redundancy, and
- (2) a set of smaller attendant tables (dimension tables), one for each dimension. The schema graph resembles a starburst, with the dimension tables displayed in a radial pattern around the central fact table.
- Data Mining: Concepts and Techniques

## Slide 19: Example of Star Schema

- time_key
- day
- day_of_the_week
- month
- quarter
- year
- time
- location_key
- street
- city
- province_or_street
- country
- location
- Sales Fact Table
- time_key
- item_key
- branch_key
- location_key
- units_sold
- dollars_sold
- avg_sales
- Measures
- item_key
- item_name
- brand
- type
- supplier_type
- item
- branch_key
- branch_name
- branch_type
- branch

## Slide 20: 

- Q & A