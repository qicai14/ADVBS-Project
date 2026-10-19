/* =====================================================================
   01_tables.sql  -  GSHG database: tables, keys and defaults
   Owner: M1 (shared base script; only Lim Qi Cai edits it)
   Source: design/erd.md (logical design). Run first; drops and
   rebuilds the whole GSHG database, so all data is lost.

   Member constraints (1c), denormalisation (1b), procedures and
   triggers are NOT here. Each member adds them in their own folder
   (M1_.. to M5_..) so each piece of work is traceable to its owner.
   ===================================================================== */

USE master;
GO

IF DB_ID(N'GSHG') IS NOT NULL
BEGIN
    ALTER DATABASE GSHG SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GSHG;
END
GO

CREATE DATABASE GSHG;
GO

USE GSHG;
GO

/* ---------- Hotels, rooms, categories, rates ---------- */

CREATE TABLE HOTEL (
    hotel_id          INT IDENTITY(1,1) NOT NULL,
    name              NVARCHAR(100)     NOT NULL,
    country           NVARCHAR(60)      NOT NULL,
    city              NVARCHAR(60)      NOT NULL,
    currency_code     CHAR(3)           NOT NULL,
    checkin_deadline  TIME(0)           NOT NULL,   -- guest not arrived by this time = no-show
    CONSTRAINT PK_HOTEL PRIMARY KEY (hotel_id)
);

CREATE TABLE ROOM_CATEGORY (
    category_id    INT IDENTITY(1,1) NOT NULL,
    category_name  NVARCHAR(30)      NOT NULL,
    CONSTRAINT PK_ROOM_CATEGORY PRIMARY KEY (category_id),
    CONSTRAINT UQ_ROOM_CATEGORY_name UNIQUE (category_name)
);

CREATE TABLE ROOM (
    room_id        INT IDENTITY(1,1) NOT NULL,
    hotel_id       INT               NOT NULL,
    category_id    INT               NOT NULL,
    room_no        NVARCHAR(10)      NOT NULL,
    max_occupancy  TINYINT           NOT NULL,
    is_accessible  BIT               NOT NULL CONSTRAINT DF_ROOM_is_accessible DEFAULT 0,
    CONSTRAINT PK_ROOM PRIMARY KEY (room_id),
    CONSTRAINT UQ_ROOM_hotel_room_no UNIQUE (hotel_id, room_no),
    CONSTRAINT FK_ROOM_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id),
    CONSTRAINT FK_ROOM_ROOM_CATEGORY FOREIGN KEY (category_id) REFERENCES ROOM_CATEGORY (category_id)
);

CREATE TABLE RATE_PLAN (
    rate_plan_id       INT IDENTITY(1,1) NOT NULL,
    plan_name          NVARCHAR(50)      NOT NULL,
    noshow_charge_pct  DECIMAL(5,2)      NOT NULL,   -- % of the booked room charge
    CONSTRAINT PK_RATE_PLAN PRIMARY KEY (rate_plan_id),
    CONSTRAINT UQ_RATE_PLAN_name UNIQUE (plan_name)
);

CREATE TABLE ROOM_RATE (
    rate_id         INT IDENTITY(1,1) NOT NULL,
    hotel_id        INT               NOT NULL,
    category_id     INT               NOT NULL,
    rate_plan_id    INT               NOT NULL,
    start_date      DATE              NOT NULL,
    end_date        DATE              NOT NULL,
    nightly_rate    DECIMAL(10,2)     NOT NULL,
    child_rate_pct  DECIMAL(5,2)      NOT NULL,
    CONSTRAINT PK_ROOM_RATE PRIMARY KEY (rate_id),
    CONSTRAINT FK_ROOM_RATE_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id),
    CONSTRAINT FK_ROOM_RATE_ROOM_CATEGORY FOREIGN KEY (category_id) REFERENCES ROOM_CATEGORY (category_id),
    CONSTRAINT FK_ROOM_RATE_RATE_PLAN FOREIGN KEY (rate_plan_id) REFERENCES RATE_PLAN (rate_plan_id)
);

