// Cell Editable Hook (더블클릭으로 편집 모드 진입)
export const CellEditable = {
  mounted() {
    this.el.addEventListener("dblclick", () => {
      const rowId = this.el.dataset.rowId
      const field = this.el.dataset.field
      const target = this.el.getAttribute("phx-target")
      this.pushEventTo(target, "cell_edit_start", {
        "row-id": rowId,
        "field": field
      })
    })
  }
}
