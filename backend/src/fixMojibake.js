/**
 * Fix Mojibake Script - Sửa dữ liệu tiếng Việt bị lỗi encoding trong MongoDB
 * Chạy: node src/fixMojibake.js
 */
require('dotenv').config();
const { connectDB } = require('./config/database');
const { Market, Category } = require('./models');

const correctCategories = [
  { _id: '6a05c9fbd2507d6b2ee9b47f', name: 'Rau củ',        icon: '🥬', description: 'Rau xanh, rau thơm, rau ăn lá' },
  { _id: '6a05c9fbd2507d6b2ee9b48c', name: 'Trái cây',     icon: '🍎', description: 'Trái cây tươi các loại' },
  { _id: '6a05c9fbd2507d6b2ee9b48f', name: 'Thịt',          icon: '🥩', description: 'Thịt heo, thịt bò, thịt gia cầm' },
  { _id: '6a05c9fbd2507d6b2ee9b492', name: 'Hải sản',      icon: '🦐', description: 'Cá, tôm, cua, mực tươi sống' },
  { _id: '6a05c9fbd2507d6b2ee9b495', name: 'Trứng & Sữa',  icon: '🥚', description: 'Trứng gà, trứng vịt, sữa tươi' },
  { _id: '6a05c9fbd2507d6b2ee9b498', name: 'Gia vị',        icon: '🌶️', description: 'Tiêu, ớt, hành, tỏi, gia vị gói' },
  { _id: '6a05c9fbd2507d6b2ee9b49b', name: 'Đồ khô',        icon: '🍄', description: 'Nấm khô, rong biển, đậu khô' },
  { _id: '6a05c9fbd2507d6b2ee9b49e', name: 'Đồ uống',        icon: '🧃', description: 'Nước giải khát, nước ép tươi' },
];

