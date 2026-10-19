# W7 Database Administration


## Slide 1: 

- Database Administration
- CT004-3.5-3 Advanced Database Systems

## Slide 2: Database Administration

- At the end of this chapter, you will be able to:
- Explain the evolution of Database administration
- Discuss the role of the Data Administrator
- Discuss the role of the Database Administrator

## Slide 3: Database Administration

- DBMS is just a tool for managing data and must be used effectively to produce the desired results
- Introduction of a DBMS represents a big change and can have a big impact
  - Positive or negative depending on how its administered
- Process includes 3 important aspects
  - Technological : DBMS software and hardware
  - Managerial: administrative functions
  - Cultural: Corporate resistance to change

## Slide 4: Technological aspect

- Selecting, installing, configuring and monitoring the DBMS
  - To make sure it handles data storage, access and security efficiently
  - Managed by people with technical skills necessary to provide adequate support for all users
    - Programmers, managers and end-users
  - Database administration staffing is a key consideration
    - Personnel must have mix of technical and managerial skills

> Notes: This is very important aspect since it will effect the organization from financial point of view  which type of database to be used (planning a head for 5 years at least)  database administrators must be having many skiils How to provide support

## Slide 5: Managerial Aspect

- High quality DBMS does not guarantee a high quality information system
- Requires careful planning to create appropriate organisational structure
- Personnel must have excellent interpersonal and communication skills combined with broad organisational and business understanding
- Top management must be committed to the new system and support the database administration functions goals and roles

> Notes: Understand the process is the most important factor Proper planning  communication skills  top management support (Case scenario)

## Slide 6: Cultural Impact

- DBMS is likely to have an effect on people, functions and interactions
  - Additional personnel may be required
  - New roles allocated
  - Employee performance might be evaluated
- Individual department managers surrender ownership to data administration function and share data with the rest of the company
- People might be unwilling to use the information provided and question its accuracy
- Database administration department will need to listen to end users concerns and act by educating about benefits

> Notes: Organizational culture  The values and behaviors that contribute to the unique social and psychological environment of an organization. Organizational culture includes an organization's expectations, experiences, philosophy, and values that hold it together, and is expressed in its self-image, inner workings, interactions with the outside world, and future expectations. It is based on shared attitudes, beliefs, customs, and written and unwritten rules that have been developed over time and are considered valid. Also called corporate culture  Change process  Unfreeze A basic tendency of people is to seek a context in which they have relative safety and feel a sense of control. In establishing themselves, they attach their sense of identity to their environment. This creates a comfortable stasis from which any alternatives, even those which may offer significant benefit, will cause discomfort. Talking about the future thus is seldom enough to move them from this 'frozen' state and significant effort may be required to 'unfreeze' them and get them moving. This usually requires Push methods to get them moving, after which Pull methods can be used to keep them going. The term 'change ready' is often used to describe people who are unfrozen and ready to take the next step. Some people come ready for change whilst others take a long time to let go of their comfortable current realities.  Transition A key part of Lewin's model is the notion that change, even at the psychological level, is a journey rather than a simple step. This journey may not be that simple and the person may need to go through several stages of misunderstanding before they get to the other side. A classic trap in change is for the leaders to spend months on their own personal journeys and then expect everyone else to cross the chasm in a single bound. Transitioning thus requires time. Leadership is often important and when whole organizations change, the one-eyed person may be king. Some form of coaching, counseling or other psychological support will often be very helpful also. Although transition may be hard for the individual, often the hardest part is to start. Even when a person is unfrozen and ready for change, that first step can be very scary. Transition can also be a pleasant trap and, as Robert Louis Stephenson said, 'It is better to travel hopefully than arrive.' People become comfortable in temporary situations where they are not accountable for the hazards of normal work and where talking about change may be substituted for real action.  Refreeze At the other end of the journey, the final goal is to 'refreeze', putting down roots again and establishing the new place of stability. In practice, refreezing may be a slow process as transitions seldom stop cleanly, but go more in fits and starts with a long tail of bits and pieces. There are good and bad things about this. In modern organizations, this stage is often rather tentative as the next change may well be around the next corner. What is often encouraged, then, is more of a state of 'slushiness' where freezing is never really achieved (theoretically making the next unfreezing easier). The danger with this that many organizations have found is that people fall into a state of change shock, where they work at a low level of efficiency and effectiveness as they await the next change. 'It's not worth it' is a common phrase when asked to improve what they do.  - Share Data (position power) (case scenario)

## Slide 7: Evolution of the Database Administration Function

- Data administration function developed based on the evolution
  - from departmental data processing
  - to the more centralised electronic data processing
  - to the more formal information systems department
- Typical file systems behaved as distinct ‘islands of information’
- As applications began to share a common data repository
  - the need for centralised data management became clear
    - introduction of the database administration function

> Notes: Departmental data  centralised electronic  formal information systems   Filebased System  introduction of databases  database administration function required

## Slide 8: Data and Database Administration

- Many large organisations have two main roles for managing the company data
- Data Administrator and Database Administrator
  - Data Administration: A high-level function that is responsible for the overall management of data resources in an organization, including maintaining corporate-wide definitions and standards
  - Database Administration: A technical function that is responsible for dealing with technical issues such as security enforcement, database performance, and backup and recovery
- In a small organisation often the same person

## Slide 9: Data Administrator (DA) Responsibilities

