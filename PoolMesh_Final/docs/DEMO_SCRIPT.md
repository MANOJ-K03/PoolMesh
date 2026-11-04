# Live demo script (about 6-8 minutes)

Before you start: Oracle running, `.env` set, database freshly installed. Run `python main.py`, log in as **12 (Fathima Begum)**.

| # | Do this | Say this |
|---|---|---|
| 1 | Press `S` (Show-SQL ON) | "The app has no business logic. Watch the SQL it sends." |
| 2 | Menu `1`, press Enter twice | Ride search; women-only rides are visible because Fathima is female. Use `U` later to show a male user cannot see them. |
| 3 | Menu `12` > `2` self-test | "Every constraint, trigger and procedure rule is proven automatically." (19/19 should pass on fresh data.) |
| 4 | Menu `11` Guided demo, answer `y` to reset | T1-T5 story below. Press Enter between stages. |
| 5 | T1 | Pooled fare Rs 754 - 15% = 640.90, minus 20 points = 630.90. Ride 9 becomes FULL. |
| 6 | T2 | Cancellation returns the seat via `trg_booking_seats`; ride 9 re-opens; Rs 377 refunded. |
| 7 | T3 | Late cancellation (90 minutes before departure): refund and Trust 79 -> 74. |
| 8 | T4 | The cursor: one line per passenger, 65.37 kg CO2, driver credited Rs 1,556.10. |
| 9 | T5 | Two bad ratings; Vikram 42 -> 34 and becomes Watchlist. |
| 10 | `U` > user 6 (Divya, driver of ride 11), menu `2`, book ride 11 | "A driver cannot book their own ride" - the database refuses it (ORA-20011). Try ride 10 (FULL) for ORA-20010. |
| 11 | Menu `10`, run Q6 and Q20 | "Low-trust list now shows Vikram as Watchlist; RANK() shows driver revenue." |

## If something goes wrong
* Connection error: check `.env` (user, password, DSN) and that the listener is up.
* "Ride is not open" in the demo: the data was already modified - run Menu 12 > 1 to reset, then Menu 11.
* No Oracle on the demo laptop: show the BEFORE/AFTER tables in the Review II PDF (sections 8-10) and slide 14.
