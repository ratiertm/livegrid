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

    this.el.addEventListener("mousedown", this.handleMouseDown)
  },

  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown)
  }
}
