// 글로벌 리사이즈 플래그 (ColumnReorder와 충돌 방지)
window.__gridResizing = false

// Column Resize Hook (컬럼 너비 드래그 조절)
export const ColumnResize = {
  mounted() {
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()

      window.__gridResizing = true

      const headerCell = this.el.parentElement
      const columnIndex = this.el.dataset.colIndex
      const columnField = this.el.dataset.field
      const startX = e.clientX
      const startWidth = headerCell.offsetWidth
      let finalWidth = startWidth

      document.body.style.cursor = "col-resize"
      document.body.style.userSelect = "none"

      const handleMouseMove = (e) => {
        const diff = e.clientX - startX
        finalWidth = Math.max(50, startWidth + diff)

        const grid = headerCell.closest(".lv-grid")
        if (grid) {
          const selector = `[data-col-index="${columnIndex}"]`
          grid.querySelectorAll(`.lv-grid__header-cell${selector}, .lv-grid__filter-cell${selector}, .lv-grid__cell${selector}`).forEach(cell => {
            cell.style.width = finalWidth + "px"
            cell.style.flex = `0 0 ${finalWidth}px`
          })
        }
      }

      const handleMouseUp = () => {
        document.body.style.cursor = ""
        document.body.style.userSelect = ""
        document.removeEventListener("mousemove", handleMouseMove)
        document.removeEventListener("mouseup", handleMouseUp)

        if (finalWidth !== startWidth && columnField) {
          const target = headerCell.getAttribute("phx-target")
          if (target) {
            this.pushEventTo(target, "grid_column_resize", {
              field: columnField,
              width: String(Math.round(finalWidth))
            })
          }
        }

        setTimeout(() => { window.__gridResizing = false }, 0)
      }

      document.addEventListener("mousemove", handleMouseMove)
      document.addEventListener("mouseup", handleMouseUp)
    }

    this.handleDblClick = (e) => {
      e.preventDefault()
      e.stopPropagation()

      const headerCell = this.el.parentElement
      const columnIndex = this.el.dataset.colIndex
      const columnField = this.el.dataset.field
      const grid = headerCell.closest(".lv-grid")
      if (!grid || !columnField) return

      // Measure max content width using a hidden canvas
      const canvas = document.createElement("canvas")
      const ctx = canvas.getContext("2d")
      const style = getComputedStyle(headerCell)
      ctx.font = style.font || "14px sans-serif"

      let maxWidth = 0

      // Measure header text
      const headerText = headerCell.querySelector(".lv-grid__header-text")
      if (headerText) {
        maxWidth = Math.max(maxWidth, ctx.measureText(headerText.textContent.trim()).width)
      }

      // Measure all data cells in this column
      const cells = grid.querySelectorAll(`.lv-grid__cell[data-col-index="${columnIndex}"]`)
      cells.forEach(cell => {
        const text = cell.textContent.trim()
        if (text) {
          maxWidth = Math.max(maxWidth, ctx.measureText(text).width)
        }
      })

      // Add padding (16px each side + border)
      const fitWidth = Math.min(500, Math.max(50, Math.ceil(maxWidth) + 40))

      // Apply to all cells
      const selector = `[data-col-index="${columnIndex}"]`
      grid.querySelectorAll(`.lv-grid__header-cell${selector}, .lv-grid__filter-cell${selector}, .lv-grid__cell${selector}`).forEach(cell => {
        cell.style.width = fitWidth + "px"
        cell.style.flex = `0 0 ${fitWidth}px`
      })

      // Push to server
      const target = headerCell.getAttribute("phx-target")
      if (target) {
        this.pushEventTo(target, "grid_column_resize", {
          field: columnField,
          width: String(fitWidth)
        })
      }
    }

    this.el.addEventListener("mousedown", this.handleMouseDown)
    this.el.addEventListener("dblclick", this.handleDblClick)
  },

  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown)
    this.el.removeEventListener("dblclick", this.handleDblClick)
  }
}
