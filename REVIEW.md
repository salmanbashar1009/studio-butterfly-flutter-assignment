# Code Review: `sms_console.dart`

This document contains a comprehensive code review of the starter implementation in `starter/lib/sms_console.dart` compared against the `API-CONTRACT.md`. The starter implementation contains multiple critical defects that make it unsafe and unfit for production.


## Detailed Findings

### Finding 1: Production API Key Hardcoded in Source Code
* **Severity:** Critical
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 9
* **Problem description:** The live API key (credentials) is hardcoded directly into the Flutter source code (`const String kApiKey = 'fw_live_8c21e0b47ad94f13ba77e0c9d51a3b62';`).
* **Technical explanation:** Hardcoding credentials in source code compiles them into the client binary (APK, IPA, or JS bundle). Decompiling the app (e.g., using jadx or running `strings` on the binary) makes extracting this API key trivial.
* **Why it is dangerous:** The key is a live credentials token (`fw_live_...`). If the key is leaked, malicious actors can use it to access the backend directly.
* **Real-world impact:** Attackers can hijack the account to send bulk spam, phishing SMS campaigns, or exhaust the corporate Twilio/AWS balance, costing the business thousands of dollars and leading to account suspension and brand damage.
* **Recommended fix:** Remove hardcoded credentials. Inject configuration values at build time using `--dart-define` or retrieve credentials securely from a server session after user authentication.

---

### Finding 2: Missing Required `X-Tenant-Id` Header
* **Severity:** Critical
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 46-49, 71-78, 125-128
* **Problem description:** The API requests do not include the `X-Tenant-Id` header.
* **Technical explanation:** The API contract states: *"Both headers are required on every call. A request without `X-Tenant-Id`, or with a tenant the token does not grant, returns `403`."* The starter code defines `const String kTenantId` but never appends it to the headers map in `http.get` or `http.post`.
* **Why it is dangerous:** Running the application in production will fail immediately at the API gateway layer due to missing required tenant validation.
* **Real-world impact:** The application is completely broken. Users will receive `403 Forbidden` errors for every operation, rendering the screen completely non-functional.
* **Recommended fix:** Ensure every request incorporates the `'X-Tenant-Id': kTenantId` header.

---

### Finding 3: Insecure Static Global App State
* **Severity:** High
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 12-16
* **Problem description:** App state is managed using static fields in a global `AppState` class.
* **Technical explanation:** Static fields in Dart exist for the entire lifecycle of the application process. Because they are not bound to a widget lifecycle or session, their state persists until the OS terminates the application.
* **Why it is dangerous:** If a user logs out and another logs in (or if the application supports switching tenants), the previous tenant's data (`history`, `totalCost`) remains cached in memory and visible.
* **Real-world impact:** Cross-tenant data leakage, displaying confidential communication cost structures of tenant A to tenant B. It also makes testing impossible because tests share the same global state, causing side-effects.
* **Recommended fix:** Migrate to a modern state management solution (e.g., Riverpod or Bloc) with scoped containers that clean up state on tenant changes.

---

### Finding 4: Inexact Floating-Point Math for Monetary Calculations
* **Severity:** Critical
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 13, 18-22, 53-56, 83, 85
* **Problem description:** Monetary values are modeled and calculated using double-precision floating-point numbers (`double`).
* **Technical explanation:** Floating-point numbers (IEEE 754) cannot represent base-10 fractional values accurately. Accumulating double precision values (e.g., `0.0079 * 3` or adding multiple decimals) leads to precision drift (e.g., yielding `0.023700000000000002`).
* **Why it is dangerous:** The API contract specifies that rates run to 4 decimal places (`0.0079`) and must be calculated exactly. Using floats for accounting leads to math errors that compound over hundreds of thousands of transactions.
* **Real-world impact:** Discrepancy between invoice calculations on the client vs. the backend. The business will either overbill or underbill customers, violating accounting regulations and damaging customer trust.
* **Recommended fix:** Represent monetary values as integer cents (or micro-cents, e.g., value * 10,000 for 4-decimal rates) or use a precise decimal library like `decimal` to ensure exact calculations.

---

