# kkopiconnect_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase data used by the app

Customers can use **Continue as guest** on the login screen without creating
an email/password account. This uses Firebase Anonymous Authentication to
securely associate orders with the current device session, and asks for the
customer name before opening the app. The name can still be updated at checkout.
Enable the
**Anonymous** provider under Firebase Console → Authentication → Sign-in
method. At checkout, the customer must provide a name; it is saved as
`customerName` on their order. Guest orders remain associated with that
anonymous session and are not transferred between devices unless the guest
registers from Settings. Registration links email/password credentials to the
existing guest account so its UID and orders are preserved.
If guest sign-in returns `admin-restricted-operation`, review the Firebase
Authentication settings to ensure user/account creation is allowed as well as
the Anonymous provider; this restriction cannot be resolved in the app code.

The mobile app listens to Firestore in real time. The `products` collection
accepts both the admin product shape (`basePrice`, `categoryId`, `isAvailable`)
and the web aliases (`price`, `category`, `available`). Each document should
also include `name`, `description`, and `imageUrl`; optional `sizes`,
`sugarLevels`, `isBestSeller`, `isNew`, and `isClassic` are parsed. Admin-only
fields such as `cloudinaryPublicId` and `updatedAt` may also be stored in the
same document. Product edits are reflected by the live collection listener.
If the menu is empty, the Home and Categories screens show whether Firestore
returned no `products` documents, returned documents that failed the app's
availability/schema checks, or rejected the read with a Firebase error code.
Confirm the Firebase Console is open to project `kkopiconnect-2f015`; for
`permission-denied`, verify the user is signed in, the deployed Firestore rules
allow signed-in product reads, and App Check enforcement is configured for the
app's Android package and signing certificate. A Firestore read does not create
or restore deleted documents.

### Web-editable menu categories

Use `categories/{categoryId}` for menu categories. Required fields are
`name` (string), `iconKey` (string), and `sortOrder` (number). The built-in
categories are `iced_lattes` (Iced Lattes, `icedLattes`), `bubble_teas`
(Bubble Teas, `bubbleTeas`), `fruit_teas` (Fruit Teas, `fruitTea`),
`non_caffeine` (Non Caffeine, `nonCaffeine`), and `amerikano` (Amerikano,
`amerikano`). `default` is also supported as an icon key. “All” is a
customer-facing filter and should not be created as a category document.
Product documents should refer to category document IDs in `categoryId` or
`categories`. Changes are read live and update Home, Categories, Search, and
product category matching. The web admin can rename, reorder, and manage these
categories by editing this collection. While only the previous built-in IDs
are present, the app displays the new built-in lineup and maps the old product
category values to the closest new category. Remove obsolete category
documents when adding the new IDs so they do not appear alongside the new
lineup. If the collection is empty, the app keeps its built-in categories.
Mobile implementation: `lib/data/menu_category_repository.dart`,
`lib/data/menu_catalog.dart`, and `lib/screens/main_interface_screen.dart`.

Example document `categories/iced_lattes`:

```json
{
  "name": "Iced Lattes",
  "iconKey": "icedLattes",
  "sortOrder": 1,
  "updatedAt": "<Firestore server timestamp>"
}
```

Active promotion cards and promotion notifications can use documents in
`advertisements` or `promotions` with `title`, `eyebrow`, `description`,
`buttonLabel`, `imageUrl`, `isActive`, `sortOrder`, and a linked `productId`
(or `productIds` for compatibility). Optional `startAt` and `endAt` Firestore
timestamps control when a promotion is shown. `startAt` is inclusive and
`endAt` is exclusive; leave either field out for an open-ended schedule. The
mobile app watches both collections and follows the configured
`buttonActionType` and `buttonTarget`
when a campaign is selected. If no action type is configured, it opens the
linked `productId` directly; if it is empty, the first available product in
`productIds` is used. Promotion changes saved in either collection appear on
mobile.
Set `buttonActionType` to `product`, `category`, `menu`, `cart`, or `orders`
to control where the promotion's action goes. For `product` or `category`,
`buttonTarget` must be that Firestore document ID. If `buttonActionType` is
omitted, existing behavior is preserved: linked products open first, otherwise
the menu dashboard opens.
Use this copy-ready Firebase Web SDK format when adding or editing an
advertisement in the web admin. Promotion form entries can use the same fields
and are saved in the `promotions` collection. Change the text, image URL,
product IDs, and date values:

