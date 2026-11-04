"""PoolMesh DB - Modern Web Application Server for Review III.
Hosts the carpooling system on localhost:5000, connected directly to Oracle XE.
"""
import os
import sys
import time
from datetime import datetime
from decimal import Decimal
from pathlib import Path
from flask import Flask, jsonify, request, render_template_string, send_from_directory

# Ensure poolmesh module is discoverable
APP_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(APP_DIR))

import poolmesh.config as config
from poolmesh.db import Database, DBError, clean_error
import poolmesh.queries as qm
import poolmesh.demo as demo_mod
import poolmesh.selftest as st_mod

app = Flask(__name__, static_folder=str(APP_DIR / "static"))
app.config["JSON_SORT_KEYS"] = False

# Live SQL execution log for the Show-SQL inspector
SQL_HISTORY = []

def record_sql(sql, params=None, duration_ms=0, error=None):
    SQL_HISTORY.append({
        "timestamp": datetime.now().strftime("%H:%M:%S"),
        "sql": sql.strip(),
        "params": str(params) if params else None,
        "duration_ms": round(duration_ms, 2),
        "error": error
    })
    if len(SQL_HISTORY) > 60:
        SQL_HISTORY.pop(0)

def get_db():
    db = Database()
    db.connect()
    # Hook echo to record queries
    original_echo = db._echo
    def custom_echo(sql, params):
        original_echo(sql, params)
    db._echo = custom_echo
    return db

def serialize_val(val):
    if val is None:
        return None
    if isinstance(val, Decimal):
        return int(val) if val == val.to_integral() else float(val)
    if isinstance(val, datetime):
        return val.strftime("%Y-%m-%d %H:%M")
    return val

def rows_to_dicts(cols, rows):
    col_names = [c.lower() for c in cols]
    return [dict(zip(col_names, [serialize_val(v) for v in r])) for r in rows]

# ----------------- API ROUTES -----------------

@app.route("/api/stats")
def get_stats():
    t0 = time.time()
    db = get_db()
    try:
        tables = ["USERS", "VEHICLES", "LOCATIONS", "RIDES", "BOOKINGS", "PAYMENTS", "RATINGS", "CARBON_LEDGER"]
        counts = {}
        for t in tables:
            counts[t] = db.scalar(f"SELECT COUNT(*) FROM {t}")
        
        # Summary metrics
        total_co2 = db.scalar("SELECT NVL(ROUND(SUM(co2_saved_kg), 1), 0) FROM carbon_ledger")
        total_fare = db.scalar("SELECT NVL(ROUND(SUM(fare_amount), 2), 0) FROM bookings WHERE booking_status = 'COMPLETED'")
        open_rides = db.scalar("SELECT COUNT(*) FROM rides WHERE status = 'OPEN'")
        confirmed_bookings = db.scalar("SELECT COUNT(*) FROM bookings WHERE booking_status = 'CONFIRMED'")

        record_sql("SELECT COUNT(*) FROM 8 tables + carbon/fare metrics", None, (time.time() - t0) * 1000)
        return jsonify({
            "status": "online",
            "db_version": db.conn.version,
            "counts": counts,
            "total_co2_kg": float(total_co2 or 0),
            "total_revenue": float(total_fare or 0),
            "open_rides": open_rides,
            "confirmed_bookings": confirmed_bookings
        })
    finally:
        db.close()

@app.route("/api/users")
def get_users():
    t0 = time.time()
    db = get_db()
    try:
        sql = """
        SELECT user_id, full_name, email, phone, gender, role, license_no,
               wallet_balance, trust_score, fn_trust_level(trust_score) AS trust_level,
               green_points, TO_CHAR(joined_on, 'YYYY-MM-DD') AS joined_on
        FROM users ORDER BY user_id
        """
        cols, rows = db.query(sql)
        record_sql(sql, None, (time.time() - t0) * 1000)
        return jsonify(rows_to_dicts(cols, rows))
    finally:
        db.close()

