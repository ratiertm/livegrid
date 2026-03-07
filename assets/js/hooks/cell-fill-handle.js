/**
 * CellFillHandle Hook
 * Excel-style cell fill handle - drag to autofill adjacent cells.
 *
 * Attached to the fill handle element (small square at cell corner).
 * On mousedown+drag, calculates target row range and sends fill event.
 */
export const CellFillHandle = {
  mounted() {
    this.isDragging = false
    this.startRowId = null
    this.startColField = null
    this.highlightedCells = []

    this.el.addEventListener("mousedown", (e) => {
      e.preventDefault()
      e.stopPropagation()

      this.isDragging = true
      this.startRowId = this.el.dataset.rowId
      this.startColField = this.el.dataset.field

      // Add global mouse listeners
      document.addEventListener("mousemove", this.handleMouseMove)
      document.addEventListener("mouseup", this.handleMouseUp)

      // Add dragging class
      this.el.closest(".lv-grid__body")?.classList.add("lv-grid--fill-dragging")
    })

    this.handleMouseMove = (e) => {
      if (!this.isDragging) return

      // Find the cell under cursor
      const target = document.elementFromPoint(e.clientX, e.clientY)
      if (!target) return

      const cell = target.closest(".lv-grid__cell")
      const row = target.closest(".lv-grid__row")
      if (!cell || !row) return

      const rowId = row.dataset.rowId
      if (!rowId) return

      // Clear previous highlights
      this.clearHighlights()

      // Highlight range from start to current
      const allRows = Array.from(
        this.el.closest(".lv-grid__body")?.querySelectorAll(".lv-grid__row[data-row-id]") || []
      )
      const startIdx = allRows.findIndex(r => r.dataset.rowId === this.startRowId)
      const endIdx = allRows.findIndex(r => r.dataset.rowId === rowId)

      if (startIdx === -1 || endIdx === -1) return

      const minIdx = Math.min(startIdx, endIdx)
      const maxIdx = Math.max(startIdx, endIdx)

      // Get column index
      const colIdx = this.el.dataset.colIndex

      for (let i = minIdx; i <= maxIdx; i++) {
        if (i === startIdx) continue // Skip source cell
        const targetCell = allRows[i].querySelector(`[data-col-index="${colIdx}"]`)
        if (targetCell) {
          targetCell.classList.add("lv-grid__cell--fill-target")
          this.highlightedCells.push(targetCell)
        }
      }

      this.lastRowId = rowId
    }

    this.handleMouseUp = (e) => {
      if (!this.isDragging) return
      this.isDragging = false

      document.removeEventListener("mousemove", this.handleMouseMove)
      document.removeEventListener("mouseup", this.handleMouseUp)

      this.el.closest(".lv-grid__body")?.classList.remove("lv-grid--fill-dragging")

      // Collect target row IDs
      const targetRowIds = this.highlightedCells
        .map(cell => cell.closest(".lv-grid__row")?.dataset.rowId)
        .filter(Boolean)

      this.clearHighlights()

      if (targetRowIds.length > 0) {
        const target = this.el.getAttribute("phx-target")
        this.pushEventTo(target, "grid_cell_fill", {
          source_row_id: this.startRowId,
          field: this.startColField,
          target_row_ids: targetRowIds
        })
      }
    }
  },

  clearHighlights() {
    this.highlightedCells.forEach(cell => {
      cell.classList.remove("lv-grid__cell--fill-target")
    })
    this.highlightedCells = []
  },

  destroyed() {
    document.removeEventListener("mousemove", this.handleMouseMove)
    document.removeEventListener("mouseup", this.handleMouseUp)
  }
}
