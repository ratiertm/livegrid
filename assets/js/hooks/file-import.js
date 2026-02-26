// F-511: File Import Hook (CSV/TSV 파일 읽기 -> 서버 전송)
export const FileImport = {
  mounted() {
    this.el.addEventListener("click", () => {
      const input = document.createElement("input")
      input.type = "file"
      input.accept = ".csv,.tsv,.txt"
      input.style.display = "none"
      input.addEventListener("change", (e) => {
        const file = e.target.files[0]
        if (!file) { input.remove(); return }

        const reader = new FileReader()
        reader.onload = (ev) => {
          const text = ev.target.result
          const lines = text.trim().split(/\r?\n/)
          const delimiter = lines[0].includes("\t") ? "\t" : ","
          const rows = lines.map(line => {
            const result = []
            let current = ""
            let inQuotes = false
            for (let i = 0; i < line.length; i++) {
              const ch = line[i]
              if (ch === '"') {
                inQuotes = !inQuotes
              } else if (ch === delimiter && !inQuotes) {
                result.push(current.trim())
                current = ""
              } else {
                current += ch
              }
            }
            result.push(current.trim())
            return result
          })

          const headers = rows[0]
          const data = rows.slice(1).filter(r => r.some(c => c !== ""))
          this.pushEvent("import_file", { headers, data })
          input.remove()
        }
        reader.readAsText(file, "UTF-8")
      })
      document.body.appendChild(input)
      input.click()
    })
  }
}