- High level corporate function
  - Responsible for controlling the overall corporate data resources both computerised and manual also data outside the scope of DBMS
- Covers a larger area of operations than DBA
- Strong managerial orientation with company wide scope
- Sets data administration goals
- Sets data policies, procedures, standards
- Long term planning
- Will be involved in the conceptual and logical design of a database system
- Database security is a concern of DA in association with DBA
- DBA may report to DA dependent on structure of the organisation

> Notes: Why DA Will be involved in the conceptual and logical design of a database system?  Database security

## Slide 10: Database Administrator - DBA

- Low level more technically oriented than DA
- Involved in physical design of database systems
- Has narrower DBMS specific scope
- On the data management side will be concerned with the issue of controlling the database
  - Centralised and shared databases
    - Distributed databases can force organisation to de-centralise data administration
    - DBA define and delegate responsibilities of each local DBA
    - Imposes more complex co-ordinating activities on system DBA

## Slide 11: DBA’s Responsibilities

- Coordinating, monitoring and allocating database administration resources
  - Selection of DBMS, Utilities and Hardware
  - End User Support
  - Enforcing Policies, Procedures and Standards
  - Data Security, Privacy and Integrity
  - Data Backup and Recovery
  - Data Distribution and Use
  - Design and Implementation of Databases and Applications
  - Authorisation Management

## Slide 12: Selection of DBMS, Utilities and Hardware

- Important technical responsibility, needs to consider:
  - DBMS model
  - DBMS storage capacity
  - Application development support
  - Security and integrity
  - Backup and recovery
  - Concurrency control
  - Performance
  - DBA tools
  - Data distribution
  - Portability and standards
  - Hardware
  - Vendor training and support
  - Available third-party tools
  - Cost

> Notes: Application development support (PHP, MYSQL)  Performance (access and SQL server)  Hardware (Server, terminals, network tools)

## Slide 13: End User Support

- User requirements gathering
- Conflict and problem resolution
- Finding solutions to information needs
- Ensuring quality and integrity of applications and data
- Building user confidence
- Managing training and support of DBMS users

> Notes: requirements gathering (conflicts inside the organization)  Finding solutions to information needs (reports)  Ensuring quality and integrity of applications and data (application developers should be involve)     - imbedded SQL statements in applications     - Applications build by different languages (Java, VB, C)  - Integrity by enforcing the integrity rules example the use of (triggers)

## Slide 14: Policies, Procedures and Standards

- Continuous enforcement of the policies procedures and standards
  - Policies
    - General statements of direction that support goals
  - Standards
    - More detailed and specific than policies and describe minimum requirements
  - Procedures
    - Written instructions that describe a series of steps to be followed

> Notes: DA will set Policies, Procedures and Standards DBA will enforce Policies, Procedures and Standards

## Slide 15: Data Security, Privacy and Integrity

- Of great concern to DBA’s
- With distributed data:
  - More difficult to maintain data control, security and integrity
- Must use the security and integrity mechanisms provided by the DBMS
- Must team up with internet security experts
  - To build firewalls, proxy services to safeguard from possible external attacks

> Notes: - One of the most important aspects in organizations  - Security, Privacy using authorization and authentication

## Slide 16: Data Backup and Recovery

- Periodic data and applications backups
  - Tools to ensure backup and recovery of the data
- Proper backup identification
  - Detailed descriptions and date information to ensure correct backups are used
- Convenient and safe backup storage
  - Multiple backups stored at different locations
- Physical protection of both hardware and software
  - Restricted access, fire protection, air conditioning
- Personal access control to the database software
  - Multilevel passwords and privileges

> Notes: Data backup (Server burn case scenario)  Database security can involve - Physical protection of both hardware and software Restricted access, fire protection, air conditioning - Personal access control to the database software Multilevel passwords and privileges

## Slide 17: Data Distribution and Use

- Data is only useful if it reaches the right users in a timely fashion in the right format
- Time consuming in typical applications programming environment
- Internet has opened databases to corporate users
  - Make use of more sophisticated query tools
  - Make use of Internet web front ends
  - Reduce dependency on application programmers
- DBA must enforce procedures and standards

> Notes: authorization and authentication

## Slide 18: Design and Implementation of Databases and Applications

- DBA provides data modelling and design services to the end-user community
- Implementation of the physical database
- Develop test and implement the operational procedures required by new system
  - Training, security and backup and recovery plans
  - Assigning responsibility for database control and maintenance
  - Authorise application of users to access database
  - Fine tuning and/or reconfiguration of DBMS

## Slide 19: Authorisation Management

- User Access Management
  - Define each user to the database
  - Assign passwords to each user
  - Define user groups
  - Assign access privileges
  - Physical access control
- View definition
  - Define data views to protect and control the scope of the data that are accessible to users
- DBMS utilities access control
  - Placing limits on the use of query and reporting tools
- DBMS usage monitoring
  - Audit the use of the data in the database.
  - Create an audit log

## Slide 20: Contrasting DA and DBA Activities and Characteristics

| DA | DBA |
|---|---|
| Strategic planning | Control and supervision |
| Sets long term goals | Executes plans to reach goals |
| Sets policies and standards | Enforces policies and procedures Enforces programming standards |
| Broad scope | Narrow scope |
| Long term | Short term focus on daily operations |
| Managerial Orientation | Technical orientation |
| DBMS independent | DBMS specific |

## Slide 21: Q & A
