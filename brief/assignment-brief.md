# Assignment brief (text extracted from `ADVBS_Assignment Question.docx`)

In this assignment you are required to:

Form yourselves into groups of 5 students.

Design, develop and implement a solution to a business problem.

Implement the solution in either MS SQL Server.

Document the solution as set out in the assignment requirements.

Submit individual personal reflection report about your work. Apart from your presentation and viva marks, personal reflection will be considered to measure the individual performance from both group and individual components. The personal reflection report should provide a comprehensive discussion of the system.  Students should be able to explain in detail the work that has been done and needs to fully discuss their roles and efforts in the project. Students should also highlight development of their own element of product which was then integrated by the team to compile a finished product.

Include a workload matrix, providing details on the distribution of work amongst group members.  The workload matrix has to be agreed and signed off by ALL group members.

Student required to submit softcopy of both your documentation and application.

Submission Date: 3rd January 2027

There will be a presentation session for each group to demonstrate their work. All group members must attend the demonstration.  Demonstration schedules will be shared later.


## Case Study: GLOBAL STAY HOTEL GROUP (GSHG)

Global Stay Hotel Group (GSHG) manages reservations for hotels in several countries. Its head office is in Kuala Lumpur, Malaysia. Each hotel has rooms in categories such as Standard, Deluxe, Family, and Suite. Room rates vary by hotel, room category, and stay date.

Guests can book one or more rooms under a single reservation. Each room has a maximum occupancy, and every person staying in a room must be recorded. At least one adult aged 18 or above must be assigned to each occupied room. A child under 12 may stay at a reduced rate, while an infant under 2 may stay without an additional room charge if no extra bed is required. Extra beds and baby cots are subject to availability and may incur a charge.

Hotels offer optional services, including airport transfers, breakfast packages, parking, and spa treatments. Some services are charged per person, some per room, and others per reservation. Accessible rooms can be requested but may only be assigned to guests when the room is available.

A reservation may be Pending, Confirmed, Checked In, Checked Out, or Cancelled. A room cannot be assigned to overlapping active stays. Guests may change their stay dates or room category, subject to availability and any price difference. A cancellation made less than 48 hours before the scheduled check-in time incurs a charge equal to the first night’s room rate. A guest who does not arrive by the hotel’s check-in deadline is recorded as a no-show and charged according to the reservation’s rate plan.

At check-out, the final bill includes room charges, optional services, applicable discounts, and any additional charges. Payments and refunds must be recorded so that the outstanding balance can be determined. Rooms taken out of service for maintenance cannot be assigned to reservations during the maintenance period.

Project scope: Design a database covering:

Hotels, rooms, room categories, and rates

Guest reservations and room assignments

Optional services

Cancellations, changes, and no-shows

Check-in, check-out, billing, and payments

Room maintenance


### Requirements:


### DESIGN

Develop an ERD to support GSHG’s activities. Show entities and relationships, followed by a logical design. Identify primary and foreign keys, cardinality, and optionality. The design must be in 3NF or higher unless denormalization is justified. Your model must support the business requirements above.

Document and justify your optimization strategy. Each of the five group members must produce one distinct optimization strategy. Explain the strategy. No SQL needed in this part.

Document the constraints in your system. Explain how they support the business rules and provide a functional description of the stored procedure and triggers. Each member must design one constraint, one stored procedure and one trigger.


### IMPLEMENTATION

- Implement your design and the optimization strategy.  You will be expected to demonstrate tables, referential integrity, appropriate test data, appropriate constraints and appropriate optimization techniques.  You will be expected to justify any mapping or denormalization issues.
- Implement the triggers and constraints for which you developed functional descriptions.  You must be able to explain and justify the constraints and triggers during the presentation. Triggers which function but which the group cannot explain will receive zero marks.  Some marks may be awarded for non-functioning constraints and triggers where the group can identify the issues.
- Each group member is required to create and use T-SQL feature (choose from: stored procedure; or function) to support a business requirement or enhance usability. One good quality example is sufficient, but you must be able to explain why and how you would use this feature and what benefits it offers compared to other possible implementation approaches. Features which function but which the group cannot explain will receive zero marks.  Some marks may be rewarded for features which are not fully functional, but where the group can explain the issues.
- Create the following queries – Groups must be able to explain the queries and justify the approach taken. Marks will be reduced where groups cannot explain how they have arrived at their solutions.