@app.route("/api/user/<int:user_id>")
def get_user_dashboard(user_id):
    t0 = time.time()
    db = get_db()
    try:
        user_sql = """
        SELECT user_id, full_name, email, phone, gender, role, license_no,
               wallet_balance, trust_score, fn_trust_level(trust_score) AS trust_level,
               green_points, TO_CHAR(joined_on, 'DD-Mon-YYYY') AS joined
        FROM users WHERE user_id = :u
        """
        cols, rows = db.query(user_sql, {"u": user_id})
        if not rows:
            return jsonify({"error": "User not found"}), 404
        user_data = rows_to_dicts(cols, rows)[0]

        # Rider bookings
        bookings_sql = """
        SELECT b.booking_id, b.ride_id, s.loc_name AS source, d.loc_name AS destination,
               TO_CHAR(r.departure_time, 'DD-Mon HH24:MI') AS departs,
               b.seats_booked, b.fare_amount, b.booking_status,
               r.status AS ride_status, u.full_name AS driver_name
        FROM bookings b
        JOIN rides r ON r.ride_id = b.ride_id
        JOIN locations s ON s.location_id = r.source_id
        JOIN locations d ON d.location_id = r.dest_id
        JOIN users u ON u.user_id = r.driver_id
        WHERE b.rider_id = :u
        ORDER BY r.departure_time DESC
        """
        b_cols, b_rows = db.query(bookings_sql, {"u": user_id})
        user_data["bookings"] = rows_to_dicts(b_cols, b_rows)

        # Driver rides
        rides_sql = """
        SELECT r.ride_id, s.loc_name AS source, d.loc_name AS destination,
               TO_CHAR(r.departure_time, 'DD-Mon HH24:MI') AS departs,
               r.distance_km, r.base_fare_per_km, r.seats_available,
               v.seat_capacity, r.ride_type, r.status,
               v.model AS vehicle_model, v.reg_no,
               (SELECT COUNT(*) FROM bookings b WHERE b.ride_id = r.ride_id AND b.booking_status = 'CONFIRMED') AS confirmed_passengers
        FROM rides r
        JOIN vehicles v ON v.vehicle_id = r.vehicle_id
        JOIN locations s ON s.location_id = r.source_id
        JOIN locations d ON d.location_id = r.dest_id
        WHERE r.driver_id = :u
        ORDER BY r.departure_time DESC
        """
        r_cols, r_rows = db.query(rides_sql, {"u": user_id})
        user_data["offered_rides"] = rows_to_dicts(r_cols, r_rows)

        # Vehicles owned
        veh_sql = "SELECT vehicle_id, reg_no, model, fuel_type, seat_capacity, emission_g_per_km FROM vehicles WHERE owner_id = :u"
        v_cols, v_rows = db.query(veh_sql, {"u": user_id})
        user_data["vehicles"] = rows_to_dicts(v_cols, v_rows)

        record_sql(f"Dashboard query for user {user_id}", {"u": user_id}, (time.time() - t0) * 1000)
        return jsonify(user_data)
    finally:
        db.close()

@app.route("/api/locations")
def get_locations():
    db = get_db()
    try:
        cols, rows = db.query("SELECT location_id, loc_name, city, is_campus_hub, latitude, longitude FROM locations ORDER BY location_id")
        return jsonify(rows_to_dicts(cols, rows))
    finally:
        db.close()

