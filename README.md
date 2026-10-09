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
`users/{uid}/notificationReads/{notificationId}`. Firestore Security Rules must
allow each signed-in user to read and write only their own notification state,
allow clients to read product and active-promotion data, allow signed-in users
to query and increment search counts in `popularSearches`, and restrict
product/category/promotion/notification/payment-method/option writes to
authorized admin accounts. Signed-in users need read access to active
categories, notifications, and payment methods. The mobile
project does not contain Firestore rules; configure these in the Firebase
project before expecting live reads or writes to work.

New customer profiles are created at `users/{uid}` by
`lib/screens/register_screen.dart` with `name`, `email`, `phone`, `isActive`,
`createdAt`, and `updatedAt`. The Settings screen listens to this document for
web-managed name changes; profile-photo URLs are stored in both Firebase Auth
and the `photoUrl` field. Mobile implementation:
`lib/screens/profile_screen.dart`.

For web-editable content, signed-in app users need read access to
`categories`, `notifications`, and `paymentMethods`. Only the authorized web
admin should write those collections. If the Firebase project uses custom
claims, an admin-only write condition can be based on
`request.auth.token.admin == true`; assign that claim from a trusted
Admin-SDK environment. Merge collection-specific rules into the current rules
instead of replacing the full ruleset. Example rule fragments:

```text
function signedIn() {
  return request.auth != null;
}

function isAdmin() {
  return signedIn() && request.auth.token.admin == true;
}

match /categories/{categoryId} {
  allow read: if signedIn();
  allow write: if isAdmin();
}

match /notifications/{notificationId} {
  allow read: if signedIn();
  allow write: if isAdmin();
}

match /paymentMethods/{methodId} {
  allow read: if signedIn();
  allow write: if isAdmin();
}
```

Do not grant mobile users admin writes to these shared configuration
collections. For each signed-in user, separately permit read/write of only
their own `users/{uid}/notificationReads/{notificationId}` documents.

Orders are written to `orders/{orderId}` by
`lib/data/order_repository.dart`. This is the shared mobile/admin contract:
the document contains `id` and `orderId` (both the document ID), `userId` and
`customerId` (both the Firebase Auth UID), `customerName`, `customerEmail`,
`items`, `fulfillment` and `orderType` (same value: `Pickup` or `Dine In`),
`paymentMethod`, `instructions`, `status`, `total`, `createdAt` (Firestore
server timestamp), and `updatedAt` (Firestore server timestamp). Each item
contains product identity/details, quantity, size, sugar, selected extras and
their saved prices, and line total. The admin app should listen to the
`orders` collection and change the shared `status` field on the existing
document to publish status updates to the customer app in real time; do not
create a second order collection or replace the document.

A signed-in customer must be permitted to create an order whose `userId`
matches their Firebase Auth UID, read only their own orders, and update only
their own `status` to `Cancelled`.
For example, merge the following match into the Firebase project's existing
Firestore rules (do not replace rules for other collections):

```text
match /orders/{orderId} {
  allow create: if request.auth != null
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.id == orderId
    && request.resource.data.status == 'Pending';
  allow read: if request.auth != null
    && resource.data.userId == request.auth.uid;
  allow update: if request.auth != null
    && resource.data.userId == request.auth.uid
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status'])
    && request.resource.data.status == 'Cancelled';
}
```

Admin status changes should be made by a trusted server using the Firebase
Admin SDK, not by allowing clients to update arbitrary order fields. If placing
an order reports `permission-denied`, check this match and the Firebase Console
App Check enforcement settings for the app.

The assistant uses Firebase AI Logic with `gemini-2.5-flash`. Enable Firebase AI
Logic for the configured Firebase project and register the Android debug
App Check token printed by a debug run in Firebase Console > App Check before
testing AI requests on a debug device.