### Finding 5: Type Cast Crash on String Money Value
* **Severity:** Critical
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 55
* **Problem description:** The starter code casts the backend's `totalCost` field directly to a double: `(costRows[i]['totalCost'] as double)`.
* **Technical explanation:** The API contract specifies that `totalCost` (and other cost fields) are sent as a *"decimal STRING, never a float"* (e.g., `"12.4500"`). In Dart, performing `as double` on a `String` throws a runtime `TypeError` (`String is not a subtype of double`).
* **Why it is dangerous:** Unconditional casting will fail immediately as soon as a non-null payload is returned.
* **Real-world impact:** The application will crash on the user's phone the moment the cost breakdown is returned from the server, causing a 100% crash rate for this feature.
* **Recommended fix:** Parse the decimal string to a precise integer/decimal using `int.parse` or `Decimal.parse()`.

---

### Finding 6: Attempting to Display Non-Existent Recipient Data
* **Severity:** Critical
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 140
* **Problem description:** The cost breakdown list view displays `rows[i]['recipient']`, which is not returned by the cost breakdown API.
* **Technical explanation:** The `/api/v1/sms/cost/breakdown` endpoint returns `rows` containing `provider`, `totalCost`, and `messageCount`. It does not contain `recipient` values. The API contract explicitly says: *"Note what is not here: recipient phone numbers. The cost endpoint never returns them. If your UI shows a phone number on this screen, it invented it."*
* **Why it is dangerous:** Accessing a non-existent key `recipient` will evaluate to `null`. Passing `null` to a `Text` widget in Flutter (or displaying unformatted/missing data) can trigger runtime exceptions or render broken UI.
* **Real-world impact:** The list item will display blank recipients, or crash the widget tree depending on the environment, violating contract definitions and providing a confusing user experience.
* **Recommended fix:** Separate the Cost Breakdown UI from the Message History UI. Get the message history list from the `/api/v1/sms/messages` endpoint which does contain masked recipients.

---

### Finding 7: Hardcoded SMS Segment Count
* **Severity:** High
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 82
* **Problem description:** The number of SMS segments is hardcoded to 1 when estimating local transaction costs.
* **Technical explanation:** In telecom, messages are split into multiple segments depending on encoding and length (e.g., exceeding 160 characters for GSM-7 or 70 characters for Unicode). The contract specifies that `segmentCount` is dynamic and returned in the response. Hardcoding it to 1 ignores multi-segment costs.
* **Why it is dangerous:** The cost calculated on the client will be far lower than the actual cost billed by the backend, leading to client-side data mismatch.
* **Real-world impact:** Users are misinformed about the actual costs they incurred. If a user sends a long message of 3 segments, the app will charge them for 1 segment locally but they will be billed for 3 on their invoice.
* **Recommended fix:** Retrieve and use the `segmentCount` from the send SMS API response: `final segments = result['segmentCount'] as int;`.

---

### Finding 8: Hardcoded Frontend SMS Rates
* **Severity:** High
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 18-22
* **Problem description:** SMS rates for providers (Twilio, Vonage, AWS SNS) are hardcoded in the Flutter frontend inside the `rateFor` function.
* **Technical explanation:** SMS pricing is highly dynamic and subject to frequent changes based on carrier fees, geographic routing, and provider price hikes. Hardcoding rates locally requires an app update every time prices change.
* **Why it is dangerous:** The app computes local costs based on outdated static rates, drifting from actual backend billing.
* **Real-world impact:** The transaction costs shown immediately after sending a message will not match the cost computed by the backend, causing client-server financial discrepancies.
* **Recommended fix:** Do not compute rates locally using hardcoded rules. Read the exact `cost` returned by the server response in `POST /api/v1/sms/send`: `"cost": "0.1500"`.

---

### Finding 9: Network Request Inside Widget Build Method
* **Severity:** High
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 124-128
* **Problem description:** A network call `http.get` is instantiated directly inside the `FutureBuilder`'s `future:` parameter.
* **Technical explanation:** In Flutter, the `build` method is invoked frequently (e.g., when the keyboard opens, orientation changes, or parent widgets rebuild). Placing a network request instantiation directly in the build method triggers a new HTTP call on every rebuild.
* **Why it is dangerous:** It creates a massive number of duplicate network calls, wastefully consuming user battery and cellular data.
* **Real-world impact:** The API server will quickly rate-limit the client with a `429 Too Many Requests` error, locking out the user and degrading overall server performance.
* **Recommended fix:** Execute the network request outside of the build phase. Bind the widget to a state container or cache the future in a state variable (e.g., in `initState` or using a state provider).