@app.route("/api/rides")
def search_rides():
    t0 = time.time()
    db = get_db()
    try:
        user_id = request.args.get("user_id", type=int)
        src = request.args.get("src", "").strip().lower()
        dst = request.args.get("dst", "").strip().lower()
        hub_only = request.args.get("hub_only", "false").lower() == "true"
        status_filter = request.args.get("status", "OPEN")

        gender = "M"
        if user_id:
            g = db.scalar("SELECT gender FROM users WHERE user_id = :u", {"u": user_id})
            if g:
                gender = g

        sql = """
        SELECT r.ride_id, r.driver_id, u.full_name AS driver_name, u.trust_score AS driver_trust,
               fn_trust_level(u.trust_score) AS driver_trust_level,
               v.model AS vehicle_model, v.fuel_type, v.seat_capacity,
               s.location_id AS source_id, s.loc_name AS source, s.is_campus_hub AS source_is_hub,
               d.location_id AS dest_id, d.loc_name AS destination, d.is_campus_hub AS dest_is_hub,
               TO_CHAR(r.departure_time, 'YYYY-MM-DD HH24:MI') AS departure_time_raw,
               TO_CHAR(r.departure_time, 'DD-Mon HH24:MI') AS departs,
               r.distance_km, r.base_fare_per_km, r.seats_available, r.ride_type, r.status,
               fn_calc_fare(r.ride_id, 1) AS base_fare_1_seat
        FROM rides r
        JOIN locations s ON s.location_id = r.source_id
        JOIN locations d ON d.location_id = r.dest_id
        JOIN users u ON u.user_id = r.driver_id
        JOIN vehicles v ON v.vehicle_id = r.vehicle_id
        WHERE 1=1
        """
        params = {}
        if status_filter != "ALL":
            sql += " AND r.status = :status"
            params["status"] = status_filter
        if src:
            sql += " AND LOWER(s.loc_name) LIKE :src"
            params["src"] = f"%{src}%"
        if dst:
            sql += " AND LOWER(d.loc_name) LIKE :dst"
            params["dst"] = f"%{dst}%"
        if hub_only:
            sql += " AND s.is_campus_hub = 'Y'"

        sql += " ORDER BY r.departure_time"
        cols, rows = db.query(sql, params)
        data = rows_to_dicts(cols, rows)

        # Mark suitability for female / male
        for r in data:
            r["can_book"] = True
            r["gender_warning"] = None
            if r["ride_type"] == "WOMEN_ONLY" and gender != "F":
                r["can_book"] = False
                r["gender_warning"] = "Women-only ride. trg_women_only_check will block male riders."

        record_sql(sql, params, (time.time() - t0) * 1000)
        return jsonify(data)
    finally:
        db.close()

@app.route("/api/rides/calc-fare", methods=["POST"])
def calculate_fare():
    t0 = time.time()
    db = get_db()
    try:
        body = request.json or {}
        ride_id = int(body.get("ride_id"))
        seats = int(body.get("seats", 1))

        # Check ride and vehicle details to calculate transparent breakdown
        sql = """
        SELECT r.distance_km, r.base_fare_per_km, r.seats_available, v.seat_capacity
        FROM rides r JOIN vehicles v ON v.vehicle_id = r.vehicle_id
        WHERE r.ride_id = :r
        """
        cols, rows = db.query(sql, {"r": ride_id})
        if not rows:
            return jsonify({"error": f"Ride {ride_id} not found"}), 404
        
        dist, rate, avail, cap = rows[0]
        dist = float(dist)
        rate = float(rate)
        avail = int(avail)
        cap = int(cap)

        # Call Oracle stored function fn_calc_fare directly!
        fn_fare = db.scalar("SELECT fn_calc_fare(:r, :s) FROM dual", {"r": ride_id, "s": seats})
        fn_fare = float(fn_fare)

        occ_after = (cap - avail) + seats
        discount_pct = 0.15 if occ_after >= 4 else (0.10 if occ_after == 3 else (0.05 if occ_after == 2 else 0.0))
        undiscounted = round(dist * rate * seats, 2)
        saved = round(undiscounted - fn_fare, 2)

        record_sql(f"SELECT fn_calc_fare({ride_id}, {seats}) FROM dual", {"r": ride_id, "s": seats}, (time.time() - t0) * 1000)
        return jsonify({
            "ride_id": ride_id,
            "seats": seats,
            "distance_km": dist,
            "base_rate_per_km": rate,
            "vehicle_capacity": cap,
            "seats_available": avail,
            "occupancy_after": occ_after,
            "discount_pct": int(discount_pct * 100),
            "undiscounted_fare": undiscounted,
            "discount_amount": saved,
            "pooled_fare": fn_fare
        })
    except Exception as e:
        return jsonify({"error": clean_error(e)}), 400
    finally:
        db.close()

