# Gainly — Product Specification

## 1. Product vision

Gainly is a daily financial performance and budget management application designed primarily for people with irregular or daily income.

The application is especially aimed at:

* gig workers
* delivery drivers and couriers
* rideshare drivers
* freelancers
* self-employed workers
* small entrepreneurs
* independent workers
* people with several daily income sources
* people who need to earn money regularly rather than relying on a fixed monthly salary

Gainly is not primarily designed as a traditional monthly salary budgeting application.

Its core purpose is to answer:

**“Am I financially moving forward or backward today?”**

The application should help users:

* understand what they earn every day
* understand what they spend every day
* identify positive and negative days
* compensate for negative days
* remain financially positive over time
* monitor irregular income
* understand which activities generate money
* detect excessive expenses quickly
* maintain better financial discipline
* reach monthly income objectives

The product should remain simple, visual and fast to use.

---

# 2. Platforms

Gainly must be built as a cross-platform application.

Technology:

* Flutter
* Dart

Supported platforms:

* iOS
* Android
* Web

The architecture should allow desktop platforms to be added later if desired.

---

# 3. Backend

Use Supabase as the initial backend.

Use:

* Supabase Auth
* PostgreSQL
* Row Level Security
* optional Realtime where useful
* cloud persistence
* synchronization between devices

The application must remain functional without being permanently connected to the internet.

---

# 4. Project language

All technical project content must be written in English.

This includes:

* source code
* variable names
* database schemas
* filenames
* comments
* README
* technical documentation
* GitHub documentation
* architecture documentation
* tests


---

# 5. User interface languages

The application must support:

* English
* French
* Spanish

All UI strings must use a localization system from the beginning.

No user-facing text should be hardcoded directly inside screens.

---

# 6. Core financial concepts

Gainly uses two different balances.

## 6.1 Balance

`Balance` represents the user's real financial position.

It includes every transaction:

* work income
* benefits
* salary
* gifts
* refunds
* expenses
* exceptional income
* excluded performance transactions

Formula:

Balance =
Starting Balance

* all income

- all expenses

---

## 6.2 Performance Balance

`Performance Balance` represents financial performance related to the activity the user wants to measure.

Certain transactions can be excluded.

Examples:

Included:

* Uber Eats income
* Deliveroo income
* rideshare income
* freelance income
* business income
* fuel expenses
* food expenses
* work-related expenses

Potentially excluded:

* government benefits
* RSA
* APL
* gifts
* exceptional reimbursements
* loans
* exceptional income

Formula:

Performance Balance =
Starting Performance Balance

* included performance income

- included performance expenses

Performance Balance is the main financial indicator on the Dashboard.

Balance appears nearby but with lower visual priority.

---

# 7. Starting balances

Users may define:

* Starting Balance
* Starting Performance Balance

These values are independent.

Example:

Starting Balance: €1,000
Starting Performance Balance: €250

Both values are optional during onboarding.

If a value has not been configured, do NOT display `€0`.

Instead display an actionable state such as:

`Set your starting balance`

Tapping it should open the correct section in Settings.

Starting balances can be configured later.

They represent global starting amounts and do not require historical transaction details.

---

# 8. Transactions

Two main transaction types:

* Income
* Expense

Each transaction should support:

* amount
* transaction type
* date
* category
* source or merchant
* payment method
* optional note
* included in performance
* created_at
* updated_at
* deleted_at
* user_id

Use soft deletion.

---

# 9. Categories

Categories must have a default performance behavior.

Example:

Benefits
`Included in Performance = false`

Delivery
`Included in Performance = true`

Fuel
`Included in Performance = true`

Users can override this setting for an individual transaction without changing the entire category.

Categories should be editable and reusable.

---

# 10. Default income categories

Initial categories:

* Delivery
* Rideshare
* Freelance
* Sales
* Salary
* Benefits
* Refund
* Gift
* Other

---

