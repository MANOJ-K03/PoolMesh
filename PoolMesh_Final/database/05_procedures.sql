-- PoolMesh DB - Stored procedures incl. cursor
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

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
