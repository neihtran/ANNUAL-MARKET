const mongoose = require('mongoose');
const { Order, Product, User, Market, Notification } = require('../models');
const { NotFoundError, BadRequestError, ConflictError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');
const config = require('../config/constants');
const socketService = require('./socketService');

class OrderService {
  async create(buyerId, data) {
    const supportsTransactions = mongoose.connection?.readyState === 1 && (
      mongoose.connection?.client?.topology?.description?.type === 'ReplicaSetWithPrimary' ||
      mongoose.connection?.client?.topology?.description?.type === 'Sharded'
    );

    if (supportsTransactions) {
      const session = await mongoose.startSession();
      session.startTransaction();
      try {
        const order = await this._createOrderInternal(buyerId, data, session);
        await session.commitTransaction();
        return order;
      } catch (error) {
        await session.abortTransaction();
        throw error;
      } finally {
        await session.endSession();
      }
    }

    return this._createOrderInternal(buyerId, data, null);
  }

  async _createOrderInternal(buyerId, data, session = null) {
    const buyerQuery = User.findById(buyerId);
    const buyer = session != null ? await buyerQuery.session(session) : await buyerQuery;
    if (!buyer) throw new NotFoundError('Người mua không tồn tại');

    if (!data.marketId) throw new BadRequestError('Vui lòng chọn chợ để mua hàng');
    if (!data.items || data.items.length === 0) {
      throw new BadRequestError('Đơn hàng phải có ít nhất 1 sản phẩm');
    }

    const marketQuery = Market.findById(data.marketId);
    const market = session != null ? await marketQuery.session(session) : await marketQuery;
    if (!market) throw new NotFoundError('Chợ không tồn tại');

    const orderItems = [];
    let subtotal = 0;
    const sellerIds = new Set();
    const unavailableSellers = [];

    for (const item of data.items) {
      const productQuery = Product.findById(item.productId).populate('shopId');
      const product = session != null ? await productQuery.session(session) : await productQuery;

      if (!product) throw new NotFoundError(`Sản phẩm ${item.productId} không tồn tại`);
      if (!product.isAvailable) {
        throw new BadRequestError(`Sản phẩm "${product.name}" hiện không có sẵn`);
      }
      
      // Check if shop is selling
      if (product.shopId && typeof product.shopId === 'object' && product.shopId.isSelling === false) {
        unavailableSellers.push(product.shopId.name || 'Shop');
        continue; // Skip this product
      }
      
      if (product.stock < item.quantity) {
        throw new BadRequestError(`Sản phẩm "${product.name}" không đủ số lượng (còn ${product.stock})`);
      }

      product.stock -= item.quantity;
      if (session != null) {
        await product.save({ session });
      } else {
        await product.save();
      }

      orderItems.push({
        productId: product._id,
        sellerId: product.sellerId,
        shopId: product.shopId?._id || product.shopId,
        shopName: product.shopId?.name || 'Shop',
        name: product.name,
        imageUrl: product.images?.[0] || '',
        price: product.price,
        quantity: item.quantity,
        unit: product.unit,
      });

      sellerIds.add(product.sellerId.toString());
      subtotal += product.price * item.quantity;
    }

    // If all products were skipped due to unavailable sellers
    if (orderItems.length === 0) {
      const shopNames = [...new Set(unavailableSellers)].join(', ');
      throw new BadRequestError(`Các sạp ${shopNames} hiện đang đóng. Vui lòng chọn sạp khác đang mở.`);
    }

    const shippingFee = subtotal >= config.shippingFee.freeThreshold ? 0 : config.shippingFee.base;
    const total = subtotal + shippingFee;
    const estimatedMinutes = 30 + (sellerIds.size * 15);

    const order = new Order({
      buyerId,
      marketId: data.marketId,
      items: orderItems,
      deliveryAddress: data.deliveryAddress,
      subtotal,
      shippingFee,
      discount: 0,
      total,
      paymentMethod: data.paymentMethod || 'cod',
      note: data.note || '',
      estimatedMinutes,
      status: 'finding_shipper',
    });

    if (session != null) {
      await order.save({ session });
    } else {
      await order.save();
    }

    await Notification.createNotification(
      buyerId,
      'Đơn hàng đã được tạo',
      `Đơn hàng ${order.orderNumber} đang chờ shipper nhận`,
      'order_new',
      { orderId: order._id }
    );

    const admins = await User.find({ role: 'admin', status: { $ne: 'banned' } }).select('_id');
    if (admins.length > 0) {
      const adminNotifications = admins.map((admin) => ({
        userId: admin._id,
        title: 'Có đơn hàng mới',
        body: `Đơn hàng ${order.orderNumber} vừa được tạo và đang chờ shipper nhận`,
        type: 'order_new',
        data: { orderId: order._id.toString() },
      }));
      await Notification.createManyNotifications(adminNotifications);
      admins.forEach((admin) => {
        socketService.sendNotification(admin._id.toString(), {
          title: 'Có đơn hàng mới',
          body: `Đơn hàng ${order.orderNumber} vừa được tạo và đang chờ shipper nhận`,
          type: 'order_new',
          referenceId: order._id.toString(),
          data: { orderId: order._id.toString() },
          createdAt: new Date().toISOString(),
        });
      });
    }

    socketService.broadcastNewOrder({
      orderId: order._id,
      marketId: market._id,
      marketName: market.name,
      marketLocation: market.location,
      itemCount: orderItems.length,
      total: order.total,
      shippingFee: order.shippingFee,
    });

    return order;
  }

  async getAll(query) {
    const { page, limit, skip } = getPaginationParams(query);
    const filter = {};

    if (query.status) filter.status = query.status;
    if (query.marketId) filter.marketId = query.marketId;
    if (query.paymentStatus) filter.paymentStatus = query.paymentStatus;
    if (query.search) {
      filter.$or = [
        { orderNumber: { $regex: query.search, $options: 'i' } },
      ];
    }

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('buyerId', 'fullName phone avatar')
        .populate('marketId', 'name address')
        .populate('shipperId', 'fullName phone avatar')
        .populate('items.sellerId', 'fullName phone avatar')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments(filter),
    ]);

    const formattedOrders = orders.map(order => ({
      ...order,
      buyer: order.buyerId,
      market: order.marketId,
      shipper: order.shipperId,
    }));

    return {
      orders: formattedOrders,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getById(id) {
    const order = await Order.findById(id)
      .populate('buyerId', 'fullName phone avatar')
      .populate('marketId', 'name address location')
      .populate('shipperId', 'fullName phone avatar location')
      .populate('items.productId', 'name images price unit')
      .populate('items.sellerId', 'fullName phone avatar')
      .populate('items.shopId', 'name')
      .lean();

    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    const sellerIds = this._extractSellerIds(order);

    return {
      ...order,
      buyer: order.buyerId,
      market: order.marketId,
      shipper: order.shipperId,
      sellerIds,
    };
  }

  async getByBuyer(buyerId, query) {
    const { page, limit, skip } = getPaginationParams(query);
    const filter = { buyerId };
    if (query.status) filter.status = query.status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('marketId', 'name')
        .populate('shipperId', 'fullName phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments(filter),
    ]);

    return {
      orders: orders.map(o => ({ ...o, market: o.marketId, shipper: o.shipperId })),
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getBySeller(sellerId, query) {
    const { page, limit, skip } = getPaginationParams(query);

    // Step 1: Find all products by this seller
    const sellerProducts = await Product.find({ sellerId }).select('_id').lean();
    const productIds = sellerProducts.map(p => p._id);

    if (productIds.length === 0) {
      return {
        orders: [],
        pagination: buildPaginationResponse(0, page, limit),
      };
    }

    // Step 2: Find orders containing any of these products
    const filter = {
      'items.productId': { $in: productIds },
    };
    if (query.status) filter.status = query.status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('buyerId', 'fullName phone avatar')
        .populate('marketId', 'name')
        .populate('shipperId', 'fullName phone')
        .populate('items.productId', 'name images price unit')
        .populate('items.shopId', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments(filter),
    ]);

    // Step 3: Filter items to only this seller's products
    const productIdStrings = new Set(productIds.map(id => id.toString()));
    const filteredOrders = orders.map(order => ({
      ...order,
      // Only keep items from this seller
      items: order.items.filter(item => {
        const pid = item.productId?._id?.toString() || item.productId?.toString();
        return productIdStrings.has(pid);
      }),
      buyer: order.buyerId,
      market: order.marketId,
      shipper: order.shipperId,
    }));

    return {
      orders: filteredOrders,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getAvailableForShipper(query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { status: 'finding_shipper', shipperId: null };

    let ordersQuery = Order.find(filter)
      .populate('buyerId', 'fullName phone')
      .populate('marketId', 'name address location')
      .populate('items.sellerId', 'fullName phone avatar')
      .sort({ createdAt: 1 })
      .skip(skip)
      .limit(limit);

    const [orders, total] = await Promise.all([
      ordersQuery.lean(),
      Order.countDocuments(filter),
    ]);

    // Distance sorting
    if (query.lat && query.lng) {
      const userLat = parseFloat(query.lat);
      const userLng = parseFloat(query.lng);
      const maxDist = parseFloat(query.maxDistance) || 999;

      let withDistance = orders.map(order => {
        const ml = order.marketId?.location;
        const dist = calcDistance(userLat, userLng, ml?.lat || 0, ml?.lng || 0);
        return { ...order, market: order.marketId, distance: Math.round(dist * 10) / 10 };
      });

      if (query.maxDistance) {
        withDistance = withDistance.filter(o => o.distance <= maxDist);
      }
      withDistance.sort((a, b) => a.distance - b.distance);

      return {
        orders: withDistance,
        pagination: buildPaginationResponse(total, page, limit),
      };
    }

    return {
      orders: orders.map(o => ({ ...o, market: o.marketId })),
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getActiveForShipper(shipperId, query) {
    const { page, limit, skip } = getPaginationParams(query);
    const filter = {
      shipperId,
      status: { $in: ['shipper_accepted', 'heading_to_market', 'arrived_at_market', 'ready_for_pickup', 'seller_handed_over', 'picked_up', 'shopping', 'delivering'] },
    };

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('buyerId', 'fullName phone avatar')
        .populate('marketId', 'name address location')
        .populate('items.productId', 'name images price unit')
        .populate('items.sellerId', 'fullName phone avatar')
        .populate('items.shopId', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments(filter),
    ]);

    return {
      orders: orders.map(o => ({ ...o, buyer: o.buyerId, market: o.marketId })),
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getHistoryForShipper(shipperId, query) {
    const { page, limit, skip } = getPaginationParams(query);
    const filter = {
      shipperId,
      status: { $in: ['delivered', 'cancelled'] },
    };

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('buyerId', 'fullName phone')
        .populate('marketId', 'name')
        .populate('items.sellerId', 'fullName phone avatar')
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Order.countDocuments(filter),
    ]);

    return {
      orders: orders.map(o => ({ ...o, buyer: o.buyerId, market: o.marketId })),
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async acceptOrder(orderId, shipperId) {
    // Atomic update — only succeeds if shipperId is null and status is finding_shipper
    const order = await Order.findOneAndUpdate(
      {
        _id: orderId,
        status: 'finding_shipper',
        shipperId: null,
      },
      {
        $set: { shipperId, status: 'shipper_accepted' },
        // Pre-save hook won't fire on findOneAndUpdate, so push manually
        $push: { statusHistory: { status: 'shipper_accepted', note: '' } },
      },
      { new: true }
    ).populate('buyerId', 'fullName phone');

    if (!order) {
      throw new ConflictError('Đơn hàng không còn khả dụng (đã có người nhận hoặc trạng thái không phù hợp)');
    }

    socketService.broadcastOrderTaken(orderId);

    await Notification.createNotification(
      order.buyerId._id,
      'Shipper đã nhận đơn',
      `Shipper đang đến lấy đơn hàng ${order.orderNumber}`,
      'order_new',
      { orderId: order._id }
    );

    const sellerIds = this._extractSellerIds(order);
    socketService.emitOrderStatusChange(
      orderId,
      order.buyerId._id.toString(),
      sellerIds,
      shipperId,
      'shipper_accepted'
    );

    return order;
  }

  async updateStatus(orderId, newStatus, userId, userRole, note = '', confirmImageUrl = '') {
    const order = await Order.findById(orderId);
    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    const roleTransitions = {
      shipper: {
        'shipper_accepted': ['heading_to_market'],
        'heading_to_market': ['arrived_at_market'],
        'arrived_at_market': [],
        'ready_for_pickup': [],
        'seller_handed_over': ['picked_up'],
        'picked_up': ['delivering'],
        'shopping': ['delivering'],
        'delivering': ['delivered'],
      },
      seller: {
        'arrived_at_market': ['ready_for_pickup'],
        'shipper_accepted': ['ready_for_pickup'],
        'heading_to_market': ['ready_for_pickup'],
        'ready_for_pickup': ['seller_handed_over'],
      },
      buyer: {
        'pending': ['cancelled'],
        'finding_shipper': ['cancelled'],
      },
      admin: {
        'pending': ['cancelled'],
        'finding_shipper': ['cancelled'],
        'shipper_accepted': ['cancelled'],
        'heading_to_market': ['cancelled'],
        'arrived_at_market': ['cancelled'],
        'ready_for_pickup': ['cancelled'],
        'seller_handed_over': ['cancelled'],
        'picked_up': ['cancelled'],
        'shopping': ['cancelled'],
        'delivering': ['delivered', 'cancelled'],
      },
    };

    const allowed = roleTransitions[userRole]?.[order.status] || [];
    if (!allowed.includes(newStatus)) {
      throw new BadRequestError(`Không thể chuyển từ "${order.status}" sang "${newStatus}"`);
    }

    const updateOps = {
      $set: { status: newStatus },
      $push: { statusHistory: { status: newStatus, note: note || '' } },
    };

    if (newStatus === 'delivered') {
      updateOps.$set.deliveredAt = new Date();
      updateOps.$set.paymentStatus = order.paymentMethod === 'cod' ? 'paid' : order.paymentStatus;
      if (confirmImageUrl) updateOps.$set.confirmImageUrl = confirmImageUrl;
    }

    const updatedOrder = await Order.findByIdAndUpdate(orderId, updateOps, { new: true })
      .populate('buyerId', 'fullName phone')
      .populate('marketId', 'name')
      .populate('shipperId', 'fullName phone');

    const sellerIds = this._extractSellerIds(updatedOrder);
    socketService.emitOrderStatusChange(
      orderId,
      updatedOrder.buyerId._id.toString(),
      sellerIds,
      updatedOrder.shipperId?._id?.toString(),
      newStatus
    );

    const statusMessages = {
      'heading_to_market': 'shipper đang đến chợ',
      'arrived_at_market': 'shipper đã đến chợ',
      'ready_for_pickup': 'đơn hàng đã được người bán chuẩn bị xong',
      'seller_handed_over': 'người bán đã giao đơn cho shipper',
      'picked_up': 'shipper đã nhận đơn từ người bán',
      'shopping': 'shipper đang đi mua hàng',
      'delivering': 'đang được giao đến bạn',
      'delivered': 'đã được giao thành công',
      'cancelled': 'đã bị hủy',
    };

    if (statusMessages[newStatus]) {
      await Notification.createNotification(
        order.buyerId.toString(),
        'Cập nhật đơn hàng',
        `Đơn hàng ${order.orderNumber} ${statusMessages[newStatus]}`,
        'order_new',
        { orderId: order._id }
      );
    }

    return {
      ...updatedOrder.toObject(),
      buyer: updatedOrder.buyerId,
      market: updatedOrder.marketId,
      shipper: updatedOrder.shipperId,
    };
  }

  async cancel(orderId, userId, userRole, reason) {
    const order = await Order.findById(orderId);
    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    console.log(`[orderService.cancel] orderId=${orderId} orderStatus="${order.status}" buyerId=${order.buyerId} userId=${userId} userRole=${userRole}`);

    const shipperReturnable = ['shipper_accepted', 'heading_to_market', 'arrived_at_market', 'ready_for_pickup'];
    const cancellable = ['pending', 'finding_shipper', 'shipper_accepted', 'heading_to_market', 'arrived_at_market', 'ready_for_pickup', 'seller_handed_over'];
    if (!cancellable.includes(order.status)) {
      console.log(`[orderService.cancel] REJECTED: status "${order.status}" not in cancellable list`);
      throw new BadRequestError('Không thể hủy đơn hàng ở trạng thái này');
    }

    if (userRole === 'buyer' && order.buyerId.toString() !== userId.toString()) {
      throw new BadRequestError('Bạn không có quyền hủy đơn hàng này');
    }

    if (userRole === 'shipper') {
      if (order.shipperId?.toString() !== userId.toString()) {
        throw new BadRequestError('Bạn không phải shipper của đơn hàng này');
      }
      if (!shipperReturnable.includes(order.status)) {
        throw new BadRequestError('Shipper chỉ có thể trả đơn trước khi nhận hàng từ seller');
      }

      const returnedOrder = await Order.findByIdAndUpdate(
        orderId,
        {
          $set: {
            status: 'finding_shipper',
            shipperId: null,
            shipperLocation: null,
            cancelReason: reason || '',
            cancelBy: 'shipper',
          },
          $push: { statusHistory: { status: 'finding_shipper', note: reason ? `Shipper trả đơn: ${reason}` : 'Shipper trả đơn' } },
        },
        { new: true }
      )
        .populate('buyerId', 'fullName phone')
        .populate('marketId', 'name address location')
        .populate('shipperId', 'fullName phone');

      await Notification.createNotification(
        order.buyerId.toString(),
        'Shipper đã trả đơn',
        `Đơn hàng ${order.orderNumber} đang được tìm shipper khác${reason ? `: ${reason}` : ''}`,
        'order_status',
        { orderId: order._id }
      );

      const sellerIds = this._extractSellerIds(order);
      socketService.emitOrderStatusChange(
        orderId,
        order.buyerId.toString(),
        sellerIds,
        null,
        'finding_shipper'
      );

      socketService.broadcastNewOrder({
        orderId: order._id,
        marketId: order.marketId,
        marketName: order.marketId?.name || '',
        marketLocation: order.marketId?.location || null,
        itemCount: order.items.length,
        total: order.total,
        shippingFee: order.shippingFee,
      });

      return {
        ...returnedOrder.toObject(),
        buyer: returnedOrder.buyerId,
        market: returnedOrder.marketId,
        shipper: returnedOrder.shipperId,
      };
    }

    const supportsTransactions = mongoose.connection?.readyState === 1 && (
      mongoose.connection?.client?.topology?.description?.type === 'ReplicaSetWithPrimary' ||
      mongoose.connection?.client?.topology?.description?.type === 'Sharded'
    );

    if (supportsTransactions) {
      const session = await mongoose.startSession();
      session.startTransaction();
      try {
        for (const item of order.items) {
          await Product.findByIdAndUpdate(
            item.productId,
            { $inc: { stock: item.quantity } },
            { session }
          );
        }

        const updatedOrder = await Order.findByIdAndUpdate(
          orderId,
          {
            $set: { status: 'cancelled', cancelReason: reason || '', cancelBy: userRole },
            $push: { statusHistory: { status: 'cancelled', note: reason || '' } },
          },
          { new: true }
        ).session(session);

        await session.commitTransaction();

        if (order.status === 'finding_shipper') {
          socketService.broadcastOrderTaken(orderId);
        }

        await Notification.createNotification(
          order.buyerId.toString(),
          'Đơn hàng đã bị hủy',
          `Đơn hàng ${order.orderNumber} đã bị hủy${reason ? `: ${reason}` : ''}`,
          'order_new',
          { orderId: order._id }
        );

        if (order.shipperId) {
          await Notification.createNotification(
            order.shipperId.toString(),
            'Đơn hàng đã bị hủy',
            `Đơn hàng ${order.orderNumber} đã bị hủy bởi người mua`,
            'order_new',
            { orderId: order._id }
          );
        }

        return updatedOrder;
      } catch (error) {
        await session.abortTransaction();
        throw error;
      } finally {
        session.endSession();
      }
    }

    // Non-transaction path (standalone MongoDB)
    for (const item of order.items) {
      await Product.findByIdAndUpdate(
        item.productId,
        { $inc: { stock: item.quantity } }
      );
    }

    const updatedOrder = await Order.findByIdAndUpdate(
      orderId,
      {
        $set: { status: 'cancelled', cancelReason: reason || '', cancelBy: userRole },
        $push: { statusHistory: { status: 'cancelled', note: reason || '' } },
      },
      { new: true }
    );

    if (order.status === 'finding_shipper') {
      socketService.broadcastOrderTaken(orderId);
    }

    await Notification.createNotification(
      order.buyerId.toString(),
      'Đơn hàng đã bị hủy',
      `Đơn hàng ${order.orderNumber} đã bị hủy${reason ? `: ${reason}` : ''}`,
      'order_new',
      { orderId: order._id }
    );

    if (order.shipperId) {
      await Notification.createNotification(
        order.shipperId.toString(),
        'Đơn hàng đã bị hủy',
        `Đơn hàng ${order.orderNumber} đã bị hủy bởi người mua`,
        'order_new',
        { orderId: order._id }
      );
    }

    return updatedOrder;
  }

  // Helper: extract unique seller IDs from order items
  _extractSellerIds(order) {
    if (!order.items) return [];
    const seen = new Set();
    for (const item of order.items) {
      const sid = item.sellerId?.toString?.() || item.sellerId;
      if (sid) seen.add(sid);
    }
    return [...seen];
  }

  async update(orderId, userId, userRole, data) {
    const order = await Order.findById(orderId);
    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    // Only buyer can update their own order, and only in pending/finding_shipper status
    const editableStatuses = ['pending', 'finding_shipper'];
    if (userRole === 'buyer' && order.buyerId.toString() !== userId.toString()) {
      throw new BadRequestError('Bạn không có quyền cập nhật đơn hàng này');
    }
    if (userRole === 'buyer' && !editableStatuses.includes(order.status)) {
      throw new BadRequestError('Đơn hàng không thể cập nhật ở trạng thái này');
    }

    const updateData = {};
    if (data.note !== undefined) updateData.note = data.note;
    if (data.deliveryAddress !== undefined) {
      updateData.deliveryAddress = data.deliveryAddress;
    }

    // Updating items requires stock check — only admin can do this safely
    if (data.items && (userRole === 'admin' || (userRole === 'buyer' && editableStatuses.includes(order.status)))) {
      throw new BadRequestError('Không thể cập nhật danh sách sản phẩm. Vui lòng hủy đơn hàng và tạo lại.');
    }

    const updated = await Order.findByIdAndUpdate(orderId, updateData, { new: true })
      .populate('buyerId', 'fullName phone')
      .populate('marketId', 'name')
      .populate('shipperId', 'fullName phone');

    return {
      ...updated.toObject(),
      buyer: updated.buyerId,
      market: updated.marketId,
      shipper: updated.shipperId,
    };
  }

  /**
   * Shipper cập nhật vị trí GPS của mình trong khi đang giao hàng.
   */
  async updateShipperLocation(orderId, shipperId, lat, lng) {
    const order = await Order.findById(orderId);
    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    // Only the assigned shipper can update
    if (order.shipperId?.toString() !== shipperId) {
      throw new ConflictError('Bạn không phải shipper của đơn này');
    }

    // Only update during active delivery
    if (!['shipper_accepted', 'shopping', 'delivering'].includes(order.status)) {
      throw new BadRequestError('Không thể cập nhật vị trí ở trạng thái này');
    }

    order.shipperLocation = { lat, lng, updatedAt: new Date() };
    await order.save();

    // Notify buyer of updated shipper location via Socket.io
    try {
      const socketService = require('./socketService');
      socketService.emitToUser(order.buyerId.toString(), 'order:location_update', {
        orderId: order._id,
        lat,
        lng,
        updatedAt: new Date().toISOString(),
      });
    } catch (_) {
      // Non-critical: socket failure should not break location update
    }

    return order.toObject();
  }

  /**
   * Lấy thông tin tracking: order + shipper location + market location + delivery address.
   * Dùng cho buyer và shipper xem vị trí trên bản đồ.
   */
  async getOrderTrack(orderId, userId, userRole) {
    const order = await Order.findById(orderId)
      .populate('marketId', 'name address location')
      .populate('shipperId', 'fullName phone avatar location')
      .lean();

    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    // Authorization: buyer must own the order, shipper must be assigned
    if (userRole === 'buyer' && order.buyerId?.toString() !== userId.toString()) {
      throw new ConflictError('Bạn không có quyền theo dõi đơn này');
    }
    if (userRole === 'shipper' && order.shipperId?.toString() !== userId.toString()) {
      throw new ConflictError('Bạn không phải shipper của đơn này');
    }

    const market = order.marketId || {};
    const shipper = order.shipperId || {};
    const marketLoc = market.location || {};
    const shipperLoc = (shipper.location || order.shipperLocation) || {};

    return {
      orderId: order._id,
      orderNumber: order.orderNumber,
      status: order.status,
      // Market location (pickup point)
      market: {
        name: market.name || '',
        address: market.address || '',
        lat: marketLoc.lat || null,
        lng: marketLoc.lng || null,
      },
      // Delivery destination
      delivery: {
        address: order.deliveryAddress?.address || '',
        lat: order.deliveryAddress?.lat || null,
        lng: order.deliveryAddress?.lng || null,
      },
      // Shipper location
      shipper: shipperLoc.lat != null ? {
        name: shipper.fullName || '',
        phone: shipper.phone || '',
        lat: shipperLoc.lat,
        lng: shipperLoc.lng,
        updatedAt: shipperLoc.updatedAt || null,
      } : null,
    };
  }
}

function calcDistance(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

module.exports = new OrderService();
