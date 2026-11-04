-- PoolMesh DB - 20 SQL queries
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

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
