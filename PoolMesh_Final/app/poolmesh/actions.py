"""One function per menu option. Business rules live in the database;
these functions only collect input and call SQL / PL-SQL."""
from datetime import datetime
from . import ui
from .db import DBError


# ---------------------------------------------------------------- users ----
def list_users(db):
    cols, rows = db.query(
        "SELECT user_id, full_name, role, gender, wallet_balance, trust_score, "
        "fn_trust_level(trust_score) AS trust_level, green_points FROM users ORDER BY user_id")
    ui.table(cols, rows)


def login(db):
    ui.section("Choose who you are logged in as")
    list_users(db)
    while True:
        uid = ui.ask_int("Enter user_id")
        cols, rows = db.query(
            "SELECT user_id, full_name, role, gender FROM users WHERE user_id = :u", {"u": uid})
        if rows:
            return dict(zip(("id", "name", "role", "gender"), rows[0]))
        ui.fail("No such user.")


def dashboard(db, user):
    ui.section(f"Dashboard - {user['name']}")
    cols, rows = db.query(
        "SELECT user_id, role, wallet_balance, trust_score, fn_trust_level(trust_score) AS trust_level, "
        "green_points, TO_CHAR(joined_on,'DD-Mon-YYYY') AS joined FROM users WHERE user_id = :u",
        {"u": user["id"]})
    ui.table(cols, rows)
    ui.section("My bookings (as rider)")
    cols, rows = db.query(
        "SELECT b.booking_id, b.ride_id, s.loc_name AS source, d.loc_name AS destination, "
        "TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs, b.seats_booked AS seats, "
        "b.fare_amount AS fare, b.booking_status AS status "
        "FROM bookings b JOIN rides r ON r.ride_id=b.ride_id "
        "JOIN locations s ON s.location_id=r.source_id JOIN locations d ON d.location_id=r.dest_id "
        "WHERE b.rider_id=:u ORDER BY r.departure_time", {"u": user["id"]})
    ui.table(cols, rows)
    ui.section("Rides I offer (as driver)")
    cols, rows = db.query(
        "SELECT r.ride_id, s.loc_name AS source, d.loc_name AS destination, "
        "TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs, r.seats_available AS seats_left, "
        "r.ride_type, r.status FROM rides r "
        "JOIN locations s ON s.location_id=r.source_id JOIN locations d ON d.location_id=r.dest_id "
        "WHERE r.driver_id=:u ORDER BY r.departure_time", {"u": user["id"]})
    ui.table(cols, rows)


def top_up(db, user):
    amt = ui.ask_float("Amount to add to wallet (Rs)", lo=0)
    before = db.scalar("SELECT wallet_balance FROM users WHERE user_id=:u", {"u": user["id"]})
    db.execute("UPDATE users SET wallet_balance = wallet_balance + :a WHERE user_id = :u",
               {"a": amt, "u": user["id"]})
    after = db.scalar("SELECT wallet_balance FROM users WHERE user_id=:u", {"u": user["id"]})
    ui.ok(f"Wallet: Rs {ui.fmt(before)}  ->  Rs {ui.fmt(after)}")


# ---------------------------------------------------------------- rides ----
SEARCH_SQL = """
SELECT r.ride_id, s.loc_name AS source, d.loc_name AS destination,
       TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs,
       r.seats_available AS seats, r.base_fare_per_km AS rate, r.ride_type,
       u.full_name AS driver, fn_calc_fare(r.ride_id, 1) AS fare_1_seat
FROM   rides r
JOIN   locations s ON s.location_id = r.source_id
JOIN   locations d ON d.location_id = r.dest_id
JOIN   users     u ON u.user_id     = r.driver_id
WHERE  r.status = 'OPEN' AND r.seats_available > 0
  AND  LOWER(s.loc_name) LIKE :src AND LOWER(d.loc_name) LIKE :dst
  AND  (r.ride_type = 'GENERAL' OR :gender = 'F')
ORDER  BY r.departure_time"""


def search_rides(db, user):
    ui.section("Search rides  (leave a field empty to match anything)")
    src = ui.ask("From (part of a place name, e.g. 'main gate')", "")
    dst = ui.ask("To   (e.g. 'airport')", "")
    cols, rows = db.query(SEARCH_SQL, {"src": f"%{src.lower()}%", "dst": f"%{dst.lower()}%",
                                       "gender": user["gender"] or "X"})
    ui.table(cols, rows)
    if user["gender"] != "F":
        ui.info("Women-only rides are hidden for this user (rule enforced again by trg_women_only_check).")