### Member 1 — Reservations and room availability

i. Show available rooms for a specified hotel, check-in date, check-out date, and room category. Exclude rooms with overlapping active reservations or maintenance periods.
ii. Show the reservation ID, guest name, room category, check-in date, and check-out date for all confirmed reservations at a specified hotel.
iii. Display every reservation with a textual description of its status.
iv. Identify the room category most frequently booked at a specified hotel during a given date range.
v. Show the number of confirmed reservations by hotel and room category, including subtotals for each hotel and an overall grand total. Use ROLLUP or CUBE.
vi. Find hotels with no confirmed reservations for a specified month.
vii. Develop one additional query that provides useful information about reservation demand.

### Member 2- Guests and room occupancy

viii. Show each guest’s ID, name, and total number of completed stays. Display the most frequent guests first.
ix. Show the names and ages of all guests assigned to a specified reservation and room.
x. Find room assignments where the number of occupants reaches the room’s maximum occupancy.
xi. List reservations that include at least one child and at least one adult.
xii. Show the number of adults, children, and infants staying at each hotel on a specified date. Include a breakdown by hotel and age category, hotel subtotals, and a grand total. Use ROLLUP or CUBE.
xiii. Show accessible rooms assigned to guests during a specified date range.
xiv. Develop one additional query that provides useful information about guests or occupancy.

### Member 3 -Room rates and optional services

xv. Show the regular nightly rate and the rate after a 10% promotional discount for Deluxe rooms at a specified hotel. Label the calculated columns clearly.
xvi. List the optional services selected for a specified reservation, including quantity, charging basis, and calculated charge.
xvii. Find optional services that have never been purchased.
xviii. Show the total value of breakfast packages sold by each hotel during a specified month.
xix. Show optional-service revenue by hotel and service type, including hotel subtotals and an overall grand total. Use ROLLUP or CUBE.
xx. Find the five reservations with the highest optional-service charges during a specified date range.
xxi. Develop one additional query that provides useful information about rates or services.

### Member 4 — Changes, cancellations, and no-shows

xxii. List reservations cancelled less than 48 hours before scheduled check-in, showing the applicable cancellation charge.
xxiii. Show the original and revised stay dates for reservations changed during a specified month.
xxiv. Find guests who have cancelled more than one reservation.
xxv. Show the number of no-shows recorded at each hotel during a specified date range, sorted from highest to lowest.
xxvi. Show cancellation counts by hotel and month for a specified year, including hotel subtotals and a grand total. Use ROLLUP or CUBE. (7 marks)
xxvii. Identify the hotel with the highest cancellation rate for a specified year. State clearly how the rate is calculated.
xxviii. Develop one additional query that provides useful information about reservation changes, cancellations, or no-shows.

### Member 5 — Billing, payments, and maintenance

xxix. Show the room charges, service charges, discounts, payments, and outstanding balance for a specified reservation.
xxx. List reservations that have been checked out but still have an outstanding balance.
xxxi. Show all rooms currently under maintenance, including the hotel name, room number, maintenance start date, and expected completion date.
xxxii. Find rooms with no completed stays during a specified date range.
xxxiii. Show total payments received by hotel and payment method during a specified month, including hotel subtotals and an overall grand total. Use ROLLUP or CUBE.
xxxiv. Identify the hotel with the highest revenue from completed stays in a specified quarter.
xxxv. Develop one additional query that provides useful information about billing, payments, or maintenance.

### Assessment Criteria


| CLO1 | Explain advanced database concepts related to database design and administration. (C2,PLO1) | Final Exam |
|---|---|---|
| CLO2 | Apply the concepts and techniques related to database such as: Transaction management, optimization strategies, database Security, and advanced database programming for a given scenario. (C3, PLO2) | Final Exam |
| CLO3 | Demonstrate the ability to create a database system using advanced database concepts for a given case study. (A3, PLO6) | Group Assignment |

| No | Component | Marks Allocated |
|---|---|---|
| 1 | Design  ER Model Constraints, stored procedure Triggers, optimisation Strategy | 30% |
| 2 | Implementation   Constraints Triggers Stored procedure Optimisation strategy SQL Queries | 50% |
| 3 | Project Presentation (system demo) | 20% |
