export function buildCoordinatePayload(point) {
  const coordinates = Array.isArray(point?.coordinates) ? point.coordinates : null;
  if (!coordinates || coordinates.length < 2) {
    return null;
  }

  const [rawLng, rawLat] = coordinates;
  const lng = Number(rawLng);
  const lat = Number(rawLat);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }

  return {
    lat,
    lng,
    latitude: lat,
    longitude: lng
  };
}

export function attachDeliveryCoordinates(order) {
  if (!order || typeof order !== "object") {
    return order;
  }

  const deliveryCoordinates = buildCoordinatePayload(order.delivery_location);

  return {
    ...order,
    lat: deliveryCoordinates?.lat ?? null,
    lng: deliveryCoordinates?.lng ?? null,
    delivery_coordinates: deliveryCoordinates
  };
}
