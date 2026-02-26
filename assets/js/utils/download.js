// CSV 다운로드 핸들러 (레거시 - 기존 호환)
window.addEventListener("phx:download_csv", (e) => {
  const {content, filename} = e.detail

  const blob = new Blob([content], {type: 'text/csv;charset=utf-8;'})
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)

  link.setAttribute('href', url)
  link.setAttribute('download', filename)
  link.style.visibility = 'hidden'

  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
})

// 범용 파일 다운로드 핸들러 (Base64 -> Blob -> Download)
// Excel, CSV 등 모든 형식 지원
window.addEventListener("phx:download_file", (e) => {
  const {content, filename, mime_type} = e.detail

  const byteCharacters = atob(content)
  const byteNumbers = new Array(byteCharacters.length)
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i)
  }
  const byteArray = new Uint8Array(byteNumbers)

  const blob = new Blob([byteArray], {type: mime_type || 'application/octet-stream'})
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
})
