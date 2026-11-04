# PoolMesh DB - Review III Showcase & Viva Presentation Guide

**Course:** BCSE302P – Database Systems | **Institution:** Vellore Institute of Technology, Vellore  
**Team Members:**  
* Manoj Kumar S (24BDE0052)  
* Manoj K (24BDE0147)  
* S M Nithin (24BDE0033)  

---

## 🌟 1. Application URL & Quick Launch

* **Live Localhost Web Application:** [http://localhost:5000](http://localhost:5000) *(Already hosted & active on your machine!)*
* **Desktop 1-Click Launchers:**
  * Double-click `run_localhost_app.bat` in `C:\Users\Admin\Desktop\PoolMesh_Final_Project` to start/restart the web server anytime.
  * Double-click `run_cli.bat` if the professor explicitly asks to see the terminal/CLI interface.

---

## 🚀 2. Review III 5-Minute Live Demo Script for Sir

Follow these exact steps in your browser at `http://localhost:5000`:

### Step 1: Open Dashboard & Explain Architecture (1 min)
1. Point out the top header:
   * **Database Engine:** Connected live to **Oracle XE 11g** via Port 1521.
   * **Database Objects:** 8 constrained tables, 99 constraints, 8 sequences, 3 functions, 3 triggers, 3 stored procedures, 1 explicit cursor.
   * **Seed Data:** 126 rows loaded across the 8 tables.
2. Show the **Logged In User** in the top-right:
   * Start with **User 12 (Fathima Begum)**.
   * Highlight her **Wallet Balance (Rs 150.00)**, **Trust Score (91 - Excellent)**, and **Green Points (344 pts)**.
   * Show that her profile has both "My Bookings (as Rider)" and "My Offered Rides (as Driver)".

### Step 2: Search & Book a Ride with Dynamic Pooled Fare (1.5 min)
1. Click the **"Find & Book Rides"** tab.
2. Show the filters: From, To, Campus Hubs Only toggle.
3. Show **Ride #8 (Katpadi Junction)** with the pink **WOMEN-ONLY** badge.
   * *Say to Sir:* "Because Fathima is registered as Female (F), she can view and book this ride. If we switch to a male user, trigger `trg_women_only_check` prevents him from booking."
4. Click **"Book Seats"** on **Ride #9** (VIT Main Gate &rarr; Koyambedu CMBT):
   * Move the seat slider to **2 seats**.
   * Watch the real-time math box: it queries Oracle stored function `fn_calc_fare(9, 2)`.
   * Explain: Undiscounted fare is 130 km &times; Rs 2.90 &times; 2 = Rs 754.00.
   * Occupancy discount of 15% is automatically applied because the car reaches 4 occupants &rarr; Rs 640.90!
   * Enter **20** in "Redeem Green Points" &rarr; reduces fare by Rs 10 (1 pt = Rs 0.50).
   * Click **"Confirm Booking (sp_book_ride)"** &rarr; Oracle procedure runs in an atomic transaction:
     - Deducts wallet balance.
     - Deducts green points.
     - Decrements available seats in `RIDES`.
     - Inserts into `BOOKINGS` and `PAYMENTS`.
     - Ride #9 flips to **FULL** via trigger `trg_booking_seats`.

### Step 3: Demonstrate Ride Completion with Cursor `c_pass` (1 min)
1. Use the top user switcher to switch to **User 9 (Vikram Singh)**.
2. On the Dashboard under "My Offered Rides", look at **Ride #6 (Bengaluru &rarr; VIT Main Gate)**.
3. Click **"Complete Ride (Cursor)"**:
   * *Say to Sir:* "This executes stored procedure `sp_complete_ride`, which declares an explicit parameterised cursor `c_pass` that loops over each confirmed passenger one-by-one."
   * Show the execution output:
     - Calculates carbon savings via `fn_co2_saved(210, 185, 4)` = 21.79 kg per passenger.
     - Inserts 3 rows into `CARBON_LEDGER`.
     - Awards 218 Green Points to each rider.
     - Marks bookings as `COMPLETED`.
     - Credits Vikram's driver wallet with Rs 1,556.10!

### Step 4: Ratings & Live Trust Score Trigger (45 sec)
1. Switch user to **User 10 (Meera Nair)**.
2. Go to the **"Rate Trips & Trust"** tab.
3. Find completed Ride #6 with Driver Vikram Singh.
4. Give Vikram **1 Star** and comment: *"Rash driving on the ghat section"*.
5. Click **"Submit Rating"**:
   * *Say to Sir:* "Trigger `trg_rating_trust` fires instantly upon INSERT into `RATINGS`. A 1-star rating deducts 5 points from the driver's trust score."
   * Watch Vikram's Trust Score fall from 42 &rarr; 34, moving him into the **Watchlist** tier (`fn_trust_level`)!

### Step 5: Run the 20 Review II SQL Queries & Self-Test Proofs (1 min)
1. Click the **"20 SQL Queries"** tab:
   * Click **Q6 (Low-trust alert list)** &rarr; click **"Run Query Live"**. Show that Vikram now appears in the low-trust alert list!
   * Click **Q20 (Driver revenue ranking using analytic function RANK() OVER)** &rarr; click **"Run Query Live"**.
2. Click the **"Self-Test (19 Proofs)"** tab:
   * Click **"Run All 19 Proof Tests"**.
   * All 8 constraints, 3 triggers, 4 procedure validations, and 4 functions will execute against Oracle and display **19/19 PASSED**!

---

## 🎯 3. Rapid Viva Q&A (What Sir Might Ask)

### Q1: Where does your business logic reside? In Python or the Database?
**Answer:**  
"All business logic resides **strictly inside the Oracle Database** using Constraints, Functions, Triggers, and Stored Procedures. The Python web front-end only acts as a thin presentation layer that collects inputs and executes stored procedures. Even if a user attempts to bypass the UI and execute direct SQL, the database constraints and triggers guarantee integrity."

### Q2: Why did you use an explicit Cursor `c_pass` in `sp_complete_ride` instead of a set-based UPDATE?
**Answer:**  
"Because completing a ride requires multiple dependent actions for each individual passenger:
1. Calculating exact per-seat CO2 savings via `fn_co2_saved` based on vehicle emission factor and occupancy.
2. Inserting an audit record into `CARBON_LEDGER`.
3. Updating each passenger's accumulated Green Points in `USERS`.
4. Updating booking status in `BOOKINGS`.
5. Accumulating driver credit only for non-cash bookings.
The explicit parameterised cursor `CURSOR c_pass(cp_ride NUMBER)` allows row-by-row transactional control and progress logging."

### Q3: How do you prevent overbooking in concurrent transactions?
**Answer:**  
"In `sp_book_ride`, we use `SELECT * INTO v_ride FROM rides WHERE ride_id = p_ride_id FOR UPDATE;` which applies a pessimistic row lock on the ride record. Additionally, the table has a CHECK constraint `ck_ride_seats CHECK (seats_available >= 0)` as the ultimate line of defence."

### Q4: How is the Women-Only carpooling safety rule enforced?
**Answer:**  
"Through `BEFORE INSERT` trigger `trg_women_only_check` on the `BOOKINGS` table. When an insert occurs on a ride where `ride_type = 'WOMEN_ONLY'`, the trigger checks the rider's gender in `USERS`. If gender is not `'F'`, it aborts the transaction with `RAISE_APPLICATION_ERROR(-20050, 'Women-only ride: booking allowed only for female riders')`."

### Q5: How does your dynamic pooled pricing work?
**Answer:**  
"Stored function `fn_calc_fare(ride_id, seats)` computes `Distance × Rate × Seats` and applies an occupancy discount:
* 1 occupant: 0%
* 2 occupants: 5%
* 3 occupants: 10%
* 4+ occupants: 15%
As more students join the pool, individual fares decrease while the driver's total earnings increase."
