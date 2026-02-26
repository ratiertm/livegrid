// Cell Editor Hook (인라인 셀 편집 - 자동 포커스 & 텍스트 선택)
export const CellEditor = {
  mounted() {
    this.el.focus()
    if (typeof this.el.select === "function") {
      this.el.select()
    }

    const isRowEdit = this.el.dataset.rowEdit === "true"

    // F-922: 입력 제한 (정규식) - IME 합성 이벤트 처리
    this._isComposing = false  // IME 합성 상태 플래그
    const patternStr = this.el.dataset.inputPattern
    if (patternStr) {
      try {
        const regex = new RegExp(patternStr)
        this._lastValidValue = this.el.value || ""

        // IME 합성 시작 (한글, 중국어, 일본어 등)
        this.el.addEventListener("compositionstart", () => {
          this._isComposing = true  // 합성 중: 검증 건너뛰기
        })

        // IME 합성 완료 (최종 텍스트 확정)
        this.el.addEventListener("compositionend", () => {
          this._isComposing = false  // 합성 완료: 검증 실행
          // 합성 완료 후 입력값 검증
          if (regex.test(this.el.value)) {
            this._lastValidValue = this.el.value
          } else {
            const pos = this.el.selectionStart - 1
            this.el.value = this._lastValidValue
            this.el.setSelectionRange(pos, pos)
          }
        })

        // 일반 입력 (키보드 직접 입력)
        this.el.addEventListener("input", (e) => {
          // 조합 중에는 검증 건너뛰기 (IME가 처리할 때까지 대기)
          if (!this._isComposing) {
            if (regex.test(e.target.value)) {
              this._lastValidValue = e.target.value
            } else {
              const pos = e.target.selectionStart - 1
              e.target.value = this._lastValidValue
              e.target.setSelectionRange(pos, pos)
            }
          }
        })
      } catch (_err) {
        // 잘못된 정규식 무시
      }
    }

    if (isRowEdit) {
      // F-920: 행 편집 모드
      this.el.addEventListener("keydown", (e) => {
        if (e.key === "Tab") {
          e.preventDefault()
          const row = this.el.closest(".lv-grid__row")
          const editors = [...row.querySelectorAll('[data-row-edit="true"]')]
          const idx = editors.indexOf(this.el)
          const next = e.shiftKey ? idx - 1 : idx + 1
          if (next >= 0 && next < editors.length) {
            editors[next].focus()
            if (typeof editors[next].select === "function") editors[next].select()
          }
        } else if (e.key === "Enter") {
          e.preventDefault()
          const row = this.el.closest(".lv-grid__row")
          const saveBtn = row.querySelector(".lv-grid__row-edit-save")
          if (saveBtn) saveBtn.click()
        } else if (e.key === "Escape") {
          e.preventDefault()
          const row = this.el.closest(".lv-grid__row")
          const cancelBtn = row.querySelector(".lv-grid__row-edit-cancel")
          if (cancelBtn) cancelBtn.click()
        }
      })
    } else {
      // 셀 편집 모드: Tab 키 가로채기
      this.el.addEventListener("keydown", (e) => {
        if (e.key === "Tab") {
          e.preventDefault()
          const rowId = this.el.getAttribute("phx-value-row-id")
          const field = this.el.getAttribute("phx-value-field")
          const value = this.el.value || ""
          const target = this.el.getAttribute("phx-target")
          const direction = e.shiftKey ? "prev_editable" : "next_editable"
          this.pushEventTo(target, "cell_edit_save_and_move", {
            "row-id": rowId,
            "field": field,
            "value": value,
            "direction": direction
          })
        }
      })

      // select 요소 change 이벤트
      if (this.el.tagName === "SELECT") {
        this.el.addEventListener("change", (e) => {
          const rowId = this.el.getAttribute("phx-value-row-id")
          const field = this.el.getAttribute("phx-value-field")
          this.pushEventTo(this.el, "cell_select_change", {
            "select_value": e.target.value,
            "row-id": rowId,
            "field": field
          })
        })
      }
    }
  },
  updated() {
    this.el.focus()
  },
  destroyed() {
    const isRowEdit = this.el.dataset.rowEdit === "true"
    if (!isRowEdit) {
      const grid = document.querySelector('[phx-hook="GridKeyboardNav"]')
      if (grid) {
        setTimeout(() => grid.focus(), 0)
      }
    }
  }
}
