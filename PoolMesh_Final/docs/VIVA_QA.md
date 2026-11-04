# Viva questions and short answers

**Why put business rules inside the database instead of Python?**
Every client sees identical behaviour, and a front-end bug cannot create an invalid booking. Constraints and triggers act as the last line of defence.

**How do you prevent two riders booking the last seat at the same time?**
`sp_book_ride` runs `SELECT ... FOR UPDATE` on the ride row, so the second transaction waits. As a final guard, `CHECK (seats_available >= 0)` rejects any insert that would overbook.

**Why are seats_available, trust_score and green_points stored columns?**
They are derived values, but stored for fast reads (search, leaderboards). Triggers and procedures update them in the same transaction as the event that changes them, so they cannot drift.

**Why did you create triggers after loading the data?**
The seed history (seat counts, fares, ledger) is already consistent. Loading with triggers on would recount seats and double-apply Trust changes.

**Why an explicit cursor in sp_complete_ride?**
Each passenger needs several dependent actions on different tables (ledger row, points, status, running driver credit) plus a progress message. The cursor makes the per-row logic visible; a single INSERT...SELECT gives no per-row control.

**Explain the fare formula.**
distance x rate x seats x (1 - discount). Discount depends on occupied seats after the booking: 1 = 0%, 2 = 5%, 3 = 10%, 4+ = 15%. Each rider pays less as the car fills while the driver earns more in total.

**Explain the CO2 formula.**
Solo baseline 150 g/km. Each person in the pool carries emission / occupants. Saved kg = km x (150 - emission/occupants) / 1000, never below 0. Example: 210 km, Innova 185 g/km, 4 occupants: 21.79 kg per passenger.

**Why do bad ratings cost more than good ratings earn?**
Deltas are +2, +1, 0, -3, -5 (late cancel -5), clamped to 0-100, so scores are hard to inflate and risky users surface quickly.

**What is the difference between a function and a procedure here?**
Functions return a value and are usable inside SQL (fn_trust_level in Q6). Procedures perform a business operation that changes several tables and commits.

**Which normal form is the schema in?**
3NF: every non-key attribute depends on the key only. Facts like location name live in LOCATIONS, not repeated in RIDES. Derived columns are a deliberate, documented denormalisation for performance.

**What happens if you delete a ride that has bookings?**
Oracle raises ORA-02292 (FK_BOOK_RIDE) - history is preserved (shown in the DELETE demo).

**Known limitations?**
Redeemed Green Points are not returned on cancellation; refunds always go to the wallet; payments are records only (no gateway).

**What would you do next?**
A configurable rules table, a web/mobile front end over the same procedures, a real payment gateway, live route distances.