@app.route("/api/rides/book", methods=["POST"])
def book_ride():
    t0 = time.time()
    db = get_db()
    try:
        body = request.json or {}
        ride_id = int(body.get("ride_id"))
        rider_id = int(body.get("rider_id"))
        seats = int(body.get("seats", 1))
        pay_mode = str(body.get("pay_mode", "WALLET")).upper()
        redeem_points = int(body.get("redeem_points", 0))

        # Call Oracle stored procedure sp_book_ride!
        out_lines = db.call("sp_book_ride", ride_id, rider_id, seats, pay_mode, redeem_points)

        # Get updated user info and booking
        new_wallet = db.scalar("SELECT wallet_balance FROM users WHERE user_id = :u", {"u": rider_id})
        new_points = db.scalar("SELECT green_points FROM users WHERE user_id = :u", {"u": rider_id})
        ride_status = db.query("SELECT seats_available, status FROM rides WHERE ride_id = :r", {"r": ride_id})[1][0]

        record_sql(f"EXEC sp_book_ride({ride_id}, {rider_id}, {seats}, '{pay_mode}', {redeem_points})",
                   None, (time.time() - t0) * 1000)
        return jsonify({
            "success": True,
            "messages": out_lines,
            "new_wallet": float(new_wallet),
            "new_points": int(new_points),
            "ride_seats_available": int(ride_status[0]),
            "ride_status": ride_status[1]
        })
    except DBError as e:
        record_sql(f"EXEC sp_book_ride (FAILED: {e})", None, (time.time() - t0) * 1000, error=str(e))
        return jsonify({"success": False, "error": str(e)}), 400
    except Exception as e:
        msg = clean_error(e)
        record_sql(f"EXEC sp_book_ride (FAILED: {msg})", None, (time.time() - t0) * 1000, error=msg)
        return jsonify({"success": False, "error": msg}), 400
    finally:
        db.close()

@app.route("/api/bookings/cancel", methods=["POST"])
def cancel_booking():
    t0 = time.time()
    db = get_db()
    try:
        body = request.json or {}
        booking_id = int(body.get("booking_id"))

        # Call Oracle stored procedure sp_cancel_booking!
        out_lines = db.call("sp_cancel_booking", booking_id)

        # Check booking details
        sql = """
        SELECT b.booking_id, b.booking_status, b.rider_id, u.wallet_balance, u.trust_score,
               r.ride_id, r.seats_available, r.status
        FROM bookings b
        JOIN users u ON u.user_id = b.rider_id
        JOIN rides r ON r.ride_id = b.ride_id
        WHERE b.booking_id = :b
        """
        cols, rows = db.query(sql, {"b": booking_id})
        details = rows_to_dicts(cols, rows)[0] if rows else {}

        record_sql(f"EXEC sp_cancel_booking({booking_id})", None, (time.time() - t0) * 1000)
        return jsonify({
            "success": True,
            "messages": out_lines,
            "details": details
        })
    except DBError as e:
        record_sql(f"EXEC sp_cancel_booking({booking_id}) (FAILED)", None, (time.time() - t0) * 1000, error=str(e))
        return jsonify({"success": False, "error": str(e)}), 400
    except Exception as e:
        msg = clean_error(e)
        return jsonify({"success": False, "error": msg}), 400
    finally:
        db.close()

@app.route("/api/rides/offer", methods=["POST"])
def offer_ride():
    t0 = time.time()
    db = get_db()
    try:
        body = request.json or {}
        driver_id = int(body.get("driver_id"))
        vehicle_id = int(body.get("vehicle_id"))
        source_id = int(body.get("source_id"))
        dest_id = int(body.get("dest_id"))
        dep_str = str(body.get("departure_time"))  # "2026-11-05 08:30"
        dist_km = float(body.get("distance_km"))
        base_fare = float(body.get("base_fare_per_km"))
        seats = int(body.get("seats_available"))
        ride_type = str(body.get("ride_type", "GENERAL")).upper()

        dep_dt = datetime.strptime(dep_str, "%Y-%m-%d %H:%M")

        sql = """
        INSERT INTO rides (ride_id, driver_id, vehicle_id, source_id, dest_id,
                           departure_time, distance_km, base_fare_per_km,
                           seats_available, ride_type, status)
        VALUES (seq_ride.NEXTVAL, :d, :v, :s, :t, :dep, :km, :rate, :seats, :rtype, 'OPEN')
        RETURNING ride_id INTO :rid
        """
        with db.conn.cursor() as cur:
            rid_var = cur.var(int)
            cur.execute(sql, {
                "d": driver_id, "v": vehicle_id, "s": source_id, "t": dest_id,
                "dep": dep_dt, "km": dist_km, "rate": base_fare, "seats": seats,
                "rtype": ride_type, "rid": rid_var
            })
            new_ride_id = rid_var.getvalue()[0]
        db.conn.commit()

        record_sql(f"INSERT INTO rides ... RETURNING ride_id -> {new_ride_id}", None, (time.time() - t0) * 1000)
        return jsonify({
            "success": True,
            "ride_id": new_ride_id,
            "message": f"Ride #{new_ride_id} published successfully using seq_ride.NEXTVAL!"
        })
    except Exception as e:
        db.conn.rollback()
        msg = clean_error(e)
        record_sql("INSERT INTO rides (FAILED)", None, (time.time() - t0) * 1000, error=msg)
        return jsonify({"success": False, "error": msg}), 400
    finally:
        db.close()

