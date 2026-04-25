import { getIO } from "../config/socket.js";

// Emit to specific order room
export const emitToOrder = (order_id, event, data) => {
  const io = getIO();
  if (!io) return;
  io.to(`order-${order_id}`).emit(event, data);
};

// Emit to specific driver
export const emitToDriver = (driver_id, event, data) => {
  const io = getIO();
  if (!io) return;
  io.to(`driver-${driver_id}`).emit(event, data);
};

// Emit to specific restaurant
export const emitToRestaurant = (restaurant_id, event, data) => {
  const io = getIO();
  if (!io) return;
  io.to(`restaurant-${restaurant_id}`).emit(event, data);
};

// Emit to specific customer
export const emitToCustomer = (customer_id, event, data) => {
  const io = getIO();
  if (!io) return;
  io.to(`customer-${customer_id}`).emit(event, data);
};

// Emit to all admins
export const emitToAdmins = (event, data) => {
  const io = getIO();
  if (!io) return;
  io.to("admin").emit(event, data);
};

// Broadcast to all connected clients
export const broadcastToAll = (event, data) => {
  const io = getIO();
  if (!io) return;
  io.emit(event, data);
};