def book_ride(db, user):
    search_rides(db, user)
    ride = ui.ask_int("Ride id to book (0 to cancel)", lo=0)
    if ride == 0:
        return
    seats = ui.ask_int("Seats", 1, 4, default=1)
    mode = ui.ask("Payment mode WALLET / UPI / CASH", "WALLET").upper()
    pts_avail = db.scalar("SELECT green_points FROM users WHERE user_id=:u", {"u": user["id"]})
    pts = ui.ask_int(f"Green Points to redeem (you have {ui.fmt(pts_avail)}; 1 pt = Rs 0.50, max 20% of fare)",
                     lo=0, default=0)
    try:
        fare = db.scalar("SELECT fn_calc_fare(:r, :s) FROM dual", {"r": ride, "s": seats})
    except Exception as exc:  # fn_calc_fare raises -20001 if the ride does not exist
        ui.fail(str(exc).splitlines()[0])
        return
    ui.info(f"fn_calc_fare says the pooled fare is Rs {ui.fmt(fare)} (before points).")
    if not ui.confirm("Confirm booking?"):
        return
    try:
        for line in db.call("sp_book_ride", ride, user["id"], seats, mode, pts):
            ui.ok(line)
    except DBError as exc:
        ui.fail(str(exc))


def cancel_booking(db, user):
    ui.section("Your CONFIRMED bookings")
    cols, rows = db.query(
        "SELECT b.booking_id, b.ride_id, s.loc_name AS source, d.loc_name AS destination, "
        "TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs, b.seats_booked AS seats, b.fare_amount AS fare "
        "FROM bookings b JOIN rides r ON r.ride_id=b.ride_id "
        "JOIN locations s ON s.location_id=r.source_id JOIN locations d ON d.location_id=r.dest_id "
        "WHERE b.rider_id=:u AND b.booking_status='CONFIRMED' ORDER BY r.departure_time", {"u": user["id"]})
    ui.table(cols, rows)
    if not rows:
        return
    bid = ui.ask_int("Booking id to cancel (0 to go back)", lo=0)
    if bid == 0:
        return
    ui.info("Cancelling less than 2 hours before departure costs 5 Trust points.")
    if not ui.confirm("Really cancel?"):
        return
    try:
        for line in db.call("sp_cancel_booking", bid):
            ui.ok(line)
    except DBError as exc:
        ui.fail(str(exc))


def offer_ride(db, user):
    if user["role"] == "RIDER":
        ui.fail("Only DRIVER / BOTH users can offer rides (RIDER accounts have no licence).")
        return
    ui.section("Your vehicles")
    cols, rows = db.query(
        "SELECT vehicle_id, reg_no, model, fuel_type, seat_capacity FROM vehicles WHERE owner_id=:u",
        {"u": user["id"]})
    ui.table(cols, rows)
    if not rows:
        ui.fail("You have no vehicle registered.")
        return
    veh = ui.ask_int("Vehicle id", default=rows[0][0])
    cap = db.scalar("SELECT seat_capacity FROM vehicles WHERE vehicle_id=:v AND owner_id=:u",
                    {"v": veh, "u": user["id"]})
    if cap is None:
        ui.fail("That is not your vehicle.")
        return
    ui.section("Locations")
    cols, rows = db.query("SELECT location_id, loc_name, city, is_campus_hub AS hub FROM locations ORDER BY 1")
    ui.table(cols, rows)
    src = ui.ask_int("Source location id")
    dst = ui.ask_int("Destination location id")
    when = None
    while when is None:
        raw = ui.ask("Departure (YYYY-MM-DD HH:MM)", "2026-11-02 08:00")
        try:
            when = datetime.strptime(raw, "%Y-%m-%d %H:%M")
        except ValueError:
            ui.fail("Use the format 2026-11-02 08:00")
    km = ui.ask_float("Distance in km", lo=0)
    rate = ui.ask_float("Base fare per km (Rs)", lo=0, default=3)
    seats = ui.ask_int(f"Seats offered (vehicle capacity {ui.fmt(cap)})", 1, int(cap), default=int(cap))
    rtype = ui.ask("Ride type GENERAL / WOMEN_ONLY", "GENERAL").upper()
    sql = ("INSERT INTO rides (ride_id, driver_id, vehicle_id, source_id, dest_id, departure_time, "
           "distance_km, base_fare_per_km, seats_available, ride_type) "
           "VALUES (seq_ride.NEXTVAL, :d, :v, :s, :t, :w, :km, :rate, :seats, :rt) RETURNING ride_id INTO :rid")
    try:
        with db.conn.cursor() as cur:
            rid = cur.var(int)
            db._echo(sql, None)
            cur.execute(sql, {"d": user["id"], "v": veh, "s": src, "t": dst, "w": when, "km": km,
                              "rate": rate, "seats": seats, "rt": rtype, "rid": rid})
        db.conn.commit()
        ui.ok(f"Ride {rid.getvalue()[0]} published.")
    except Exception as exc:
        db.conn.rollback()
        from .db import clean_error
        ui.fail("Database refused the ride: " + clean_error(exc))


