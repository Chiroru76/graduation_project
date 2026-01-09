module.exports = {
  content: [
    "./app/views/**/*.{html,erb}",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js",
  ],
  theme: {
    extend: {
      colors: {
        game: {
          purple: {
            light: '#E9D5FF',
            DEFAULT: '#C084FC',
            dark: '#7C3AED',
          },
          pink: {
            light: '#FBCFE8',
            DEFAULT: '#F472B6',
            dark: '#EC4899',
          },
          blue: {
            light: '#BFDBFE',
            DEFAULT: '#60A5FA',
            dark: '#3B82F6',
          },
          gold: {
            light: '#FDE68A',
            DEFAULT: '#FBBF24',
            dark: '#F59E0B',
          },
        },
      },
      backgroundImage: {
        'game-gradient': 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        'game-card': 'linear-gradient(145deg, #ffffff 0%, #f3f4f6 100%)',
        'game-shine': 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)',
      },
      animation: {
        'bounce-slow': 'bounce 2s infinite',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'shine': 'shine 3s infinite',
        'float': 'float 3s ease-in-out infinite',
      },
      keyframes: {
        shine: {
          '0%': { backgroundPosition: '-200% center' },
          '100%': { backgroundPosition: '200% center' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
      },
    },
  },
  plugins: [],
};
