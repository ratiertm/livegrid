// Grid Config Import Hook (JSON 파일 읽기 -> 서버 전송)
export const ConfigImport = {
  mounted() {
    this.el.addEventListener("click", () => {
      const input = document.createElement("input")
      input.type = "file"
      input.accept = ".json"
      input.style.display = "none"
      input.addEventListener("change", (e) => {
        const file = e.target.files[0]
        if (!file) { input.remove(); return }

        // 1MB 제한
        if (file.size > 1024 * 1024) {
          this.pushEvent("import_config_error", { error: "파일이 너무 큽니다 (최대 1MB)" })
          input.remove()
          return
        }

        const reader = new FileReader()
        reader.onload = (ev) => {
          const json = ev.target.result
          this.pushEvent("import_config", { json })
          input.remove()
        }
        reader.onerror = () => {
          this.pushEvent("import_config_error", { error: "파일 읽기에 실패했습니다" })
          input.remove()
        }
        reader.readAsText(file, "UTF-8")
      })
      document.body.appendChild(input)
      input.click()
    })
  }
}