```javascript
import {
  Timestamp,
  doc,
  serverTimestamp,
  setDoc,
} from "firebase/firestore";

const startAt = new Date("2026-11-13T00:00:00+08:00");
const endAt = new Date("2026-11-16T00:00:00+08:00");

await setDoc(
  doc(db, "advertisements", "weekend-iced-latte-deal"),
  {
    title: "Weekend Iced Latte Deal",
    eyebrow: "THIS WEEKEND",
    description: "Get 20% off any iced latte from Friday through Sunday.",
    buttonLabel: "Browse the offer",
    buttonActionType: "product",
    buttonTarget: "iced-latte-product-id",
    imageUrl: "https://example.com/promotion-banner.jpg",
    imageUrls: ["https://example.com/promotion-banner.jpg"],
    isActive: true,
    sortOrder: 1,
    productId: "iced-latte-product-id",
    productIds: ["iced-latte-product-id"],
    isBuyOneTakeOne: false,
    startAt: Timestamp.fromDate(startAt),
    endAt: Timestamp.fromDate(endAt),
    updatedAt: serverTimestamp(),
  },
  { merge: true },
);
```

In the web admin, use date/time pickers and write `startAt` and `endAt` as
Firestore `Timestamp` values (not display-formatted strings). The notification
bell shows a red dot while there are unread active promotions, system
announcements, or orders; marking a notification read clears its corresponding
unread state.
The carousel is hidden until at least one active promotion is available. Upload
an image around 1600 × 700 px (about 2.3:1) and set `imageUrl` to its public
HTTPS URL. The image fills the entire carousel card with a cover crop. On a
typical 390 px-wide phone, the card is about 362 × 158 px; on narrow phones it
is about 190 px high and crops more from the sides. Keep the product or artwork
near the center with important details away from the edges. The Flutter web
build uses the same carousel; on very wide browser windows the cover crop is
more pronounced.

Search analytics are stored in `popularSearches` documents with `term`,
`searchCount`, and `updatedAt`. The app increments a document for each submitted
search and displays the most-searched terms. Recent searches are persisted with
device-local preferences and are not uploaded.

### Product favorites and community rating

Product hearts are saved to `users/{uid}/favoriteProducts/{productId}` so a
signed-in customer's favorites follow them between devices. Favorites are
private saves and do not affect star ratings.

The favorite access pattern is implemented in `firestore.rules` and deployed
with `firebase deploy --only firestore:rules`. Keep existing product, order,
and admin rules when changing the ruleset.

