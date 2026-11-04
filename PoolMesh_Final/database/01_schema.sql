-- PoolMesh DB - Tables, constraints, sequences, indexes (clean-up + DDL)
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

-- ==========================================================================
-- 0. CLEAN-UP (optional, for re-runs)
-- ==========================================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE carbon_ledger CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE ratings CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE payments CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE bookings CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE rides CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE locations CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE vehicles CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE users CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_user'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_vehicle'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_location'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ride'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_booking'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_payment'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_rating'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ledger'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ==========================================================================
-- 1. DDL - TABLES, CONSTRAINTS
-- ==========================================================================

CREATE TABLE users (
  user_id         NUMBER         CONSTRAINT pk_users PRIMARY KEY,
  full_name       VARCHAR2(60)   NOT NULL,
  email           VARCHAR2(80)   NOT NULL,
  phone           VARCHAR2(15)   NOT NULL,
  gender          CHAR(1),
  role            VARCHAR2(10)   DEFAULT 'RIDER',
  license_no      VARCHAR2(20),
  wallet_balance  NUMBER(10,2)   DEFAULT 0,
  trust_score     NUMBER(3)      DEFAULT 100,
  green_points    NUMBER(8)      DEFAULT 0,
  joined_on       DATE           DEFAULT SYSDATE,
  CONSTRAINT uq_user_email   UNIQUE (email),
  CONSTRAINT uq_user_phone   UNIQUE (phone),
  CONSTRAINT uq_user_license UNIQUE (license_no),
  CONSTRAINT ck_user_gender  CHECK (gender IN ('M','F','O')),
  CONSTRAINT ck_user_role    CHECK (role IN ('RIDER','DRIVER','BOTH')),
  CONSTRAINT ck_user_license CHECK (role = 'RIDER' OR license_no IS NOT NULL),
  CONSTRAINT ck_user_wallet  CHECK (wallet_balance >= 0),
  CONSTRAINT ck_user_trust   CHECK (trust_score BETWEEN 0 AND 100),
  CONSTRAINT ck_user_points  CHECK (green_points >= 0)
);


CREATE TABLE vehicles (
  vehicle_id         NUMBER        CONSTRAINT pk_vehicles PRIMARY KEY,
  owner_id           NUMBER        NOT NULL,
  reg_no             VARCHAR2(15)  NOT NULL,
  model              VARCHAR2(40)  NOT NULL,
  fuel_type          VARCHAR2(10),
  seat_capacity      NUMBER(1),
  emission_g_per_km  NUMBER(5,1)   NOT NULL,
  CONSTRAINT fk_veh_owner  FOREIGN KEY (owner_id) REFERENCES users(user_id),
  CONSTRAINT uq_veh_reg    UNIQUE (reg_no),
  CONSTRAINT ck_veh_fuel   CHECK (fuel_type IN ('PETROL','DIESEL','CNG','EV')),
  CONSTRAINT ck_veh_seats  CHECK (seat_capacity BETWEEN 1 AND 6),
  CONSTRAINT ck_veh_emis   CHECK (emission_g_per_km >= 0)
);


CREATE TABLE locations (
  location_id    NUMBER        CONSTRAINT pk_locations PRIMARY KEY,
  loc_name       VARCHAR2(60)  NOT NULL,
  city           VARCHAR2(40)  NOT NULL,
  is_campus_hub  CHAR(1)       DEFAULT 'N',
  latitude       NUMBER(9,6),
  longitude      NUMBER(9,6),
  CONSTRAINT ck_loc_hub CHECK (is_campus_hub IN ('Y','N'))
);


CREATE TABLE rides (
  ride_id           NUMBER         CONSTRAINT pk_rides PRIMARY KEY,
  driver_id         NUMBER         NOT NULL,
  vehicle_id        NUMBER         NOT NULL,
  source_id         NUMBER         NOT NULL,
  dest_id           NUMBER         NOT NULL,
  departure_time    TIMESTAMP      NOT NULL,
  distance_km       NUMBER(6,1)    NOT NULL,
  base_fare_per_km  NUMBER(5,2)    NOT NULL,
  seats_available   NUMBER(1)      NOT NULL,
  ride_type         VARCHAR2(12)   DEFAULT 'GENERAL',
  status            VARCHAR2(10)   DEFAULT 'OPEN',
  CONSTRAINT fk_ride_driver  FOREIGN KEY (driver_id)  REFERENCES users(user_id),
  CONSTRAINT fk_ride_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
  CONSTRAINT fk_ride_source  FOREIGN KEY (source_id)  REFERENCES locations(location_id),
  CONSTRAINT fk_ride_dest    FOREIGN KEY (dest_id)    REFERENCES locations(location_id),
  CONSTRAINT ck_ride_route   CHECK (source_id <> dest_id),
  CONSTRAINT ck_ride_dist    CHECK (distance_km > 0),
  CONSTRAINT ck_ride_fare    CHECK (base_fare_per_km > 0),
  CONSTRAINT ck_ride_seats   CHECK (seats_available >= 0),
  CONSTRAINT ck_ride_type    CHECK (ride_type IN ('GENERAL','WOMEN_ONLY')),
  CONSTRAINT ck_ride_status  CHECK (status IN ('OPEN','FULL','COMPLETED','CANCELLED'))
);


