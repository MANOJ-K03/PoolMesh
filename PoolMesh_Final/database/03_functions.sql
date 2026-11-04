-- PoolMesh DB - Stored functions
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

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
