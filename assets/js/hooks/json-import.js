// Grid Builder: JSON Config Import Hook
// .json 파일을 읽어서 서버로 전송
export const JsonImport = {
  mounted() {
    this.el.addEventListener("click", () => {
      const input = document.createElement("input")
      input.type = "file"
      input.accept = ".json"
      input.style.display = "none"
      input.addEventListener("change", (e) => {
        const file = e.target.files[0]
        if (!file) { input.remove(); return }

        const reader = new FileReader()
        reader.onload = (ev) => {
          try {
            const data = JSON.parse(ev.target.result)
            this.pushEvent("import_grid_json", data)
          } catch (err) {
            this.pushEvent("import_grid_json_error", { error: "Invalid JSON file" })
          }
          input.remove()
        }
        reader.onerror = () => {
          this.pushEvent("import_grid_json_error", { error: "File read failed" })
          input.remove()
        }
        reader.readAsText(file, "UTF-8")
      })
      document.body.appendChild(input)
      input.click()
    })
  }
}
