# Design review and member allocation (Part 1: Design)

Reviewed 2026-10-19 against the brief and the lecture slides (W1 ERD, W6 triggers, W10 optimisation).
Revised diagram: [erd.md](erd.md).

> **Group size:** the brief is written for **5 members** (5 query sets, "each of the five members"
> for 1b/1c). We have 4. Ask the lecturer whether slot M5 (Billing, payments, maintenance) is
> dropped or shared before splitting work. The tables below keep 5 slots so nothing is lost.

## 1a. Does the excalidraw ERD support the business requirements?

Mostly yes: 21 entities, every scope item has a home, the 3NF structure is sound, and the M1–M5
queries can all be answered. Gaps, all fixed in `erd.md`:

| # | Gap | Why it matters | Fix |
|---|-----|----------------|-----|
| 1 | **Optionality not shown** (arrowheads are only bar / crow's foot, no circles) | Brief explicitly asks for cardinality *and* optionality | Mermaid `o` / `|` markers on every line |
| 2 | Only one diagram (attributes + keys together) | Brief asks for an ERD *followed by* a logical design | Split into conceptual ERD + logical design |
| 3 | No service type | M3 "revenue by service type", "breakfast packages sold" need a type shared across hotels | `SERVICE_TYPE` lookup + FK on `SERVICE` |
| 4 | `RESERVATION_SERVICE` has no room or date | Per-room services can't say which room; "sold during a month" has no date | Nullable `stay_id`, `service_date` |
| 5 | `RESERVATION_CHANGE` hangs off `RESERVATION` | Dates and category belong to each room (`STAY`); a 2-room booking can change one room | FK now `stay_id` |
| 6 | `MAINTENANCE.end_date` only | M5 "currently under maintenance … expected completion date" needs expected vs actual | `expected_end_date` + nullable `actual_end_date` |
| 7 | Types are `string`/`int` | Logical design should use SQL Server types | `nvarchar`, `datetime2`, `decimal`, `bit` … |
| 8 | `old_category` arrow drawn from `EXTRA_ITEM` | Drawing glitch | Fixed |

Points to **justify in the report** (deliberate, not errors):
- `STAY.category_id` duplicates `ROOM.category_id` once assigned. It records the *requested* category while `room_id` is still null (Pending) and supports upgrades.
- `BILL` stores totals that can be derived. Snapshot at check-out; good candidate for M5's denormalisation argument.
- `STAY_NIGHT.rate_charged`, `charge_amount` columns: historical price at booking time, not derivable later because rates change.
- Ages are never stored; derive Adult/Child/Infant from `GUEST.dob` against the stay date (keeps 3NF).

## 1b. Optimisation strategy: one distinct strategy per member

W10 teaches exactly five denormalisation strategies, one per member. Each is tied to that
member's query area so they can argue it from their own queries. No SQL needed in this part.

| Slot | Area | Strategy (W10) | What to denormalise and why |
|------|------|----------------|-----------------------------|
| M1 | Reservations & availability | **Duplicating FK attributes in 1:\*** | Copy `hotel_id` into `STAY` so availability and "confirmed reservations by hotel/category" filter stays by hotel without joining `RESERVATION`/`ROOM`. |
| M2 | Guests & occupancy | **Duplicating non-key attributes in 1:\*** | Store `age_category` (Adult/Child/Infant) on `STAY_OCCUPANT`, fixed at check-in, so the ROLLUP by age category and "at least one adult/child" queries skip the `GUEST` join and `DATEDIFF` per row. |
| M3 | Rates & services | **Lookup table** (W10 slides 13–14) | `SERVICE_TYPE` and charge-basis lookup; copy `unit_price` into `RESERVATION_SERVICE` so revenue sums don't join `SERVICE` and survive price changes. |
| M4 | Changes, cancellations, no-shows | **Combining 1:1 relationships** | Merge `CANCELLATION` and `NO_SHOW` (both optional 1:1 with `RESERVATION`) into `RESERVATION` columns, or argue why they stay separate (mostly-null columns). Speeds cancellation-rate and no-show counts. |
| M5 | Billing, payments, maintenance | **Partitioning relations** (horizontal) | Partition `PAYMENT` (and/or `STAY_NIGHT`) by year/quarter; monthly payment ROLLUP and quarterly revenue scan one partition. |

Spare if someone wants a different one: **Introducing repeating groups** (e.g. `phone1`, `phone2` on
`GUEST`, max 2 fixed), or **indexing** (composite non-clustered index on
`STAY(room_id, scheduled_checkin, scheduled_checkout)`; not in W10 but a standard strategy).

## 1c. Constraint, stored procedure and trigger per member

No two members touch the same business rule. Each needs a functional description (purpose,
inputs, table(s), what it checks/does, error raised).

| Slot | Constraint | Stored procedure | Trigger |
|------|-----------|------------------|---------|
| M1 | `CHECK (scheduled_checkout > scheduled_checkin)` on `STAY` | `usp_CreateReservation`: hotel, booker, rate plan, rooms/categories, dates → inserts `RESERVATION` + `STAY` + `STAY_NIGHT` rows in one transaction (status Pending) | `trg_Stay_NoOverlap` (AFTER INSERT, UPDATE on `STAY`): reject a room already in an active stay with overlapping dates, or a room from a different hotel than the reservation |
| M2 | `CHECK (dob <= GETDATE())` on `GUEST`; composite PK on `STAY_OCCUPANT` stops the same guest twice in a room | `usp_AddOccupant`: stay, guest → checks occupant count and returns age category | `trg_StayOccupant_Rules` (AFTER INSERT, DELETE on `STAY_OCCUPANT`): occupants ≤ `max_occupancy`; at least one adult (18+) per occupied room |
| M3 | `CHECK (charge_basis IN ('Per person','Per room','Per reservation'))` and `unit_price >= 0` on `SERVICE` | `usp_AddServiceToReservation`: reservation, service, qty, optional stay → computes `charge_amount` from charge basis (× occupants / × rooms / flat) | `trg_RoomRate_NoOverlap` (AFTER INSERT, UPDATE on `ROOM_RATE`): no two rate periods overlap for the same hotel + category + rate plan |
| M4 | `CHECK (status IN ('Pending','Confirmed','Checked In','Checked Out','Cancelled'))` on `RESERVATION` | `usp_CancelReservation`: reservation, cancel time → if < 48 h before check-in, charge = first night's `rate_charged`; inserts `CANCELLATION`, sets status | `trg_Stay_LogChange` (AFTER UPDATE on `STAY`): when dates or category change, write old/new values and price difference to `RESERVATION_CHANGE` (uses `inserted`/`deleted`) |
| M5 | `CHECK (amount > 0 AND pay_type IN ('Payment','Refund'))` on `PAYMENT`; `CHECK (expected_end_date >= start_date)` on `MAINTENANCE` | `usp_CheckOutAndBill`: reservation → sums room, service and extra charges minus discount, inserts `BILL`, sets Checked Out, returns outstanding balance (`OUTPUT` param) | `trg_Stay_BlockMaintenance` (AFTER INSERT, UPDATE on `STAY`): reject assigning a room during an open maintenance period |

Notes:
- M1 and M5 both put an AFTER trigger on `STAY`. SQL Server allows several; they enforce different rules.
- Implementation part 3 asks each member for one SP **or function**; the 1c SP can double as that.
  Function alternative for M2: `fn_AgeCategory(dob, on_date)`.
- W6: cross-table rules must be triggers (CHECK sees only its own row), which is why the overlap,
  occupancy and maintenance rules are triggers, not constraints.

## Open-ended choices (defaults until a member picks otherwise)

The brief asks for no special features. Its only open-ended items are each member's "one additional query" and the choice of SP or function.

| Slot | Additional query (default) | Why it's useful |
|------|----------------------------|-----------------|
| M1 | Occupancy rate by hotel and month for a year: room-nights sold ÷ room-nights available (rooms × days, minus maintenance days) | Core demand KPI; reuses the availability logic |
| M2 | Average occupants per stay by room category compared with `max_occupancy` | Shows whether categories are over- or under-sized |
| M3 | Service attach rate per hotel: % of reservations with at least one optional service | Shows which hotels upsell services |
| M4 | Average lead time (days between `created_at` and `cancelled_at`) and share of late (< 48 h) cancellations per hotel | Supports the 48-hour policy decision |
| M5 | Room-nights lost to maintenance per hotel in a period, with average maintenance duration | Ties maintenance to lost revenue |

Other defaults: `BILL.discount` is a parameter supplied at check-out (no promotions table; the 10% Deluxe promotion is a calculated column in M3's query). Each member's 1c stored procedure also serves as their implementation-section T-SQL feature.