```text
function signedIn() {
  return request.auth != null;
}

function favoritePath(uid, productId) {
  return /databases/$(database)/documents/users/$(uid)/favoriteProducts/$(productId);
}

function likePath(productId, uid) {
  return /databases/$(database)/documents/productLikes/$(productId)/users/$(uid);
}

match /users/{uid}/favoriteProducts/{productId} {
  allow read: if signedIn() && request.auth.uid == uid;
  allow create: if signedIn()
    && request.auth.uid == uid
    && request.resource.data.keys().hasOnly(['productId', 'createdAt'])
    && request.resource.data.productId == productId
    && existsAfter(likePath(productId, uid));
  allow delete: if signedIn()
    && request.auth.uid == uid
    && !existsAfter(likePath(productId, uid));
  allow update: if false;
}

match /productLikes/{productId} {
  allow read: if signedIn();
  allow create: if signedIn()
    && request.resource.data.keys().hasOnly(['productId', 'favoriteCount', 'updatedAt'])
    && request.resource.data.productId == productId
    && request.resource.data.favoriteCount is int
    && request.resource.data.favoriteCount == 1
    && existsAfter(likePath(productId, request.auth.uid))
    && existsAfter(favoritePath(request.auth.uid, productId));
  allow update: if signedIn()
    && request.resource.data.keys().hasOnly(['productId', 'favoriteCount', 'updatedAt'])
    && request.resource.data.productId == productId
    && request.resource.data.favoriteCount is int
    && (
      (
        existsAfter(likePath(productId, request.auth.uid))
        && !exists(likePath(productId, request.auth.uid))
        && request.resource.data.favoriteCount == resource.data.favoriteCount + 1
        && existsAfter(favoritePath(request.auth.uid, productId))
      )
      ||
      (
        !existsAfter(likePath(productId, request.auth.uid))
        && exists(likePath(productId, request.auth.uid))
        && request.resource.data.favoriteCount == resource.data.favoriteCount - 1
        && !existsAfter(favoritePath(request.auth.uid, productId))
      )
    );
  allow delete: if false;

  match /users/{uid} {
    allow read: if signedIn() && request.auth.uid == uid;
    allow create: if signedIn()
      && request.auth.uid == uid
      && request.resource.data.keys().hasOnly(['uid', 'createdAt'])
      && request.resource.data.uid == uid
      && existsAfter(favoritePath(uid, productId))
      && existsAfter(/databases/$(database)/documents/productLikes/$(productId));
    allow delete: if signedIn()
      && request.auth.uid == uid
      && !existsAfter(favoritePath(uid, productId));
    allow update: if false;
  }
}
```

Star ratings are separate: each signed-in user can submit one 1–5 rating per
product and edit it later. The user's current rating is stored at
`productRatings/{productId}/users/{uid}`. The aggregate document at
`productRatings/{productId}` stores `ratingCount`, `ratingTotal`, and
`ratingAverage`; a Firestore transaction updates the user's rating and the
aggregate together. Product details show the live average, number of ratings,
and five tappable stars for the current user's editable rating. The Best
Selling section and chatbot rank products by average star rating (then number
of ratings); before products are rated, they fall back to the existing
admin-marked best sellers.

The deployed `firestore.rules` also includes the following rating access
pattern. `productRatings` summary documents are readable by the app, while
individual ratings are private to their author.

