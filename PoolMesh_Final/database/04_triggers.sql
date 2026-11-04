-- PoolMesh DB - Triggers (create after data load)
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

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
  BEGIN
    SELECT ride_type
      INTO v_type
      FROM rides
     WHERE ride_id = :NEW.ride_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN;
  END;

  IF v_type = 'WOMEN_ONLY' THEN
    SELECT gender
      INTO v_gender
      FROM users
     WHERE user_id = :NEW.rider_id;

    IF NVL(v_gender, 'X') <> 'F' THEN
      RAISE_APPLICATION_ERROR(
        -20050,
        'Women-only ride: booking allowed only for female riders'
      );
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
