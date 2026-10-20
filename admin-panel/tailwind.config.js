/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#0F766E", // Emerald/Teal brand color
          hover: "#0D9488",
          light: "#CCFBF1",
          dark: "#115E59",
        },
        amber: {
          DEFAULT: "#F59E0B",
          light: "#FEF3C7",
        },
        surface: {
          DEFAULT: "#FFFFFF",
          muted: "#F8FAFC",
          border: "#E2E8F0",
        }
      },
      fontFamily: {
        tajawal: ['var(--font-tajawal)', 'sans-serif'],
      }
    },
  },
  plugins: [],
};
