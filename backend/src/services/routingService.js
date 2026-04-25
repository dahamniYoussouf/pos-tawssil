import axios from 'axios';

const clampNumber = (value, min, max) => Math.min(max, Math.max(min, value));

const parsePositiveInt = (value) => {
  const parsed = Number.parseInt(String(value ?? ''), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
};

const getOsrmTimeoutMs = (options = {}) => {
  const fromOptions = parsePositiveInt(options.timeoutMs ?? options.timeout_ms);
  const fromEnv = parsePositiveInt(process.env.OSRM_TIMEOUT_MS ?? process.env.ROUTING_TIMEOUT_MS);
  return clampNumber(fromOptions ?? fromEnv ?? 1200, 200, 10000);
};

/**
 * Calculate route distance and travel time between two coordinates
 * @param {number} startLng - Starting longitude
 * @param {number} startLat - Starting latitude
 * @param {number} endLng - Destination longitude
 * @param {number} endLat - Destination latitude
 * @param {number} speedKmh - Motor speed in km/h (default: 40)
 * @param {object} options - { mode?: "osrm" | "direct" }
 * @returns {Object} Route info with distance and time estimates
 */
const estimateDirectRoute = (startLng, startLat, endLng, endLat, speedKmh = 40) => {
  const R = 6371;
  const dLat = (endLat - startLat) * Math.PI / 180;
  const dLon = (endLng - startLng) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(startLat * Math.PI / 180) * Math.cos(endLat * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const distanceKm = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const timeMinutes = (distanceKm / speedKmh) * 60;
  return {
    distanceKm: parseFloat(distanceKm.toFixed(2)),
    timeMin: Math.floor(timeMinutes * 0.9),
    timeMax: Math.ceil(timeMinutes * 1.2)
  };
};

const calculateRouteTime = async (startLng, startLat, endLng, endLat, speedKmh = 40, options = {}) => {
  const envMode = process.env.ROUTING_MODE;
  const mode = (options.mode || envMode || "osrm").toString().toLowerCase();
  if (mode === "direct") {
    return estimateDirectRoute(startLng, startLat, endLng, endLat, speedKmh);
  }

  try {
    // Get actual route from OSRM
    const url = `https://router.project-osrm.org/route/v1/driving/${startLng},${startLat};${endLng},${endLat}?overview=false`;
    const response = await axios.get(url, { timeout: getOsrmTimeoutMs(options) });

    const distanceKm = response.data.routes[0].distance / 1000;
    const timeMinutes = (distanceKm / speedKmh) * 60;

    return {
      distanceKm: parseFloat(distanceKm.toFixed(2)),
      timeMin: Math.floor(timeMinutes * 0.9),  // optimistic
      timeMax: Math.ceil(timeMinutes * 1.2)    // with delays
    };
  } catch (error) {
    // Fallback to straight-line distance
    return estimateDirectRoute(startLng, startLat, endLng, endLat, speedKmh);
  }
};

export default calculateRouteTime;
