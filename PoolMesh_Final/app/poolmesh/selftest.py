"""Automated checks that mirror the Review II proof tests (constraints, triggers,
procedure validations). Run on freshly installed seed data."""
from . import ui
from .db import DBError, clean_error

CONSTRAINT_TESTS = [
    ("Duplicate e-mail", "INSERT INTO users (user_id, full_name, email, phone, gender) VALUES (50,'Test User','manoj.kumar@vit.ac.in','9000000001','M')", "UQ_USER_EMAIL"),
    ("Driver without licence", "INSERT INTO users (user_id, full_name, email, phone, gender, role) VALUES (51,'Test Driver','t1@x.com','9000000002','M','DRIVER')", "CK_USER_LICENSE"),
    ("Ride same source/destination", "INSERT INTO rides (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, distance_km, base_fare_per_km, seats_available) VALUES (50,1,1,2,2,TIMESTAMP '2026-10-30 08:00:00',10,3,3)", "CK_RIDE_ROUTE"),
    ("Trust score 120", "UPDATE users SET trust_score = 120 WHERE user_id = 4", "CK_USER_TRUST"),
    ("Booking for missing ride", "INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount) VALUES (50,999,4,1,100)", "FK_BOOK_RIDE"),
    ("Same rider books ride twice", "INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount) VALUES (51,7,4,1,100)", "UQ_BOOK_RIDE_RIDER"),
    ("User rates themselves", "INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars) VALUES (50,17,4,4,5)", "CK_RATE_SELF"),
    ("Rating of 6 stars", "INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars) VALUES (51,17,4,1,6)", "CK_RATE_STARS"),
]

PROC_TESTS = [
    ("Book a CANCELLED ride", (12, 4, 1, "UPI"), "ORA-20010"),
    ("Driver books own ride", (7, 1, 1, "UPI"), "ORA-20011"),
    ("Overbooking (3 seats, 2 free)", (7, 4, 3, "UPI"), "ORA-20012"),
    ("Wallet too low", (11, 7, 4, "WALLET"), "ORA-20013"),
]


def _expect_error(db, label, runner, needle, results):
    try:
        runner()
        results.append((label, False, "no error raised"))
    except Exception as exc:
        msg = clean_error(exc) if not isinstance(exc, DBError) else str(exc)
        results.append((label, needle in msg.upper(), msg.splitlines()[0]))
    finally:
        db.conn.rollback()


def run_all(db):
    results = []
    ui.section("1. Constraint enforcement (8 tests)")
    for label, sql, needle in CONSTRAINT_TESTS:
        _expect_error(db, label, lambda s=sql: db.execute(s, commit=False), needle, results)

    ui.section("2. Trigger tests (rolled back)")
    _expect_error(db, "trg_women_only_check blocks male rider",
                  lambda: db.execute("INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount) "
                                     "VALUES (901, 8, 7, 1, 32)", commit=False), "ORA-20050", results)
    try:
        db.execute("INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount) "
                   "VALUES (902, 11, 4, 4, 1142.40)", commit=False)
        a = db.query("SELECT seats_available, status FROM rides WHERE ride_id=11")[1][0]
        db.execute("UPDATE bookings SET booking_status='CANCELLED' WHERE booking_id=902", commit=False)
        b = db.query("SELECT seats_available, status FROM rides WHERE ride_id=11")[1][0]
        results.append(("trg_booking_seats: last seat -> FULL, cancel -> OPEN",
                        (a[0], a[1], b[0], b[1]) == (0, "FULL", 4, "OPEN"), f"{tuple(a)} then {tuple(b)}"))
    except Exception as exc:
        results.append(("trg_booking_seats", False, clean_error(exc)))
    finally:
        db.conn.rollback()
    try:
        db.execute("INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments) "
                   "VALUES (903, 12, 12, 6, 2, 'Late pickup')", commit=False)
        t = db.scalar("SELECT trust_score FROM users WHERE user_id=6")
        results.append(("trg_rating_trust: 2 stars lowers 100 -> 97", t == 97, f"trust_score = {t}"))
    except Exception as exc:
        results.append(("trg_rating_trust", False, clean_error(exc)))
    finally:
        db.conn.rollback()

    ui.section("3. Procedure validation (each call must be refused)")
    for label, args, needle in PROC_TESTS:
        _expect_error(db, label, lambda a=args: db.call("sp_book_ride", *a), needle, results)

    ui.section("4. Function checks")
    checks = [
        ("fn_calc_fare(9,1) = 339.30", "SELECT fn_calc_fare(9,1) FROM dual", 339.30),
        ("fn_calc_fare(9,2) = 640.90", "SELECT fn_calc_fare(9,2) FROM dual", 640.90),
        ("fn_co2_saved(135,118,4) = 16.27", "SELECT fn_co2_saved(135,118,4) FROM dual", 16.27),
    ]
    for label, sql, want in checks:
        got = db.scalar(sql)
        results.append((label, abs(float(got) - want) < 0.005, f"got {got}"))
    got = db.scalar("SELECT fn_trust_level(35) FROM dual")
    results.append(("fn_trust_level(35) = Watchlist", got == "Watchlist", str(got)))

    print()
    for label, passed, detail in results:
        (ui.ok if passed else ui.fail)(f"{label}  {ui.dim('-> ' + detail)}")
    n = sum(1 for _, p, _ in results if p)
    print()
    (ui.ok if n == len(results) else ui.fail)(f"{n}/{len(results)} checks passed")
    return n == len(results)
