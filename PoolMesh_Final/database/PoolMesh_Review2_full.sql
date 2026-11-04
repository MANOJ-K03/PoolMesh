-- PoolMesh DB - Review II : complete Oracle script
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- Run in SQL Developer / SQL*Plus as the schema owner (e.g. POOLMESH).
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


-- ==========================================================================
-- 3. DML - DATA POPULATION (loaded before triggers exist, so values are stored as given)
-- ==========================================================================

INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (1, 'Manoj Kumar S', 'manoj.kumar@vit.ac.in', '9840011101', 'M', 'BOTH', 'DL-TN23-2020-1001', 1250,
   96, 0, DATE '2026-06-12');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (2, 'Priya Sharma', 'priya.sharma@vit.ac.in', '9840011102', 'F', 'DRIVER', 'DL-TN23-2019-1002',
   2100, 100, 0, DATE '2026-06-15');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (3, 'Karthik Raman', 'karthik.raman@vit.ac.in', '9840011103', 'M', 'BOTH', 'DL-TN32-2021-1003',
   800, 88, 0, DATE '2026-06-20');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (4, 'Ananya Iyer', 'ananya.iyer@vit.ac.in', '9840011104', 'F', 'RIDER', NULL, 650, 92, 717,
   DATE '2026-07-02');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (5, 'S M Nithin', 'nithin.sm@vit.ac.in', '9840011105', 'M', 'DRIVER', 'DL-TN23-2018-1004', 1900,
   97, 0, DATE '2026-07-05');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (6, 'Divya Lakshmi', 'divya.lakshmi@vit.ac.in', '9840011106', 'F', 'BOTH', 'DL-TN04-2020-1005',
   1400, 100, 0, DATE '2026-07-09');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (7, 'Rahul Verma', 'rahul.verma@vit.ac.in', '9840011107', 'M', 'RIDER', NULL, 420, 58, 625,
   DATE '2026-07-14');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (8, 'Sneha Reddy', 'sneha.reddy@vit.ac.in', '9840011108', 'F', 'RIDER', NULL, 980, 85, 344,
   DATE '2026-07-21');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (9, 'Vikram Singh', 'vikram.singh@gmail.com', '9840011109', 'M', 'DRIVER', 'DL-KA05-2017-1006',
   2600, 42, 0, DATE '2026-07-25');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (10, 'Meera Nair', 'meera.nair@vit.ac.in', '9840011110', 'F', 'RIDER', NULL, 300, 79, 151,
   DATE '2026-08-01');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (11, 'Aditya Rao', 'aditya.rao@vit.ac.in', '9840011111', 'M', 'RIDER', NULL, 1150, 66, 264,
   DATE '2026-08-10');
INSERT INTO users
  (user_id, full_name, email, phone, gender, role, license_no, wallet_balance, trust_score,
   green_points, joined_on)
VALUES
  (12, 'Fathima Begum', 'fathima.begum@vit.ac.in', '9840011112', 'F', 'RIDER', NULL, 150, 91, 344,
   DATE '2026-08-18');


INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (1, 1, 'TN23AB1234', 'Maruti Swift', 'PETROL', 4, 120);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (2, 2, 'TN23CD5678', 'Hyundai i20', 'PETROL', 4, 118);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (3, 3, 'TN32EF9012', 'Honda City', 'DIESEL', 4, 135.5);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (4, 5, 'TN23GH3456', 'Tata Nexon EV', 'EV', 4, 0);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (5, 6, 'TN04JK7890', 'Maruti Ertiga CNG', 'CNG', 6, 96);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (6, 9, 'KA05LM2345', 'Toyota Innova', 'DIESEL', 6, 185);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (7, 1, 'TN23NP6789', 'Hyundai Creta', 'DIESEL', 4, 140);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (8, 2, 'TN23QR1122', 'Tata Tiago', 'PETROL', 4, 110);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (9, 3, 'TN32ST3344', 'Mahindra XUV300', 'PETROL', 4, 128);
INSERT INTO vehicles
  (vehicle_id, owner_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km)
VALUES
  (10, 5, 'TN23UV5566', 'Maruti Wagon R CNG', 'CNG', 4, 88);


INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (1, 'VIT Main Gate', 'Vellore', 'Y', 12.9692, 79.1559);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (2, 'Katpadi Junction', 'Vellore', 'Y', 12.9722, 79.1375);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (3, 'Chennai International Airport', 'Chennai', 'N', 12.9941, 80.1709);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (4, 'Chennai Central', 'Chennai', 'N', 13.0827, 80.2757);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (5, 'Koyambedu CMBT', 'Chennai', 'N', 13.0694, 80.1945);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (6, 'Bengaluru Majestic', 'Bengaluru', 'N', 12.9779, 77.5727);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (7, 'Electronic City', 'Bengaluru', 'N', 12.8456, 77.6603);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (8, 'VIT Ladies Hostel Gate', 'Vellore', 'Y', 12.9715, 79.1598);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (9, 'Tirupati Bus Stand', 'Tirupati', 'N', 13.6288, 79.4192);
INSERT INTO locations
  (location_id, loc_name, city, is_campus_hub, latitude, longitude)
VALUES
  (10, 'Kanchipuram Bus Stand', 'Kanchipuram', 'N', 12.8342, 79.7036);


INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (1, 2, 2, 1, 3, TIMESTAMP '2026-10-05 06:00:00', 135, 3, 1, 'WOMEN_ONLY', 'COMPLETED');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (2, 1, 1, 1, 6, TIMESTAMP '2026-10-06 05:30:00', 210, 2.8, 1, 'GENERAL', 'COMPLETED');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (3, 5, 4, 1, 2, TIMESTAMP '2026-10-07 17:00:00', 8, 5, 2, 'GENERAL', 'COMPLETED');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (4, 3, 3, 2, 3, TIMESTAMP '2026-10-08 07:00:00', 130, 3, 1, 'GENERAL', 'COMPLETED');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (5, 6, 5, 1, 4, TIMESTAMP '2026-10-09 06:30:00', 138, 2.5, 2, 'GENERAL', 'COMPLETED');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (6, 9, 6, 6, 1, TIMESTAMP '2026-10-11 15:00:00', 210, 2.6, 3, 'GENERAL', 'OPEN');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (7, 1, 7, 1, 3, TIMESTAMP '2026-10-14 06:00:00', 135, 3.2, 2, 'GENERAL', 'OPEN');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (8, 2, 8, 1, 2, TIMESTAMP '2026-10-13 18:00:00', 8, 4, 3, 'WOMEN_ONLY', 'OPEN');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (9, 3, 9, 1, 5, TIMESTAMP '2026-10-15 06:00:00', 130, 2.9, 2, 'GENERAL', 'OPEN');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (10, 5, 10, 2, 6, TIMESTAMP '2026-10-16 05:00:00', 215, 2.7, 0, 'GENERAL', 'FULL');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (11, 6, 5, 1, 9, TIMESTAMP '2026-10-17 07:30:00', 112, 3, 4, 'GENERAL', 'OPEN');
INSERT INTO rides
  (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km,
   seats_available, ride_type, status)
VALUES
  (12, 9, 6, 1, 7, TIMESTAMP '2026-10-18 06:00:00', 205, 2.4, 6, 'GENERAL', 'CANCELLED');


INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (1, 1, 4, 1, 405, 'COMPLETED', TO_DATE('2026-10-04 06:00','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (2, 1, 8, 1, 384.75, 'COMPLETED', TO_DATE('2026-10-03 02:53','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (3, 1, 12, 1, 364.5, 'COMPLETED', TO_DATE('2026-10-03 23:46','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (4, 2, 7, 1, 588, 'COMPLETED', TO_DATE('2026-10-04 03:09','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (5, 2, 11, 1, 558.6, 'COMPLETED', TO_DATE('2026-10-05 00:02','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (6, 2, 4, 1, 529.2, 'COMPLETED', TO_DATE('2026-10-04 03:55','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (7, 3, 7, 1, 40, 'COMPLETED', TO_DATE('2026-10-06 12:18','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (8, 3, 11, 1, 38, 'COMPLETED', TO_DATE('2026-10-05 16:11','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (9, 4, 4, 2, 741, 'COMPLETED', TO_DATE('2026-10-07 03:54','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (10, 4, 10, 1, 351, 'COMPLETED', TO_DATE('2026-10-06 00:47','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (11, 5, 8, 1, 345, 'COMPLETED', TO_DATE('2026-10-08 04:10','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (12, 5, 12, 1, 327.75, 'COMPLETED', TO_DATE('2026-10-07 01:03','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (13, 5, 7, 2, 586.5, 'COMPLETED', TO_DATE('2026-10-08 04:56','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (14, 6, 10, 1, 546, 'CONFIRMED', TO_DATE('2026-10-09 10:19','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (15, 6, 11, 1, 518.7, 'CONFIRMED', TO_DATE('2026-10-10 14:12','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (16, 6, 1, 1, 491.4, 'CONFIRMED', TO_DATE('2026-10-09 11:55','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (17, 7, 4, 1, 432, 'CONFIRMED', TO_DATE('2026-10-11 02:18','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (18, 7, 11, 1, 410.4, 'CANCELLED', TO_DATE('2026-10-12 03:41','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (19, 7, 7, 1, 410.4, 'CONFIRMED', TO_DATE('2026-10-10 04:04','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (20, 8, 10, 1, 32, 'CONFIRMED', TO_DATE('2026-10-11 16:27','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (21, 9, 8, 1, 377, 'CONFIRMED', TO_DATE('2026-10-12 03:50','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (22, 9, 11, 1, 358.15, 'CONFIRMED', TO_DATE('2026-10-11 16:43','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (23, 10, 4, 1, 580.5, 'CONFIRMED', TO_DATE('2026-10-11 06:26','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (24, 10, 7, 1, 551.48, 'CONFIRMED', TO_DATE('2026-10-10 19:19','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (25, 10, 10, 1, 522.45, 'CONFIRMED', TO_DATE('2026-10-10 08:12','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (26, 10, 11, 1, 493.43, 'CONFIRMED', TO_DATE('2026-10-09 21:05','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (27, 11, 12, 2, 638.4, 'CONFIRMED', TO_DATE('2026-10-12 07:58','YYYY-MM-DD HH24:MI'));
INSERT INTO bookings
  (booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status, booked_at)
VALUES
  (28, 12, 8, 1, 492, 'CANCELLED', TO_DATE('2026-10-11 20:51','YYYY-MM-DD HH24:MI'));


INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (1, 1, 405, 'UPI', 'PAID', TO_DATE('2026-10-04 06:00','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (2, 2, 384.75, 'WALLET', 'PAID', TO_DATE('2026-10-03 02:53','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (3, 3, 364.5, 'WALLET', 'PAID', TO_DATE('2026-10-03 23:46','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (4, 4, 588, 'UPI', 'PAID', TO_DATE('2026-10-04 03:09','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (5, 5, 558.6, 'CASH', 'PAID', TO_DATE('2026-10-05 00:02','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (6, 6, 529.2, 'WALLET', 'PAID', TO_DATE('2026-10-04 03:55','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (7, 7, 40, 'WALLET', 'PAID', TO_DATE('2026-10-06 12:18','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (8, 8, 38, 'UPI', 'PAID', TO_DATE('2026-10-05 16:11','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (9, 9, 741, 'UPI', 'PAID', TO_DATE('2026-10-07 03:54','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (10, 10, 351, 'WALLET', 'PAID', TO_DATE('2026-10-06 00:47','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (11, 11, 345, 'WALLET', 'PAID', TO_DATE('2026-10-08 04:10','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (12, 12, 327.75, 'UPI', 'PAID', TO_DATE('2026-10-07 01:03','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (13, 13, 586.5, 'CASH', 'PAID', TO_DATE('2026-10-08 04:56','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (14, 14, 546, 'WALLET', 'PAID', TO_DATE('2026-10-09 10:19','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (15, 15, 518.7, 'UPI', 'PAID', TO_DATE('2026-10-10 14:12','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (16, 16, 491.4, 'WALLET', 'PAID', TO_DATE('2026-10-09 11:55','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (17, 17, 432, 'WALLET', 'PAID', TO_DATE('2026-10-11 02:18','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (18, 18, 410.4, 'UPI', 'REFUNDED', TO_DATE('2026-10-12 03:41','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (19, 19, 410.4, 'UPI', 'PAID', TO_DATE('2026-10-10 04:04','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (20, 20, 32, 'WALLET', 'PAID', TO_DATE('2026-10-11 16:27','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (21, 21, 377, 'WALLET', 'PAID', TO_DATE('2026-10-12 03:50','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (22, 22, 358.15, 'UPI', 'PAID', TO_DATE('2026-10-11 16:43','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (23, 23, 580.5, 'UPI', 'PAID', TO_DATE('2026-10-11 06:26','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (24, 24, 551.48, 'WALLET', 'PAID', TO_DATE('2026-10-10 19:19','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (25, 25, 522.45, 'UPI', 'PAID', TO_DATE('2026-10-10 08:12','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (26, 26, 493.43, 'CASH', 'PAID', TO_DATE('2026-10-09 21:05','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (27, 27, 638.4, 'WALLET', 'PAID', TO_DATE('2026-10-12 07:58','YYYY-MM-DD HH24:MI'));
INSERT INTO payments
  (payment_id, booking_id, amount, pay_mode, pay_status, paid_at)
VALUES
  (28, 28, 492, 'UPI', 'REFUNDED', TO_DATE('2026-10-11 20:51','YYYY-MM-DD HH24:MI'));


INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (1, 1, 16.27, 163, TO_DATE('2026-10-05 09:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (2, 2, 16.27, 163, TO_DATE('2026-10-05 09:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (3, 3, 16.27, 163, TO_DATE('2026-10-05 09:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (4, 4, 25.2, 252, TO_DATE('2026-10-06 08:30','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (5, 5, 25.2, 252, TO_DATE('2026-10-06 08:30','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (6, 6, 25.2, 252, TO_DATE('2026-10-06 08:30','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (7, 7, 1.2, 12, TO_DATE('2026-10-07 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (8, 8, 1.2, 12, TO_DATE('2026-10-07 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (9, 9, 30.2, 302, TO_DATE('2026-10-08 10:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (10, 10, 15.1, 151, TO_DATE('2026-10-08 10:00','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (11, 11, 18.05, 181, TO_DATE('2026-10-09 09:30','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (12, 12, 18.05, 181, TO_DATE('2026-10-09 09:30','YYYY-MM-DD HH24:MI'));
INSERT INTO carbon_ledger
  (ledger_id, booking_id, co2_saved_kg, points_earned, logged_at)
VALUES
  (13, 13, 36.1, 361, TO_DATE('2026-10-09 09:30','YYYY-MM-DD HH24:MI'));


INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (1, 1, 4, 2, 5, 'Smooth ride, punctual pickup', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (2, 2, 8, 2, 5, 'Felt very safe on a women-only ride',
   TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (3, 3, 12, 2, 4, 'Good driving, AC was working', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (4, 4, 7, 1, 4, 'On time and polite', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (5, 5, 11, 1, 5, 'Comfortable car, fair fare', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (6, 6, 4, 1, 5, 'Great conversation, safe driving',
   TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (7, 7, 7, 5, 5, 'EV ride was quiet and smooth', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (8, 9, 4, 3, 4, 'Reached the airport early', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (9, 10, 10, 3, 3, 'Driver was 15 minutes late', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (10, 11, 8, 6, 5, 'Excellent CNG ride, very clean car',
   TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (11, 13, 7, 6, 4, 'Good value for money', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (12, 13, 6, 7, 3, 'Rider kept the group waiting', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));
INSERT INTO ratings
  (rating_id, booking_id, rater_id, ratee_id, stars, comments, rated_at)
VALUES
  (13, 4, 1, 7, 4, 'Co-rider was cooperative', TO_DATE('2026-10-10 20:00','YYYY-MM-DD HH24:MI'));


COMMIT;


-- ==========================================================================
-- 4. SQL QUERIES
-- ==========================================================================

-- Q1. Open rides leaving from a campus hub  [Ride search (FR4): multi-table JOIN with filtering and sorting]
SELECT r.ride_id, s.loc_name AS source, d.loc_name AS destination,
       TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs,
       r.seats_available AS seats, r.base_fare_per_km AS rate, u.full_name AS driver
FROM   rides r
JOIN   locations s ON s.location_id = r.source_id
JOIN   locations d ON d.location_id = r.dest_id
JOIN   users     u ON u.user_id     = r.driver_id
WHERE  s.is_campus_hub = 'Y' AND r.status = 'OPEN' AND r.seats_available > 0
ORDER  BY r.departure_time;


-- Q2. Women-only rides open for booking  [Safety feature: filter on ride_type with 3-table JOIN]
SELECT r.ride_id, s.loc_name AS source, d.loc_name AS destination,
       TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs,
       r.seats_available AS seats, u.full_name AS driver
FROM   rides r
JOIN   locations s ON s.location_id = r.source_id
JOIN   locations d ON d.location_id = r.dest_id
JOIN   users     u ON u.user_id     = r.driver_id
WHERE  r.ride_type = 'WOMEN_ONLY' AND r.status = 'OPEN';


-- Q3. Driver earnings report  [Aggregation: SUM, COUNT DISTINCT, GROUP BY on completed bookings]
SELECT u.full_name AS driver, COUNT(DISTINCT r.ride_id) AS rides_done,
       SUM(b.seats_booked) AS passengers, SUM(b.fare_amount) AS earnings
FROM   bookings b
JOIN   rides r ON r.ride_id = b.ride_id
JOIN   users u ON u.user_id = r.driver_id
WHERE  b.booking_status = 'COMPLETED'
GROUP  BY u.user_id, u.full_name
ORDER  BY earnings DESC;


-- Q4. Route demand analysis  [GROUP BY with HAVING: which routes attract the most seats]
SELECT s.loc_name AS source, d.loc_name AS destination,
       COUNT(*) AS bookings, SUM(b.seats_booked) AS seats_sold
FROM   bookings b
JOIN   rides r     ON r.ride_id = b.ride_id
JOIN   locations s ON s.location_id = r.source_id
JOIN   locations d ON d.location_id = r.dest_id
WHERE  b.booking_status <> 'CANCELLED'
GROUP  BY s.loc_name, d.loc_name
HAVING SUM(b.seats_booked) >= 3
ORDER  BY seats_sold DESC;


-- Q5. Top 5 eco-riders  [Carbon Ledger leaderboard: JOIN + SUM + FETCH FIRST]
SELECT u.full_name AS rider, COUNT(*) AS trips,
       SUM(cl.co2_saved_kg) AS co2_saved_kg, SUM(cl.points_earned) AS green_points
FROM   carbon_ledger cl
JOIN   bookings b ON b.booking_id = cl.booking_id
JOIN   users u    ON u.user_id    = b.rider_id
GROUP  BY u.user_id, u.full_name
ORDER  BY co2_saved_kg DESC
FETCH FIRST 5 ROWS ONLY;


-- Q6. Low-trust alert list  [Uses stored function fn_trust_level inside a query]
SELECT full_name, role, trust_score, fn_trust_level(trust_score) AS trust_level
FROM   users
WHERE  trust_score < 80
ORDER  BY trust_score;


-- Q7. Overall cancellation rate  [Conditional aggregation with CASE]
SELECT COUNT(*) AS total_bookings,
       SUM(CASE WHEN booking_status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(AVG(CASE WHEN booking_status = 'CANCELLED' THEN 100 ELSE 0 END), 2) AS cancel_rate_pct
FROM   bookings;


-- Q8. Riders booking more than the average  [Subquery in HAVING (nested aggregate)]
SELECT u.full_name AS rider, COUNT(*) AS bookings_made
FROM   bookings b
JOIN   users u ON u.user_id = b.rider_id
GROUP  BY u.user_id, u.full_name
HAVING COUNT(*) > (SELECT AVG(cnt)
                   FROM  (SELECT COUNT(*) AS cnt FROM bookings GROUP BY rider_id))
ORDER  BY bookings_made DESC, rider;


-- Q9. Rides using eco-fuel vehicles  [Subquery with IN: EV and CNG vehicles only]
SELECT r.ride_id, v.model, v.fuel_type, r.distance_km, r.status
FROM   rides r
JOIN   vehicles v ON v.vehicle_id = r.vehicle_id
WHERE  r.vehicle_id IN (SELECT vehicle_id FROM vehicles
                        WHERE  fuel_type IN ('EV','CNG'))
ORDER  BY r.ride_id;


-- Q10. Users who have never booked a seat  [Correlated NOT EXISTS (anti-join)]
SELECT u.user_id, u.full_name, u.role
FROM   users u
WHERE  NOT EXISTS (SELECT 1 FROM bookings b WHERE b.rider_id = u.user_id)
ORDER  BY u.user_id;


-- Q11. Seats sold per ride (including empty rides)  [LEFT JOIN with NVL so rides with zero sales still appear]
SELECT r.ride_id, s.loc_name || ' to ' || d.loc_name AS route,
       r.status, NVL(SUM(b.seats_booked), 0) AS seats_sold
FROM   rides r
JOIN   locations s ON s.location_id = r.source_id
JOIN   locations d ON d.location_id = r.dest_id
LEFT   JOIN bookings b ON b.ride_id = r.ride_id AND b.booking_status <> 'CANCELLED'
GROUP  BY r.ride_id, s.loc_name, d.loc_name, r.status
ORDER  BY r.ride_id;


-- Q12. Bookings priced above their ride's average  [Correlated subquery: early bookers pay the undiscounted fare]
SELECT b.booking_id, b.ride_id, u.full_name AS rider,
       ROUND(b.fare_amount / b.seats_booked, 2) AS per_seat_fare
FROM   bookings b
JOIN   users u ON u.user_id = b.rider_id
WHERE  b.booking_status <> 'CANCELLED'
AND    b.fare_amount / b.seats_booked >
       (SELECT AVG(b2.fare_amount / b2.seats_booked) FROM bookings b2
        WHERE  b2.ride_id = b.ride_id AND b2.booking_status <> 'CANCELLED')
ORDER  BY b.booking_id;


-- Q13. Vehicle occupancy per ride  [Arithmetic on joined columns; occupancy % of seat capacity]
SELECT r.ride_id, v.model, v.seat_capacity AS capacity,
       v.seat_capacity - r.seats_available AS seats_filled,
       ROUND((v.seat_capacity - r.seats_available) / v.seat_capacity * 100, 1) AS occupancy_pct
FROM   rides r
JOIN   vehicles v ON v.vehicle_id = r.vehicle_id
WHERE  r.status <> 'CANCELLED'
ORDER  BY occupancy_pct DESC, r.ride_id;


-- Q14. Payment mode and status summary  [Two-column GROUP BY over PAYMENTS]
SELECT pay_mode, pay_status, COUNT(*) AS payments, SUM(amount) AS total_amount
FROM   payments
GROUP  BY pay_mode, pay_status
ORDER  BY pay_mode, pay_status;


-- Q15. Average star rating per driver  [Joins RATINGS to the driver of the rated ride; AVG and HAVING]
SELECT u.full_name AS driver, COUNT(*) AS ratings, ROUND(AVG(rt.stars), 2) AS avg_stars
FROM   ratings rt
JOIN   bookings b ON b.booking_id = rt.booking_id
JOIN   rides r    ON r.ride_id = b.ride_id AND r.driver_id = rt.ratee_id
JOIN   users u    ON u.user_id = rt.ratee_id
GROUP  BY u.user_id, u.full_name
HAVING COUNT(*) >= 1
ORDER  BY avg_stars DESC, ratings DESC, driver;


-- Q16. Campus-hub route statistics  [Campus Hub Network feature: destinations served from hubs]
SELECT d.loc_name AS destination, COUNT(*) AS rides_offered,
       ROUND(AVG(r.distance_km), 1) AS avg_km,
       ROUND(AVG(r.base_fare_per_km), 2) AS avg_rate
FROM   rides r
JOIN   locations s ON s.location_id = r.source_id
JOIN   locations d ON d.location_id = r.dest_id
WHERE  s.is_campus_hub = 'Y' AND r.status <> 'CANCELLED'
GROUP  BY d.loc_name
ORDER  BY rides_offered DESC, destination;


-- Q17. CO2 saved by fuel type  [Four-table JOIN: ledger to vehicle; environmental impact report]
SELECT v.fuel_type, COUNT(*) AS bookings,
       SUM(cl.co2_saved_kg) AS co2_saved_kg, SUM(cl.points_earned) AS points
FROM   carbon_ledger cl
JOIN   bookings b ON b.booking_id = cl.booking_id
JOIN   rides r    ON r.ride_id    = b.ride_id
JOIN   vehicles v ON v.vehicle_id = r.vehicle_id
GROUP  BY v.fuel_type
ORDER  BY co2_saved_kg DESC;


-- Q18. Everyone travelling on ride 10  [Set operation: UNION of the driver and the riders]
SELECT 'DRIVER' AS role_in_ride, u.full_name
FROM   rides r JOIN users u ON u.user_id = r.driver_id
WHERE  r.ride_id = 10
UNION
SELECT 'RIDER', u.full_name
FROM   bookings b JOIN users u ON u.user_id = b.rider_id
WHERE  b.ride_id = 10 AND b.booking_status <> 'CANCELLED'
ORDER  BY 1, 2;


-- Q19. Women-only integrity audit  [Data-quality check: must return 0 violations]
SELECT COUNT(*) AS women_only_violations
FROM   bookings b
JOIN   rides r ON r.ride_id = b.ride_id
JOIN   users u ON u.user_id = b.rider_id
WHERE  r.ride_type = 'WOMEN_ONLY' AND u.gender <> 'F';


-- Q20. Driver revenue ranking  [Analytic function RANK() OVER over an aggregate]
SELECT u.full_name AS driver, SUM(b.fare_amount) AS booked_revenue,
       RANK() OVER (ORDER BY SUM(b.fare_amount) DESC) AS revenue_rank
FROM   bookings b
JOIN   rides r ON r.ride_id = b.ride_id
JOIN   users u ON u.user_id = r.driver_id
WHERE  b.booking_status <> 'CANCELLED'
GROUP  BY u.user_id, u.full_name
ORDER  BY revenue_rank;



-- ==========================================================================
-- 5. FUNCTIONS
-- ==========================================================================

CREATE OR REPLACE FUNCTION fn_calc_fare (
  p_ride_id IN NUMBER,
  p_seats   IN NUMBER
) RETURN NUMBER IS
  v_dist   rides.distance_km%TYPE;
  v_rate   rides.base_fare_per_km%TYPE;
  v_avail  rides.seats_available%TYPE;
  v_cap    vehicles.seat_capacity%TYPE;
  v_occ    NUMBER;          -- seats occupied once this booking is added
  v_disc   NUMBER;          -- pooling discount (0 to 0.15)
BEGIN
  SELECT r.distance_km, r.base_fare_per_km, r.seats_available, v.seat_capacity
    INTO v_dist, v_rate, v_avail, v_cap
    FROM rides r JOIN vehicles v ON v.vehicle_id = r.vehicle_id
   WHERE r.ride_id = p_ride_id;

  v_occ  := (v_cap - v_avail) + p_seats;
  v_disc := CASE WHEN v_occ >= 4 THEN 0.15
                 WHEN v_occ  = 3 THEN 0.10
                 WHEN v_occ  = 2 THEN 0.05
                 ELSE 0 END;

  RETURN ROUND(v_dist * v_rate * p_seats * (1 - v_disc), 2);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Ride ' || p_ride_id || ' not found');
END fn_calc_fare;
/

CREATE OR REPLACE FUNCTION fn_co2_saved (
  p_distance_km IN NUMBER,
  p_emission_g  IN NUMBER,     -- vehicle emission, g CO2 per km
  p_occupants   IN NUMBER      -- driver + all booked passengers
) RETURN NUMBER DETERMINISTIC IS
  c_solo_g CONSTANT NUMBER := 150;   -- average solo car, g CO2 per km
BEGIN
  -- every passenger would have driven alone; in the pool each person
  -- carries only (emission / occupants) of the car's emission
  RETURN GREATEST(0, ROUND(p_distance_km * (c_solo_g - p_emission_g / p_occupants) / 1000, 2));
END fn_co2_saved;
/

CREATE OR REPLACE FUNCTION fn_trust_level (
  p_score IN NUMBER
) RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
  RETURN CASE WHEN p_score >= 80 THEN 'Excellent'
              WHEN p_score >= 40 THEN 'Good'
              ELSE 'Watchlist' END;
END fn_trust_level;
/


-- ==========================================================================
-- 6. TRIGGERS
-- ==========================================================================

CREATE OR REPLACE TRIGGER trg_booking_seats
AFTER INSERT OR UPDATE OF booking_status ON bookings
FOR EACH ROW
BEGIN
  IF INSERTING AND :NEW.booking_status = 'CONFIRMED' THEN
    -- take the seats; the ride becomes FULL when none are left
    UPDATE rides
       SET seats_available = seats_available - :NEW.seats_booked,
           status = CASE WHEN seats_available - :NEW.seats_booked = 0
                         THEN 'FULL' ELSE status END
     WHERE ride_id = :NEW.ride_id;

  ELSIF UPDATING AND :OLD.booking_status = 'CONFIRMED'
                 AND :NEW.booking_status = 'CANCELLED' THEN
    -- give the seats back; a FULL ride re-opens
    UPDATE rides
       SET seats_available = seats_available + :OLD.seats_booked,
           status = CASE WHEN status = 'FULL' THEN 'OPEN' ELSE status END
     WHERE ride_id = :NEW.ride_id;
  END IF;
END trg_booking_seats;
/

CREATE OR REPLACE TRIGGER trg_women_only_check
BEFORE INSERT ON bookings
FOR EACH ROW
DECLARE
  v_type   rides.ride_type%TYPE;
  v_gender users.gender%TYPE;
BEGIN
  SELECT ride_type INTO v_type FROM rides WHERE ride_id = :NEW.ride_id;

  IF v_type = 'WOMEN_ONLY' THEN
    SELECT gender INTO v_gender FROM users WHERE user_id = :NEW.rider_id;
    IF NVL(v_gender, 'X') <> 'F' THEN
      RAISE_APPLICATION_ERROR(-20050,
        'Women-only ride: booking allowed only for female riders');
    END IF;
  END IF;
END trg_women_only_check;
/

CREATE OR REPLACE TRIGGER trg_rating_trust
AFTER INSERT ON ratings
FOR EACH ROW
BEGIN
  UPDATE users
     SET trust_score = LEAST(100, GREATEST(0, trust_score +
           CASE :NEW.stars WHEN 5 THEN  2
                           WHEN 4 THEN  1
                           WHEN 3 THEN  0
                           WHEN 2 THEN -3
                           ELSE        -5 END))
   WHERE user_id = :NEW.ratee_id;
END trg_rating_trust;
/


-- ==========================================================================
-- 7. PROCEDURES (sp_complete_ride contains the cursor)
-- ==========================================================================

CREATE OR REPLACE PROCEDURE sp_book_ride (
  p_ride_id       IN NUMBER,
  p_rider_id      IN NUMBER,
  p_seats         IN NUMBER,
  p_pay_mode      IN VARCHAR2,
  p_redeem_points IN NUMBER DEFAULT 0
) IS
  v_ride    rides%ROWTYPE;
  v_wallet  users.wallet_balance%TYPE;
  v_points  users.green_points%TYPE;
  v_fare    NUMBER;
  v_used    NUMBER := 0;
  v_bid     NUMBER;
BEGIN
  SELECT * INTO v_ride FROM rides WHERE ride_id = p_ride_id FOR UPDATE;

  IF v_ride.status <> 'OPEN' THEN
    RAISE_APPLICATION_ERROR(-20010, 'Ride is not open for booking');
  ELSIF v_ride.driver_id = p_rider_id THEN
    RAISE_APPLICATION_ERROR(-20011, 'A driver cannot book their own ride');
  ELSIF p_seats > v_ride.seats_available THEN
    RAISE_APPLICATION_ERROR(-20012, 'Only ' || v_ride.seats_available ||
                                    ' seat(s) available');
  ELSIF p_pay_mode NOT IN ('WALLET','UPI','CASH') THEN
    RAISE_APPLICATION_ERROR(-20016, 'Invalid payment mode');
  END IF;

  SELECT wallet_balance, green_points INTO v_wallet, v_points
    FROM users WHERE user_id = p_rider_id FOR UPDATE;

  v_fare := fn_calc_fare(p_ride_id, p_seats);          -- pooled fare

  IF p_redeem_points > 0 THEN                          -- Green Points: 1 pt = Rs 0.50, max 20%
    v_used := LEAST(p_redeem_points, v_points, FLOOR(v_fare * 0.20 / 0.5));
    v_fare := v_fare - v_used * 0.5;
  END IF;

  IF p_pay_mode = 'WALLET' AND v_wallet < v_fare THEN
    RAISE_APPLICATION_ERROR(-20013, 'Insufficient wallet balance');
  END IF;

  INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount)
  VALUES (seq_booking.NEXTVAL, p_ride_id, p_rider_id, p_seats, v_fare)
  RETURNING booking_id INTO v_bid;       -- triggers fire here

  INSERT INTO payments (payment_id, booking_id, amount, pay_mode)
  VALUES (seq_payment.NEXTVAL, v_bid, v_fare, p_pay_mode);

  IF p_pay_mode = 'WALLET' THEN
    UPDATE users SET wallet_balance = wallet_balance - v_fare
     WHERE user_id = p_rider_id;
  END IF;
  IF v_used > 0 THEN
    UPDATE users SET green_points = green_points - v_used
     WHERE user_id = p_rider_id;
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Booking ' || v_bid || ' confirmed. Fare = Rs ' || v_fare ||
                       ' (points used: ' || v_used || ')');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20014, 'Ride or rider not found');
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20015, 'Rider has already booked this ride');
END sp_book_ride;
/

CREATE OR REPLACE PROCEDURE sp_cancel_booking (
  p_booking_id IN NUMBER
) IS
  v_b      bookings%ROWTYPE;
  v_dep    rides.departure_time%TYPE;
  v_amt    NUMBER := 0;
  v_late   BOOLEAN;
BEGIN
  SELECT * INTO v_b FROM bookings WHERE booking_id = p_booking_id FOR UPDATE;
  IF v_b.booking_status <> 'CONFIRMED' THEN
    RAISE_APPLICATION_ERROR(-20020, 'Only a CONFIRMED booking can be cancelled');
  END IF;

  SELECT departure_time INTO v_dep FROM rides WHERE ride_id = v_b.ride_id;
  v_late := CAST(v_dep AS DATE) < SYSDATE + 2/24;      -- less than 2 hours to departure

  UPDATE bookings SET booking_status = 'CANCELLED'     -- trigger returns the seats
   WHERE booking_id = p_booking_id;

  UPDATE payments SET pay_status = 'REFUNDED'
   WHERE booking_id = p_booking_id AND pay_status = 'PAID'
  RETURNING amount INTO v_amt;

  UPDATE users SET wallet_balance = wallet_balance + v_amt   -- refund to wallet
   WHERE user_id = v_b.rider_id;

  IF v_late THEN                                       -- late-cancellation penalty
    UPDATE users SET trust_score = GREATEST(0, trust_score - 5)
     WHERE user_id = v_b.rider_id;
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Booking ' || p_booking_id || ' cancelled. Refund = Rs ' || v_amt ||
                       CASE WHEN v_late THEN ' | late cancellation: trust -5' ELSE '' END);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20021, 'Booking ' || p_booking_id || ' not found');
END sp_cancel_booking;
/

CREATE OR REPLACE PROCEDURE sp_complete_ride (
  p_ride_id IN NUMBER
) IS
  v_ride      rides%ROWTYPE;
  v_emission  vehicles.emission_g_per_km%TYPE;
  v_occupants NUMBER;
  v_co2       NUMBER;
  v_pts       NUMBER;
  v_credit    NUMBER := 0;
  v_count     NUMBER := 0;

  -- explicit parameterised cursor: all live bookings of one ride
  CURSOR c_pass (cp_ride NUMBER) IS
    SELECT b.booking_id, b.rider_id, b.seats_booked, b.fare_amount, p.pay_mode
      FROM bookings b JOIN payments p ON p.booking_id = b.booking_id
     WHERE b.ride_id = cp_ride AND b.booking_status = 'CONFIRMED'
     ORDER BY b.booking_id;
BEGIN
  SELECT * INTO v_ride FROM rides WHERE ride_id = p_ride_id FOR UPDATE;
  IF v_ride.status NOT IN ('OPEN','FULL') THEN
    RAISE_APPLICATION_ERROR(-20030, 'Ride is already ' || v_ride.status);
  END IF;

  SELECT emission_g_per_km INTO v_emission
    FROM vehicles WHERE vehicle_id = v_ride.vehicle_id;
  SELECT NVL(SUM(seats_booked), 0) + 1 INTO v_occupants      -- + the driver
    FROM bookings WHERE ride_id = p_ride_id AND booking_status = 'CONFIRMED';

  FOR rec IN c_pass(p_ride_id) LOOP
    v_co2 := fn_co2_saved(v_ride.distance_km, v_emission, v_occupants) * rec.seats_booked;
    v_pts := ROUND(v_co2 * 10);                              -- 10 Green Points per kg

    INSERT INTO carbon_ledger (ledger_id, booking_id, co2_saved_kg, points_earned)
    VALUES (seq_ledger.NEXTVAL, rec.booking_id, v_co2, v_pts);

    UPDATE users    SET green_points = green_points + v_pts WHERE user_id = rec.rider_id;
    UPDATE bookings SET booking_status = 'COMPLETED'        WHERE booking_id = rec.booking_id;

    IF rec.pay_mode <> 'CASH' THEN                           -- cash goes straight to driver
      v_credit := v_credit + rec.fare_amount;
    END IF;
    v_count := v_count + 1;
    DBMS_OUTPUT.PUT_LINE('Booking ' || rec.booking_id || ' | rider ' || rec.rider_id ||
                         ' | CO2 saved ' || v_co2 || ' kg | +' || v_pts || ' pts');
  END LOOP;

  UPDATE users SET wallet_balance = wallet_balance + v_credit WHERE user_id = v_ride.driver_id;
  UPDATE rides SET status = 'COMPLETED' WHERE ride_id = p_ride_id;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Ride ' || p_ride_id || ' completed: ' || v_count ||
                       ' booking(s), driver credited Rs ' || v_credit);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20031, 'Ride ' || p_ride_id || ' not found');
END sp_complete_ride;
/


-- ==========================================================================
-- 8. DML DEMONSTRATION: INSERT / UPDATE / DELETE
-- ==========================================================================

INSERT INTO rides (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time,
                   distance_km, base_fare_per_km, seats_available, ride_type)
VALUES (seq_ride.NEXTVAL, 1, 7, 8, 2, TIMESTAMP '2026-10-20 08:00:00', 6.5, 4.50, 4, 'GENERAL');
COMMIT;

UPDATE rides SET base_fare_per_km = 5.50 WHERE ride_id = 101;
COMMIT;

UPDATE users SET wallet_balance = wallet_balance + 500 WHERE user_id = 12;
COMMIT;

DELETE FROM rides WHERE ride_id = 101;
COMMIT;

DELETE FROM rides WHERE ride_id = 12;


-- ==========================================================================
-- 9. TRIGGER TESTS (rolled back)
-- ==========================================================================

-- Rahul (male) tries to book the women-only ride 8
INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount)
VALUES (901, 8, 7, 1, 32);

-- Ananya books all 4 free seats of ride 11 directly, then cancels
INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount)
VALUES (902, 11, 4, 4, 1142.40);
SELECT ride_id, seats_available, status FROM rides WHERE ride_id = 11;
UPDATE bookings SET booking_status = 'CANCELLED' WHERE booking_id = 902;
SELECT ride_id, seats_available, status FROM rides WHERE ride_id = 11;
ROLLBACK;                      -- leave the data untouched

-- Fathima gives driver Divya a 2-star rating for booking 12
INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments)
VALUES (903, 12, 12, 6, 2, 'Late pickup');
SELECT user_id, full_name, trust_score, fn_trust_level(trust_score) AS trust_level
FROM   users WHERE user_id = 6;
ROLLBACK;


-- ==========================================================================
-- 10. REAL-WORLD TRANSACTIONS
-- ==========================================================================

-- T0 validation (each call must fail with the shown error)
EXEC sp_book_ride(12, 4, 1, 'UPI');
EXEC sp_book_ride(7, 1, 1, 'UPI');
EXEC sp_book_ride(7, 4, 3, 'UPI');
EXEC sp_book_ride(11, 7, 4, 'WALLET');

-- T1
SET SERVEROUTPUT ON
EXEC sp_book_ride(9, 12, 2, 'WALLET', 20);

-- T2
EXEC sp_cancel_booking(21);

-- T3
UPDATE rides SET departure_time = SYSTIMESTAMP + INTERVAL '90' MINUTE WHERE ride_id = 8;
COMMIT;
EXEC sp_cancel_booking(20);

-- T4
EXEC sp_complete_ride(6);

-- T5
INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments)
VALUES (seq_rating.NEXTVAL, 14, 10, 9, 1, 'Rash driving on the ghat section');
INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments)
VALUES (seq_rating.NEXTVAL, 15, 11, 9, 2, 'Took phone calls while driving');
COMMIT;
