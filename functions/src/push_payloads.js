function announcementPayload(notificationId, before, after) {
  if (!after || after.isActive !== true) return null;

  const isPromotion =
    typeof after.type === "string" &&
    after.type.trim().toLowerCase() === "promotion";
  const body =
    typeof after.message === "string" && after.message.trim()
      ? after.message
      : isPromotion && typeof after.description === "string"
        ? after.description
        : "";
  const changed =
    !before ||
    before.isActive !== true ||
    before.title !== after.title ||
    before.message !== after.message ||
    before.description !== after.description ||
    before.type !== after.type ||
    before.imageUrl !== after.imageUrl ||
    before.version !== after.version;
  if (
    !changed ||
    typeof after.title !== "string" ||
    !after.title.trim() ||
    !body.trim()
  ) {
    return null;
  }

  const data = {
    type: "announcement",
    notificationId,
  };
  if (typeof after.imageUrl === "string" && after.imageUrl.trim()) {
    data.imageUrl = after.imageUrl.trim().slice(0, 2048);
  }
  if (typeof after.version === "string" && after.version.trim()) {
    data.version = after.version.trim().slice(0, 50);
  }

  return {
    notification: {
      title: after.title.trim().slice(0, 128),
      body: body.trim().slice(0, 1_000),
    },
    data,
  };
}

function advertisementPayload(advertisementId, before, after) {
  if (!after || after.isActive !== true) return null;

  const changed =
    !before ||
    before.isActive !== true ||
    before.title !== after.title ||
    before.description !== after.description ||
    before.imageUrl !== after.imageUrl ||
    JSON.stringify(before.imageUrls || []) !==
      JSON.stringify(after.imageUrls || []) ||
    before.buttonLabel !== after.buttonLabel ||
    before.buttonActionType !== after.buttonActionType ||
    before.buttonTarget !== after.buttonTarget;
  if (
    !changed ||
    typeof after.title !== "string" ||
    typeof after.description !== "string" ||
    !after.title.trim() ||
    !after.description.trim()
  ) {
    return null;
  }

  const data = {
    type: "promotion",
    advertisementId,
  };
  const imageUrl =
    (Array.isArray(after.imageUrls)
      ? after.imageUrls.find((url) => typeof url === "string" && url.trim())
      : null) || after.imageUrl;
  if (typeof imageUrl === "string" && imageUrl.trim()) {
    data.imageUrl = imageUrl.trim().slice(0, 2048);
  }
  for (const field of ["buttonLabel", "buttonActionType", "buttonTarget"]) {
    if (typeof after[field] === "string" && after[field].trim()) {
      data[field] = after[field].trim().slice(0, 256);
    }
  }

  return {
    notification: {
      title: after.title.trim().slice(0, 128),
      body: after.description.trim().slice(0, 1_000),
    },
    data,
  };
}

function orderPayload(orderId, before, after) {
  if (!after || typeof after.status !== "string") return null;
  if (before && before.status === after.status) return null;

  const userId =
    typeof after.userId === "string" && after.userId
      ? after.userId
      : after.customerId;
  if (typeof userId !== "string" || !userId) return null;

  const status = after.status.trim();
  if (!status) return null;
  const fulfillment =
    typeof after.fulfillment === "string" && after.fulfillment.trim()
      ? after.fulfillment.trim().toLowerCase()
      : "placed";

  return {
    userId,
    message: {
      notification: {
        title: "Order status update",
        body: `Your ${fulfillment} order ${orderId} is ${status.toLowerCase()}.`,
      },
      data: {
        type: "order_status",
        orderId,
        status,
      },
    },
  };
}

module.exports = {
  advertisementPayload,
  announcementPayload,
  orderPayload,
};
