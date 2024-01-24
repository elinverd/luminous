// https://tailwindcss.com/docs/configuration
module.exports = {
  mode: "jit",
  content: ["../lib/luminous/components.ex"],
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
