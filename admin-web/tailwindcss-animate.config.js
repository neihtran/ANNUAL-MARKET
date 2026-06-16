const plugin = require('tailwindcss/plugin');

module.exports = plugin(function ({ addUtilities }) {
  addUtilities({
    '.animate-shimmer': {
      animation: 'shimmer 2s linear infinite',
      background: 'linear-gradient(to right, hsl(var(--muted)), hsl(var(--muted)/50), hsl(var(--muted)))',
      backgroundSize: '200% 100%',
    },
  });
});