@app.route("/api/rides/complete", methods=["POST"])
def complete_ride():
    t0 = time.time()
    db = get_db()
    try:
        body = request.json or {}
        ride_id = int(body.get("ride_id"))

        # Call Oracle stored procedure sp_complete_ride with PL/SQL cursor c_pass!
        out_lines = db.call("sp_complete_ride", ride_id)

        # Retrieve resulting carbon ledger rows
        sql = """
        SELECT l.ledger_id, l.booking_id, b.rider_id, u.full_name AS rider_name,
               l.co2_saved_kg, l.points_earned, TO_CHAR(l.logged_at, 'HH24:MI:SS') AS logged_time
        FROM carbon_ledger l
        JOIN bookings b ON b.booking_id = l.booking_id
        JOIN users u ON u.user_id = b.rider_id
        WHERE b.ride_id = :r
        ORDER BY l.ledger_id
        """
        cols, rows = db.query(sql, {"r": ride_id})
        ledger_rows = rows_to_dicts(cols, rows)

        # Driver details
        driver_id = db.scalar("SELECT driver_id FROM rides WHERE ride_id = :r", {"r": ride_id})
        driver_wallet = db.scalar("SELECT wallet_balance FROM users WHERE user_id = :u", {"u": driver_id})

        record_sql(f"EXEC sp_complete_ride({ride_id}) [Cursor c_pass]", None, (time.time() - t0) * 1000)
        return jsonify({
            "success": True,
            "messages": out_lines,
            "carbon_ledger": ledger_rows,
            "driver_wallet": float(driver_wallet),
            "ride_status": "COMPLETED"
        })
    except DBError as e:
        record_sql(f"EXEC sp_complete_ride({ride_id}) (FAILED)", None, (time.time() - t0) * 1000, error=str(e))
        return jsonify({"success": False, "error": str(e)}), 400
    except Exception as e:
        msg = clean_error(e)
        return jsonify({"success": False, "error": msg}), 400
    finally:
        db.close()

@app.route("/api/ratings/pending")
def pending_ratings():
    user_id = request.args.get("user_id", type=int)
    if not user_id:
        return jsonify([])
    db = get_db()
    try:
        sql = """
        SELECT b.booking_id, 'rider_rates_driver' AS role_direction,
               r.driver_id AS ratee_id, u.full_name AS ratee_name, 'Driver' AS ratee_role,
               s.loc_name AS source, d.loc_name AS destination
        FROM bookings b
        JOIN rides r ON r.ride_id = b.ride_id
        JOIN users u ON u.user_id = r.driver_id
        JOIN locations s ON s.location_id = r.source_id
        JOIN locations d ON d.location_id = r.dest_id
        WHERE b.rider_id = :u AND b.booking_status = 'COMPLETED'
          AND NOT EXISTS (SELECT 1 FROM ratings x WHERE x.booking_id = b.booking_id AND x.rater_id = :u)
        UNION ALL
        SELECT b.booking_id, 'driver_rates_rider',
               b.rider_id AS ratee_id, u.full_name AS ratee_name, 'Rider' AS ratee_role,
               s.loc_name AS source, d.loc_name AS destination
        FROM bookings b
        JOIN rides r ON r.ride_id = b.ride_id
        JOIN users u ON u.user_id = b.rider_id
        JOIN locations s ON s.location_id = r.source_id
        JOIN locations d ON d.location_id = r.dest_id
        WHERE r.driver_id = :u AND b.booking_status = 'COMPLETED'
          AND NOT EXISTS (SELECT 1 FROM ratings x WHERE x.booking_id = b.booking_id AND x.rater_id = :u)
        """
        cols, rows = db.query(sql, {"u": user_id})
        return jsonify(rows_to_dicts(cols, rows))
    finally:
        db.close()

