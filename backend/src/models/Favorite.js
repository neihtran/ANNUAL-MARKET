const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
}, {
  timestamps: true,
});

favoriteSchema.index({ userId: 1, productId: 1 }, { unique: true });
favoriteSchema.index({ productId: 1 });

module.exports = mongoose.model('Favorite', favoriteSchema);
