/**
 * Seed Script - Khởi tạo dữ liệu ban đầu cho hệ thống Chợ Tươi Thông
 * Áp dụng cho TP Đà Nẵng
 * Chạy: node src/seed.js
 */
require('dotenv').config();
const { connectDB } = require('./config/database');
const { User, Market, Category, Shop, Product } = require('./models');

const seedData = async () => {
  try {
    await connectDB();
    console.log('✅ Connected to MongoDB');

    // ── 1. Admin ──────────────────────────────────────────────────────────
    const adminEmail = 'admin@chotruyenthong.vn';
    const adminPassword = 'Admin123!';
    let admin = await User.findOne({ email: adminEmail });
    if (!admin) {
      admin = await User.create({
        email: adminEmail, password: adminPassword,
        fullName: 'Quản trị viên', phone: '0900000001',
        role: 'admin', isApproved: true, isVerified: true, status: 'active',
        location: { lat: 16.0544, lng: 108.2022 },
      });
      console.log(`✅ Admin: ${adminEmail} / ${adminPassword}`);
    } else {
      console.log(`ℹ️  Admin exists: ${adminEmail}`);
    }

    // ── 2. Categories ───────────────────────────────────────────────────────
    const categoriesData = [
      { name: 'Rau củ',        icon: '🥬', description: 'Rau xanh, rau thơm, rau ăn lá',     sortOrder: 1 },
      { name: 'Trái cây',       icon: '🍎', description: 'Trái cây tươi các loại',            sortOrder: 2 },
      { name: 'Thịt',           icon: '🥩', description: 'Thịt heo, thịt bò, thịt gia cầm',    sortOrder: 3 },
      { name: 'Hải sản',        icon: '🦐', description: 'Cá, tôm, cua, mực tươi sống',       sortOrder: 4 },
      { name: 'Trứng & Sữa',    icon: '🥚', description: 'Trứng gà, trứng vịt, sữa tươi',    sortOrder: 5 },
      { name: 'Gia vị',         icon: '🌶️', description: 'Tiêu, ớt, hành, tỏi, gia vị gói',   sortOrder: 6 },
      { name: 'Đồ khô',         icon: '🍄', description: 'Nấm khô, rong biển, đậu khô',       sortOrder: 7 },
      { name: 'Đồ uống',         icon: '🧃', description: 'Nước giải khát, nước ép tươi',      sortOrder: 8 },
    ];
    const createdCategories = [];
    for (const cat of categoriesData) {
      let category = await Category.findOne({ name: cat.name });
      if (!category) category = await Category.create(cat);
      createdCategories.push(category);
    }
    console.log(`ℹ️  ${createdCategories.length} categories ready`);

    // ── 3. Markets — Đà Nẵng districts ───────────────────────────────────
    const marketsData = [
      // Hai Chau (trung tâm Đà Nẵng)
      {
        name: 'Chợ Hàn',
        address: '01 Trần Quý Cáp, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng',
        district: 'Hai Chau',
        location: { lat: 16.0544, lng: 108.2022 },
        openTime: '05:00', closeTime: '18:00', isActive: true,
        description: 'Chợ Hàn là trái tim thương mại truyền thống của Đà Nẵng, nằm ngay trung tâm Quận Hải Châu. Chợ bán đủ các loại thực phẩm tươi sống, rau củ quả và hàng hóa phục vụ đời sống.',
      },
      {
        name: 'Chợ Đợt Cồn',
        address: 'Đường Nguyễn Văn Linh, Phường Nam Dương, Quận Hải Châu, Đà Nẵng',
        district: 'Hai Chau',
        location: { lat: 16.0613, lng: 108.2105 },
        openTime: '04:00', closeTime: '17:30', isActive: true,
        description: 'Chợ Đợt Cồn nổi tiếng với các sản phẩm hải sản tươi sống từ biển Đà Nẵng, là điểm đến quen thuộc của người dân địa phương.',
      },
      // Thanh Khê
      {
        name: 'Chợ Cồn',
        address: '54 Đường Thanh Khê Đông 1, Phường Thanh Khê Đông, Quận Thanh Khê, Đà Nẵng',
        district: 'Thanh Khe',
        location: { lat: 16.0607, lng: 108.1809 },
        openTime: '05:00', closeTime: '18:00', isActive: true,
        description: 'Chợ Cồn là chợ truyền thống lớn của Quận Thanh Khê, chuyên bán thực phẩm tươi sống, rau xanh và hàng khô phục vụ cư dân hai bên sông Hàn.',
      },
      // Son Tra
      {
        name: 'Chợ Mỹ An',
        address: 'Phường Mỹ An, Quận Sơn Trà, Đà Nẵng',
        district: 'Son Tra',
        location: { lat: 16.0792, lng: 108.2485 },
        openTime: '06:00', closeTime: '17:30', isActive: true,
        description: 'Chợ Mỹ An phục vụ khu vực du lịch và cư dân Sơn Trà, chuyên hải sản tươi và nông sản từ vùng ngoại thành Đà Nẵng.',
      },
      {
        name: 'Chợ Phước Mỹ',
        address: 'Phường Phước Mỹ, Quận Sơn Trà, Đà Nẵng',
        district: 'Son Tra',
        location: { lat: 16.0851, lng: 108.2319 },
        openTime: '05:30', closeTime: '17:30', isActive: true,
        description: 'Chợ Phước Mỹ là điểm bán buôn và bán lẻ thực phẩm chính của khu vực Sơn Trà, gần Bãi Biển Mỹ Khê.',
      },
      // Ngu Hanh Son
      {
        name: 'Chợ Hòa Hải',
        address: 'Phường Hòa Hải, Quận Ngũ Hành Sơn, Đà Nẵng',
        district: 'Ngu Hanh Son',
        location: { lat: 16.0178, lng: 108.2481 },
        openTime: '06:00', closeTime: '17:00', isActive: true,
        description: 'Chợ Hòa Hải phục vụ cư dân khu vực ven biển Đà Nẵng, chuyên cá và hải sản tươi được đánh bắt trong ngày.',
      },
      // Lien Chieu
      {
        name: 'Chợ Hòa Khánh',
        address: 'Đường Nguyễn Lương Bằng, Phường Hòa Khánh Bắc, Quận Liên Chiểu, Đà Nẵng',
        district: 'Lien Chieu',
        location: { lat: 16.0856, lng: 108.1347 },
        openTime: '05:00', closeTime: '17:30', isActive: true,
        description: 'Chợ Hòa Khánh là chợ đầu mối lớn phía Tây Đà Nẵng, cung cấp thực phẩm cho cư dân Liên Chiểu và vùng lân cận KCN.',
      },
      {
        name: 'Chợ Tam Thuận',
        address: 'Phường Tam Thuận, Quận Liên Chiểu, Đà Nẵng',
        district: 'Lien Chieu',
        location: { lat: 16.0723, lng: 108.1583 },
        openTime: '05:30', closeTime: '17:00', isActive: true,
        description: 'Chợ Tam Thuận là chợ truyền thống phục vụ cư dân khu vực Tây Bắc Đà Nẵng.',
      },
      // Cam Le
      {
        name: 'Chợ Khuê Trung',
        address: 'Phường Khuê Trung, Quận Cẩm Lệ, Đà Nẵng',
        district: 'Cam Le',
        location: { lat: 16.0126, lng: 108.2099 },
        openTime: '05:30', closeTime: '17:30', isActive: true,
        description: 'Chợ Khuê Trung phục vụ khu vực đông dân cư Cẩm Lệ, chuyên nông sản tươi từ các vùng trồng rau Hòa Vang.',
      },
      // Hoa Vang
      {
        name: 'Chợ Hòa Vang',
        address: 'Thị trấn Hòa Vang, Huyện Hòa Vang, Đà Nẵng',
        district: 'Hoa Vang',
        location: { lat: 15.9377, lng: 108.0483 },
        openTime: '06:00', closeTime: '17:00', isActive: true,
        description: 'Chợ Hòa Vang là chợ truyền thống của huyện Hòa Vang, nổi tiếng với rau hữu cơ và nông sản sạch từ vùng ngoại thành Đà Nẵng.',
      },
    ];

    const createdMarkets = [];
    for (const m of marketsData) {
      let market = await Market.findOne({ name: m.name });
      if (!market) {
        market = await Market.create(m);
        console.log(`✅ Market: ${m.name} (${m.district})`);
      } else {
        console.log(`ℹ️  Market exists: ${m.name}`);
      }
      createdMarkets.push(market);
    }

    const vegetablesCat = createdCategories.find(c => c.name === 'Rau củ');
    const fruitsCat    = createdCategories.find(c => c.name === 'Trái cây');
    const meatCat      = createdCategories.find(c => c.name === 'Thịt');
    const seafoodCat   = createdCategories.find(c => c.name === 'Hải sản');
    const eggsCat      = createdCategories.find(c => c.name === 'Trứng & Sữa');

    // ── 4. Sellers ────────────────────────────────────────────────────────
    const sellersData = [
      { email: 'seller1@demo.com', fullName: 'Chị Lan - Rau Tươi Đà Nẵng',  phone: '0911000001', marketIdx: 0, category: vegetablesCat },
      { email: 'seller2@demo.com', fullName: 'Anh Minh - Trái Cây Sơn Trà',     phone: '0911000002', marketIdx: 3, category: fruitsCat    },
      { email: 'seller3@demo.com', fullName: 'Bác Hùng - Thịt Hàn',               phone: '0911000003', marketIdx: 0, category: meatCat      },
      { email: 'seller4@demo.com', fullName: 'Cô Hương - Hải Sản Cồn',          phone: '0911000004', marketIdx: 1, category: seafoodCat   },
      { email: 'seller5@demo.com', fullName: 'Chị Mai - Trứng Sữa Hòa Vang',    phone: '0911000005', marketIdx: 9, category: eggsCat      },
      { email: 'seller6@demo.com', fullName: 'Anh Tuấn - Rau Xanh Thanh Khê',    phone: '0911000006', marketIdx: 2, category: vegetablesCat },
    ];

    const createdSellers = [];
    for (const s of sellersData) {
      let seller = await User.findOne({ email: s.email });
      const market = createdMarkets[s.marketIdx];
      if (!seller) {
        seller = await User.create({
          email: s.email, password: 'Demo1234',
          fullName: s.fullName, phone: s.phone,
          role: 'seller', isApproved: true, isVerified: true, status: 'active',
          marketId: market._id, categoryIds: [s.category._id],
          location: { lat: market.location.lat, lng: market.location.lng },
        });
        console.log(`✅ Seller: ${s.email}`);
      } else {
        const updateData = {};
        let needsUpdate = false;

        if (!seller.marketId) {
          updateData.marketId = market._id;
          needsUpdate = true;
        }

        if (!Array.isArray(seller.categoryIds) || seller.categoryIds.length === 0) {
          updateData.categoryIds = [s.category._id];
          needsUpdate = true;
        }

        if (!seller.location?.lat || !seller.location?.lng) {
          updateData.location = { lat: market.location.lat, lng: market.location.lng };
          needsUpdate = true;
        }

        if (!seller.isApproved || seller.status !== 'active' || !seller.isVerified) {
          updateData.isApproved = true;
          updateData.isVerified = true;
          updateData.status = 'active';
          needsUpdate = true;
        }

        if (needsUpdate) {
          seller = await User.findByIdAndUpdate(seller._id, updateData, { new: true, runValidators: true });
          console.log(`🔄 Backfilled seller profile: ${s.email}`);
        } else {
          console.log(`ℹ️  Seller exists: ${s.email}`);
        }
      }

      let shop = await Shop.findOne({ sellerId: seller._id });
      if (!shop) {
        shop = await Shop.create({
          sellerId: seller._id, marketId: market._id,
          categoryId: s.category._id,
          name: s.fullName.split(' - ')[1] || s.fullName,
          description: `Gian hàng chuyên ${s.category.name} tươi ngon tại ${market.name}, ${market.district}`,
          isApproved: true, isOpen: true,
        });
        console.log(`   → Shop: ${shop.name} @ ${market.name}`);
      } else {
        const shopUpdate = {};
        let needsShopUpdate = false;

        if (!shop.marketId) {
          shopUpdate.marketId = market._id;
          needsShopUpdate = true;
        }
        if (!shop.categoryId) {
          shopUpdate.categoryId = s.category._id;
          needsShopUpdate = true;
        }
        if (!shop.isApproved || !shop.isOpen) {
          shopUpdate.isApproved = true;
          shopUpdate.isOpen = true;
          needsShopUpdate = true;
        }

        if (needsShopUpdate) {
          shop = await Shop.findByIdAndUpdate(shop._id, shopUpdate, { new: true, runValidators: true });
          console.log(`🔄 Backfilled shop: ${shop.name} @ ${market.name}`);
        }
      }

      createdSellers.push({ seller, shop, market, category: s.category });
    }

    // ── 5. Buyers ────────────────────────────────────────────────────────
    const buyersData = [
      { email: 'buyer1@demo.com', fullName: 'Nguyễn Văn A', phone: '0901000001' },
      { email: 'buyer2@demo.com', fullName: 'Trần Thị B', phone: '0901000002' },
      { email: 'buyer3@demo.com', fullName: 'Lê Minh C', phone: '0901000003' },
    ];
    for (const b of buyersData) {
      let buyer = await User.findOne({ email: b.email });
      if (!buyer) {
        buyer = await User.create({
          email: b.email, password: 'Demo1234',
          fullName: b.fullName, phone: b.phone,
          role: 'buyer', isApproved: true, isVerified: true, status: 'active',
          location: { lat: 16.0544, lng: 108.2022 },
        });
        console.log(`✅ Buyer: ${b.email}`);
      } else {
        console.log(`ℹ️  Buyer exists: ${b.email}`);
      }
    }

    // ── 6. Shippers ─────────────────────────────────────────────────────
    const shippersData = [
      { email: 'shipper1@demo.com', fullName: 'Shipper Đỗ Văn X', phone: '0933000001' },
      { email: 'shipper2@demo.com', fullName: 'Shipper Lê Văn Y', phone: '0933000002' },
    ];
    for (const s of shippersData) {
      let shipper = await User.findOne({ email: s.email });
      if (!shipper) {
        shipper = await User.create({
          email: s.email, password: 'Demo1234',
          fullName: s.fullName, phone: s.phone,
          role: 'shipper', isApproved: true, isVerified: true, status: 'active',
          location: { lat: 16.0544, lng: 108.2022 },
        });
        console.log(`✅ Shipper: ${s.email}`);
      } else {
        console.log(`ℹ️  Shipper exists: ${s.email}`);
      }
    }

    // ── 7. Products ──────────────────────────────────────────────────────
    const productsData = [
      // Rau củ (vegetables)
      { name: 'Rau muống tươi',    price: 15000, unit: 'bó',  stock: 100, category: vegetablesCat, soldCount: 45 },
      { name: 'Rau cải xanh',     price: 12000, unit: 'bó',  stock: 80,  category: vegetablesCat, soldCount: 38 },
      { name: 'Xà lách lốc',        price: 18000, unit: 'bó',  stock: 60,  category: vegetablesCat, soldCount: 22 },
      { name: 'Dưa leo',            price: 10000, unit: 'kg',  stock: 50,  category: vegetablesCat, soldCount: 55 },
      { name: 'Cà chua',            price: 20000, unit: 'kg',  stock: 40,  category: vegetablesCat, soldCount: 30 },
      { name: 'Rau mồng tơi',       price: 12000, unit: 'bó',  stock: 70,  category: vegetablesCat, soldCount: 20 },
      // Trái cây (fruits)
      { name: 'Cam Vinh',           price: 35000, unit: 'kg',  stock: 80,  category: fruitsCat, soldCount: 50 },
      { name: 'Táo Mỹ',             price: 55000, unit: 'kg',  stock: 60,  category: fruitsCat, soldCount: 35 },
      { name: 'Nho đen Úc',         price: 120000, unit: 'kg', stock: 30,  category: fruitsCat, soldCount: 15 },
      { name: 'Bưởi da xanh',       price: 45000, unit: 'kg',  stock: 50,  category: fruitsCat, soldCount: 28 },
      { name: 'Xoài Cát Hòa Lộc',  price: 60000, unit: 'kg',  stock: 25,  category: fruitsCat, soldCount: 10 },
      // Thịt (meat)
      { name: 'Thịt ba chỉ heo',    price: 85000, unit: 'kg',  stock: 30,  category: meatCat, soldCount: 60 },
      { name: 'Thịt bò Mỹ',        price: 180000, unit: 'kg', stock: 20,  category: meatCat, soldCount: 18 },
      { name: 'Thịt gà ta',         price: 95000, unit: 'kg',  stock: 25,  category: meatCat, soldCount: 42 },
      // Hải sản (seafood)
      { name: 'Cá thác lác',        price: 70000, unit: 'kg',  stock: 20,  category: seafoodCat, soldCount: 25 },
      { name: 'Tôm thẻ',            price: 150000, unit: 'kg', stock: 15,  category: seafoodCat, soldCount: 20 },
      { name: 'Mực ống tươi',      price: 120000, unit: 'kg', stock: 10,  category: seafoodCat, soldCount: 15 },
      // Trứng sữa
      { name: 'Trứng gà ta',        price: 35000, unit: 'vỉ',  stock: 50,  category: eggsCat, soldCount: 80 },
      { name: 'Sữa tươi Đà Nẵng', price: 25000, unit: 'lít', stock: 40,  category: eggsCat, soldCount: 65 },
    ];

    for (let i = 0; i < productsData.length; i++) {
      const p = productsData[i];
      const sellerIdx = i % createdSellers.length;
      const { seller, shop, market } = createdSellers[sellerIdx];

      const existing = await Product.findOne({ name: p.name, shopId: shop._id });
      if (!existing) {
        await Product.create({
          shopId: shop._id, sellerId: seller._id, marketId: market._id,
          categoryId: p.category._id,
          name: p.name,
          description: `${p.name} tươi ngon, đảm bảo chất lượng tại ${market.name}, Đà Nẵng`,
          price: p.price, unit: p.unit, stock: p.stock, minOrder: 1,
          isAvailable: true, images: [], soldCount: p.soldCount,
          location: { lat: market.location.lat, lng: market.location.lng },
          isFresh: true,
          productLocation: { lat: market.location.lat, lng: market.location.lng },
        });
        console.log(`✅ Product: ${p.name} @ ${shop.name}`);
      } else {
        console.log(`ℹ️  Product exists: ${p.name}`);
      }
    }

    console.log('\n🎉 Seed completed successfully!');
    console.log('════════════════════════════════════════════');
    console.log('📍 TP Đà Nẵng - 8 quận/huyện:');
    console.log('   Hai Chau, Thanh Khe, Son Tra, Ngu Hanh Son');
    console.log('   Lien Chieu, Cam Le, Hoa Vang, Hoa Khanh');
    console.log(`📍 Tổng chợ: ${createdMarkets.length} chợ`);
    console.log('────────────────────────────────────────────');
    console.log('📋 Admin: admin@chotruyenthong.vn / Admin123!');
    console.log('📋 Seller: seller1@demo.com / Demo1234');
    console.log('📋 Buyer: buyer1@demo.com / Demo1234');
    console.log('📋 Shipper: shipper1@demo.com / Demo1234');
    console.log('════════════════════════════════════════════\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Seed failed:', error);
    process.exit(1);
  }
};

seedData();