// All 14 markets from the API
const correctMarkets = [
  {
    _id: '6a0b03d00de73b1d74dcf7d5',
    name: 'Chợ Hàn',
    address: '01 Trần Quý Cáp, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng',
    district: 'Hai Chau',
    description: 'Chợ Hàn là trái tim thương mại truyền thống của Đà Nẵng, nằm ngay trung tâm Quận Hải Châu.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7db',
    name: 'Chợ Đống Cón',
    address: 'Đường Nguyễn Văn Linh, Phường Nam Dương, Quận Hải Châu, Đà Nẵng',
    district: 'Hai Chau',
    description: 'Chợ Đống Cón nổi tiếng với các sản phẩm hải sản tươi sống từ biển Đà Nẵng.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7de',
    name: 'Chợ Cồn',
    address: '54 Đường Thanh Khê Đông 1, Phường Thanh Khê Đông, Quận Thanh Khê, Đà Nẵng',
    district: 'Thanh Khe',
    description: 'Chợ Cồn là chợ truyền thống lớn của Quận Thanh Khê, chuyên bán thực phẩm tươi sống và rau xanh.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7e1',
    name: 'Chợ Mỹ An',
    address: 'Phường Mỹ An, Quận Sơn Trà, Đà Nẵng',
    district: 'Son Tra',
    description: 'Chợ Mỹ An phục vụ khu vực du lịch và cư dân Sơn Trà, chuyên hải sản tươi và nông sản từ vùng ngoại thành Đà Nẵng.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7e4',
    name: 'Chợ Phước Mỹ',
    address: 'Phường Phước Mỹ, Quận Sơn Trà, Đà Nẵng',
    district: 'Son Tra',
    description: 'Chợ Phước Mỹ là điểm bán buôn và bán lẻ thực phẩm chính của khu vực Sơn Trà, gần Bãi Biển Mỹ Khê.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7e7',
    name: 'Chợ Hòa Hải',
    address: 'Phường Hòa Hải, Quận Ngũ Hành Sơn, Đà Nẵng',
    district: 'Ngu Hanh Son',
    description: 'Chợ Hòa Hải phục vụ cư dân khu vực ven biển Đà Nẵng, chuyên cá và hải sản tươi được đánh bắt trong ngày.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7ea',
    name: 'Chợ Hòa Khánh',
    address: 'Đường Nguyễn Lương Bằng, Phường Hòa Khánh Bắc, Quận Liên Chiểu, Đà Nẵng',
    district: 'Lien Chieu',
    description: 'Chợ Hòa Khánh là chợ đầu mối lớn phía Tây Đà Nẵng, cung cấp thực phẩm cho cư dân Liên Chiểu và vùng lân cận KCN.',
  },
  {
    _id: '6a104c7e544ae2a2097f887e',
    name: 'Chợ Tam Thuận',
    address: 'Phường Tam Thuận, Quận Liên Chiểu, Đà Nẵng',
    district: 'Lien Chieu',
    description: 'Chợ Tam Thuận là chợ truyền thống phục vụ cư dân khu vực Tây Bắc Đà Nẵng.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7f0',
    name: 'Chợ Khuê Trung',
    address: 'Phường Khuê Trung, Quận Cẩm Lệ, Đà Nẵng',
    district: 'Cam Le',
    description: 'Chợ Khuê Trung phục vụ khu vực đông dân cư Cẩm Lệ, chuyên nông sản tươi từ các vùng trồng rau Hòa Vang.',
  },
  {
    _id: '6a0b03d10de73b1d74dcf7f3',
    name: 'Chợ Hòa Vang',
    address: 'Thị trấn Hòa Vang, Huyện Hòa Vang, Đà Nẵng',
    district: 'Hoa Vang',
    description: 'Chợ Hòa Vang là chợ truyền thống của huyện Hòa Vang, nổi tiếng với rau hữu cơ và nông sản sạch từ vùng ngoại thành Đà Nẵng.',
  },
  {
    _id: '6a05c9fbd2507d6b2ee9b4a4',
    name: 'Chợ Hàng Da',
    address: 'Phường Hải Châu 2, Quận Hải Châu, Đà Nẵng',
    district: 'Hai Chau',
    description: 'Chợ Hàng Da là chợ truyền thống nổi tiếng với các sản phẩm da và thực phẩm địa phương.',
  },
  {
    _id: '6a05c9fbd2507d6b2ee9b4a7',
    name: 'Chợ Đặng Bằng',
    address: 'Phường Thanh Bình, Quận Hải Châu, Đà Nẵng',
    district: 'Hai Chau',
    description: 'Chợ Đặng Bằng phục vụ cư dân khu vực Thanh Bình với đa dạng thực phẩm tươi sống.',
  },
  {
    _id: '6a05c9fbd2507d6b2ee9b4aa',
    name: 'Chợ Vinh',
    address: 'Phường Vinh, Quận Ngũ Hành Sơn, Đà Nẵng',
    district: 'Ngu Hanh Son',
    description: 'Chợ Vinh phục vụ khu vực phía Nam Đà Nẵng với các sản phẩm nông sản và hải sản tươi.',
  },
  {
    _id: '6a05c9fbd2507d6b2ee9b4ad',
    name: 'Chợ Phong Phú',
    address: 'Phường Khuê Mỹ, Quận Ngũ Hành Sơn, Đà Nẵng',
    district: 'Ngu Hanh Son',
    description: 'Chợ Phong Phú là điểm mua sắm tiện lợi cho cư dân khu vực Khuê Mỹ và lân cận.',
  },
];

const fixMojibake = async () => {
  try {
    await connectDB();
    console.log('✅ Connected to MongoDB\n');

    // ── Fix Categories ──────────────────────────────────────────────────────
    console.log('📦 Fixing categories...');
    for (const cat of correctCategories) {
      const updated = await Category.findByIdAndUpdate(
        cat._id,
        { name: cat.name, icon: cat.icon, description: cat.description },
        { new: true }
      );
      if (updated) {
        console.log(`   ✅ ${cat.name}`);
      } else {
        console.log(`   ⚠️  Category not found: ${cat._id}`);
      }
    }

    // ── Fix ALL Markets ───────────────────────────────────────────────────
    console.log('\n🏪 Fixing all markets...');
    for (const mkt of correctMarkets) {
      const updated = await Market.findByIdAndUpdate(
        mkt._id,
        {
          name: mkt.name,
          address: mkt.address,
          district: mkt.district,
          description: mkt.description,
        },
        { new: true }
      );
      if (updated) {
        console.log(`   ✅ ${mkt.name} (${mkt.district})`);
      } else {
        console.log(`   ⚠️  Market not found: ${mkt._id} - ${mkt.name}`);
      }
    }

    // ── Verify ─────────────────────────────────────────────────────────────
    console.log('\n🔍 Verifying categories...');
    const cats = await Category.find({}).select('name description');
    cats.forEach(c => console.log(`   - ${c.name}: ${c.description}`));

    console.log('\n🔍 Verifying markets...');
    const mkts = await Market.find({}).select('name address district').sort({ district: 1 });
    mkts.forEach(m => console.log(`   - ${m.name} (${m.district})`));

    console.log('\n🎉 Mojibake fix completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Fix failed:', error);
    process.exit(1);
  }
};

fixMojibake();
