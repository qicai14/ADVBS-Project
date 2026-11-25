# Proposed edits to Lim-owned files (not applied)

`design/erd.md`, logical design, STAY entity: add after `int category_id FK "requested category"`:
```
        int hotel_id FK "denormalised copy of RESERVATION.hotel_id (M1, W10 strategy)"
```
Add the relationship line `HOTEL ||--o{ STAY : "copied hotel_id"` next to the other HOTEL relationships.

`design/design-review.md`, table 1b row M1: change "so availability and 'confirmed reservations by hotel/category' filter stays by hotel without joining RESERVATION/ROOM" to "so the most-booked-category query (iv) and the occupancy query (vii) filter stays by hotel without joining RESERVATION". Queries i and v still join RESERVATION.
