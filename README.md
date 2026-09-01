# FoodExpress — Customer App (Flutter)

Flutter client for the Customer-facing REST API of the food delivery
backend (`Api/CustomerAuthApiController`, `CustomerApiController`,
`CartApiController`, `CheckoutApiController`, `OrderApiController`,
`ProfileApiController`).

**Order tracking now includes a live map** (matches the website, which
uses Leaflet + OpenStreetMap) — restaurant and delivery-partner markers
on a free OSM map via `flutter_map`, no Google Maps API key needed.

No local Flutter install needed to get an APK — GitHub Actions builds
it for you.

## 1. Backend URL

Already set to your live backend in `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'https://food.tvkomalur.xyz/api';
```

No change needed unless you move to a different domain.

## 2. Push this project to GitHub

```bash
git init
git add .
git commit -m "Customer app"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

(Create the empty repo on github.com first, if you don't have one.)

## 3. Get the APK

Pushing to `main` automatically triggers the **Build APK** GitHub
Actions workflow (`.github/workflows/build-apk.yml`):

1. Go to your repo → **Actions** tab
2. Open the latest **Build APK** run (takes ~4-6 min)
3. Scroll to **Artifacts** → download `customer-app-release-apk`
4. Unzip it → you get `app-release.apk`
5. Copy it to your Android phone and install it (enable "install from
   unknown sources" if prompted)

You can also trigger a build manually anytime from the Actions tab
using **Run workflow** (the `workflow_dispatch` trigger).

## Project structure

```
lib/
  config/api_config.dart      – backend base URL + endpoint paths
  models/                     – Category, Restaurant, MenuItem, CartItem, Address, Order
  services/                   – one file per backend API controller
  state/app_state.dart        – login state + cart badge count
  screens/
    auth/                     – login, register
    home/                     – categories, top restaurants, coupons
    restaurant/               – search + menu + add to cart
    cart/                     – cart screen
    checkout/                 – address select, coupon, place order
    orders/                   – order list + tracking (text timeline)
    profile/                  – profile + saved addresses
  widgets/root_shell.dart     – bottom navigation bar
```

## Notes
- Auth uses a Bearer token (`Authorization: Bearer <token>`), stored
  locally with `shared_preferences`, matching `BaseApiController` on
  the backend.
- Make sure CORS is allowed on the backend if you test with
  `flutter run` on a real device against a remote API — CodeIgniter
  needs `App\Filters\Cors` (or similar) enabled for the API group if
  not already.

## Design pass (matches the "Jeevi Foodie Delivery" mockup)
- Deep green + gold theme, splash screen, one-time onboarding screen,
  restyled login/signup, search bar + offer banner on Home, list-style
  restaurant cards with Open/Closed + discount badges, category tabs +
  a dedicated Food Detail screen on the restaurant menu, an "Order
  Placed Successfully" screen, tabbed Orders (All/Ongoing/Completed/
  Cancelled), and a redesigned Profile with a green header + menu
  (My Orders, Addresses, Payment Methods, Wallet, Logout).
- **Wallet is new** — the website has a wallet balance/history page but
  no mobile API for it, so an endpoint (`GET /customer/wallet`) was
  added, alongside making `payment_method=wallet` at checkout actually
  debit the balance (previously it was stored but never charged). Both
  changes are in `backend_api_update.zip` — deploy those before the
  wallet screen or wallet checkout option will work.
- **Live tracking map** — `GET /customer/orders/track/<code>` now also
  returns `restaurant_lat`/`restaurant_lng` alongside the existing
  partner `lat`/`lng`, so the map has something to center on even before
  a delivery partner is assigned. This is in `backend_api_update.zip`.
- **Left out on purpose:**
  - Google/Apple sign-in buttons from the mockup — the backend only
    has email/password auth, so these would be dead buttons.
  - Notifications, Help & Support, and a generic Settings screen —
    no backend support for these exists yet, so they're left off the
    Profile menu rather than added as non-functional links.

## Push Notifications (Firebase)

Customers get a push notification whenever their order's status
changes (confirmed, preparing, out for delivery, delivered, cancelled),
triggered from the delivery partner's app/dashboard and the admin
panel. Tapping the notification opens that order's tracking screen.

Without any setup, the app still works fine — it just skips push
notifications silently (see `main.dart`'s try/catch around
`Firebase.initializeApp()`). To turn it on:

### 1. Create a Firebase project
1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Add project** (free tier is enough).
2. Inside the project → **Add app** → Android → package name **exactly** `com.foodexpress.customer_app`.
3. Download the `google-services.json` it gives you.

### 2. Add the Android app config to GitHub Actions
```bash
base64 -w0 google-services.json   # macOS: base64 -i google-services.json
```
Copy the output, then on GitHub: repo → **Settings → Secrets and
variables → Actions → New repository secret**
- Name: `GOOGLE_SERVICES_JSON_BASE64`
- Value: the base64 string you copied

The workflow (`.github/workflows/build-apk.yml`) picks this up
automatically on the next build — no other change needed. If the
secret isn't set, that step is skipped and the app just builds without
push notifications.

### 3. Let the backend send notifications
1. Firebase Console → ⚙️ **Project Settings → Service Accounts → Generate new private key** → downloads a JSON file.
2. Upload that file to your server, **outside** the public webroot (e.g. next to, not inside, `public/`).
3. In your server's `.env`, set:
   ```
   firebase.projectId = your-firebase-project-id
   firebase.credentialsPath = /full/path/to/that-service-account-file.json
   ```
4. Deploy `backend_api_update.zip` (adds `PushNotificationService`,
   the `device_tokens` table/migration, and the notify hooks in the
   delivery-partner and admin order-status controllers).
5. Run the new migration on the server: `php spark migrate`.

That's it — no extra composer packages needed; the service mints its
own short-lived Google OAuth2 token from the service-account key using
just `curl` + `openssl`, and calls FCM's HTTP v1 send API directly.

### Sending a broadcast/promo notification ("50% off today!")
Order-status pushes go to one specific customer (their device token).
For general offers/announcements to *everyone*, the admin panel has
**Admin → Notifications** — type a title + message, optionally attach a
banner image, and it sends instantly to every customer's app (via the
`promotions` FCM topic, which the app subscribes every device to
automatically - no per-user looping needed). This is separate from
order-status notifications and does not target a specific customer or
order.

The banner image shows as a big picture in the notification whether
the app is open (drawn locally via `flutter_local_notifications`),
backgrounded, or fully closed (drawn by Android itself). Skip the
image field to send a plain text notification.