---

### Finding 10: Unhandled Network Failures and Errors
* **Severity:** High
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 46-51, 125-134
* **Problem description:** The responses from HTTP calls are parsed via `jsonDecode` directly without validating the status code.
* **Technical explanation:** If the API returns `502 Bad Gateway`, `429 Too Many Requests`, `401 Unauthorized`, or `500 Server Error`, the response body is not the expected success JSON structure. Attempting to parse the body as if it were a successful response will throw exceptions.
* **Why it is dangerous:** Unhandled failures cause silent app breakage or crashes. The user is left in an infinite loading state or a broken screen with no indication of what went wrong.
* **Real-world impact:** In unstable network environments, the app will hang or crash, providing zero feedback or retry actions for recovery.
* **Recommended fix:** Always inspect HTTP status codes. Handle exceptions, map them to semantic domain-level errors, and display informative error screens containing a "Retry" CTA.

---

### Finding 11: Memory Leaks due to Un-disposed Controllers
* **Severity:** Medium
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 32-33
* **Problem description:** `TextEditingController` objects are instantiated but never disposed of when the state is destroyed.
* **Technical explanation:** `TextEditingController` objects register listeners with the Flutter framework. If they are not disposed of, they remain in memory and continue listening, preventing the widget state from being garbage-collected.
* **Why it is dangerous:** Continuous leakage of widgets and controllers degrades device performance.
* **Real-world impact:** Users who open and close the SMS page multiple times will experience increasing memory usage, causing UI stuttering and eventually forcing the OS to terminate the app (OOM crash).
* **Recommended fix:** Override the `dispose` method in the widget state and call `.dispose()` on all controllers.

---

### Finding 12: Race Conditions and Unmounted State Check
* **Severity:** High
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 95
* **Problem description:** `setState` is invoked after asynchronous network calls without checking if the widget is still mounted.
* **Technical explanation:** In Dart, execution resumes after an `await` statement. If a user navigates away from the widget before the request completes, the widget will be unmounted. Calling `setState` on an unmounted state object throws a framework exception.
* **Why it is dangerous:** Floods crash reporting tools (e.g., Firebase Crashlytics) with unhandled exceptions and can lead to unexpected UI behavior or crashes.
* **Real-world impact:** If a user clicks send and immediately taps the back button, the app will throw a runtime exception, degrading stability metrics.
* **Recommended fix:** Check `if (!mounted) return;` before calling `setState` after any asynchronous operation.

---

### Finding 13: Hardcoded Currency Sign and UI Styling
* **Severity:** Medium
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 88, 122, 141
* **Problem description:** The Euro currency symbol `€` is hardcoded across the user interface.
* **Technical explanation:** The API contract states that the currency is dynamic and returned in the payload (e.g., `"currency": "EUR"`). Hardcoding `€` ignores this parameter.
* **Why it is dangerous:** Limits localizability. If a tenant operates in USD or GBP, the UI will display the Euro symbol but show numbers matching USD, resulting in incorrect financial presentation.
* **Real-world impact:** Users see incorrect currency symbols, which is confusing and makes the application look unprofessional.
* **Recommended fix:** Extract the `currency` code from the API response and format it using a locale-aware currency formatter.

---

### Finding 14: Inconsistent Overlapping Loading States
* **Severity:** Medium
* **File name:** `starter/lib/sms_console.dart`
* **Line number:** 44-61, 63-96
* **Problem description:** The loading states of `loadCosts` and `sendSms` overlap and mutate the same boolean, leading to UI glitches.
* **Technical explanation:** `sendSms` sets `loading = true`, then calls `loadCosts` which also sets `loading = true`. When `loadCosts` completes, it sets `loading = false`, but `sendSms` is still executing. When `sendSms` finally completes, it sets `loading = false` again. This causes race conditions and UI flickering.
* **Why it is dangerous:** The loading indicator can disappear while operations are still active.
* **Real-world impact:** The user might think the operation finished and tap "Send" again, causing double-sends of SMS messages due to lack of visual locks.
* **Recommended fix:** Manage state transitions using immutable states in a state management architecture, separating loading states for sending vs. fetching history/costs.
