// Keyboard Navigation Hook (F-810) + Cell Range Selection (F-940)
export const GridKeyboardNav = {
  mounted() {
    this.focusedRowId = null
    this.focusedColIdx = null
    this.isEditing = false
    this.pendingFocus = null

    // F-940: Cell Range Selection
    this.cellRange = null  // {anchorRowId, anchorColIdx, extentRowId, extentColIdx}
    this.isDragging = false
    this.dragAnchorRowId = null
    this.dragAnchorColIdx = null

    this.el.setAttribute("tabindex", "0")

    this.rebuildNavigationMap()

    // F-940: mousedown (기존 click 대체) → 셀 포커스 + Shift 범위 + 드래그 시작
    this.el.addEventListener("mousedown", (e) => {
      if (this.isEditing) return
      // 체크박스, 버튼 등은 무시
      if (e.target.closest("input, button, select")) return

      const cell = e.target.closest(".lv-grid__cell[data-col-index]")
      const row = e.target.closest(".lv-grid__row[data-row-id]")
      if (!cell || !row) return

      const rowId = parseInt(row.dataset.rowId)
      const colIdx = parseInt(cell.dataset.colIndex)

      if (e.shiftKey && this.focusedRowId !== null) {
        // Shift+Click: 현재 포커스 → 앵커, 클릭셀 → extent
        e.preventDefault()
        this.setCellRange(this.focusedRowId, this.focusedColIdx, rowId, colIdx)
        this.pushCellRangeToServer()
      } else {
        // 일반 클릭: 범위 해제 + 단일 포커스 + 드래그 시작
        if (this.cellRange) {
          this.clearCellRange()
          this.pushEventTo(this.el, "clear_cell_range", {})
        }
        this.setFocus(rowId, colIdx)
        this.isDragging = true
        this.dragAnchorRowId = rowId
        this.dragAnchorColIdx = colIdx
        this.el.classList.add("lv-grid--selecting")
      }
    })

    // F-940: mousemove → 드래그 범위 확장
    this.el.addEventListener("mousemove", (e) => {
      if (!this.isDragging || this.isEditing) return
      const cell = e.target.closest(".lv-grid__cell[data-col-index]")
      const row = e.target.closest(".lv-grid__row[data-row-id]")
      if (!cell || !row) return

      const rowId = parseInt(row.dataset.rowId)
      const colIdx = parseInt(cell.dataset.colIndex)

      // 앵커와 다른 셀로 이동했을 때만 범위 생성
      if (rowId !== this.dragAnchorRowId || colIdx !== this.dragAnchorColIdx) {
        this.setCellRange(this.dragAnchorRowId, this.dragAnchorColIdx, rowId, colIdx)
      }
    })

    // F-940: mouseup → 드래그 종료
    this._onMouseUp = () => {
      if (this.isDragging) {
        this.isDragging = false
        this.el.classList.remove("lv-grid--selecting")
        if (this.cellRange) {
          this.pushCellRangeToServer()
        }
      }
    }
    document.addEventListener("mouseup", this._onMouseUp)

    // 키다운 -> 내비게이션 + F-700: Undo/Redo (Ctrl+Z/Y) + F-940: Ctrl+C, Shift+Arrow
    this.el.addEventListener("keydown", (e) => {
      if (!this.isEditing) {
        if ((e.ctrlKey || e.metaKey) && e.key === "z" && !e.shiftKey) {
          e.preventDefault()
          this.pushEvent("grid_undo", {})
          return
        }
        if ((e.ctrlKey || e.metaKey) && (e.key === "y" || (e.key === "z" && e.shiftKey))) {
          e.preventDefault()
          this.pushEvent("grid_redo", {})
          return
        }
        // FA-044: Ctrl+F → Find & Highlight 바 토글
        if ((e.ctrlKey || e.metaKey) && e.key === "f") {
          e.preventDefault()
          this.pushEventTo(this.el, "toggle_find_bar", {})
          return
        }
        // F-940: Ctrl+C → JS에서 직접 DOM 읽기 + 클립보드 쓰기
        if ((e.ctrlKey || e.metaKey) && e.key === "c") {
          e.preventDefault()
          if (this.cellRange) {
            this._copyRangeToClipboard()
          } else if (this.focusedRowId !== null) {
            this._copyCellToClipboard(this.focusedRowId, this.focusedColIdx)
          }
          return
        }
      }
      if (this.isEditing) return
      this.handleKeydown(e)
    })

    // F-900: 셀 툴팁
    this.el.addEventListener("mouseenter", (e) => {
      const cellValue = e.target.closest(".lv-grid__cell-value")
      if (!cellValue) return
      if (cellValue.scrollWidth > cellValue.clientWidth) {
        cellValue.title = cellValue.textContent.trim()
      } else {
        cellValue.removeAttribute("title")
      }
    }, true)

    // FA-037: Column Hover Highlight
    this._hoveredColIdx = null
    this.el.addEventListener("mouseenter", (e) => {
      if (!this.el.dataset.columnHoverHighlight) return
      const cell = e.target.closest(".lv-grid__cell[data-col-index], .lv-grid__header-cell[data-col-index]")
      if (!cell) return
      const colIdx = cell.dataset.colIndex
      if (colIdx === this._hoveredColIdx) return
      this._clearColumnHover()
      this._hoveredColIdx = colIdx
      this.el.querySelectorAll(`.lv-grid__cell[data-col-index="${colIdx}"], .lv-grid__header-cell[data-col-index="${colIdx}"]`).forEach(el => {
        el.classList.add("lv-grid__cell--col-hover")
      })
    }, true)

    this.el.addEventListener("mouseleave", () => {
      this._clearColumnHover()
    })

    // F-932: 클립보드 붙여넣기
    this.el.addEventListener("paste", (e) => {
      if (this.isEditing) return
      if (this.focusedRowId === null || this.focusedColIdx === null) return

      const text = (e.clipboardData || window.clipboardData).getData("text")
      if (!text || !text.trim()) return

      e.preventDefault()

      const rows = text.trim().split(/\r?\n/).map(line => line.split("\t"))

      this.pushEvent("paste_cells", {
        start_row_id: this.focusedRowId,
        start_col_idx: this.focusedColIdx,
        data: rows
      })
    })

    // F-800: 우클릭 컨텍스트 메뉴
    this.el.addEventListener("contextmenu", (e) => {
      if (this.isEditing) return
      const cell = e.target.closest(".lv-grid__cell[data-col-index]")
      const row = e.target.closest(".lv-grid__row[data-row-id]")
      if (cell && row) {
        e.preventDefault()
        this.pushEventTo(this.el, "show_context_menu", {
          row_id: parseInt(row.dataset.rowId),
          col_idx: parseInt(cell.dataset.colIndex),
          x: e.clientX,
          y: e.clientY
        })
      }
    })

    // F-800: 컨텍스트 메뉴 복사 액션 인터셉트 (사용자 제스처 내에서 클립보드 쓰기)
    this.el.addEventListener("click", (e) => {
      const menuItem = e.target.closest(".lv-grid__context-menu-item")
      if (!menuItem) return

      const action = menuItem.getAttribute("phx-value-action")
      if (action === "copy_cell" || action === "copy_row") {
        const rowId = parseInt(menuItem.getAttribute("phx-value-row-id"))
        const colIdx = parseInt(menuItem.getAttribute("phx-value-col-idx"))

        if (action === "copy_cell") {
          this._copyCellToClipboard(rowId, colIdx)
        } else {
          this._copyRowToClipboard(rowId)
        }
      }
    })

    // F-800: 클립보드 쓰기 폴백 (서버 push_event 경유 시)
    this.handleEvent("clipboard_write", ({text}) => {
      this._writeToClipboard(text)
    })

    // (D) F-800-INSERT: 서버 → 특정 행으로 스크롤
    this.handleEvent("scroll_to_row", ({row_id}) => {
      const rowEl = this.el.querySelector(`.lv-grid__row[data-row-id="${row_id}"]`)
      if (rowEl) {
        rowEl.scrollIntoView({block: "nearest", behavior: "smooth"})
      }
    })

    // (E) F-800-INSERT: 서버 → 특정 셀에 포커스
    this.handleEvent("focus_cell", ({row_id, col_idx}) => {
      if (this.rowIds && this.rowIds.includes(row_id)) {
        this.setFocus(row_id, col_idx)
      } else {
        // 가상 스크롤: 행이 아직 DOM에 없으면 pendingFocus로 지연
        this.pendingFocus = {rowId: row_id, colIdx: col_idx}
      }
    })

    // 서버 이벤트: 편집 종료 후 포커스 이동
    this.handleEvent("grid_edit_ended", ({direction, row_id, field}) => {
      this.isEditing = false

      if (direction === "down") {
        if (this.focusedRowId !== null) {
          this.moveFocus(1, 0)
        }
      } else if (direction === "next_editable") {
        this.moveToNextEditable(1)
      } else if (direction === "prev_editable") {
        this.moveToNextEditable(-1)
      } else if (direction === "stay") {
        this.reapplyFocusVisual()
      }

      requestAnimationFrame(() => this.el.focus())
    })
  },

  updated() {
    this.rebuildNavigationMap()

    const hasEditor = !!this.el.querySelector('input[phx-hook="CellEditor"], select[phx-hook="CellEditor"]')
    if (hasEditor) {
      this.isEditing = true
    } else if (this.isEditing) {
      this.isEditing = false
    }

    if (this.pendingFocus) {
      const {rowId, colIdx} = this.pendingFocus
      this.pendingFocus = null
      if (this.rowIds.includes(rowId)) {
        this.setFocus(rowId, colIdx)
      }
    } else if (this.focusedRowId !== null && !this.isEditing) {
      if (this.rowIds.includes(this.focusedRowId)) {
        this.reapplyFocusVisual()
        requestAnimationFrame(() => this.el.focus())
      } else {
        this.clearFocus()
      }
    }

    // F-940: 스크롤/리렌더 후 범위 시각 재적용
    if (this.cellRange) {
      this.applyCellRangeVisual()
    }
  },

  handleKeydown(e) {
    const key = e.key

    if (this.focusedRowId === null) {
      if (["ArrowUp","ArrowDown","ArrowLeft","ArrowRight","Tab"].includes(key)) {
        e.preventDefault()
        this.focusFirstCell()
      }
      return
    }

    switch (key) {
      case "ArrowUp":
        e.preventDefault()
        if (e.shiftKey) {
          this.extendRange(-1, 0)
        } else {
          this.clearCellRangeAndSync()
          // macOS: Command+Up = Ctrl+Home (jump to first cell)
          if (e.metaKey) {
            if (this.rowIds.length > 0 && this.colIndices.length > 0) {
              this.setFocus(this.rowIds[0], this.focusedColIdx || this.colIndices[0])
            }
          } else {
            this.moveFocus(-1, 0)
          }
        }
        break
      case "ArrowDown":
        e.preventDefault()
        if (e.shiftKey) {
          this.extendRange(1, 0)
        } else {
          this.clearCellRangeAndSync()
          // macOS: Command+Down = Ctrl+End (jump to last cell)
          if (e.metaKey) {
            if (this.rowIds.length > 0 && this.colIndices.length > 0) {
              this.setFocus(this.rowIds[this.rowIds.length - 1], this.focusedColIdx || this.colIndices[this.colIndices.length - 1])
            }
          } else {
            this.moveFocus(1, 0)
          }
        }
        break
      case "ArrowLeft":
        e.preventDefault()
        if (e.shiftKey) {
          this.extendRange(0, -1)
        } else {
          this.clearCellRangeAndSync()
          // macOS: Command+Left = Home (first column in row)
          if (e.metaKey) {
            if (this.colIndices.length > 0) {
              this.setFocus(this.focusedRowId, this.colIndices[0])
            }
          } else {
            this.moveFocus(0, -1)
          }
        }
        break
      case "ArrowRight":
        e.preventDefault()
        if (e.shiftKey) {
          this.extendRange(0, 1)
        } else {
          this.clearCellRangeAndSync()
          // macOS: Command+Right = End (last column in row)
          if (e.metaKey) {
            if (this.colIndices.length > 0) {
              this.setFocus(this.focusedRowId, this.colIndices[this.colIndices.length - 1])
            }
          } else {
            this.moveFocus(0, 1)
          }
        }
        break
      case "Home":
        e.preventDefault()
        if (e.ctrlKey || e.metaKey) {
          // Ctrl+Home: first cell in entire grid
          this.clearCellRangeAndSync()
          if (this.rowIds.length > 0 && this.colIndices.length > 0) {
            this.setFocus(this.rowIds[0], this.colIndices[0])
          }
        } else {
          // Home: first column in current row
          this.clearCellRangeAndSync()
          if (this.colIndices.length > 0) {
            this.setFocus(this.focusedRowId, this.colIndices[0])
          }
        }
        break
      case "End":
        e.preventDefault()
        if (e.ctrlKey || e.metaKey) {
          // Ctrl+End: last cell in entire grid
          this.clearCellRangeAndSync()
          if (this.rowIds.length > 0 && this.colIndices.length > 0) {
            this.setFocus(
              this.rowIds[this.rowIds.length - 1],
              this.colIndices[this.colIndices.length - 1]
            )
          }
        } else {
          // End: last column in current row
          this.clearCellRangeAndSync()
          if (this.colIndices.length > 0) {
            this.setFocus(this.focusedRowId, this.colIndices[this.colIndices.length - 1])
          }
        }
        break
      case "Tab":
        e.preventDefault()
        this.clearCellRangeAndSync()
        this.moveToNextEditable(e.shiftKey ? -1 : 1)
        break
      case "Enter":
      case "F2":
        e.preventDefault()
        this.clearCellRangeAndSync()
        this.enterEditMode()
        break
      case "Escape":
        e.preventDefault()
        if (this.cellRange) {
          this.clearCellRange()
          this.pushEventTo(this.el, "clear_cell_range", {})
        } else {
          this.clearFocus()
        }
        break
    }
  },

  rebuildNavigationMap() {
    const rows = this.el.querySelectorAll(".lv-grid__row[data-row-id]")
    this.rowIds = Array.from(rows).map(r => parseInt(r.dataset.rowId))

    const firstRow = rows[0]
    if (firstRow) {
      const cells = firstRow.querySelectorAll(".lv-grid__cell[data-col-index]")
      this.colIndices = Array.from(cells).map(c => parseInt(c.dataset.colIndex))
      this.editableColIndices = Array.from(cells)
        .filter(c => c.querySelector(".lv-grid__cell-value--editable"))
        .map(c => parseInt(c.dataset.colIndex))
    } else {
      this.colIndices = []
      this.editableColIndices = []
    }

    // F-940: 범위의 앵커/extent가 더 이상 DOM에 없으면 범위 해제
    if (this.cellRange) {
      const anchorOk = this.rowIds.includes(this.cellRange.anchorRowId)
      const extentOk = this.rowIds.includes(this.cellRange.extentRowId)
      if (!anchorOk || !extentOk) {
        this.cellRange = null
      }
    }
  },

  setFocus(rowId, colIdx) {
    this.clearFocusVisual()
    this.focusedRowId = rowId
    this.focusedColIdx = colIdx
    this.applyFocusVisual()
    this.scrollCellIntoView()
    this.el.focus()
  },

  moveFocus(rowDelta, colDelta) {
    const rowIndex = this.rowIds.indexOf(this.focusedRowId)
    const colIndex = this.colIndices.indexOf(this.focusedColIdx)
    if (rowIndex === -1 || colIndex === -1) return

    const newRowIndex = Math.max(0, Math.min(this.rowIds.length - 1, rowIndex + rowDelta))
    const newColIndex = Math.max(0, Math.min(this.colIndices.length - 1, colIndex + colDelta))

    if (newRowIndex === rowIndex && rowDelta !== 0) {
      const virtualBody = this.el.querySelector(".lv-grid__body--virtual")
      if (virtualBody && rowDelta !== 0) {
        const rowHeight = parseInt(virtualBody.dataset.rowHeight) || 40
        virtualBody.scrollTop += rowDelta * rowHeight
        this.pendingFocus = {
          rowId: null,
          colIdx: this.colIndices[newColIndex]
        }
        return
      }
    }

    this.setFocus(this.rowIds[newRowIndex], this.colIndices[newColIndex])
  },

  moveToNextEditable(direction) {
    if (this.editableColIndices.length === 0) return
    if (this.focusedRowId === null) {
      this.focusFirstCell()
      return
    }

    const rowIndex = this.rowIds.indexOf(this.focusedRowId)
    let editColIdx = this.editableColIndices.indexOf(this.focusedColIdx)

    if (editColIdx === -1) {
      editColIdx = direction > 0 ? 0 : this.editableColIndices.length - 1
    } else {
      editColIdx += direction
    }

    let newRowIndex = rowIndex

    if (editColIdx >= this.editableColIndices.length) {
      editColIdx = 0
      newRowIndex = Math.min(this.rowIds.length - 1, rowIndex + 1)
    } else if (editColIdx < 0) {
      editColIdx = this.editableColIndices.length - 1
      newRowIndex = Math.max(0, rowIndex - 1)
    }

    this.setFocus(this.rowIds[newRowIndex], this.editableColIndices[editColIdx])
  },

  enterEditMode() {
    const cell = this.getCellElement(this.focusedRowId, this.focusedColIdx)
    if (!cell) return
    const editable = cell.querySelector(".lv-grid__cell-value--editable")
    if (!editable) return

    this.isEditing = true
    const rowId = String(this.focusedRowId)
    const field = editable.dataset.field
    const target = editable.getAttribute("phx-target")
    this.pushEventTo(target, "cell_edit_start", {
      "row-id": rowId,
      "field": field
    })
  },

  clearFocus() {
    this.clearFocusVisual()
    this.clearCellRange()
    this.focusedRowId = null
    this.focusedColIdx = null
    this.pushEventTo(this.el, "clear_cell_range", {})
  },

  applyFocusVisual() {
    const cell = this.getCellElement(this.focusedRowId, this.focusedColIdx)
    if (cell) cell.classList.add("lv-grid__cell--focused")
  },

  clearFocusVisual() {
    const prev = this.el.querySelector(".lv-grid__cell--focused")
    if (prev) prev.classList.remove("lv-grid__cell--focused")
  },

  reapplyFocusVisual() {
    this.clearFocusVisual()
    this.applyFocusVisual()
  },

  getCellElement(rowId, colIdx) {
    const row = this.el.querySelector(`.lv-grid__row[data-row-id="${rowId}"]`)
    if (!row) return null
    return row.querySelector(`.lv-grid__cell[data-col-index="${colIdx}"]`)
  },

  scrollCellIntoView() {
    const cell = this.getCellElement(this.focusedRowId, this.focusedColIdx)
    if (cell) cell.scrollIntoView({block: "nearest", inline: "nearest"})
  },

  focusFirstCell() {
    if (this.rowIds.length > 0 && this.colIndices.length > 0) {
      this.setFocus(this.rowIds[0], this.colIndices[0])
    }
  },

  // ── F-940: Cell Range Selection Methods ──

  setCellRange(anchorRowId, anchorColIdx, extentRowId, extentColIdx) {
    this.cellRange = { anchorRowId, anchorColIdx, extentRowId, extentColIdx }
    this.applyCellRangeVisual()
  },

  extendRange(rowDelta, colDelta) {
    if (!this.cellRange) {
      // 범위가 없으면 현재 포커스를 앵커로 설정
      this.cellRange = {
        anchorRowId: this.focusedRowId,
        anchorColIdx: this.focusedColIdx,
        extentRowId: this.focusedRowId,
        extentColIdx: this.focusedColIdx
      }
    }

    const extentRowIndex = this.rowIds.indexOf(this.cellRange.extentRowId)
    const extentColIndex = this.colIndices.indexOf(this.cellRange.extentColIdx)
    if (extentRowIndex === -1 || extentColIndex === -1) return

    const newRowIndex = Math.max(0, Math.min(this.rowIds.length - 1, extentRowIndex + rowDelta))
    const newColIndex = Math.max(0, Math.min(this.colIndices.length - 1, extentColIndex + colDelta))

    this.cellRange.extentRowId = this.rowIds[newRowIndex]
    this.cellRange.extentColIdx = this.colIndices[newColIndex]

    this.applyCellRangeVisual()
    this.pushCellRangeToServer()
  },

  clearCellRange() {
    if (this.cellRange) {
      this.clearCellRangeVisual()
      this.cellRange = null
    }
  },

  // 범위 해제 + 서버에도 동기화
  clearCellRangeAndSync() {
    if (this.cellRange) {
      this.clearCellRange()
      this.pushEventTo(this.el, "clear_cell_range", {})
    }
  },

  applyCellRangeVisual() {
    this.clearCellRangeVisual()
    if (!this.cellRange) return

    const anchorRowPos = this.rowIds.indexOf(this.cellRange.anchorRowId)
    const extentRowPos = this.rowIds.indexOf(this.cellRange.extentRowId)
    if (anchorRowPos === -1 || extentRowPos === -1) return

    const minRow = Math.min(anchorRowPos, extentRowPos)
    const maxRow = Math.max(anchorRowPos, extentRowPos)
    const minCol = Math.min(this.cellRange.anchorColIdx, this.cellRange.extentColIdx)
    const maxCol = Math.max(this.cellRange.anchorColIdx, this.cellRange.extentColIdx)

    for (let r = minRow; r <= maxRow; r++) {
      const rowId = this.rowIds[r]
      if (rowId === undefined) continue
      for (let c = minCol; c <= maxCol; c++) {
        const cell = this.getCellElement(rowId, c)
        if (!cell) continue
        cell.classList.add("lv-grid__cell--in-range")
        if (r === minRow) cell.classList.add("lv-grid__cell--range-top")
        if (r === maxRow) cell.classList.add("lv-grid__cell--range-bottom")
        if (c === minCol) cell.classList.add("lv-grid__cell--range-left")
        if (c === maxCol) cell.classList.add("lv-grid__cell--range-right")
      }
    }
  },

  clearCellRangeVisual() {
    const rangeClasses = [
      "lv-grid__cell--in-range",
      "lv-grid__cell--range-top",
      "lv-grid__cell--range-bottom",
      "lv-grid__cell--range-left",
      "lv-grid__cell--range-right"
    ]
    this.el.querySelectorAll(".lv-grid__cell--in-range").forEach(cell => {
      rangeClasses.forEach(cls => cell.classList.remove(cls))
    })
  },

  pushCellRangeToServer() {
    if (this.cellRange) {
      this.pushEventTo(this.el, "set_cell_range", {
        anchor_row_id: this.cellRange.anchorRowId,
        anchor_col_idx: this.cellRange.anchorColIdx,
        extent_row_id: this.cellRange.extentRowId,
        extent_col_idx: this.cellRange.extentColIdx
      })
    }
  },

  // ── Clipboard Helper Methods ──

  _copyCellToClipboard(rowId, colIdx) {
    const cell = this.getCellElement(rowId, colIdx)
    if (!cell) return
    const cellValue = cell.querySelector(".lv-grid__cell-value")
    const text = cellValue ? cellValue.textContent.trim() : ""
    this._writeToClipboard(text)
  },

  _copyRowToClipboard(rowId) {
    const row = this.el.querySelector(`.lv-grid__row[data-row-id="${rowId}"]`)
    if (!row) return
    const cells = row.querySelectorAll(".lv-grid__cell[data-col-index]")
    const text = Array.from(cells).map(c => {
      const cv = c.querySelector(".lv-grid__cell-value")
      return cv ? cv.textContent.trim() : ""
    }).join("\t")
    this._writeToClipboard(text)
  },

  _copyRangeToClipboard() {
    if (!this.cellRange) return
    const anchorRowPos = this.rowIds.indexOf(this.cellRange.anchorRowId)
    const extentRowPos = this.rowIds.indexOf(this.cellRange.extentRowId)
    if (anchorRowPos === -1 || extentRowPos === -1) return

    const minRow = Math.min(anchorRowPos, extentRowPos)
    const maxRow = Math.max(anchorRowPos, extentRowPos)
    const minCol = Math.min(this.cellRange.anchorColIdx, this.cellRange.extentColIdx)
    const maxCol = Math.max(this.cellRange.anchorColIdx, this.cellRange.extentColIdx)

    const lines = []
    for (let r = minRow; r <= maxRow; r++) {
      const rowId = this.rowIds[r]
      const cols = []
      for (let c = minCol; c <= maxCol; c++) {
        const cell = this.getCellElement(rowId, c)
        const cv = cell ? cell.querySelector(".lv-grid__cell-value") : null
        cols.push(cv ? cv.textContent.trim() : "")
      }
      lines.push(cols.join("\t"))
    }
    this._writeToClipboard(lines.join("\n"))
  },

  _writeToClipboard(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).catch(() => {
        this._fallbackCopy(text)
      })
    } else {
      this._fallbackCopy(text)
    }
  },

  _fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.cssText = "position:fixed;left:-9999px;top:-9999px;"
    document.body.appendChild(textarea)
    textarea.select()
    try { document.execCommand("copy") } catch(e) {}
    document.body.removeChild(textarea)
  },

  // FA-037: Column Hover Highlight
  _clearColumnHover() {
    if (this._hoveredColIdx !== null) {
      this.el.querySelectorAll(".lv-grid__cell--col-hover").forEach(el => {
        el.classList.remove("lv-grid__cell--col-hover")
      })
      this._hoveredColIdx = null
    }
  },

  destroyed() {
    // DOM에서 제거될 때는 서버 이벤트 발송 없이 로컬 정리만 수행
    this.clearFocusVisual()
    this.clearCellRange()
    this._clearColumnHover()
    this.focusedRowId = null
    this.focusedColIdx = null
    if (this._onMouseUp) {
      document.removeEventListener("mouseup", this._onMouseUp)
    }
  }
}
