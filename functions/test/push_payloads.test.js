const test = require("node:test");
const assert = require("node:assert/strict");
const {
  advertisementPayload,
  announcementPayload,
  orderPayload,
} = require("../src/push_payloads");

test("active admin announcements produce a push payload", () => {
  assert.deepEqual(
    announcementPayload("new-menu", null, {
      title: "New menu",
      message: "Try our new drinks.",
      isActive: true,
    }),
    {
      notification: {
        title: "New menu",
        body: "Try our new drinks.",
      },
      data: {
        type: "announcement",
        notificationId: "new-menu",
      },
    },
  );
});

test("active promotion notifications accept description and lowercase type", () => {
  assert.deepEqual(
    announcementPayload("new-promotion", null, {
      title: "New promotion",
      description: "Save on iced lattes this week.",
      type: "promotion",
      isActive: true,
    }),
    {
      notification: {
        title: "New promotion",
        body: "Save on iced lattes this week.",
      },
      data: {
        type: "announcement",
        notificationId: "new-promotion",
      },
    },
  );
});

test("promotion notification description edits trigger an updated push", () => {
  const before = {
    title: "New promotion",
    description: "Save this week.",
    type: "Promotion",
    isActive: true,
  };
  const after = { ...before, description: "Save this weekend." };

  assert.equal(
    announcementPayload("new-promotion", before, after).notification.body,
    "Save this weekend.",
  );
});

test("announcement pushes include optional release metadata", () => {
  const before = {
    title: "App update",
    message: "Performance improvements.",
    imageUrl: "https://example.com/old.png",
    version: "2.0.0",
    isActive: true,
  };
  const after = {
    ...before,
    imageUrl: "https://example.com/update.png",
    version: "2.1.0",
  };

  assert.deepEqual(
    announcementPayload("release-2-1-0", before, after),
    {
      notification: {
        title: "App update",
        body: "Performance improvements.",
      },
      data: {
        type: "announcement",
        notificationId: "release-2-1-0",
        imageUrl: "https://example.com/update.png",
        version: "2.1.0",
      },
    },
  );
});

test("active promotions produce a push payload", () => {
  assert.deepEqual(
    advertisementPayload("weekend-promo", null, {
      title: "Weekend offer",
      description: "Save on iced lattes this weekend.",
      isActive: true,
    }),
    {
      notification: {
        title: "Weekend offer",
        body: "Save on iced lattes this weekend.",
      },
      data: {
        type: "promotion",
        advertisementId: "weekend-promo",
      },
    },
  );
});

test("promotion action changes produce a push with the configured destination", () => {
  const before = {
    title: "Weekend offer",
    description: "Save on iced lattes.",
    isActive: true,
    buttonLabel: "Browse menu",
    buttonActionType: "menu",
    buttonTarget: "",
  };
  const after = {
    ...before,
    buttonLabel: "Order now",
    buttonActionType: "product",
    buttonTarget: "iced-latte",
  };

  assert.deepEqual(
    advertisementPayload("weekend-promo", before, after).data,
    {
      type: "promotion",
      advertisementId: "weekend-promo",
      buttonLabel: "Order now",
      buttonActionType: "product",
      buttonTarget: "iced-latte",
    },
  );
});

test("unchanged or inactive announcements do not send a push", () => {
  const announcement = {
    title: "New menu",
    message: "Try our new drinks.",
    isActive: true,
  };
  assert.equal(announcementPayload("new-menu", announcement, announcement), null);
  assert.equal(
    announcementPayload("new-menu", null, {
      ...announcement,
      isActive: false,
    }),
    null,
  );
  assert.equal(
    advertisementPayload(
      "weekend-promo",
      { title: "Weekend offer", description: "Save now.", isActive: true },
      { title: "Weekend offer", description: "Save now.", isActive: true },
    ),
    null,
  );
});

test("order creation and status changes notify only the owning user", () => {
  const created = orderPayload("KK001", null, {
    userId: "customer-1",
    fulfillment: "Pickup",
    status: "Pending",
  });
  assert.equal(created.userId, "customer-1");
  assert.equal(created.message.data.type, "order_status");
  assert.match(created.message.notification.body, /pickup order KK001 is pending/);

  assert.equal(
    orderPayload(
      "KK001",
      { userId: "customer-1", status: "Preparing" },
      { userId: "customer-1", status: "Preparing" },
    ),
    null,
  );
});