```text
function ratingPath(productId, uid) {
  return /databases/$(database)/documents/productRatings/$(productId)/users/$(uid);
}

match /productRatings/{productId} {
  allow read: if true;
  allow create: if request.auth != null
    && request.resource.data.keys().hasOnly(['productId', 'ratingCount', 'ratingTotal', 'ratingAverage', 'updatedAt'])
    && request.resource.data.productId == productId
    && request.resource.data.ratingCount == 1
    && request.resource.data.ratingTotal is int
    && request.resource.data.ratingTotal >= 1
    && request.resource.data.ratingTotal <= 5
    && request.resource.data.ratingAverage == request.resource.data.ratingTotal
    && existsAfter(ratingPath(productId, request.auth.uid))
    && getAfter(ratingPath(productId, request.auth.uid)).data.rating == request.resource.data.ratingTotal;
  allow update: if request.auth != null
    && request.resource.data.keys().hasOnly(['productId', 'ratingCount', 'ratingTotal', 'ratingAverage', 'updatedAt'])
    && request.resource.data.productId == productId
    && request.resource.data.ratingCount is int
    && request.resource.data.ratingCount >= 1
    && request.resource.data.ratingTotal is int
    && request.resource.data.ratingTotal >= request.resource.data.ratingCount
    && request.resource.data.ratingTotal <= request.resource.data.ratingCount * 5
    && request.resource.data.ratingAverage == request.resource.data.ratingTotal / request.resource.data.ratingCount
    && existsAfter(ratingPath(productId, request.auth.uid))
    && getAfter(ratingPath(productId, request.auth.uid)).data.rating >= 1
    && getAfter(ratingPath(productId, request.auth.uid)).data.rating <= 5
    && (
      (
        !exists(ratingPath(productId, request.auth.uid))
        && request.resource.data.ratingCount == resource.data.ratingCount + 1
        && request.resource.data.ratingTotal == resource.data.ratingTotal
          + getAfter(ratingPath(productId, request.auth.uid)).data.rating
      )
      ||
      (
        exists(ratingPath(productId, request.auth.uid))
        && (
          (
            get(ratingPath(productId, request.auth.uid)).data.rating == getAfter(ratingPath(productId, request.auth.uid)).data.rating
            && request.resource.data.ratingCount == resource.data.ratingCount
            && request.resource.data.ratingTotal == resource.data.ratingTotal
          )
          ||
          (
            get(ratingPath(productId, request.auth.uid)).data.rating != getAfter(ratingPath(productId, request.auth.uid)).data.rating
            && request.resource.data.ratingCount == resource.data.ratingCount
            && request.resource.data.ratingTotal == resource.data.ratingTotal
              - get(ratingPath(productId, request.auth.uid)).data.rating
              + getAfter(ratingPath(productId, request.auth.uid)).data.rating
          )
        )
      )
    );
  allow delete: if false;

  match /users/{uid} {
    allow read: if request.auth != null && request.auth.uid == uid;
    allow create: if request.auth != null
      && request.auth.uid == uid
      && request.resource.data.keys().hasOnly(['uid', 'rating', 'updatedAt'])
      && request.resource.data.uid == uid
      && request.resource.data.rating is int
      && request.resource.data.rating >= 1
      && request.resource.data.rating <= 5
      && existsAfter(/databases/$(database)/documents/productRatings/$(productId));
    allow update: if request.auth != null
      && request.auth.uid == uid
      && request.resource.data.keys().hasOnly(['uid', 'rating', 'updatedAt'])
      && request.resource.data.uid == uid
      && request.resource.data.rating is int
      && request.resource.data.rating >= 1
      && request.resource.data.rating <= 5
      && exists(/databases/$(database)/documents/productRatings/$(productId));
    allow delete: if false;
  }
}
```

Mobile implementation: `lib/data/product_favorites_repository.dart`,
`lib/data/product_rating_repository.dart`, `lib/state/favorites_store.dart`,
`lib/state/product_ratings_store.dart`, and
`lib/screens/product_detail_screen.dart`.

### Web-managed notifications and payment methods

Create `notifications/{notificationId}` documents to manage the non-order
messages shown in the Notifications screen. Required fields are `title`
(string), `type` (`Promotion`/`promotion` or `System`/`system`), and `isActive`
(boolean). `message` (string) is required for `System` notifications;
`Promotion` notifications may use `message` or `description`. Optional
`sortOrder` (number) and `iconKey` (`notifications`, `coffee`, `cardGift`, or
`localOffer`) control display. Notification read state is stored per customer at
`users/{uid}/notificationReads/notification-{notificationId}`. Dismissed
notifications are stored in the same document with `isDismissed` set to `true`,
so they stay hidden when the customer leaves and reopens Notifications. Order
status notifications are generated from the customer's live `orders` records,
and promotions saved by the admin to `notifications` appear in the Promotion
filter. Promotion cards in the home carousel continue to use active
`advertisements`. Notification documents are public broadcast content and are
readable without signing in; only active administrators can create, update, or
delete them.
Mobile implementation: `lib/data/app_notification_repository.dart` and
`lib/screens/notifications_screen.dart`.

Example document `notifications/new-menu`:

```json
{
  "title": "New Menu",
  "message": "Try our new drink.",
  "type": "System",
  "isActive": true,
  "sortOrder": 1,
  "iconKey": "coffee",
  "updatedAt": "<Firestore server timestamp>"
}
```

