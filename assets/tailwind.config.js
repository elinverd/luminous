// https://tailwindcss.com/docs/configuration
module.exports = {
  mode: "jit",
  content: ["../lib/luminous/*", "../lib/luminous/panel/*"],
  darkMode: 'media', // or 'media' or 'class'
  corePlugins: {
    textOpacity: false,
    backgroundOpacity: false,
    borderOpacity: false
  },
  plugins: [
    require('@tailwindcss/forms'),
  ]
}