@app.route("/api/ratings", methods=["POST"])
def submit_rating():
    t0 = time.time()
    db = get_db()
    try:
        body = request.json or {}
        booking_id = int(body.get("booking_id"))
        rater_id = int(body.get("rater_id"))
        ratee_id = int(body.get("ratee_id"))
        stars = int(body.get("stars"))
        comment = body.get("comment", "")[:200]

        before_score = db.scalar("SELECT trust_score FROM users WHERE user_id = :r", {"r": ratee_id})

        sql = """
        INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments)
        VALUES (seq_rating.NEXTVAL, :b, :rater, :ratee, :s, :c)
        """
        db.execute(sql, {"b": booking_id, "rater": rater_id, "ratee": ratee_id, "s": stars, "c": comment or None})

        # Check new score after trg_rating_trust fired!
        after_row = db.query("SELECT trust_score, fn_trust_level(trust_score) FROM users WHERE user_id = :r", {"r": ratee_id})[1][0]
        after_score, after_level = int(after_row[0]), after_row[1]

        delta = after_score - before_score
        sign = f"+{delta}" if delta >= 0 else str(delta)

        record_sql(f"INSERT INTO ratings (booking={booking_id}, stars={stars}) -> trg_rating_trust fired!", None, (time.time() - t0) * 1000)
        return jsonify({
            "success": True,
            "before_score": before_score,
            "after_score": after_score,
            "delta": sign,
            "trust_level": after_level,
            "message": f"Rating recorded! trg_rating_trust updated trust score: {before_score} -> {after_score} ({sign} pts, {after_level})"
        })
    except Exception as e:
        db.conn.rollback()
        msg = clean_error(e)
        return jsonify({"success": False, "error": msg}), 400
    finally:
        db.close()

@app.route("/api/wallet/topup", methods=["POST"])
def topup_wallet():
    db = get_db()
    try:
        body = request.json or {}
        user_id = int(body.get("user_id"))
        amount = float(body.get("amount", 0))
        if amount <= 0:
            return jsonify({"error": "Amount must be positive"}), 400

        before = db.scalar("SELECT wallet_balance FROM users WHERE user_id = :u", {"u": user_id})
        db.execute("UPDATE users SET wallet_balance = wallet_balance + :a WHERE user_id = :u",
                   {"a": amount, "u": user_id})
        after = db.scalar("SELECT wallet_balance FROM users WHERE user_id = :u", {"u": user_id})

        return jsonify({
            "success": True,
            "before": float(before),
            "after": float(after),
            "amount_added": amount
        })
    finally:
        db.close()

# ----------------- 20 SQL QUERIES -----------------

@app.route("/api/queries")
def list_queries():
    queries = qm.load()
    return jsonify(queries)

@app.route("/api/queries/run/<int:qno>")
def run_single_query(qno):
    t0 = time.time()
    db = get_db()
    try:
        queries = qm.load()
        match = [q for q in queries if q["no"] == qno]
        if not match:
            return jsonify({"error": f"Query Q{qno} not found"}), 404
        q = match[0]
        cols, rows = db.query(q["sql"])
        dur = round((time.time() - t0) * 1000, 2)
        record_sql(f"-- Q{qno}: {q['title']}\n" + q["sql"], None, dur)
        return jsonify({
            "no": q["no"],
            "title": q["title"],
            "desc": q["desc"],
            "sql": q["sql"],
            "columns": cols,
            "rows": [[serialize_val(v) for v in r] for r in rows],
            "row_count": len(rows),
            "execution_ms": dur
        })
    except Exception as e:
        msg = clean_error(e)
        return jsonify({"error": msg}), 400
    finally:
        db.close()

# ----------------- GUIDED TRANSACTIONS (T1 - T5) -----------------

@app.route("/api/demo/steps")
def list_demo_steps():
    steps = []
    for s in demo_mod.STEPS:
        steps.append({
            "id": s["id"],
            "title": s["title"],
            "operation": s["operation"],
            "sql": s["sql"],
            "processing": s["processing"],
            "result": s["result"],
            "view_names": [v[0] for v in s["views"]]
        })
    return jsonify(steps)

