// F-920: 행 편집 저장 버튼 Hook
export const RowEditSave = {
  mounted() {
    this.el.addEventListener("click", () => {
      const rowId = this.el.dataset.rowId
      const row = this.el.closest(".lv-grid__row")
      const editors = row.querySelectorAll('[data-row-edit="true"]')
      const values = {}
      editors.forEach(editor => {
        const field = editor.dataset.field
        if (field) {
          values[field] = editor.value || ""
        }
      })
      const target = this.el.getAttribute("phx-target")
      this.pushEventTo(target, "row_edit_save", {"row-id": rowId, "values": values})
    })
  }
}