Push alerts are sent by the trusted Firebase Functions backend. An active
notification created, activated, or updated with a new title/message (or a
promotion's description) and an active advertisement created, activated, or
updated with a new title/description are sent to registered devices. New
orders and order-status changes are sent only to that customer's devices. The
app stores each signed-in device's FCM token at
`users/{uid}/fcmTokens/{token}`. Existing notifications are not sent
retroactively. In the foreground, the app displays the push as a snackbar;
when backgrounded, Android/iOS display the system notification. Selecting an
order push opens Orders; other pushes open Notifications. Android uses the
`kkopi_updates` notification channel.

Deploy the backend and its token-write rule updates from the project directory:

```powershell
cd functions
npm install
npm test
cd ..
firebase deploy --only functions,firestore:rules
```

Cloud Functions deployment requires the Firebase project to use the Blaze
billing plan and the Firebase CLI to be signed in to `kkopiconnect-2f015`.
Install a new mobile build and allow notification permission on the device.
On Android 13 and later, notification permission must be granted in the system
prompt or app settings. Verify the device has a document in
`users/{uid}/fcmTokens` before testing. The Firebase Functions must be deployed:
without them, Firestore changes do not send push notifications.
For iOS, enable the Push Notifications capability and upload an APNs
authentication key in Firebase Console → Project settings → Cloud Messaging.
Mobile implementation: `lib/services/push_notification_service.dart`;
backend triggers: `functions/index.js`.

Create `paymentMethods/{methodId}` documents to control the choices presented
in Settings and checkout. Required fields are `name` (string), `isActive`
(boolean), and `sortOrder` (number); optional `instructions` (string) is shown
under the method name. Example `paymentMethods/gcash`:

```json
{
  "name": "GCash",
  "isActive": true,
  "sortOrder": 1,
  "instructions": "Pay using the GCash details shown by staff.",
  "updatedAt": "<Firestore server timestamp>"
}
```

When `paymentMethods` has no documents, the app uses its two built-in methods
(`Pay At The Counter` and `Gcash`). Once the web admin creates documents, those
documents become the source of truth; keep at least one active. The Settings
payment-method choice is an in-app preference; the checkout selection is saved
on each order. Mobile implementation:
`lib/data/payment_method_repository.dart`, `lib/screens/profile_screen.dart`,
and `lib/screens/order_type_screen.dart`.

Drink customization options are managed in two collections:
`drinkAddIns` for add-ins / personalizations and `drinkAddOns` for add-ons.
Each document uses `name` (string), `price` (non-negative number),
`isAvailable` (boolean), `sortOrder` (number), and `updatedAt` (server
timestamp). The mobile client listens to these collections in real time and
uses configured add-on prices in cart and order totals. Selected prices are
saved with each order line so later admin price changes do not alter an
existing cart/order. The admin app should create, edit, and disable options by
writing the same collection/document fields; the mobile repository also
exposes `saveAddIn` and `saveAddOn` for authorized writers. The customer app
shows the global `drinkAddOns` options for products in `non_caffeine`. Products
can also define their own `addons` array of `{name, price}` maps in the product
document; these product-specific options are shown for that product in any
category and take precedence over the global list. Firestore Rules should allow
clients to read these collections and restrict writes to authorized admins.

Per-user notification read state is stored at
`users/{uid}/notificationReads/{notificationId}`; dismissed entries also set
`isDismissed` to `true`. Deploy the rules in `firestore.rules` to allow this
field. The deployed Firestore Security Rules allow signed-in users to read the
app catalog and configuration collections, limit profiles, notification state,
favorites, ratings, and orders to their owner, and restrict shared configuration
writes to active admins. Rules are maintained in `firestore.rules` and
configured in `firebase.json`. Deploy updates from the project directory with
`firebase deploy --only firestore:rules`. The web admin client must use this
same Firebase project and an authenticated account recognized as an active
admin by `isActiveAdmin()`.

New customer profiles are created at `users/{uid}` by
`lib/screens/register_screen.dart` with `name`, `email`, `isActive`,
`createdAt`, and `updatedAt`. The Settings screen listens to this document for
web-managed name changes; profile-photo URLs are stored in both Firebase Auth
and the `photoUrl` field. Mobile implementation:
`lib/screens/profile_screen.dart`.

For web-editable content, signed-in app users have read access to
`categories`, `notifications`, and `paymentMethods`. Writes to those
collections are restricted to active admins recognized by `isActiveAdmin()`.
The web admin must sign in with an account that has an active admin document
in `admins/{uid}` with an `admin` or `Administrator` role.

Do not grant mobile users admin writes to these shared configuration
collections.

Orders are written to `orders/{orderId}` by
`lib/data/order_repository.dart`. This is the shared mobile/admin contract:
the document contains `id` and `orderId` (both the document ID, formatted as
`#KK001`, `#KK002`, and so on), `userId` and `customerId` (both the Firebase
Auth UID), `customerName`, `customerEmail`,
`items`, `fulfillment` and `orderType` (same value: `Pickup` or `Dine In`),
`paymentMethod`, `instructions`, `status`, `total`, `createdAt` (Firestore
server timestamp), and `updatedAt` (Firestore server timestamp). Each item
contains product identity/details, quantity, size, sugar and ice selections,
selected extras and their saved prices, and line total. The admin app should
listen to the `orders` collection and display the `orderId` field directly
without adding another `#` prefix. Existing orders retain their timestamp-based
IDs and remain readable. The admin app should change the shared `status` field
on the existing document to publish status updates to the customer app in real
time; do not create a second order collection or replace the document.

A signed-in customer can create an order whose `userId` matches their Firebase
Auth UID, read only their own orders, and update only their own `status` to
`Cancelled`. The deployed rules are maintained in `firestore.rules`; deploy
updates with `firebase deploy --only firestore:rules`.

The app increments `metadata/orderCounter` and creates the order in one
Firestore transaction. The checked-in rules grant signed-in users the counter
access needed for that transaction and restrict customer order reads,
cancellations, and deletions to their own eligible orders.

Admin status changes should be made by a trusted server using the Firebase
Admin SDK, not by allowing clients to update arbitrary order fields. If placing
an order reports `permission-denied`, check this match and the Firebase Console
App Check enforcement settings for the app.

The assistant uses Groq (`openai/gpt-oss-120b`) through a Cloudflare Worker.
The Worker verifies Firebase sign-in tokens and limits each account to 10
requests per minute. Store the Groq API key only as a Cloudflare Worker secret;
never add it to the Flutter app or source control.

To deploy the Worker on Cloudflare's free Workers plan:

1. Revoke any Groq API key that has been shared publicly, then create a new
   Groq key. Free API access and model quotas are controlled by Groq and may
   change.
2. In a terminal, change to `cloudflare` and install its dependencies:
   `cd cloudflare` then `npm install`.
3. Sign in to Cloudflare with `npx wrangler login`.
4. Add the Groq key as a Worker secret with `npx wrangler secret put GROQ_API_KEY`.
   Enter the key only at Wrangler's prompt.
5. Deploy with `npx wrangler deploy`. Wrangler prints the Worker URL.
6. From the project root, build the app with the actual URL printed in step 5:
   `flutter build apk --release` (the deployed Worker URL is the default; override it with `--dart-define=GROQ_WORKER_URL=https://kkopiconnect-groq-chat.<account-subdomain>.workers.dev` only when using a different Worker)

Cloudflare's free plan currently includes up to 100,000 Worker requests per day
and a 10 ms CPU limit per invocation; limits can change. See the
[Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/)
and [platform limits](https://developers.cloudflare.com/workers/platform/limits/).
Groq free-tier limits also apply and may change. If your Cloudflare account
already uses the rate-limit namespace ID in `cloudflare/wrangler.jsonc`, change
it to another unique positive integer before deployment.
