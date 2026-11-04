# PoolMesh DB - Final Review Project

**A Campus-to-City Carpooling Database** | BCSE302P Database Systems | VIT Vellore
Manoj Kumar S (24BDE0052) - Manoj K (24BDE0147) - S M Nithin (24BDE0033)

## What is in this package

| Folder | Contents |
|---|---|
| `database/` | Oracle scripts split by purpose (01 schema, 02 data, 03 functions, 04 triggers, 05 procedures, 06 queries, 07 demo/tests) + `PoolMesh_Review2_full.sql` (your original single script) |
| `app/` | **Review III**: menu-driven Python console application (python-oracledb) |
| `presentation/` | `PoolMesh_Final_Review.pptx` - 17 slides with speaker notes |
| `docs/` | `DEMO_SCRIPT.md` (what to click, in order), `VIVA_QA.md` (likely questions + answers), `ER_diagram.png` |

## 1. Prerequisites
* Oracle Database 12c or later (Oracle XE 21c is fine) and a schema/user, e.g. `poolmesh`
* Python 3.9+ and `pip install -r app/requirements.txt` (thin mode: no Oracle client needed)

No Oracle yet? Quickest option with Docker:
```
docker run -d --name oracle-xe -p 1521:1521 -e ORACLE_PASSWORD=oracle gvenzl/oracle-xe:21-slim
# then create the user once, e.g. in SQL*Plus / SQL Developer as SYSTEM:
CREATE USER poolmesh IDENTIFIED BY poolmesh QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE, CREATE VIEW TO poolmesh;
```

## 2. Install the database (choose one)
**A. From the app (easiest):** configure `.env` (step 3) and run `python main.py` - if the tables are missing, the app installs everything automatically. Menu 12 > 1 re-installs at any time.
**B. From SQL*Plus / SQLcl:** `cd database` then `@00_install_all.sql`
**C. SQL Developer:** open `PoolMesh_Review2_full.sql` and press F5 (Run Script).

## 3. Run the application
```
cd app
copy .env.example .env      (Windows)   |   cp .env.example .env   (Mac/Linux)
# edit .env: ORACLE_USER, ORACLE_PASSWORD, ORACLE_DSN
pip install -r requirements.txt
python main.py
```

### Menu
`1` search rides - `2` book - `3` cancel - `4` offer a ride - `5` complete a ride (cursor) - `6` rate - `7` top up wallet - `8` dashboard - `9` reports - `10` run any of the 20 queries - `11` guided demo T1-T5 - `12` install / self-test / row counts - `S` toggle Show-SQL mode - `U` switch user.

## 4. Verify everything works
Run **menu 12 > 2 (self-test)** on freshly installed data. It re-proves the 8 constraint rules, the 3 triggers, 4 procedure validations and the function results from the Review II report (19 checks).

## How the app maps to the database
The app contains **no business rules**. It collects input and calls:
`sp_book_ride`, `sp_cancel_booking`, `sp_complete_ride` (explicit cursor `c_pass`), `fn_calc_fare`, `fn_trust_level`, plus plain INSERT/UPDATE for offering rides, rating (fires `trg_rating_trust`) and wallet top-up. Turn on Show-SQL mode (`S`) to display the exact SQL / PL-SQL each option sends.

## Notes
* The scripts target Oracle only (PL/SQL, `FETCH FIRST`, `TIMESTAMP`, sequences).
* The guided demo (menu 11) changes data; it offers to reset to seed data first, and re-running requires a reset.
* Trust-score penalty for late cancellation depends on the system clock; T3 sets ride 8 to depart in 90 minutes so it is repeatable.