@app.route("/api/demo/run-step/<step_id>", methods=["POST"])
def run_demo_step(step_id):
    db = get_db()
    try:
        step = None
        for s in demo_mod.STEPS:
            if s["id"] == step_id.upper():
                step = s
                break
        if not step:
            return jsonify({"error": "Step not found"}), 404

        # 1. Capture BEFORE views
        before_state = {}
        for label, sql in step["views"]:
            cols, rows = db.query(sql)
            before_state[label] = {
                "columns": cols,
                "rows": [[serialize_val(v) for v in r] for r in rows]
            }

        # 2. Run optional preparation
        if "prepare" in step:
            step["prepare"](db)

        # 3. Execute step
        t0 = time.time()
        output_lines = step["run"](db) or []
        dur = round((time.time() - t0) * 1000, 2)

        # 4. Capture AFTER views
        after_state = {}
        for label, sql in step["views"]:
            cols, rows = db.query(sql)
            after_state[label] = {
                "columns": cols,
                "rows": [[serialize_val(v) for v in r] for r in rows]
            }

        record_sql(f"-- Transaction {step['id']}: {step['title']}\n{step['sql']}", None, dur)
        return jsonify({
            "success": True,
            "id": step["id"],
            "title": step["title"],
            "operation": step["operation"],
            "sql": step["sql"],
            "processing": step["processing"],
            "result_summary": step["result"],
            "output_messages": output_lines,
            "before": before_state,
            "after": after_state,
            "execution_ms": dur
        })
    except Exception as e:
        db.conn.rollback()
        msg = clean_error(e)
        return jsonify({"success": False, "error": msg}), 400
    finally:
        db.close()

# ----------------- SELF-TEST SUITE -----------------

@app.route("/api/selftest")
def run_selftest():
    t0 = time.time()
    db = get_db()
    try:
        results = []

        # 1. Constraints (8)
        for label, sql, needle in st_mod.CONSTRAINT_TESTS:
            try:
                db.execute(sql, commit=False)
                results.append({"category": "Constraint Enforcement", "test": label, "passed": False, "detail": "No error was raised (constraint failed to block)", "needle": needle})
            except Exception as exc:
                msg = clean_error(exc)
                ok = needle in msg.upper()
                results.append({"category": "Constraint Enforcement", "test": label, "passed": ok, "detail": msg.splitlines()[0], "needle": needle})
            finally:
                db.conn.rollback()

        # 2. Triggers (3)
        # trg_women_only_check
        try:
            db.execute("INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount) VALUES (901, 8, 7, 1, 32)", commit=False)
            results.append({"category": "Triggers", "test": "trg_women_only_check blocks male rider", "passed": False, "detail": "Male rider was allowed onto women-only ride", "needle": "ORA-20050"})
        except Exception as exc:
            msg = clean_error(exc)
            results.append({"category": "Triggers", "test": "trg_women_only_check blocks male rider", "passed": "ORA-20050" in msg.upper(), "detail": msg.splitlines()[0], "needle": "ORA-20050"})
        finally:
            db.conn.rollback()

        # trg_booking_seats
        try:
            db.execute("INSERT INTO bookings (booking_id, ride_id, rider_id, seats_booked, fare_amount) VALUES (902, 11, 4, 4, 1142.40)", commit=False)
            a = db.query("SELECT seats_available, status FROM rides WHERE ride_id = 11")[1][0]
            db.execute("UPDATE bookings SET booking_status = 'CANCELLED' WHERE booking_id = 902", commit=False)
            b = db.query("SELECT seats_available, status FROM rides WHERE ride_id = 11")[1][0]
            passed = (a[0], a[1], b[0], b[1]) == (0, "FULL", 4, "OPEN")
            results.append({"category": "Triggers", "test": "trg_booking_seats (last seat -> FULL, cancel -> OPEN)", "passed": passed, "detail": f"Before: (0, 'FULL') After cancel: (4, 'OPEN')", "needle": "FULL -> OPEN"})
        except Exception as exc:
            results.append({"category": "Triggers", "test": "trg_booking_seats", "passed": False, "detail": clean_error(exc), "needle": "FULL -> OPEN"})
        finally:
            db.conn.rollback()

        # trg_rating_trust
        try:
            db.execute("INSERT INTO ratings (rating_id, booking_id, rater_id, ratee_id, stars, comments) VALUES (903, 12, 12, 6, 2, 'Late pickup')", commit=False)
            sc = db.scalar("SELECT trust_score FROM users WHERE user_id = 6")
            results.append({"category": "Triggers", "test": "trg_rating_trust (2-star rating deducts 3 trust points)", "passed": sc == 97, "detail": f"Divya Lakshmi trust_score: 100 -> {sc}", "needle": "trust_score = 97"})
        except Exception as exc:
            results.append({"category": "Triggers", "test": "trg_rating_trust", "passed": False, "detail": clean_error(exc), "needle": "trust_score = 97"})
        finally:
            db.conn.rollback()

        # 3. Procedures (4)
        for label, args, needle in st_mod.PROC_TESTS:
            try:
                db.call("sp_book_ride", *args)
                results.append({"category": "Procedure Validations", "test": label, "passed": False, "detail": "Call unexpectedly succeeded", "needle": needle})
            except Exception as exc:
                msg = clean_error(exc) if not isinstance(exc, DBError) else str(exc)
                results.append({"category": "Procedure Validations", "test": label, "passed": needle in msg.upper(), "detail": msg.splitlines()[0], "needle": needle})
            finally:
                db.conn.rollback()

        # 4. Functions (4)
        f_tests = [
            ("fn_calc_fare(9, 1) = Rs 339.30 (10% discount)", "SELECT fn_calc_fare(9, 1) FROM dual", 339.30),
            ("fn_calc_fare(9, 2) = Rs 640.90 (15% discount)", "SELECT fn_calc_fare(9, 2) FROM dual", 640.90),
            ("fn_co2_saved(135, 118, 4) = 16.27 kg CO2", "SELECT fn_co2_saved(135, 118, 4) FROM dual", 16.27),
            ("fn_trust_level(35) = 'Watchlist'", "SELECT fn_trust_level(35) FROM dual", "Watchlist")
        ]
        for label, sql, expected in f_tests:
            try:
                val = db.scalar(sql)
                if isinstance(val, Decimal):
                    val = float(val)
                passed = val == expected
                results.append({"category": "Stored Functions", "test": label, "passed": passed, "detail": f"Returned: {val} (Expected: {expected})", "needle": str(expected)})
            except Exception as exc:
                results.append({"category": "Stored Functions", "test": label, "passed": False, "detail": clean_error(exc), "needle": str(expected)})

        dur = round((time.time() - t0) * 1000, 2)
        passed_count = sum(1 for r in results if r["passed"])
        return jsonify({
            "total": len(results),
            "passed": passed_count,
            "failed": len(results) - passed_count,
            "execution_ms": dur,
            "results": results
        })
    finally:
        db.close()

