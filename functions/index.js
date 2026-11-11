const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { setGlobalOptions } = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {
  advertisementPayload,
  announcementPayload,
  orderPayload,
} = require("./src/push_payloads");

initializeApp();
setGlobalOptions({ region: "asia-southeast1" });

const db = getFirestore();
const maxTokensPerRequest = 500;
const maxDeliveryAttempts = 3;

async function sendToTokenDocuments(tokenDocuments, message) {
  const messaging = getMessaging();
  for (let start = 0; start < tokenDocuments.length; start += maxTokensPerRequest) {
    let pending = tokenDocuments.slice(start, start + maxTokensPerRequest);
    for (let attempt = 0; pending.length > 0 && attempt < maxDeliveryAttempts; attempt++) {
      const response = await messaging.sendEachForMulticast({
        ...message,
        android: {
          ...message.android,
          notification: {
            ...message.android?.notification,
            channelId: "kkopi_updates",
          },
        },
        tokens: pending.map(
          (document) => document.get("token") || document.id,
        ),
      });

      const invalidTokens = [];
      const retryTokens = [];
      response.responses.forEach((result, index) => {
        if (result.success) return;
        const code = result.error?.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(pending[index].ref);
        } else {
          retryTokens.push(pending[index]);
          console.error(
            "FCM delivery failed:",
            pending[index].ref.path,
            code || result.error?.message,
          );
        }
      });

      if (invalidTokens.length > 0) {
        const cleanup = db.batch();
        for (const reference of invalidTokens) cleanup.delete(reference);
        await cleanup.commit();
      }

      pending = retryTokens;
      if (pending.length > 0 && attempt + 1 < maxDeliveryAttempts) {
        await new Promise((resolve) =>
          setTimeout(resolve, 500 * (2 ** attempt)),
        );
      }
    }

    if (pending.length > 0) {
      throw new Error(
        `FCM delivery failed after ${maxDeliveryAttempts} attempts for ${pending.length} token(s).`,
      );
    }
  }
}

async function sendToAllDevices(message) {
  const tokenSnapshot = await db.collectionGroup("fcmTokens").get();
  await sendToTokenDocuments(tokenSnapshot.docs, message);
}

async function sendToUser(userId, message) {
  const tokenSnapshot = await db
    .collection("users")
    .doc(userId)
    .collection("fcmTokens")
    .get();
  await sendToTokenDocuments(tokenSnapshot.docs, message);
}

exports.notifyOnAnnouncementCreated = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const payload = announcementPayload(
      event.params.notificationId,
      null,
      event.data?.data(),
    );
    if (!payload) return;
    await sendToAllDevices(payload);
  },
);

exports.notifyOnAnnouncementUpdated = onDocumentUpdated(
  "notifications/{notificationId}",
  async (event) => {
    const payload = announcementPayload(
      event.params.notificationId,
      event.data?.before.data(),
      event.data?.after.data(),
    );
    if (!payload) return;
    await sendToAllDevices(payload);
  },
);

exports.notifyOnPromotionCreated = onDocumentCreated(
  "advertisements/{advertisementId}",
  async (event) => {
    const payload = advertisementPayload(
      event.params.advertisementId,
      null,
      event.data?.data(),
    );
    if (!payload) return;
    await sendToAllDevices(payload);
  },
);

exports.notifyOnPromotionUpdated = onDocumentUpdated(
  "advertisements/{advertisementId}",
  async (event) => {
    const payload = advertisementPayload(
      event.params.advertisementId,
      event.data?.before.data(),
      event.data?.after.data(),
    );
    if (!payload) return;
    await sendToAllDevices(payload);
  },
);

exports.notifyOnOrderCreated = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const order = orderPayload(event.params.orderId, null, event.data?.data());
    if (!order) return;
    await sendToUser(order.userId, order.message);
  },
);

exports.notifyOnOrderStatusUpdated = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const order = orderPayload(
      event.params.orderId,
      event.data?.before.data(),
      event.data?.after.data(),
    );
    if (!order) return;
    await sendToUser(order.userId, order.message);
  },
);
