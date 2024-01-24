function MultiSelectVariableHook() {
  this.mounted = function() {
    this.state = {open: false, values: null}

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
        this.pushEventTo("#" + this.el.id, "variable_updated", {variable: e.detail.var_id, value: this.state.values})
      }
    })
  }
}

export default MultiSelectVariableHook;