def complete_ride(db, user):
    ui.section("Your rides that can be completed")
    cols, rows = db.query(
        "SELECT r.ride_id, s.loc_name AS source, d.loc_name AS destination, "
        "TO_CHAR(r.departure_time,'DD-Mon HH24:MI') AS departs, r.status, "
        "(SELECT COUNT(*) FROM bookings b WHERE b.ride_id=r.ride_id AND b.booking_status='CONFIRMED') AS passengers "
        "FROM rides r JOIN locations s ON s.location_id=r.source_id JOIN locations d ON d.location_id=r.dest_id "
        "WHERE r.driver_id=:u AND r.status IN ('OPEN','FULL') ORDER BY r.departure_time", {"u": user["id"]})
    ui.table(cols, rows)
    if not rows:
        return
    rid = ui.ask_int("Ride id to complete (0 to go back)", lo=0)
    if rid == 0:
        return
    ui.info("The explicit cursor c_pass will visit every confirmed passenger one by one.")
    try:
        for line in db.call("sp_complete_ride", rid):
            ui.ok(line)
    except DBError as exc:
        ui.fail(str(exc))


def rate_user(db, user):
    sql = """
SELECT b.booking_id, 'rider -> driver' AS direction, r.driver_id AS ratee_id, u.full_name AS ratee
FROM   bookings b JOIN rides r ON r.ride_id = b.ride_id JOIN users u ON u.user_id = r.driver_id
WHERE  b.rider_id = :u AND b.booking_status = 'COMPLETED'
  AND  NOT EXISTS (SELECT 1 FROM ratings x WHERE x.booking_id = b.booking_id AND x.rater_id = :u)
UNION ALL
SELECT b.booking_id, 'driver -> rider', b.rider_id, u.full_name
FROM   bookings b JOIN rides r ON r.ride_id = b.ride_id JOIN users u ON u.user_id = b.rider_id
WHERE  r.driver_id = :u AND b.booking_status = 'COMPLETED'
  AND  NOT EXISTS (SELECT 1 FROM ratings x WHERE x.booking_id = b.booking_id AND x.rater_id = :u)
ORDER  BY 1"""
    ui.section("Completed trips you have not rated yet")
    cols, rows = db.query(sql, {"u": user["id"]})
    ui.table(cols, rows)
    if not rows:
        return
    bid = ui.ask_int("Booking id to rate (0 to go back)", lo=0)
    if bid == 0:
        return
    match = [r for r in rows if r[0] == bid]
    if not match:
        ui.fail("That booking is not in the list above.")
        return
    ratee = match[0][2]
    stars = ui.ask_int("Stars (1-5)", 1, 5)
    comment = ui.ask("Comment (optional)", "")[:200]
    before = db.scalar("SELECT trust_score FROM users WHERE user_id=:r", {"r": ratee})
    try:
        db.execute("INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments) "
                   "VALUES (seq_rating.NEXTVAL, :b, :rater, :ratee, :s, :c)",
                   {"b": bid, "rater": user["id"], "ratee": ratee, "s": stars, "c": comment or None})
    except Exception as exc:
        db.conn.rollback()
        from .db import clean_error
        ui.fail("Database refused the rating: " + clean_error(exc))
        return
    cols, rows = db.query("SELECT trust_score, fn_trust_level(trust_score) FROM users WHERE user_id=:r", {"r": ratee})
    ui.ok(f"Rating saved. trg_rating_trust updated {match[0][3]}'s Trust Score: "
          f"{ui.fmt(before)} -> {ui.fmt(rows[0][0])} ({rows[0][1]})")


# -------------------------------------------------------------- reports ----
def run_query(db, q, show_sql=True):
    ui.section(f"Q{q['no']}. {q['title']}")
    if q["desc"]:
        print(ui.dim(f"  {q['desc']}"))
    if show_sql:
        print(ui.dim("\n".join("    " + l for l in q["sql"].splitlines())) + "\n")
    cols, rows = db.query(q["sql"])
    ui.table(cols, rows)