# 11. Default expense categories

Initial categories:

* Food
* Fuel
* Transport
* Housing
* Bills
* Shopping
* Leisure
* Health
* Work expenses
* Other

These categories can evolve later.

---

# 12. Sources

Category and Source are different concepts.

Example:

Category:
`Delivery`

Source:
`Uber Eats`

Another example:

Category:
`Rideshare`

Source:
`Citygo`

Sources should be remembered after creation and suggested in future transactions.

Users can create custom sources.

Examples:

* Uber Eats
* Deliveroo
* Citygo
* Shopopop
* Private client
* APL
* RSA

---

# 13. Payment methods

Keep the MVP simple.

Available methods:

* Cash
* Bank Card
* Bank Transfer
* Other

No custom payment methods are required in the MVP.

---

# 14. Transaction entry modes

Two entry modes must exist.

## Detailed mode — default

Users enter individual transactions.

Example:

Uber Eats — €50
Citygo — €25
Shopopop — €15
Private client — €10

Total income automatically becomes €100.

This is the preferred mode.

---

## Quick mode

Users may enter only a global amount.

Example:

Today's income: €100

No source breakdown required.

Such entries should internally use an identifiable state such as:

`Unspecified source`

or

`Daily total`

The same detailed/quick system should exist for expenses.

---

# 15. Daily financial states

Every day belongs to one of four states.

## Positive

Performance result > 0

## Zero after activity

Performance result = 0
AND there was performance activity.

This is visually distinct from inactivity.

## No activity

No performance transaction occurred.

## Negative

Performance result < 0

Suggested visual semantics:

* Positive → green
* Zero after activity → amber/orange
* No activity → neutral grey
* Negative → red

---

# 16. Positive streak

Rules:

Positive day:
increases streak.

Zero after activity:
does not increase streak but does not break it.

No activity:
does not increase streak but does not break it.

Negative day:
breaks the positive streak.

Example:

Monday +40 → streak 1
Tuesday +25 → streak 2
Wednesday 0 with activity → streak remains 2
Thursday +30 → streak 3
Friday −15 → streak reset

---

# 17. Positive Day Rate

Formula:

Positive Day Rate =
positive days / performance-active days

`Zero after activity` counts in the denominator.

`Negative` counts in the denominator.

`No activity` does not.

Example:

6 positive
2 zero-with-activity
2 negative

Positive Day Rate = 6 / 10 = 60%

---

# 18. Tracking streak

Maintain a simple tracking streak encouraging users to continue recording their financial activity.

Gamification must remain secondary.

Gainly is a financial application, not a game.

MVP gamification:

* Tracking Streak
* Positive Streak
* Positive Day Rate
* basic milestones/badges
* contextual encouragement

Do NOT implement:

* XP systems
* complex levels
* competitive leagues
* excessive game mechanics

---

# 19. Calendar

The calendar is one of the application's core views.

Each day should directly display its Performance result.

Examples:

+€42
−€18
€0

Colors represent the state.

Tapping a day opens the full daily detail:

* income
* expenses
* performance result
* transactions
* categories
* sources

---

# 20. Dashboard

Dashboard is the main Home screen.

Primary visual priority:

## Performance Balance

Example:

Performance Balance
+€312.40

Immediately nearby:

Balance
€1,247.50

Then:

Today

Income
Expenses
Result

Then useful summaries:

* this week
* this month
* monthly target progress
* daily minimum progress
* tracking streak
* positive day rate
* Smart Insights
* linked profile comparison summary

The screen must remain uncluttered.

---

# 21. Navigation

Use four main navigation tabs:

* Home
* Calendar
* Transactions
* Profile

A floating `+` transaction button should be available from:

* Home
* Calendar
* Transactions

Not required in Profile.

---

# 22. Transactions screen

The Transactions screen contains a chronological history.

Required:

* search bar
* edit transaction
* delete transaction
* deletion confirmation
* soft deletion