/* ---------- Guests, reservations, stays ---------- */

CREATE TABLE GUEST (
    guest_id   INT IDENTITY(1,1) NOT NULL,
    full_name  NVARCHAR(100)     NOT NULL,
    dob        DATE              NOT NULL,
    email      NVARCHAR(254)     NULL,      -- occupants may be children
    phone      NVARCHAR(20)      NULL,
    CONSTRAINT PK_GUEST PRIMARY KEY (guest_id)
);

CREATE TABLE RESERVATION (
    reservation_id  INT IDENTITY(1,1) NOT NULL,
    hotel_id        INT               NOT NULL,
    booker_id       INT               NOT NULL,
    rate_plan_id    INT               NOT NULL,
    status          NVARCHAR(20)      NOT NULL CONSTRAINT DF_RESERVATION_status DEFAULT N'Pending',
    created_at      DATETIME2(0)      NOT NULL CONSTRAINT DF_RESERVATION_created_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_RESERVATION PRIMARY KEY (reservation_id),
    CONSTRAINT FK_RESERVATION_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id),
    CONSTRAINT FK_RESERVATION_GUEST FOREIGN KEY (booker_id) REFERENCES GUEST (guest_id),
    CONSTRAINT FK_RESERVATION_RATE_PLAN FOREIGN KEY (rate_plan_id) REFERENCES RATE_PLAN (rate_plan_id)
);

CREATE TABLE STAY (
    stay_id               INT IDENTITY(1,1) NOT NULL,
    reservation_id        INT               NOT NULL,
    room_id               INT               NULL,       -- null until a room is assigned
    category_id           INT               NOT NULL,   -- requested category
    scheduled_checkin     DATETIME2(0)      NOT NULL,
    scheduled_checkout    DATETIME2(0)      NOT NULL,
    actual_checkin        DATETIME2(0)      NULL,
    actual_checkout       DATETIME2(0)      NULL,
    accessible_requested  BIT               NOT NULL CONSTRAINT DF_STAY_accessible_requested DEFAULT 0,
    CONSTRAINT PK_STAY PRIMARY KEY (stay_id),
    CONSTRAINT FK_STAY_RESERVATION FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id),
    CONSTRAINT FK_STAY_ROOM FOREIGN KEY (room_id) REFERENCES ROOM (room_id),
    CONSTRAINT FK_STAY_ROOM_CATEGORY FOREIGN KEY (category_id) REFERENCES ROOM_CATEGORY (category_id)
);

CREATE TABLE STAY_NIGHT (
    stay_id       INT            NOT NULL,
    night_date    DATE           NOT NULL,
    rate_charged  DECIMAL(10,2)  NOT NULL,   -- rate at time of booking
    CONSTRAINT PK_STAY_NIGHT PRIMARY KEY (stay_id, night_date),
    CONSTRAINT FK_STAY_NIGHT_STAY FOREIGN KEY (stay_id) REFERENCES STAY (stay_id)
);

CREATE TABLE STAY_OCCUPANT (
    stay_id   INT NOT NULL,
    guest_id  INT NOT NULL,
    CONSTRAINT PK_STAY_OCCUPANT PRIMARY KEY (stay_id, guest_id),
    CONSTRAINT FK_STAY_OCCUPANT_STAY FOREIGN KEY (stay_id) REFERENCES STAY (stay_id),
    CONSTRAINT FK_STAY_OCCUPANT_GUEST FOREIGN KEY (guest_id) REFERENCES GUEST (guest_id)
);

/* ---------- Extra beds and baby cots ---------- */

CREATE TABLE EXTRA_ITEM (
    item_id       INT IDENTITY(1,1) NOT NULL,
    hotel_id      INT               NOT NULL,
    item_name     NVARCHAR(50)      NOT NULL,
    daily_charge  DECIMAL(10,2)     NOT NULL,
    total_stock   INT               NOT NULL,
    CONSTRAINT PK_EXTRA_ITEM PRIMARY KEY (item_id),
    CONSTRAINT FK_EXTRA_ITEM_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id)
);

