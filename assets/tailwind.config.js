// https://tailwindcss.com/docs/configuration
const colors = require('tailwindcss/colors')

module.exports = {
  mode: "jit",
  content: ["./js/*.js", "../lib/luminous/components.ex"],
  darkMode: 'media', // or 'media' or 'class'
  corePlugins: {
    textOpacity: false,
    backgroundOpacity: false,
    borderOpacity: false
  },
  plugins: [
    require('daisyui'),
  ]
}
