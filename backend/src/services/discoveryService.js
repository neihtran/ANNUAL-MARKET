const { Product, Market, Shop } = require('../models');

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

class DiscoveryService {
  async getNearbyProducts(query) {
    const { lat, lng, radius = 10, categoryId, marketId, search, limit = 20, page = 1 } = query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const filter = { isAvailable: true };
    if (categoryId) filter.categoryId = categoryId;
    if (marketId) filter.marketId = marketId;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }
    let products = await Product.find(filter)
      .populate('categoryId', 'name icon')
      .populate('shopId', 'name avatar isOpen isSelling')
      .populate('marketId', 'name address district location openTime closeTime is24h isActive')
      .sort({ soldCount: -1, rating: -1 })
      .skip(skip)
      .limit(100)
      .lean();
    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxDist = parseFloat(radius);
      products = products
        .map(function(p) {
          const marketLoc = (p.marketId && p.marketId.location) || null;
          let distance = null;
          if (marketLoc && marketLoc.lat != null && marketLoc.lng != null) {
            distance = calcDistance(userLat, userLng, marketLoc.lat, marketLoc.lng);
          }
          return Object.assign({}, p, { distance: distance, productLocation: p.productLocation });
        })
        .filter(function(p) { return p.distance == null || p.distance <= maxDist; })
        .sort(function(a, b) { return (a.distance || 999) - (b.distance || 999); });
    }
    const total = products.length;
    products = products.slice(0, parseInt(limit));
    return { products: products, total: total };
  }

  async getNearbyMarkets(query) {
    const { lat, lng, district, radius = 15, isActive, limit = 20, search } = query;
    const filter = {};
    if (isActive !== undefined) filter.isActive = isActive == 'true';
    if (district) filter.district = district;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { address: { $regex: search, $options: 'i' } },
        { district: { $regex: search, $options: 'i' } },
      ];
    }
    let markets = await Market.find(filter)
      .select('-__v')
      .sort({ name: 1 })
      .limit(200)
      .lean();
    
    // Filter by real-time open status if no specific isActive filter
    if (isActive === undefined) {
      markets = markets.filter(m => m.isActive !== false);
    }
    
    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxDist = parseFloat(radius);
      markets = markets
        .map(function(m) {
          const loc = (m.location && m.location.lat != null) ? m.location : null;
          const distance = loc ? calcDistance(userLat, userLng, loc.lat, loc.lng) : null;
          return Object.assign({}, m, { distance: distance });
        })
        .filter(function(m) { return m.distance == null || m.distance <= maxDist; })
        .sort(function(a, b) { return (a.distance || 999) - (b.distance || 999); });
    }
    
    // Add isCurrentlyOpen to each market
    markets = markets.map(m => {
      const now = new Date();
      const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
      const isCurrentlyOpen = m.is24h || (m.isActive !== false && currentTime >= (m.openTime || '06:00') && currentTime <= (m.closeTime || '18:00'));
      return { ...m, isCurrentlyOpen };
    });
    
    return markets.slice(0, parseInt(limit));
  }

  async globalSearch(query) {
    const { q, lat, lng, type, limit = 10 } = query;
    if (!q || q.trim().length < 2) return { products: [], shops: [], markets: [] };
    const regex = { $regex: q.trim(), $options: 'i' };
    var productPromise = (type !== 'markets' && type !== 'shops')
      ? Product.find({ isAvailable: true, $or: [{ name: regex }, { description: regex }] })
          .populate('categoryId', 'name icon')
          .populate('marketId', 'name district location openTime closeTime is24h isActive')
          .populate('shopId', 'name avatar isOpen isSelling')
          .sort({ soldCount: -1 })
          .limit(parseInt(limit))
          .lean()
      : Promise.resolve([]);
    var shopPromise = (type !== 'products' && type !== 'markets')
      ? Shop.find({ isApproved: true, isSelling: true, name: regex })
          .populate('marketId', 'name district location openTime closeTime is24h isActive')
          .sort({ rating: -1 })
          .limit(parseInt(limit))
          .lean()
      : Promise.resolve([]);
    var marketPromise = (type !== 'products' && type !== 'shops')
      ? Market.find({ isActive: true, name: regex }).limit(parseInt(limit)).lean()
      : Promise.resolve([]);
    var results = await Promise.all([productPromise, shopPromise, marketPromise]);
    var products = results[0];
    var shops = results[1];
    var markets = results[2];
    if (lat && lng) {
      var userLat = parseFloat(lat);
      var userLng = parseFloat(lng);
      function addDistance(arr, locPath) {
        return arr.map(function(item) {
          var loc = null;
          if (locPath === 'location') {
            loc = item.location;
          } else if (item[locPath] && item[locPath].location) {
            loc = item[locPath].location;
          }
          var distance = (loc && loc.lat != null) ? calcDistance(userLat, userLng, loc.lat, loc.lng) : null;
          return Object.assign({}, item, { distance: distance });
        });
      }
      return {
        products: addDistance(products, 'marketId'),
        shops: addDistance(shops, 'marketId'),
        markets: addDistance(markets, 'location'),
      };
    }
    return { products: products, shops: shops, markets: markets };
  }

  async getFeaturedProducts(query) {
    const { limit = 10, categoryId } = query;
    const filter = { isAvailable: true };
    if (categoryId) filter.categoryId = categoryId;
    var results = await Promise.all([
      Product.find(filter)
        .populate('categoryId', 'name icon')
        .populate('shopId', 'name avatar isOpen isSelling')
        .populate('marketId', 'name district location openTime closeTime is24h isActive')
        .sort({ soldCount: -1 })
        .limit(parseInt(limit))
        .lean(),
      Product.find(Object.assign({}, filter, { rating: { $gt: 0 } }))
        .populate('categoryId', 'name icon')
        .populate('shopId', 'name avatar isOpen isSelling')
        .populate('marketId', 'name district location openTime closeTime is24h isActive')
        .sort({ rating: -1 })
        .limit(parseInt(limit))
        .lean(),
    ]);
    return { topSold: results[0], topRated: results[1] };
  }
}

module.exports = new DiscoveryService();
