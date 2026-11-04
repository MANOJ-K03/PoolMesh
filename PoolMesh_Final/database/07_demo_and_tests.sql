-- PoolMesh DB - DML demo, trigger tests, transactions T0-T5
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

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
