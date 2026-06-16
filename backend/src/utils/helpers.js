const config = require('../config/constants');

const calculateShippingFee = (distanceKm = 0) => {
  if (distanceKm <= 0) {
    return config.shippingFee.base;
  }

  if (distanceKm <= 5) {
    return config.shippingFee.base;
  }

  const extraDistance = distanceKm - 5;
  const extraFee = extraDistance * config.shippingFee.perKm;

  return config.shippingFee.base + extraFee;
};

const toRad = (value) => {
  return (value * Math.PI) / 180;
};

const calculateDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return Math.round(distance * 10) / 10;
};

const formatCurrency = (amount) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
};

const formatDate = (date, locale = 'vi-VN') => {
  return new Date(date).toLocaleDateString(locale, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const generateSlug = (text) => {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
};

const delay = (ms) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

const sleep = delay;

const buildPagination = (page, limit, total) => {
  return {
    page: parseInt(page),
    limit: parseInt(limit),
    total,
    totalPages: Math.ceil(total / limit),
  };
};

module.exports = {
  calculateShippingFee,
  calculateDistance,
  formatCurrency,
  formatDate,
  generateSlug,
  delay,
  sleep,
  toRad,
  buildPagination,
};
