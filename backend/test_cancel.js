const mongoose = require('mongoose');
const Order = require('./src/models/Order');

async function test() {
  try {
    await mongoose.connect('mongodb://localhost:27017/chotruyenthong');

    const order = await Order.findOne({ status: { $nin: ['cancelled', 'delivered'] } })
      .sort({ createdAt: -1 })
      .lean();
    
    if (!order) {
      console.log('No cancellable orders found');
      await mongoose.disconnect();
      return;
    }

    console.log('Testing cancel for order:');
    console.log('  _id:', order._id.toString());
    console.log('  orderNumber:', order.orderNumber);
    console.log('  status:', order.status, '(type:', typeof order.status, ')');
    console.log('  buyerId:', order.buyerId.toString());

    const cancellable = ['pending', 'finding_shipper', 'shipper_accepted', 'heading_to_market', 'arrived_at_market', 'ready_for_pickup', 'seller_handed_over'];
    console.log('  is cancellable:', cancellable.includes(order.status));
    console.log('  index of status:', cancellable.indexOf(order.status));

    // Simulate orderService.cancel logic
    console.log('\nDirect DB check:');
    const fromDB = await Order.findById(order._id);
    console.log('  status from DB:', fromDB.status);
    console.log('  cancellable check:', cancellable.includes(fromDB.status));

    console.log('\n✅ Status is valid and SHOULD be cancellable.');
    console.log('Issue must be with the API request - check the app terminal for [CANCEL] logs.');

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await mongoose.disconnect();
  }
}

test();
