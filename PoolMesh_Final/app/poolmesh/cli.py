"""PoolMesh DB - menu-driven console application (Review III)."""
import sys
import oracledb
from . import ui, actions, demo, queries, selftest, config
from .db import Database

LOGO = r"""
  ____             _ __  __           _       ____  ____
 |  _ \ ___   ___ | |  \/  | ___  ___| |__   |  _ \| __ )
 | |_) / _ \ / _ \| | |\/| |/ _ \/ __| '_ \  | | | |  _ \
 |  __/ (_) | (_) | | |  | |  __/\__ \ | | | | |_| | |_) |
 |_|   \___/ \___/|_|_|  |_|\___||___/_| |_| |____/|____/
        Campus-to-City Carpooling Database  |  VIT Vellore
"""

MENU = """
  {u}
  [1] Search rides              [7] Top up wallet
  [2] Book a ride               [8] My dashboard
  [3] Cancel a booking          [9] Reports & analytics
  [4] Offer a ride (drivers)    [10] SQL query explorer (Q1-Q20)
  [5] Complete a ride (drivers) [11] Guided demo - transactions T1-T5
  [6] Rate a co-traveller       [12] Database tools (install / self-test)
  [S] Show-SQL mode: {s}         [U] Switch user        [0] Exit
"""


def reports_menu(db):
    qs = {q["no"]: q for q in queries.load()}
    while True:
        ui.section("Reports & analytics")
        for i, (name, qn) in enumerate(queries.REPORTS, 1):
            print(f"  [{i}] {name}  {ui.dim('(Q' + str(qn) + ')')}")
        print("  [0] Back")
        c = ui.ask_int("Choose", 0, len(queries.REPORTS))
        if c == 0:
            return
        actions.run_query(db, qs[queries.REPORTS[c - 1][1]], show_sql=ui.SHOW_SQL)
        ui.pause()


def explorer_menu(db):
    qs = queries.load()
    while True:
        ui.section("SQL query explorer - the 20 queries of the report")
        for q in qs:
            print(f"  [{q['no']:>2}] {q['title']}  {ui.dim('- ' + q['desc'])}")
        print("  [ 0] Back")
        c = ui.ask_int("Query number", 0, len(qs))
        if c == 0:
            return
        actions.run_query(db, qs[c - 1], show_sql=True)
        ui.pause()


def tools_menu(db):
    while True:
        ui.section("Database tools")
        print("  [1] Install / reset database (runs database/01-05 scripts)")
        print("  [2] Run automated self-test (constraints, triggers, procedures, functions)")
        print("  [3] Show row counts of all 8 tables")
        print("  [0] Back")
        c = ui.ask_int("Choose", 0, 3)
        if c == 0:
            return
        if c == 1:
            if ui.confirm("This DROPS and re-creates all PoolMesh tables. Continue"):
                demo.reset_database(db)
        elif c == 2:
            selftest.run_all(db)
        else:
            tabs = ["users", "vehicles", "locations", "rides", "bookings", "payments", "ratings", "carbon_ledger"]
            sql = " UNION ALL ".join(f"SELECT '{t.upper()}' AS table_name, COUNT(*) AS row_count FROM {t}" for t in tabs)
            ui.table(*db.query(sql))
        ui.pause()


def main():
    print(ui.teal(LOGO))
    db = Database()
    db.echo = ui.sql_echo
    try:
        db.connect()
    except oracledb.DatabaseError as exc:
        ui.fail(f"Cannot connect to Oracle as '{config.USER}' at '{config.DSN}'.")
        print(f"    {exc}\n    Copy .env.example to .env and fix ORACLE_USER / ORACLE_PASSWORD / ORACLE_DSN.")
        return 1
    ui.ok(f"Connected to Oracle ({db.conn.version}) as {config.USER}")
    try:
        have_data = db.scalar("SELECT COUNT(*) FROM users")
    except oracledb.DatabaseError:
        have_data = None
    if not have_data:
        ui.info("PoolMesh tables not found - installing the database from database/*.sql ...")
        demo.reset_database(db)
    user = actions.login(db)
    while True:
        print(MENU.format(u=ui.bold(f"Logged in: {user['name']} (id {user['id']}, {user['role']})"),
                          s=ui.green("ON") if ui.SHOW_SQL else "off"))
        choice = ui.ask("Choose").upper()
        try:
            if choice == "1": actions.search_rides(db, user)
            elif choice == "2": actions.book_ride(db, user)
            elif choice == "3": actions.cancel_booking(db, user)
            elif choice == "4": actions.offer_ride(db, user)
            elif choice == "5": actions.complete_ride(db, user)
            elif choice == "6": actions.rate_user(db, user)
            elif choice == "7": actions.top_up(db, user)
            elif choice == "8": actions.dashboard(db, user)
            elif choice == "9": reports_menu(db); continue
            elif choice == "10": explorer_menu(db); continue
            elif choice == "11": demo.run(db)
            elif choice == "12": tools_menu(db); continue
            elif choice == "S":
                ui.SHOW_SQL = not ui.SHOW_SQL
                ui.info("Show-SQL mode is now " + ("ON" if ui.SHOW_SQL else "off"))
                continue
            elif choice == "U": user = actions.login(db); continue
            elif choice == "0": break
            else:
                ui.fail("Unknown option.")
                continue
        except oracledb.DatabaseError as exc:
            db.conn.rollback()
            from .db import clean_error
            ui.fail(clean_error(exc))
        except (KeyboardInterrupt, EOFError):
            print()
            continue
        ui.pause()
    db.close()
    print(ui.teal("\n  Thank you for using PoolMesh DB.\n"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
