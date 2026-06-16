const socketService = {
  io: null,

  init(io) {
    this.io = io;

    io.on('connection', (socket) => {
      console.log(`Socket connected: ${socket.id}`);

      // User joins with their userId
      socket.on('user:join', (userId) => {
        socket.userId = userId;
        socket.join(`user:${userId}`);
        console.log(`User ${userId} joined socket ${socket.id}`);
      });

      // Shipper updates location
      socket.on('shipper:update_location', async (data) => {
        const { orderId, lat, lng } = data;
        
        if (!orderId || lat === undefined || lng === undefined) {
          return socket.emit('error', { message: 'Invalid location data' });
        }

        // Emit to buyer watching this order
        io.to(`order:${orderId}`).emit('shipper:location', {
          orderId,
          lat,
          lng,
          timestamp: new Date().toISOString(),
        });
      });

      // Buyer joins order room for real-time updates
      socket.on('order:join', (orderId) => {
        socket.join(`order:${orderId}`);
        console.log(`Socket ${socket.id} joined order room: ${orderId}`);
      });

      // Buyer leaves order room
      socket.on('order:leave', (orderId) => {
        socket.leave(`order:${orderId}`);
        console.log(`Socket ${socket.id} left order room: ${orderId}`);
      });

      // Shipper joins available orders room
      socket.on('shipper:available_join', () => {
        socket.join('shippers:available');
        console.log(`Socket ${socket.id} joined available shippers room`);
      });

      socket.on('disconnect', () => {
        console.log(`Socket disconnected: ${socket.id}`);
      });
    });
  },

  // Broadcast new order to all available shippers
  broadcastNewOrder(orderData) {
    if (!this.io) return;
    
    this.io.to('shippers:available').emit('order:new_available', {
      orderId: orderData.orderId,
      marketId: orderData.marketId,
      marketName: orderData.marketName,
      marketLocation: orderData.marketLocation,
      itemCount: orderData.itemCount,
      total: orderData.total,
      shippingFee: orderData.shippingFee,
      distanceFromSeller: orderData.distanceFromSeller,
      createdAt: new Date().toISOString(),
    });
  },

  // Notify that an order has been taken
  broadcastOrderTaken(orderId) {
    if (!this.io) return;
    
    this.io.to('shippers:available').emit('order:taken', { orderId });
  },

  // Emit order status change to buyer and sellers
  emitOrderStatusChange(orderId, buyerId, sellerIds, shipperId, status) {
    if (!this.io) return;

    // Notify buyer
    if (buyerId) {
      this.io.to(`user:${buyerId}`).emit('order:status_changed', {
        orderId,
        status,
        timestamp: new Date().toISOString(),
      });
    }

    // Notify sellers
    if (sellerIds && Array.isArray(sellerIds)) {
      sellerIds.forEach((sellerId) => {
        this.io.to(`user:${sellerId}`).emit('order:status_changed', {
          orderId,
          status,
          timestamp: new Date().toISOString(),
        });
      });
    }

    // Notify shipper
    if (shipperId) {
      this.io.to(`user:${shipperId}`).emit('order:status_changed', {
        orderId,
        status,
        timestamp: new Date().toISOString(),
      });
    }
  },

  // Send notification to specific user
  sendNotification(userId, notification) {
    if (!this.io) return;
    
    this.io.to(`user:${userId}`).emit('notification:new', notification);
  },

  // Send private message to socket
  emitToUser(userId, event, data) {
    if (!this.io) return;
    
    this.io.to(`user:${userId}`).emit(event, data);
  },
};

module.exports = socketService;
