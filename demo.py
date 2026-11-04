"""Guided demonstration of the five Review II transactions (T1-T5).
Each step prints:  User operation -> SQL / PL-SQL -> DB processing -> BEFORE / AFTER -> Result."""
from . import ui, config
from .db import DBError

RIDE = "SELECT ride_id, status, seats_available FROM rides WHERE ride_id IN ({ids}) ORDER BY 1"
USERS = ("SELECT user_id, full_name, wallet_balance, trust_score, green_points FROM users "
         "WHERE user_id IN ({ids}) ORDER BY 1")

STEPS = [
    {
        "id": "T1", "title": "Fathima books 2 seats on ride 9 and redeems 20 Green Points",
        "operation": "Rider books seats (VIT Main Gate -> Koyambedu)",
        "sql": "EXEC sp_book_ride(9, 12, 2, 'WALLET', 20)",
        "processing": "fn_calc_fare gives a 15% pooled discount, points reduce the fare, "
                      "trg_women_only_check and trg_booking_seats fire, wallet is debited",
        "views": [("RIDES", RIDE.format(ids="9")), ("USERS", USERS.format(ids="12")),
                  ("BOOKINGS", "SELECT booking_id, ride_id, rider_id, seats_booked, fare_amount, booking_status FROM bookings WHERE ride_id = 9 AND rider_id = 12"),
                  ("PAYMENTS", "SELECT p.payment_id, p.booking_id, p.amount, p.pay_mode, p.pay_status FROM payments p JOIN bookings b ON b.booking_id=p.booking_id WHERE b.ride_id=9 AND b.rider_id=12")],
        "run": lambda db: db.call("sp_book_ride", 9, 12, 2, "WALLET", 20),
        "result": "Ride 9 becomes FULL, wallet Rs 650.00 -> Rs 19.10, points 344 -> 324",
    },
    {
        "id": "T2", "title": "Sneha cancels booking 21 (normal cancellation)",
        "operation": "Rider cancels a booking well before departure",
        "sql": "EXEC sp_cancel_booking(21)",
        "processing": "Status -> CANCELLED, trg_booking_seats returns the seat and re-opens the ride, "
                      "payment marked REFUNDED, amount credited to wallet",
        "views": [("RIDES", RIDE.format(ids="9")),
                  ("BOOKING + PAYMENT", "SELECT b.booking_id, b.booking_status, p.pay_status, p.amount FROM bookings b JOIN payments p ON p.booking_id=b.booking_id WHERE b.booking_id=21"),
                  ("USERS", USERS.format(ids="8"))],
        "run": lambda db: db.call("sp_cancel_booking", 21),
        "result": "Seat returned, Rs 377 refunded, ride 9 FULL -> OPEN",
    },
    {
        "id": "T3", "title": "Meera cancels booking 20 ninety minutes before departure (late cancellation)",
        "operation": "Rider cancels inside the 2-hour window",
        "sql": "UPDATE rides SET departure_time = SYSTIMESTAMP + INTERVAL '90' MINUTE WHERE ride_id = 8;\nEXEC sp_cancel_booking(20)",
        "processing": "Departure is within 2 hours -> late flag set -> refund + Trust Score penalty of 5",
        "views": [("BOOKING", "SELECT booking_id, booking_status FROM bookings WHERE booking_id=20"),
                  ("USERS", USERS.format(ids="10"))],
        "prepare": lambda db: db.execute("UPDATE rides SET departure_time = SYSTIMESTAMP + INTERVAL '90' MINUTE WHERE ride_id = 8"),
        "run": lambda db: db.call("sp_cancel_booking", 20),
        "result": "Rs 32 refunded, Meera's Trust Score 79 -> 74",
    },
    {
        "id": "T4", "title": "Vikram completes ride 6 (Bengaluru -> VIT) - the CURSOR transaction",
        "operation": "Driver closes the ride",
        "sql": "EXEC sp_complete_ride(6)",
        "processing": "Explicit cursor c_pass loops over 3 confirmed bookings: fn_co2_saved -> INSERT carbon_ledger "
                      "-> UPDATE users (points) -> UPDATE bookings (COMPLETED); driver credited once",
        "views": [("RIDES", RIDE.format(ids="6")),
                  ("BOOKINGS", "SELECT booking_id, rider_id, seats_booked, fare_amount, booking_status FROM bookings WHERE ride_id=6 ORDER BY 1"),
                  ("CARBON_LEDGER", "SELECT l.ledger_id, l.booking_id, l.co2_saved_kg, l.points_earned FROM carbon_ledger l JOIN bookings b ON b.booking_id=l.booking_id WHERE b.ride_id=6 ORDER BY 1"),
                  ("USERS", USERS.format(ids="1, 9, 10, 11"))],
        "run": lambda db: db.call("sp_complete_ride", 6),
        "result": "Ride COMPLETED, 3 ledger rows, 65.37 kg CO2 saved, driver wallet +Rs 1,556.10",
    },
    {
        "id": "T5", "title": "Meera and Aditya rate driver Vikram 1 and 2 stars",
        "operation": "Riders rate the driver",
        "sql": "INSERT INTO ratings (...) VALUES (seq_rating.NEXTVAL, 14, 10, 9, 1, ...);\nINSERT INTO ratings (...) VALUES (seq_rating.NEXTVAL, 15, 11, 9, 2, ...);",
        "processing": "trg_rating_trust fires per row: -5 then -3; fn_trust_level re-classifies the driver",
        "views": [("USERS", "SELECT user_id, full_name, trust_score, fn_trust_level(trust_score) AS trust_level FROM users WHERE user_id=9")],
        "run": lambda db: _rate(db),
        "result": "Vikram's Trust Score 42 (Good) -> 34 (Watchlist) - he now appears in the low-trust report",
    },
]