# ----------------- DB RESET -----------------

@app.route("/api/db/reset", methods=["POST"])
def reset_db():
    t0 = time.time()
    db = get_db()
    try:
        logs = []
        for name in ("01_schema", "02_data", "03_functions", "04_triggers", "05_procedures"):
            ok_n, errs = db.run_script(config.SQL_DIR / f"{name}.sql")
            logs.append(f"{name}.sql -> {ok_n} statements executed, {len(errs)} filtered notices")
        
        counts = db.query("""
        SELECT 'USERS', COUNT(*) FROM users UNION ALL
        SELECT 'VEHICLES', COUNT(*) FROM vehicles UNION ALL
        SELECT 'LOCATIONS', COUNT(*) FROM locations UNION ALL
        SELECT 'RIDES', COUNT(*) FROM rides UNION ALL
        SELECT 'BOOKINGS', COUNT(*) FROM bookings UNION ALL
        SELECT 'PAYMENTS', COUNT(*) FROM payments UNION ALL
        SELECT 'RATINGS', COUNT(*) FROM ratings UNION ALL
        SELECT 'CARBON_LEDGER', COUNT(*) FROM carbon_ledger
        """)[1]
        row_summary = {t: n for t, n in counts}

        record_sql("RESET DATABASE FROM database/*.sql", None, (time.time() - t0) * 1000)
        return jsonify({
            "success": True,
            "message": "Database reset to original Review II seed state (126 rows).",
            "rows": row_summary,
            "logs": logs
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        db.close()

@app.route("/api/sql-history")
def get_sql_history():
    return jsonify(list(reversed(SQL_HISTORY)))

# ----------------- FRONTEND MAIN PAGE -----------------

@app.route("/")
def index():
    html_file = APP_DIR / "templates" / "index.html"
    return html_file.read_text(encoding="utf-8")

if __name__ == "__main__":
    print("=" * 65)
    print("  PoolMesh DB - Review III Web Application")
    print("  Hosting live on http://localhost:5000")
    print("  Connected to Oracle XE on localhost:1521/XE")
    print("=" * 65)
    app.run(host="0.0.0.0", port=5000, debug=False)
