function MultiSelectVariableHook() {
  this.mounted = function() {
    this.state = {open: false, values: []}

    document.getElementById(this.el.id).addEventListener('dropdownOpen', (e) => {
      this.state.open = true
      this.state.values = e.detail.values
    })

    // if the clicked item exists in the state, it is removed
    // otherwise it is added to the state
    document.getElementById(this.el.id).addEventListener('valueClicked', (e) => {
      const index = this.state.values.indexOf(e.detail.value)

      if (index > -1) {
        this.state.values.splice(index, 1)
      } else {
        this.state.values.push(e.detail.value)
      }
    })

    document.getElementById(this.el.id).addEventListener('clickAway', (e) => {
      if (this.state.open) {
        this.state.open = false
        this.pushEventTo("#" + this.el.id, "lmn_variable_updated", {variable: e.detail.var_id, value: this.state.values})
      }
    })

    document.getElementById(this.el.id).addEventListener('itemSearch', (e) => {
      const text_to_search = document.getElementById(e.detail.input_id).value.toLowerCase()
      const list = document.getElementById(e.detail.list_id)

      for (const list_item of list.children) {
        if (list_item.textContent.toLowerCase().includes(text_to_search)) {
          list_item.style.display = 'list-item'
        } else {
          list_item.style.display = 'none'
        }
      }
    })

    document.getElementById(this.el.id).addEventListener('clearSelection', (e) => {
      const list = document.getElementById(e.detail.list_id)

      for (const input of list.getElementsByTagName("input")) {
        if (input.getAttribute("type") === "checkbox" && input.checked === true) {
          input.click()
        }
      }
    })

    document.getElementById(this.el.id).addEventListener('selectAll', (e) => {
      const list = document.getElementById(e.detail.list_id)

      for (const input of list.getElementsByTagName("input")) {
        if (input.getAttribute("type") === "checkbox" && input.checked === false) {
          input.click()
        }
      }
    })
  }
}

export default MultiSelectVariableHook;
