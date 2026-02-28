// Config Modal Sortable Hook (드래그&드롭으로 컬럼 순서 변경)
export const ConfigSortable = {
  mounted() {
    this.initDrag()
  },

  updated() {
    this.initDrag()
  },

  initDrag() {
    const items = this.el.querySelectorAll("[data-sortable-item]")
    items.forEach(item => {
      item.setAttribute("draggable", "true")

      item.addEventListener("dragstart", (e) => {
        this._dragField = item.dataset.field
        item.classList.add("opacity-50")
        e.dataTransfer.effectAllowed = "move"
        e.dataTransfer.setData("text/plain", item.dataset.field)
      })

      item.addEventListener("dragend", () => {
        item.classList.remove("opacity-50")
        this.el.querySelectorAll("[data-sortable-item]").forEach(i => {
          i.classList.remove("border-t-2", "border-b-2", "border-blue-500")
        })
      })

      item.addEventListener("dragover", (e) => {
        e.preventDefault()
        e.dataTransfer.dropEffect = "move"

        // Show drop indicator
        const rect = item.getBoundingClientRect()
        const midY = rect.top + rect.height / 2
        item.classList.remove("border-t-2", "border-b-2", "border-blue-500")
        if (e.clientY < midY) {
          item.classList.add("border-t-2", "border-blue-500")
        } else {
          item.classList.add("border-b-2", "border-blue-500")
        }
      })

      item.addEventListener("dragleave", () => {
        item.classList.remove("border-t-2", "border-b-2", "border-blue-500")
      })

      item.addEventListener("drop", (e) => {
        e.preventDefault()
        item.classList.remove("border-t-2", "border-b-2", "border-blue-500")

        const sourceField = e.dataTransfer.getData("text/plain")
        const targetField = item.dataset.field
        if (sourceField === targetField) return

        // Calculate insert position
        const rect = item.getBoundingClientRect()
        const midY = rect.top + rect.height / 2
        const insertBefore = e.clientY < midY

        // Build new order
        const allItems = this.el.querySelectorAll("[data-sortable-item]")
        const fields = Array.from(allItems).map(i => i.dataset.field)
        const sourceIdx = fields.indexOf(sourceField)
        if (sourceIdx < 0) return

        fields.splice(sourceIdx, 1)
        let targetIdx = fields.indexOf(targetField)
        if (!insertBefore) targetIdx += 1
        fields.splice(targetIdx, 0, sourceField)

        this.pushEventTo(this.el, "reorder_columns", { order: fields })
      })
    })
  }
}
