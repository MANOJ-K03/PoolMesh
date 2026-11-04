-- PoolMesh DB - Seed data (126 rows, loaded before triggers exist)
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

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
