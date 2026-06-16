require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');

const { connectDB } = require('./config/database');
const swaggerSpec = require('./config/swagger');
const config = require('./config/constants');
const socketService = require('./services/socketService');
const { errorHandler, notFound, apiLimiter } = require('./middlewares');
const { authRoutes, userRoutes, productRoutes, orderRoutes, reviewRoutes, sellerReviewRoutes, shipperReviewRoutes, dashboardRoutes, reportRoutes, notificationRoutes, adminUserRoutes, adminMarketRoutes, adminCategoryRoutes, adminProductRoutes, marketRoutes, categoryRoutes, sellerRoutes, buyerRoutes, shipperRoutes, uploadRoutes, paymentRoutes, discoveryRoutes } = require('./routes');

const app = express();
const server = http.createServer(app);

// Socket.io setup — must use specific allowed origins (not '*') to allow credentialed connections
const allowedSocketOrigins = [
  'http://localhost:3000',
  'http://localhost:3001',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:3001',
];
const io = new Server(server, {
  cors: {
    origin: allowedSocketOrigins,
    credentials: true,
  },
});

socketService.init(io);

app.use(helmet());
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (e.g., mobile apps, curl)
    if (!origin) {
      callback(null, true);
      return;
    }
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:3001',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:3001',
    ];
    if (
      allowedOrigins.includes(origin) ||
      origin.startsWith('http://localhost:') ||
      origin.startsWith('http://127.0.0.1:') ||
      // Allow local network IPs (Android/iOS real devices on same WiFi)
      /^http:\/\/192\.168\.\d{1,3}\.\d{1,3}(:\d+)?$/.test(origin)
    ) {
      callback(null, true);
    } else {
      callback(null, true); // Allow all origins in dev to avoid CORS issues with random dev ports
    }
  },
  credentials: true,
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Chợ Tươi Thông API Docs',
}));

app.use('/api/v1/auth', apiLimiter, authRoutes);
app.use('/api/v1/users', apiLimiter, userRoutes);
app.use('/api/v1/admin/users', apiLimiter, adminUserRoutes);
app.use('/api/v1/admin/markets', apiLimiter, adminMarketRoutes);
app.use('/api/v1/admin/categories', apiLimiter, adminCategoryRoutes);
app.use('/api/v1/admin/products', apiLimiter, adminProductRoutes);

// Discovery routes — MUST come FIRST because productRoutes and marketRoutes have /:id
// which would intercept /products/featured, /products/nearby, /markets/nearby
app.use('/api/v1', discoveryRoutes);

app.use('/api/v1/products', apiLimiter, productRoutes);
app.use('/api/v1/orders', apiLimiter, orderRoutes);
app.use('/api/v1/reviews', apiLimiter, reviewRoutes);
app.use('/api/v1/seller-reviews', apiLimiter, sellerReviewRoutes);
app.use('/api/v1/shipper-reviews', apiLimiter, shipperReviewRoutes);
app.use('/api/v1/dashboard', apiLimiter, dashboardRoutes);
app.use('/api/v1/reports', apiLimiter, reportRoutes);
app.use('/api/v1/notifications', apiLimiter, notificationRoutes);

// Public routes (no auth required)
app.use('/api/v1/markets', marketRoutes);
app.use('/api/v1/categories', categoryRoutes);

// Seller routes (mobile)
app.use('/api/v1/seller', apiLimiter, sellerRoutes);

// Buyer routes (mobile)
app.use('/api/v1/buyer', apiLimiter, buyerRoutes);

// Shipper routes (mobile)
app.use('/api/v1/shipper', apiLimiter, shipperRoutes);

// Upload routes
app.use('/api/v1/upload', uploadRoutes);

// Payment routes
app.use('/api/v1/payment', paymentRoutes);

const path = require('path');

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv,
  });
});

app.use(notFound);
app.use(errorHandler);

const os = require('os');

const startServer = async () => {
  try {
    await connectDB();
    
    // Get local IP address dynamically
    const getLocalIp = () => {
      const interfaces = os.networkInterfaces();
      for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
          if (iface.family === 'IPv4' && !iface.internal) {
            return iface.address;
          }
        }
      }
      return 'localhost';
    };
    
    const localIp = getLocalIp();
    
    server.listen(config.port, '0.0.0.0', () => {
      console.log(`🚀 Server running on port ${config.port}`);
      console.log(`🚀 Accessible at http://${localIp}:${config.port}`);
      console.log(`📖 API Docs: http://localhost:${config.port}/api-docs`);
      console.log(`🔌 Socket.IO ready`);
      console.log(`🌍 Environment: ${config.nodeEnv}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

module.exports = { app, server, io };
