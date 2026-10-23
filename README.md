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

### Web-editable menu categories

Use `categories/{categoryId}` for menu categories. Required fields are
`name` (string), `iconKey` (string), and `sortOrder` (number). Supported icon
keys are `milktea`, `coffee`, `snacks`, `frappe`, `fruitTea`, and `default`.
Use stable document IDs such as `milktea`, `coffee`, `snacks`, `frappe`, and
`fruit_tea`; product documents should refer to these IDs in `categoryId` or
`categories`. Changes are read live and update Home, Categories, Search, and
product category matching. If the collection is empty, the app keeps its
built-in starter categories until web-managed category documents exist.
Mobile implementation: `lib/data/menu_category_repository.dart`,
`lib/data/menu_catalog.dart`, and `lib/screens/main_interface_screen.dart`.

Example document `categories/coffee`:

```json
{
  "name": "Coffee",
  "iconKey": "coffee",
  "sortOrder": 2,
  "updatedAt": "<Firestore server timestamp>"
}
```

Active promotion cards and promotion notifications use documents in
`advertisements` with `title`, `eyebrow`, `description`, `buttonLabel`,
`imageUrl`, `isActive`, `sortOrder`, and optional `productId`. The admin app
should write to this same collection for promotion changes to appear on mobile.
The carousel is hidden until at least one active promotion is available. Upload
a square 800 × 800 px image (or larger, with the same 1:1 aspect ratio) and set
`imageUrl` to its public HTTPS URL. The mobile card shows a small right-aligned
image tile (about 126 × 128 px on regular screens, 88 × 110 px on narrow
screens) using a cover crop; keep the main product or artwork centered and avoid
placing important text close to the image edges. The full card is about 158 px
high on regular screens and 190 px on narrow screens.

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
(string), `message` (string), `type` (`Promotion` or `System`), `isActive`
(boolean), `sortOrder` (number), and optional `iconKey` (`notifications`,
`coffee`, `cardGift`, or `localOffer`). Notification read state is stored per
customer at
`users/{uid}/notificationReads/notification-{notificationId}`. Order status
notifications are generated from the customer's live `orders` records, and
promotions continue to be generated from active `advertisements`.
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
uses the configured prices in cart and order totals. Selected prices are saved
with each order line so later admin price changes do not alter an existing
cart/order. The admin app should create, edit, and disable options by writing
the same collection/document fields; the mobile repository also exposes
`saveAddIn` and `saveAddOn` for authorized writers. Firestore Rules should allow
clients to read these collections and restrict writes to authorized admins.

Per-user notification read state is stored at
`users/{uid}/notificationReads/{notificationId}`. The deployed Firestore
Security Rules allow signed-in users to read the app catalog and configuration
collections, limit profiles, notification state, favorites, ratings, and orders
to their owner, and restrict shared configuration writes to active admins.
Rules are maintained in `firestore.rules` and configured in `firebase.json`.
Deploy updates from the project directory with
`firebase deploy --only firestore:rules`. The web admin client must use this
same Firebase project and an authenticated account recognized as an active
admin by `isActiveAdmin()`.

New customer profiles are created at `users/{uid}` by
`lib/screens/register_screen.dart` with `name`, `email`, `phone`, `isActive`,
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
