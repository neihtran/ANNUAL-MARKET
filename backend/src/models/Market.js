const mongoose = require('mongoose');

const DN_DISTRICTS = [
  'Hai Chau',    // Quận Hải Châu (trung tâm)
  'Thanh Khe',   // Quận Thanh Khê
  'Son Tra',     // Quận Sơn Trà (Đà Nẵng)
  'Ngu Hanh Son',// Quận Ngũ Hành Sơn
  'Lien Chieu',  // Quận Liên Chiểu
  'Cam Le',      // Quận Cẩm Lệ
  'Hoa Vang',    // Huyện Hòa Vang (ngoại thành)
  'Hoa Khanh',   // Phường Hòa Khánh, Q. Liên Chiểu
];

const marketSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Tên chợ là bắt buộc'],
    trim: true,
    maxlength: [200, 'Tên chợ không quá 200 ký tự'],
  },
  address: {
    type: String,
    required: [true, 'Địa chỉ là bắt buộc'],
    trim: true,
  },
  district: {
    type: String,
    required: [true, 'Quận/huyện là bắt buộc'],
    enum: {
      values: DN_DISTRICTS,
      message: 'Quận/huyện phải thuộc TP Đà Nẵng',
    },
  },
  location: {
    lat: {
      type: Number,
      required: [true, 'Vĩ độ là bắt buộc'],
    },
    lng: {
      type: Number,
      required: [true, 'Kinh độ là bắt buộc'],
    },
  },
  images: [{
    type: String,
  }],
  openTime: {
    type: String,
    default: '06:00',
  },
  closeTime: {
    type: String,
    default: '18:00',
  },
  description: {
    type: String,
    default: '',
    maxlength: [1000, 'Mô tả không quá 1000 ký tự'],
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  is24h: {
    type: Boolean,
    default: false,
  },
  phone: {
    type: String,
    default: '',
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Virtual property: Kiểm tra chợ có đang mở cửa theo thời gian thực không
marketSchema.virtual('isCurrentlyOpen').get(function() {
  // Nếu là chợ 24h thì luôn mở
  if (this.is24h) return true;
  
  // Nếu không active thì đóng
  if (!this.isActive) return false;
  
  const now = new Date();
  const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  
  return currentTime >= this.openTime && currentTime <= this.closeTime;
});

marketSchema.index({ name: 'text' });
marketSchema.index({ 'location.lat': 1, 'location.lng': 1 });
marketSchema.index({ isActive: 1 });
marketSchema.index({ district: 1 });
marketSchema.index({ location: '2dsphere' });

marketSchema.statics.getDNDistricts = function () {
  return DN_DISTRICTS;
};

module.exports = mongoose.model('Market', marketSchema);
