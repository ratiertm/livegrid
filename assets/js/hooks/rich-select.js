// FA-035: Rich Select Editor Hook
// 검색 가능한 드롭다운 셀렉트 에디터
export const RichSelect = {
  mounted() {
    this.options = JSON.parse(this.el.dataset.options || "[]")
    this.currentValue = this.el.dataset.currentValue || ""
    this.highlightedIdx = -1
    this.filteredOptions = [...this.options]

    this._render()
    this._focusInput()
  },

  _render() {
    const currentLabel = this._labelForValue(this.currentValue)

    this.el.innerHTML = `
      <input
        type="text"
        class="lv-grid__rich-select-search"
        placeholder="검색..."
        value="${this._escapeHtml(currentLabel)}"
        autocomplete="off"
      />
      <div class="lv-grid__rich-select-options">
        ${this._renderOptions()}
      </div>
    `

    this.input = this.el.querySelector(".lv-grid__rich-select-search")
    this.optionsList = this.el.querySelector(".lv-grid__rich-select-options")

    // 입력 이벤트
    this.input.addEventListener("input", () => {
      this._filterOptions(this.input.value)
    })

    // 키보드 이벤트
    this.input.addEventListener("keydown", (e) => {
      switch (e.key) {
        case "ArrowDown":
          e.preventDefault()
          this._moveHighlight(1)
          break
        case "ArrowUp":
          e.preventDefault()
          this._moveHighlight(-1)
          break
        case "Enter":
          e.preventDefault()
          if (this.highlightedIdx >= 0 && this.highlightedIdx < this.filteredOptions.length) {
            this._selectOption(this.filteredOptions[this.highlightedIdx])
          }
          break
        case "Escape":
          e.preventDefault()
          this._cancel()
          break
        case "Tab":
          if (this.highlightedIdx >= 0 && this.highlightedIdx < this.filteredOptions.length) {
            this._selectOption(this.filteredOptions[this.highlightedIdx])
          } else {
            this._cancel()
          }
          break
      }
    })

    // 옵션 클릭
    this.optionsList.addEventListener("click", (e) => {
      const optionEl = e.target.closest(".lv-grid__rich-select-option")
      if (optionEl) {
        const value = optionEl.dataset.value
        const option = this.options.find(o => o.value === value)
        if (option) this._selectOption(option)
      }
    })
  },

  _renderOptions() {
    return this.filteredOptions.map((opt, idx) => {
      const selected = opt.value === this.currentValue ? " lv-grid__rich-select-option--selected" : ""
      const highlighted = idx === this.highlightedIdx ? " lv-grid__rich-select-option--highlighted" : ""
      return `<div class="lv-grid__rich-select-option${selected}${highlighted}" data-value="${this._escapeHtml(opt.value)}" data-idx="${idx}">${this._escapeHtml(opt.label)}</div>`
    }).join("")
  },

  _filterOptions(query) {
    const lower = query.toLowerCase()
    this.filteredOptions = this.options.filter(o =>
      o.label.toLowerCase().includes(lower) || o.value.toLowerCase().includes(lower)
    )
    this.highlightedIdx = this.filteredOptions.length > 0 ? 0 : -1
    this.optionsList.innerHTML = this._renderOptions()
  },

  _moveHighlight(delta) {
    if (this.filteredOptions.length === 0) return
    this.highlightedIdx = Math.max(0, Math.min(this.filteredOptions.length - 1, this.highlightedIdx + delta))
    this.optionsList.innerHTML = this._renderOptions()

    // 하이라이트된 옵션 스크롤
    const highlighted = this.optionsList.querySelector(".lv-grid__rich-select-option--highlighted")
    if (highlighted) highlighted.scrollIntoView({ block: "nearest" })
  },

  _selectOption(option) {
    this.pushEventTo(this.el, "cell_edit_save", {
      "row-id": this.el.dataset.rowId,
      "field": this.el.dataset.field,
      "value": option.value
    })
  },

  _cancel() {
    this.pushEventTo(this.el, "cell_edit_cancel", {
      "row-id": this.el.dataset.rowId,
      "field": this.el.dataset.field
    })
  },

  _labelForValue(value) {
    const opt = this.options.find(o => o.value === value)
    return opt ? opt.label : value
  },

  _focusInput() {
    requestAnimationFrame(() => {
      if (this.input) {
        this.input.focus()
        this.input.select()
      }
    })
  },

  _escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