CREATE TABLE STAY_EXTRA (
    stay_extra_id  INT IDENTITY(1,1) NOT NULL,
    stay_id        INT               NOT NULL,
    item_id        INT               NOT NULL,
    quantity       INT               NOT NULL,
    charge_amount  DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_STAY_EXTRA PRIMARY KEY (stay_extra_id),
    CONSTRAINT FK_STAY_EXTRA_STAY FOREIGN KEY (stay_id) REFERENCES STAY (stay_id),
    CONSTRAINT FK_STAY_EXTRA_EXTRA_ITEM FOREIGN KEY (item_id) REFERENCES EXTRA_ITEM (item_id)
);

/* ---------- Optional services ---------- */

CREATE TABLE SERVICE_TYPE (
    service_type_id  INT IDENTITY(1,1) NOT NULL,
    type_name        NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_SERVICE_TYPE PRIMARY KEY (service_type_id),
    CONSTRAINT UQ_SERVICE_TYPE_name UNIQUE (type_name)
);

CREATE TABLE SERVICE (
    service_id       INT IDENTITY(1,1) NOT NULL,
    hotel_id         INT               NOT NULL,
    service_type_id  INT               NOT NULL,
    service_name     NVARCHAR(100)     NOT NULL,
    charge_basis     NVARCHAR(20)      NOT NULL,   -- Per person, Per room, Per reservation
    unit_price       DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_SERVICE PRIMARY KEY (service_id),
    CONSTRAINT FK_SERVICE_HOTEL FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id),
    CONSTRAINT FK_SERVICE_SERVICE_TYPE FOREIGN KEY (service_type_id) REFERENCES SERVICE_TYPE (service_type_id)
);

CREATE TABLE RESERVATION_SERVICE (
    res_service_id  INT IDENTITY(1,1) NOT NULL,
    reservation_id  INT               NOT NULL,
    service_id      INT               NOT NULL,
    stay_id         INT               NULL,       -- room the service is charged to (per person / per room)
    service_date    DATE              NOT NULL,
    quantity        INT               NOT NULL,
    charge_amount   DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_RESERVATION_SERVICE PRIMARY KEY (res_service_id),
    CONSTRAINT FK_RESERVATION_SERVICE_RESERVATION FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id),
    CONSTRAINT FK_RESERVATION_SERVICE_SERVICE FOREIGN KEY (service_id) REFERENCES SERVICE (service_id),
    CONSTRAINT FK_RESERVATION_SERVICE_STAY FOREIGN KEY (stay_id) REFERENCES STAY (stay_id)
);

/* ---------- Changes, cancellations, no-shows ---------- */

CREATE TABLE RESERVATION_CHANGE (
    change_id         INT IDENTITY(1,1) NOT NULL,
    stay_id           INT               NOT NULL,
    old_category_id   INT               NOT NULL,
    new_category_id   INT               NOT NULL,
    old_checkin       DATETIME2(0)      NOT NULL,
    old_checkout      DATETIME2(0)      NOT NULL,
    new_checkin       DATETIME2(0)      NOT NULL,
    new_checkout      DATETIME2(0)      NOT NULL,
    price_difference  DECIMAL(10,2)     NOT NULL,   -- new price - old price (negative = cheaper)
    changed_at        DATETIME2(0)      NOT NULL CONSTRAINT DF_RESERVATION_CHANGE_changed_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_RESERVATION_CHANGE PRIMARY KEY (change_id),
    CONSTRAINT FK_RESERVATION_CHANGE_STAY FOREIGN KEY (stay_id) REFERENCES STAY (stay_id),
    CONSTRAINT FK_RESERVATION_CHANGE_ROOM_CATEGORY_old FOREIGN KEY (old_category_id) REFERENCES ROOM_CATEGORY (category_id),
    CONSTRAINT FK_RESERVATION_CHANGE_ROOM_CATEGORY_new FOREIGN KEY (new_category_id) REFERENCES ROOM_CATEGORY (category_id)
);