Filters:

* period
* Income / Expense
* category
* source
* Included / Excluded from Performance

Search should search at least:

* source
* category
* notes

---

# 23. Statistics

MVP statistics include:

* Balance
* Performance Balance
* daily results
* weekly results
* monthly results
* Performance Balance evolution
* total income
* income by category
* income by source
* total expenses
* expenses by category
* positive days
* zero-with-activity days
* negative days
* no-activity days
* Positive Day Rate
* positive streaks

Keep charts limited and readable.

Recommended MVP charts:

1. Performance Balance evolution line chart
2. income/expense category distribution

---

# 24. Statistics periods

Available periods:

* 7 days
* 30 days
* This month
* This year
* Custom

Default:

`This month`

---

# 25. Monthly target

Users may optionally configure:

`Monthly Target`

This represents desired gross performance income.

It does NOT represent net profit after expenses.

Example:

Monthly Target = €1,500

---

# 26. Daily Minimum

Users may optionally configure:

`Daily Minimum`

When Monthly Target is configured, recommend:

Monthly Target / 30

Example:

€1,500 / 30 = €50/day

Pre-fill:

Daily Minimum = €50

The user may freely change it.

Example:

€60/day

The configured Daily Minimum should never be silently changed later.

---

# 27. Dynamic target calculation

Gainly should dynamically calculate the pace required to reach the monthly target.

Example:

Monthly Target:
€1,500

Performance income already earned:
€900

Remaining:
€600

Days remaining:
10

Recommended pace:
€60/day

Use all remaining calendar days.

Do not model predefined workdays or weekends.

This is intentional because the target audience controls their own working schedule.

The recommendation recalculates automatically every day.

This calculation is deterministic and runs locally.

---

# 28. Smart Insights

Implement Smart Insights with deterministic local rules.

Possible insights:

* several consecutive negative days
* spending significantly above recent average
* strong Performance Balance decline
* risk of Performance Balance falling below zero
* behind monthly target
* ahead of monthly target
* unusual spending increase in a category
* required daily pace to meet monthly target

Display at most one or two important insights prominently at the same time.

Avoid overwhelming the user.

---

# 29. Linked profiles

Gainly is primarily a personal application.

Each account owns its personal financial data.

Users may voluntarily link their profile with other Gainly users.

This requires explicit authorization.

Support multiple linked profiles at the data model level.

The MVP interface can primarily optimize for 1-to-1 comparisons.

---

# 30. Invitations

Users should be able to invite another user through:

* email
* unique code
* QR code
* shareable invitation link

The invitation link should work with the operating system share sheet.

Examples:

* WhatsApp
* SMS
* email
* messaging apps

Where possible, use deep links so the link opens Gainly directly.

---

# 31. Sharing permissions

Permissions are independent for each user.

One user accepting another does not automatically force identical sharing settings.

Configurable sharing permissions should include:

* detailed transactions
* Performance Balance
* Balance
* statistics
* streaks
* targets

Performance Balance can be visible while real Balance remains hidden.

Real Balance should be privacy-sensitive.

Prefer privacy-safe defaults.

---

# 32. Authentication

Authentication should be extremely easy.

Primary login methods:

* Continue with Google
* Continue with Apple

Secondary fallback:

* Continue with Email

Google and Apple buttons should be visually prominent with recognizable official-style branding.

Use Supabase Auth.

Avoid requiring email/password when social sign-in is available.

---

# 33. Onboarding

Keep onboarding short.

Steps:

1. first name
2. language
3. currency
4. Starting Balance — optional
5. Starting Performance Balance — optional

Starting balances must be skippable.

Users should reach the application quickly.

Additional configuration can happen later.

---

# 34. Currency

Use one currency per account in the MVP.

Do not implement multi-currency transaction calculations yet.

---

# 35. Profile and Settings

Profile should contain:

