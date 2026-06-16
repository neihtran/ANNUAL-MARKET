const { User, Order } = require('../models');

function calcDistance(lat1, lng1, lat2, lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

class ShipperService {
  async updateLocation(shipperId, lat, lng) {
    await User.findByIdAndUpdate(shipperId, {
      'location.lat': lat,
      'location.lng': lng,
    });
    return { lat, lng };
  }

  async updateOnlineStatus(shipperId, isOnline) {
    const user = await User.findByIdAndUpdate(
      shipperId,
      { isOnline: !!isOnline },
      { new: true }
    );
    return user;
  }

  async getNearbyAvailableOrders(shipperId, query) {
    const { lat, lng, radius = 10, page = 1, limit = 20 } = query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const orders = await Order.find({ status: 'finding_shipper', shipperId: null })
      .populate('marketId', 'name address district location')
      .populate('buyerId', 'fullName phone')
      .select('-__v')
      .skip(skip)
      .limit(200)
      .lean();

    let filtered = orders;
    let total = orders.length;

    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxDist = parseFloat(radius);

      filtered = orders
        .map(function(o) {
          const mLoc = (o.marketId && o.marketId.location) || null;
          let distance = null;
          if (mLoc && mLoc.lat != null && mLoc.lng != null) {
            distance = calcDistance(userLat, userLng, mLoc.lat, mLoc.lng);
          }
          return Object.assign({}, o, { distance: distance });
        })
        .filter(function(o) { return o.distance == null || o.distance <= maxDist; })
        .sort(function(a, b) { return (a.distance || 999) - (b.distance || 999); });

      total = filtered.length;
    }

    return {
      orders: filtered.slice(0, parseInt(limit)),
      total: total,
    };
  }

  async getShipperProfile(shipperId) {
    const user = await User.findById(shipperId)
      .select('-password -refreshToken')
      .lean();
    return user;
  }
}

module.exports = new ShipperService();