CREATE TABLE CANCELLATION (
    cancellation_id  INT IDENTITY(1,1) NOT NULL,
    reservation_id   INT               NOT NULL,
    cancelled_at     DATETIME2(0)      NOT NULL CONSTRAINT DF_CANCELLATION_cancelled_at DEFAULT SYSDATETIME(),
    charge_amount    DECIMAL(10,2)     NOT NULL CONSTRAINT DF_CANCELLATION_charge_amount DEFAULT 0,
    CONSTRAINT PK_CANCELLATION PRIMARY KEY (cancellation_id),
    CONSTRAINT UQ_CANCELLATION_reservation UNIQUE (reservation_id),
    CONSTRAINT FK_CANCELLATION_RESERVATION FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id)
);

CREATE TABLE NO_SHOW (
    noshow_id       INT IDENTITY(1,1) NOT NULL,
    reservation_id  INT               NOT NULL,
    recorded_at     DATETIME2(0)      NOT NULL CONSTRAINT DF_NO_SHOW_recorded_at DEFAULT SYSDATETIME(),
    charge_amount   DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_NO_SHOW PRIMARY KEY (noshow_id),
    CONSTRAINT UQ_NO_SHOW_reservation UNIQUE (reservation_id),
    CONSTRAINT FK_NO_SHOW_RESERVATION FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id)
);

/* ---------- Billing and payments ---------- */

CREATE TABLE BILL (
    bill_id         INT IDENTITY(1,1) NOT NULL,
    reservation_id  INT               NOT NULL,
    room_charge     DECIMAL(10,2)     NOT NULL,
    service_charge  DECIMAL(10,2)     NOT NULL,
    discount        DECIMAL(10,2)     NOT NULL CONSTRAINT DF_BILL_discount DEFAULT 0,
    extra_charge    DECIMAL(10,2)     NOT NULL,
    issued_at       DATETIME2(0)      NOT NULL CONSTRAINT DF_BILL_issued_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_BILL PRIMARY KEY (bill_id),
    CONSTRAINT UQ_BILL_reservation UNIQUE (reservation_id),
    CONSTRAINT FK_BILL_RESERVATION FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id)
);

CREATE TABLE PAYMENT (
    payment_id      INT IDENTITY(1,1) NOT NULL,
    reservation_id  INT               NOT NULL,
    amount          DECIMAL(10,2)     NOT NULL,   -- always positive; pay_type gives the direction
    method          NVARCHAR(30)      NOT NULL,
    pay_type        NVARCHAR(10)      NOT NULL,   -- Payment or Refund
    paid_at         DATETIME2(0)      NOT NULL CONSTRAINT DF_PAYMENT_paid_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_PAYMENT PRIMARY KEY (payment_id),
    CONSTRAINT FK_PAYMENT_RESERVATION FOREIGN KEY (reservation_id) REFERENCES RESERVATION (reservation_id)
);

/* ---------- Maintenance ---------- */

CREATE TABLE MAINTENANCE (
    maintenance_id     INT IDENTITY(1,1) NOT NULL,
    room_id            INT               NOT NULL,
    start_date         DATE              NOT NULL,
    expected_end_date  DATE              NOT NULL,
    actual_end_date    DATE              NULL,      -- null = still under maintenance
    reason             NVARCHAR(200)     NOT NULL,
    CONSTRAINT PK_MAINTENANCE PRIMARY KEY (maintenance_id),
    CONSTRAINT FK_MAINTENANCE_ROOM FOREIGN KEY (room_id) REFERENCES ROOM (room_id)
);
GO

-- Quick check: expect 21 tables.
SELECT COUNT(*) AS table_count FROM sys.tables;
GO