* account information
* language
* currency
* Starting Balance
* Starting Performance Balance
* categories
* sources
* notification preferences
* privacy
* linked profiles
* sharing permissions
* logout

---

# 36. Notifications

Notifications must be configurable individually.

Default reminder time:

20:00 local time.

User can modify the time.

Only important notifications should be enabled by default.

Suggested defaults:

* daily reminder if no activity was logged
* warning after several negative days
* warning when Performance Balance drops strongly or approaches zero

Optional notifications can include:

* streak encouragement
* badges
* goal progress
* positive milestones

Avoid notification spam.

---

# 37. Offline-first behavior

Poor connectivity must NOT create a bad user experience.

Requirements:

* session remains persisted locally
* network loss must not log the user out
* cached data remains readable
* transactions can be created offline
* transactions can be edited offline
* transactions can be deleted offline
* categories should work offline where practical
* offline changes enter a synchronization queue
* synchronization resumes automatically when connectivity returns
* token refresh should happen automatically when possible

Only:

* explicit logout
* session revocation
* unrecoverable authentication problems

should return the user to authentication.

---

# 38. Synchronization

Cloud data must be recoverable across devices.

Example:

Android → user uses Gainly for months
→ buys iPhone
→ logs into the same account
→ history and progression return automatically

The local device must never be the sole source of truth for persistent financial information.

Use a local cache for offline support.

---

# 39. Sync conflicts

MVP conflict strategy:

`Last Write Wins`

If the same transaction was modified independently from multiple devices, the most recent valid modification wins.

Maintain timestamps:

* created_at
* updated_at
* deleted_at

More sophisticated conflict resolution can be added later.

---

# 40. Security

Use Supabase Row Level Security.

Users must never gain unauthorized access to other users' data by modifying client requests.

All access to shared profiles must be enforced by backend authorization policies, not only hidden in the Flutter UI.

Financial data must be treated as sensitive.

---

# 41. Data portability

CSV export is optional for the MVP.

Implement it only if it is straightforward and does not delay the core application.

Otherwise leave it for a later iteration.

---

# 42. Design direction

Gainly should feel:

* modern
* motivating
* approachable
* mature
* clean
* visual
* fast

Take inspiration from Duolingo's habit-building principles, not from its childish aesthetic.

Avoid:

* overloaded financial dashboards
* excessive buttons
* overly complex banking interfaces
* excessive gamification

Prioritize:

* strong hierarchy
* large readable financial numbers
* simple cards
* clear feedback
* meaningful color
* short animations for achievements
* easy interaction

---

# 43. MVP scope

MVP priorities:

1. Flutter project foundation
2. Supabase setup
3. authentication
4. localization
5. onboarding
6. Balance
7. Performance Balance
8. Starting Balance
9. Starting Performance Balance
10. categories
11. sources
12. income transactions
13. expense transactions
14. detailed entry mode
15. quick entry mode
16. transaction history
17. search and filters
18. edit/delete
19. Calendar
20. Dashboard
21. statistics
22. monthly target
23. Daily Minimum
24. dynamic target calculation
25. Smart Insights
26. notifications
27. offline-first support
28. cross-device synchronization
29. linked profiles
30. sharing permissions
31. basic comparison
32. basic streaks

---

# 44. Future features — NOT MVP

Do not prioritize these during initial development:

* Open Banking
* automatic bank transaction import
* advanced tax tools
* receipt OCR
* Apple Watch
* advanced widgets
* complex XP
* leagues
* public leaderboards
* complex gamification
* multi-currency accounting
* complex shared household accounting

The architecture may anticipate them, but they must not slow the MVP.

---

# 45. Product principle

Gainly should always prioritize:

**clarity → consistency → financial awareness → corrective action**

The application should help users quickly see:

* what they earned
* what they spent
* whether the day was positive
* whether their overall performance is improving
* whether they are on track for their target
* what corrective action may help tomorrow
