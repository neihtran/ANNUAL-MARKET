const mongoose = require('mongoose');
const Order = require('./src/models/Order');

async function check() {
  try {
    await mongoose.connect('mongodb://localhost:27017/chotruyenthong');
    const orders = await Order.find({})
      .sort({ createdAt: -1 })
      .limit(10)
      .select('orderNumber status createdAt')
      .lean();
    console.log(JSON.stringify(orders, null, 2));
  } catch (e) {
    console.error(e.message);
  } finally {
    await mongoose.disconnect();
  }
}

check();
