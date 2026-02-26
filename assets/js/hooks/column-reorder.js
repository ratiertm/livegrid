// Column Reorder Hook (드래그&드롭으로 컬럼 순서 변경 + 클릭 시 정렬)
export const ColumnReorder = {
  mounted() {
    this.isDragging = false
    this.startX = 0
    this.startY = 0
    this.ghost = null
    this.indicator = null
    this.dragThreshold = 5
    this.sourceField = this.el.dataset.field
    this.isFrozen = this.el.dataset.frozen === "true"

    this.handleMouseDown = (e) => {
      if (window.__gridResizing) return
      if (e.target.closest && e.target.closest(".lv-grid__resize-handle")) return
      if (e.target.classList.contains("lv-grid__resize-handle")) return

      this.startX = e.clientX
      this.startY = e.clientY
      this.isDragging = false

      const onMouseMove = (e) => {
        if (window.__gridResizing) {
          document.removeEventListener("mousemove", onMouseMove)
          document.removeEventListener("mouseup", onMouseUp)
          this.isDragging = false
          return
        }

        if (this.isFrozen) return

        const dx = e.clientX - this.startX
        const dy = e.clientY - this.startY
        const distance = Math.sqrt(dx * dx + dy * dy)

        if (!this.isDragging && distance > this.dragThreshold) {
          this.isDragging = true
          this.startDrag(e)
        }

        if (this.isDragging) {
          this.onDrag(e)
        }
      }

      const onMouseUp = (e) => {
        document.removeEventListener("mousemove", onMouseMove)
        document.removeEventListener("mouseup", onMouseUp)

        if (this.isDragging) {
          e.preventDefault()
          e.stopPropagation()
          this.endDrag(e)
        } else {
          this.handleSort()
        }
        this.isDragging = false
      }

      document.addEventListener("mousemove", onMouseMove)
      document.addEventListener("mouseup", onMouseUp)
    }

    this.el.addEventListener("mousedown", this.handleMouseDown)
  },

  handleSort() {
    const sortable = this.el.dataset.sortable === "true"
    if (!sortable) return

    const field = this.el.dataset.field
    const direction = this.el.dataset.sortDirection
    const target = this.el.getAttribute("phx-target")

    if (target && field) {
      this.pushEventTo(target, "grid_sort", {field: field, direction: direction})
    }
  },

  startDrag(e) {
    this.el.classList.add("lv-grid__header-cell--dragging")
    document.body.style.userSelect = "none"
    document.body.style.cursor = "grabbing"

    this.ghost = this.el.cloneNode(true)
    this.ghost.classList.add("lv-grid__header-cell--ghost")
    this.ghost.style.width = this.el.offsetWidth + "px"
    this.ghost.style.position = "fixed"
    this.ghost.style.pointerEvents = "none"
    this.ghost.style.zIndex = "9999"
    document.body.appendChild(this.ghost)

    this.indicator = document.createElement("div")
    this.indicator.className = "lv-grid__reorder-indicator"
    const header = this.el.closest(".lv-grid__header")
    if (header) {
      header.style.position = "relative"
      header.appendChild(this.indicator)
    }

    this.updateGhostPosition(e)
  },

  onDrag(e) {
    this.updateGhostPosition(e)
    this.updateIndicator(e)
  },

  updateGhostPosition(e) {
    if (!this.ghost) return
    this.ghost.style.left = (e.clientX - this.el.offsetWidth / 2) + "px"
    this.ghost.style.top = (e.clientY - 24) + "px"
  },

  updateIndicator(e) {
    if (!this.indicator) return
    const header = this.el.closest(".lv-grid__header")
    if (!header) return

    const cells = Array.from(header.querySelectorAll(".lv-grid__header-cell[data-field]:not([data-frozen='true'])"))
    let closestCell = null
    let insertBefore = true
    let minDist = Infinity

    cells.forEach(cell => {
      const rect = cell.getBoundingClientRect()
      const midX = rect.left + rect.width / 2

      const dist = Math.abs(e.clientX - midX)
      if (dist < minDist) {
        minDist = dist
        closestCell = cell
        insertBefore = e.clientX < midX
      }
    })

    if (closestCell) {
      const rect = closestCell.getBoundingClientRect()
      const headerRect = header.getBoundingClientRect()
      const x = insertBefore ? rect.left - headerRect.left : rect.right - headerRect.left
      this.indicator.style.left = x + "px"
      this.indicator.style.top = "0"
      this.indicator.style.height = header.offsetHeight + "px"
      this.indicator.style.display = "block"

      this._dropTarget = closestCell
      this._insertBefore = insertBefore
    }
  },

  endDrag(e) {
    this.el.classList.remove("lv-grid__header-cell--dragging")
    document.body.style.userSelect = ""
    document.body.style.cursor = ""

    if (this.ghost) {
      this.ghost.remove()
      this.ghost = null
    }
    if (this.indicator) {
      this.indicator.remove()
      this.indicator = null
    }

    if (this._dropTarget) {
      const header = this.el.closest(".lv-grid__header")
      if (!header) return

      const cells = Array.from(header.querySelectorAll(".lv-grid__header-cell[data-field]:not([data-frozen='true'])"))
      const fields = cells.map(c => c.dataset.field)
      const sourceIdx = fields.indexOf(this.sourceField)
      const targetField = this._dropTarget.dataset.field

      if (sourceIdx >= 0 && targetField !== this.sourceField) {
        fields.splice(sourceIdx, 1)
        let targetIdx = fields.indexOf(targetField)
        if (!this._insertBefore) {
          targetIdx += 1
        }
        fields.splice(targetIdx, 0, this.sourceField)

        const target = this.el.getAttribute("phx-target")
        if (target) {
          this.pushEventTo(target, "grid_column_reorder", {order: fields})
        }
      }

      this._dropTarget = null
      this._insertBefore = true
    }
  },

  destroyed() {
    if (this.handleMouseDown) {
      this.el.removeEventListener("mousedown", this.handleMouseDown)
    }
  }
}
