// Row Reorder Hook (F-930: 드래그&드롭으로 행 순서 변경)
export const RowReorder = {
  mounted() {
    this.isDragging = false
    this.startY = 0
    this.ghost = null
    this.indicator = null
    this.dragThreshold = 5
    this.sourceRowId = this.el.dataset.rowId

    const handle = this.el.querySelector(".lv-grid__row-drag-handle")
    if (!handle) return

    this.handleMouseDown = (e) => {
      e.preventDefault()
      this.startY = e.clientY
      this.isDragging = false

      const onMouseMove = (moveE) => {
        const dy = Math.abs(moveE.clientY - this.startY)
        if (!this.isDragging && dy > this.dragThreshold) {
          this.isDragging = true
          this.startDrag(moveE)
        }
        if (this.isDragging) {
          this.onDrag(moveE)
        }
      }

      const onMouseUp = (upE) => {
        document.removeEventListener("mousemove", onMouseMove)
        document.removeEventListener("mouseup", onMouseUp)
        if (this.isDragging) {
          this.endDrag(upE)
        }
        this.isDragging = false
      }

      document.addEventListener("mousemove", onMouseMove)
      document.addEventListener("mouseup", onMouseUp)
    }

    handle.addEventListener("mousedown", this.handleMouseDown)
  },

  startDrag(e) {
    this.el.classList.add("lv-grid__row--dragging")
    document.body.style.userSelect = "none"
    document.body.style.cursor = "grabbing"

    this.ghost = this.el.cloneNode(true)
    this.ghost.classList.add("lv-grid__row--ghost")
    this.ghost.style.position = "fixed"
    this.ghost.style.width = this.el.offsetWidth + "px"
    this.ghost.style.pointerEvents = "none"
    this.ghost.style.zIndex = "9999"
    document.body.appendChild(this.ghost)

    this.indicator = document.createElement("div")
    this.indicator.className = "lv-grid__row-drop-indicator"
    const body = this.el.closest(".lv-grid__body")
    if (body) {
      body.style.position = "relative"
      body.appendChild(this.indicator)
    }

    this.updateGhostPosition(e)
  },

  onDrag(e) {
    this.updateGhostPosition(e)
    this.updateIndicator(e)
  },

  updateGhostPosition(e) {
    if (!this.ghost) return
    this.ghost.style.left = this.el.getBoundingClientRect().left + "px"
    this.ghost.style.top = (e.clientY - 20) + "px"
  },

  updateIndicator(e) {
    if (!this.indicator) return
    const body = this.el.closest(".lv-grid__body")
    if (!body) return

    const rows = Array.from(body.querySelectorAll(".lv-grid__row[data-row-id]"))
    let closest = null
    let minDist = Infinity

    rows.forEach(row => {
      const rect = row.getBoundingClientRect()
      const midY = rect.top + rect.height / 2
      const dist = Math.abs(e.clientY - midY)
      if (dist < minDist) {
        minDist = dist
        closest = row
        this._insertBefore = e.clientY < midY
      }
    })

    if (closest) {
      const rect = closest.getBoundingClientRect()
      const bodyRect = body.getBoundingClientRect()
      const y = this._insertBefore ? rect.top - bodyRect.top + body.scrollTop : rect.bottom - bodyRect.top + body.scrollTop
      this.indicator.style.top = y + "px"
      this.indicator.style.display = "block"
      this._dropTarget = closest
    }
  },

  endDrag(_e) {
    this.el.classList.remove("lv-grid__row--dragging")
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
      const targetRowId = this._dropTarget.dataset.rowId
      if (targetRowId && targetRowId !== this.sourceRowId) {
        const target = this.el.getAttribute("phx-target")
        if (target) {
          this.pushEventTo(target, "grid_move_row", {
            from_id: this.sourceRowId,
            to_id: targetRowId
          })
        }
      }
      this._dropTarget = null
    }
  },

  destroyed() {
    const handle = this.el.querySelector(".lv-grid__row-drag-handle")
    if (handle && this.handleMouseDown) {
      handle.removeEventListener("mousedown", this.handleMouseDown)
    }
  }
}