def _rate(db):
    db.execute("INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments) "
               "VALUES (seq_rating.NEXTVAL, 14, 10, 9, 1, 'Rash driving on the ghat section')", commit=False)
    db.execute("INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments) "
               "VALUES (seq_rating.NEXTVAL, 15, 11, 9, 2, 'Took phone calls while driving')", commit=False)
    db.conn.commit()
    return ["2 ratings inserted (trigger trg_rating_trust fired twice)"]


def reset_database(db):
    """Re-install schema, seed data, functions, triggers and procedures."""
    ui.section("Re-installing PoolMesh DB from database/*.sql")
    for name in ("01_schema", "02_data", "03_functions", "04_triggers", "05_procedures"):
        ok_n, errs = db.run_script(config.SQL_DIR / f"{name}.sql")
        (ui.ok if not errs else ui.fail)(f"{name}.sql  -> {ok_n} statements ok, {len(errs)} errors")
        for first, msg in errs:
            if "ORA-00942" in msg or "ORA-02289" in msg:
                continue  # DROP of objects that do not exist yet (first install)
            ui.fail(f"    {first}  ->  {msg}")
    counts = db.query("SELECT 'USERS', COUNT(*) FROM users UNION ALL SELECT 'RIDES', COUNT(*) FROM rides "
                      "UNION ALL SELECT 'BOOKINGS', COUNT(*) FROM bookings UNION ALL SELECT 'PAYMENTS', COUNT(*) FROM payments")[1]
    ui.info("Rows now: " + ", ".join(f"{t}={n}" for t, n in counts))


def show_views(db, views):
    for label, sql in views:
        print(ui.bold(f"   {label}"))
        cols, rows = db.query(sql)
        ui.table(cols, rows)


def run(db):
    ui.banner("GUIDED DEMO - five real-world transactions (T1-T5)")
    print("  The demo needs the original seed data. Re-install the database first?")
    if ui.confirm("Reset database to seed data now"):
        reset_database(db)
    for step in STEPS:
        ui.banner(f"{step['id']}  {step['title']}")
        print(f"  {ui.bold('USER OPERATION  ')} {step['operation']}")
        print(f"  {ui.bold('SQL / PL-SQL    ')} " + step["sql"].replace("\n", "\n" + " " * 19))
        print(f"  {ui.bold('DB PROCESSING   ')} {step['processing']}")
        ui.pause()
        print(ui.teal("\n  ---- BEFORE ----"))
        show_views(db, step["views"])
        if "prepare" in step:
            step["prepare"](db)
        try:
            lines = step["run"](db)
            print(ui.teal("\n  ---- OUTPUT ----"))
            for l in lines:
                ui.ok(l)
        except DBError as exc:
            ui.fail(str(exc))
            ui.info("(Has the demo been run before? Choose 'reset' to restore the seed data.)")
            ui.pause()
            return
        print(ui.teal("\n  ---- AFTER ----"))
        show_views(db, step["views"])
        ui.ok(f"RESULT: {step['result']}")
        ui.pause()
    ui.banner("Reports after the five transactions")
    from . import queries, actions
    qs = {q["no"]: q for q in queries.load()}
    for n in (6, 5):
        actions.run_query(db, qs[n], show_sql=False)