CREATE TABLE bookings (
  booking_id      NUMBER         CONSTRAINT pk_bookings PRIMARY KEY,
  ride_id         NUMBER         NOT NULL,
  rider_id        NUMBER         NOT NULL,
  seats_booked    NUMBER(1)      NOT NULL,
  fare_amount     NUMBER(8,2)    NOT NULL,
  booking_status  VARCHAR2(10)   DEFAULT 'CONFIRMED',
  booked_at       DATE           DEFAULT SYSDATE,
  CONSTRAINT fk_book_ride    FOREIGN KEY (ride_id)  REFERENCES rides(ride_id),
  CONSTRAINT fk_book_rider   FOREIGN KEY (rider_id) REFERENCES users(user_id),
  CONSTRAINT uq_book_ride_rider UNIQUE (ride_id, rider_id),
  CONSTRAINT ck_book_seats   CHECK (seats_booked BETWEEN 1 AND 4),
  CONSTRAINT ck_book_fare    CHECK (fare_amount >= 0),
  CONSTRAINT ck_book_status  CHECK (booking_status IN ('CONFIRMED','CANCELLED','COMPLETED'))
);


CREATE TABLE payments (
  payment_id  NUMBER        CONSTRAINT pk_payments PRIMARY KEY,
  booking_id  NUMBER        NOT NULL,
  amount      NUMBER(8,2)   NOT NULL,
  pay_mode    VARCHAR2(8),
  pay_status  VARCHAR2(10)  DEFAULT 'PAID',
  paid_at     DATE          DEFAULT SYSDATE,
  CONSTRAINT fk_pay_booking  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  CONSTRAINT uq_pay_booking  UNIQUE (booking_id),
  CONSTRAINT ck_pay_amount   CHECK (amount > 0),
  CONSTRAINT ck_pay_mode     CHECK (pay_mode IN ('WALLET','UPI','CASH')),
  CONSTRAINT ck_pay_status   CHECK (pay_status IN ('PAID','REFUNDED','FAILED'))
);


CREATE TABLE ratings (
  rating_id   NUMBER         CONSTRAINT pk_ratings PRIMARY KEY,
  booking_id  NUMBER         NOT NULL,
  rater_id    NUMBER         NOT NULL,
  ratee_id    NUMBER         NOT NULL,
  stars       NUMBER(1)      NOT NULL,
  comments    VARCHAR2(200),
  rated_at    DATE           DEFAULT SYSDATE,
  CONSTRAINT fk_rate_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  CONSTRAINT fk_rate_rater   FOREIGN KEY (rater_id)   REFERENCES users(user_id),
  CONSTRAINT fk_rate_ratee   FOREIGN KEY (ratee_id)   REFERENCES users(user_id),
  CONSTRAINT uq_rate_once    UNIQUE (booking_id, rater_id),
  CONSTRAINT ck_rate_self    CHECK (rater_id <> ratee_id),
  CONSTRAINT ck_rate_stars   CHECK (stars BETWEEN 1 AND 5)
);


CREATE TABLE carbon_ledger (
  ledger_id      NUMBER        CONSTRAINT pk_ledger PRIMARY KEY,
  booking_id     NUMBER        NOT NULL,
  co2_saved_kg   NUMBER(8,2)   NOT NULL,
  points_earned  NUMBER(6)     DEFAULT 0,
  logged_at      DATE          DEFAULT SYSDATE,
  CONSTRAINT fk_led_booking  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  CONSTRAINT uq_led_booking  UNIQUE (booking_id),
  CONSTRAINT ck_led_co2      CHECK (co2_saved_kg >= 0),
  CONSTRAINT ck_led_points   CHECK (points_earned >= 0)
);

-- ==========================================================================
-- 2. SEQUENCES AND INDEXES
-- ==========================================================================

CREATE SEQUENCE seq_user     START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_vehicle  START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_location START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_ride     START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking  START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_payment  START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_rating   START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_ledger   START WITH 101 INCREMENT BY 1 NOCACHE;

CREATE INDEX idx_rides_search   ON rides (source_id, dest_id, departure_time);
CREATE INDEX idx_book_ride      ON bookings (ride_id);
CREATE INDEX idx_book_rider     ON bookings (rider_id);
CREATE INDEX idx_rate_ratee     ON ratings (ratee_id);
