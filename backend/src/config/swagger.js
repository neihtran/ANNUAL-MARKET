const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Chợ Tươi Thông API',
      version: '1.0.0',
      description: 'API documentation for Chợ Tươi Thông marketplace platform',
      contact: {
        name: 'Chợ Tươi Thông',
        email: 'support@chotruyenthong.vn',
      },
    },
    servers: [
      {
        url: 'http://localhost:3001',
        description: 'Development server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            email: { type: 'string' },
            fullName: { type: 'string' },
            phone: { type: 'string' },
            avatar: { type: 'string' },
            role: { type: 'string', enum: ['buyer', 'seller', 'shipper', 'admin'] },
            status: { type: 'string', enum: ['active', 'inactive', 'banned'] },
            address: { $ref: '#/components/schemas/Address' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
        },
        Address: {
          type: 'object',
          properties: {
            street: { type: 'string' },
            ward: { type: 'string' },
            district: { type: 'string' },
            city: { type: 'string' },
            coordinates: {
              type: 'object',
              properties: {
                lat: { type: 'number' },
                lng: { type: 'number' },
              },
            },
          },
        },
        Product: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            sellerId: { type: 'string' },
            name: { type: 'string' },
            description: { type: 'string' },
            category: { type: 'string', enum: ['vegetables', 'fruits', 'meat', 'seafood', 'eggs', 'others'] },
            images: { type: 'array', items: { type: 'string' } },
            price: { type: 'number' },
            unit: { type: 'string' },
            stock: { type: 'number' },
            minOrder: { type: 'number' },
            isOrganic: { type: 'boolean' },
            isAvailable: { type: 'boolean' },
            rating: { type: 'number' },
            reviewCount: { type: 'number' },
            createdAt: { type: 'string', format: 'date-time' },
          },
        },
        Order: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            orderNumber: { type: 'string' },
            buyerId: { type: 'string' },
            sellerId: { type: 'string' },
            shipperId: { type: 'string', nullable: true },
            items: {
              type: 'array',
              items: { $ref: '#/components/schemas/OrderItem' },
            },
            subtotal: { type: 'number' },
            shippingFee: { type: 'number' },
            total: { type: 'number' },
            status: {
              type: 'string',
              enum: ['pending', 'finding_shipper', 'shipper_accepted', 'shopping', 'delivering', 'delivered', 'cancelled'],
            },
            paymentMethod: { type: 'string', enum: ['cod', 'momo', 'vnpay'] },
            paymentStatus: { type: 'string', enum: ['unpaid', 'paid', 'refunded'] },
            shippingAddress: { $ref: '#/components/schemas/ShippingAddress' },
            note: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' },
          },
        },
        OrderItem: {
          type: 'object',
          properties: {
            productId: { type: 'string' },
            name: { type: 'string' },
            image: { type: 'string' },
            price: { type: 'number' },
            quantity: { type: 'number' },
            unit: { type: 'string' },
          },
        },
        ShippingAddress: {
          type: 'object',
          properties: {
            street: { type: 'string' },
            ward: { type: 'string' },
            district: { type: 'string' },
            city: { type: 'string' },
            fullName: { type: 'string' },
            phone: { type: 'string' },
            coordinates: {
              type: 'object',
              properties: {
                lat: { type: 'number' },
                lng: { type: 'number' },
              },
            },
          },
        },
        Review: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            orderId: { type: 'string' },
            productId: { type: 'string' },
            buyerId: { type: 'string' },
            rating: { type: 'number', minimum: 1, maximum: 5 },
            comment: { type: 'string' },
            images: { type: 'array', items: { type: 'string' } },
            createdAt: { type: 'string', format: 'date-time' },
          },
        },
        Pagination: {
          type: 'object',
          properties: {
            page: { type: 'integer' },
            limit: { type: 'integer' },
            total: { type: 'integer' },
            totalPages: { type: 'integer' },
          },
        },
        ApiResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: { type: 'object' },
            pagination: { $ref: '#/components/schemas/Pagination' },
          },
        },
        Error: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            message: { type: 'string' },
            error: {
              type: 'object',
              properties: {
                code: { type: 'string' },
                details: { type: 'array', items: { type: 'object' } },
              },
            },
          },
        },
      },
    },
    security: [{ bearerAuth: [] }],
    tags: [
      { name: 'Auth', description: 'Authentication endpoints' },
      { name: 'Users', description: 'User management endpoints' },
      { name: 'Products', description: 'Product management endpoints' },
      { name: 'Orders', description: 'Order management endpoints' },
      { name: 'Reviews', description: 'Review endpoints' },
      { name: 'Dashboard', description: 'Admin dashboard endpoints' },
      { name: 'Notifications', description: 'Notification endpoints' },
    ],
  },
  apis: [],
};

const specs = swaggerJsdoc(options);

module.exports = specs;
