// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// CSV 다운로드 핸들러 (레거시 - 기존 호환)
window.addEventListener("phx:download_csv", (e) => {
  const {content, filename} = e.detail

  // Blob 생성
  const blob = new Blob([content], {type: 'text/csv;charset=utf-8;'})

  // 다운로드 링크 생성
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)

  link.setAttribute('href', url)
  link.setAttribute('download', filename)
  link.style.visibility = 'hidden'

  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
})

// 범용 파일 다운로드 핸들러 (Base64 → Blob → Download)
// Excel, CSV 등 모든 형식 지원
window.addEventListener("phx:download_file", (e) => {
  const {content, filename, mime_type} = e.detail

  // Base64 → 바이너리 변환
  const byteCharacters = atob(content)
  const byteNumbers = new Array(byteCharacters.length)
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i)
  }
  const byteArray = new Uint8Array(byteNumbers)

  // Blob 생성 + 다운로드
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

// Grid Scroll Hook (스크롤 위치 감지 - 미리 로딩)
let Hooks = {}
Hooks.GridScroll = {
  mounted() {
    let isLoading = false
    let hasMoreData = true
    let savedScrollTop = 0
    let loadCount = 0
    
    this.el.addEventListener("scroll", (e) => {
      const scrollTop = e.target.scrollTop
      const scrollHeight = e.target.scrollHeight
      const clientHeight = e.target.clientHeight
      
      // 스크롤 위치 저장
      savedScrollTop = scrollTop
      
      // 하단까지 남은 거리
      const distanceToBottom = scrollHeight - scrollTop - clientHeight
      
      // 매 스크롤마다는 로그 안 찍고, 조건 충족 시에만
      if (distanceToBottom < 300 && !isLoading && hasMoreData) {
        loadCount++
        isLoading = true
        this.pushEvent("load_more", {})
        
        // 1초 후 다시 로딩 가능 (중복 방지)
        setTimeout(() => {
          isLoading = false
        }, 1000)
      }
    })
    
    // DOM 업데이트 후 스크롤 위치 복원
    this.updated = () => {
      if (savedScrollTop > 0) {
        this.el.scrollTop = savedScrollTop
      }
    }
    
    // 서버에서 "no_more_data" 이벤트를 받으면 더 이상 로드하지 않음
    this.handleEvent("no_more_data", () => {
      hasMoreData = false
    })
    
    // 서버에서 "reset_scroll" 이벤트를 받으면 다시 로드 가능하게
    this.handleEvent("reset_scroll", () => {
      hasMoreData = true
      isLoading = false
      savedScrollTop = 0  // 스크롤 위치도 리셋
      loadCount = 0
      this.el.scrollTop = 0
    })
  }
}

// Virtual Scroll Hook (가상 스크롤 - 보이는 행만 렌더링)
Hooks.VirtualScroll = {
  mounted() {
    this.pending = false
    this.lastSentOffset = -1
    this.savedScrollTop = 0       // 스크롤 위치 저장 (DOM 패치 후 복원용)
    this.isRestoringScroll = false // DOM 패치 복원 중 플래그
    this.isServerReset = false     // 서버에서 reset 요청 시 플래그

    const rowHeight = parseInt(this.el.dataset.rowHeight) || 40

    this.scrollHandler = () => {
      // DOM 패치 복원으로 인한 스크롤 이벤트 무시
      if (this.isRestoringScroll) {
        return
      }

      // 서버 리셋 후 첫 스크롤 무시
      if (this.isServerReset) {
        this.isServerReset = false
        return
      }

      // 사용자의 실제 스크롤: 현재 위치 저장
      this.savedScrollTop = this.el.scrollTop

      // requestAnimationFrame으로 throttle (~16ms = 60fps)
      if (!this.pending) {
        this.pending = true
        requestAnimationFrame(() => {
          this.pending = false
          const scrollTop = Math.round(this.el.scrollTop)
          const newOffset = Math.floor(scrollTop / rowHeight)

          // 동일한 offset이면 서버에 전송하지 않음
          if (newOffset !== this.lastSentOffset) {
            this.lastSentOffset = newOffset
            this.pushEventTo(this.el, "grid_scroll", {
              scroll_top: String(scrollTop)
            })
          }
        })
      }
    }

    this.el.addEventListener("scroll", this.scrollHandler, {passive: true})

    // 마우스가 그리드 컨테이너 위에 있을 때 페이지 스크롤 항상 차단
    // preventDefault()로 네이티브 스크롤을 막고 직접 scrollTop 제어
    this.wheelHandler = (e) => {
      e.preventDefault()
      this.el.scrollTop += e.deltaY
    }
    this.el.addEventListener("wheel", this.wheelHandler, {passive: false})

    // 서버에서 정렬/데이터 변경 시 스크롤 위치 리셋
    this.handleEvent("reset_virtual_scroll", () => {
      this.savedScrollTop = 0
      this.lastSentOffset = -1
      this.isServerReset = true
      this.el.scrollTop = 0
    })
  },

  updated() {
    // LiveView DOM 패치 후 스크롤 위치 복원
    // savedScrollTop이 0이면 복원하지 않음 (맨 위에 있으므로 자연스러움)
    if (this.savedScrollTop > 0) {
      this.isRestoringScroll = true
      this.el.scrollTop = this.savedScrollTop
      // 복원 완료 후 플래그 해제 (microtask로 비동기 처리)
      requestAnimationFrame(() => {
        this.isRestoringScroll = false
      })
    }
  },

  destroyed() {
    this.el.removeEventListener("scroll", this.scrollHandler)
    this.el.removeEventListener("wheel", this.wheelHandler)
  }
}

// Cell Editable Hook (더블클릭으로 편집 모드 진입)
Hooks.CellEditable = {
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

// Column Resize Hook (컬럼 너비 드래그 조절)
Hooks.ColumnResize = {
  mounted() {
    this.handleMouseDown = (e) => {
      e.preventDefault()
      e.stopPropagation()
      const headerCell = this.el.parentElement
      const columnIndex = this.el.dataset.colIndex
      const columnField = this.el.dataset.field
      const startX = e.clientX
      const startWidth = headerCell.offsetWidth
      let finalWidth = startWidth

      // 리사이즈 커서 표시
      document.body.style.cursor = "col-resize"
      document.body.style.userSelect = "none"

      const handleMouseMove = (e) => {
        const diff = e.clientX - startX
        finalWidth = Math.max(50, startWidth + diff) // 최소 50px

        // 같은 컬럼 인덱스의 모든 셀 너비 변경
        const grid = headerCell.closest(".lv-grid")
        if (grid) {
          const selector = `[data-col-index="${columnIndex}"]`
          grid.querySelectorAll(`.lv-grid__header-cell${selector}, .lv-grid__filter-cell${selector}, .lv-grid__cell${selector}`).forEach(cell => {
            cell.style.width = finalWidth + "px"
            cell.style.flex = `0 0 ${finalWidth}px`
          })
        }
      }

      const handleMouseUp = () => {
        document.body.style.cursor = ""
        document.body.style.userSelect = ""
        document.removeEventListener("mousemove", handleMouseMove)
        document.removeEventListener("mouseup", handleMouseUp)

        // 서버에 최종 너비 push (리사이즈가 실제로 발생한 경우만)
        if (finalWidth !== startWidth && columnField) {
          const target = headerCell.getAttribute("phx-target")
          if (target) {
            this.pushEventTo(target, "grid_column_resize", {
              field: columnField,
              width: String(Math.round(finalWidth))
            })
          }
        }
      }

      document.addEventListener("mousemove", handleMouseMove)
      document.addEventListener("mouseup", handleMouseUp)
    }

    this.el.addEventListener("mousedown", this.handleMouseDown)
  },

  destroyed() {
    this.el.removeEventListener("mousedown", this.handleMouseDown)
  }
}

// Column Reorder Hook (드래그&드롭으로 컬럼 순서 변경)
Hooks.ColumnReorder = {
  mounted() {
    this.isDragging = false
    this.startX = 0
    this.startY = 0
    this.ghost = null
    this.indicator = null
    this.dragThreshold = 5 // 5px 이상 이동 시 드래그 모드
    this.sourceField = this.el.dataset.field
    this.isFrozen = this.el.dataset.frozen === "true"

    // frozen 컬럼은 드래그 불가
    if (this.isFrozen) return

    this.handleMouseDown = (e) => {
      // 리사이즈 핸들 위에서는 드래그 시작하지 않음
      if (e.target.classList.contains("lv-grid__resize-handle")) return
      // 정렬 클릭과 구분하기 위해 즉시 드래그 시작하지 않음
      this.startX = e.clientX
      this.startY = e.clientY
      this.isDragging = false

      const onMouseMove = (e) => {
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
        }
        this.isDragging = false
      }

      document.addEventListener("mousemove", onMouseMove)
      document.addEventListener("mouseup", onMouseUp)
    }

    this.el.addEventListener("mousedown", this.handleMouseDown)
  },

  startDrag(e) {
    // 원본에 dragging 클래스 추가
    this.el.classList.add("lv-grid__header-cell--dragging")
    document.body.style.userSelect = "none"
    document.body.style.cursor = "grabbing"

    // Ghost 요소 생성
    this.ghost = this.el.cloneNode(true)
    this.ghost.classList.add("lv-grid__header-cell--ghost")
    this.ghost.style.width = this.el.offsetWidth + "px"
    this.ghost.style.position = "fixed"
    this.ghost.style.pointerEvents = "none"
    this.ghost.style.zIndex = "9999"
    document.body.appendChild(this.ghost)

    // Indicator 생성
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

    // 모든 reorderable 헤더 셀 가져오기 (frozen 제외)
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
    // 클린업
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

    // 새 순서 계산
    if (this._dropTarget) {
      const header = this.el.closest(".lv-grid__header")
      if (!header) return

      const cells = Array.from(header.querySelectorAll(".lv-grid__header-cell[data-field]:not([data-frozen='true'])"))
      const fields = cells.map(c => c.dataset.field)
      const sourceIdx = fields.indexOf(this.sourceField)
      const targetField = this._dropTarget.dataset.field

      if (sourceIdx >= 0 && targetField !== this.sourceField) {
        // 소스를 제거
        fields.splice(sourceIdx, 1)
        // 타겟 위치 찾기
        let targetIdx = fields.indexOf(targetField)
        if (!this._insertBefore) {
          targetIdx += 1
        }
        // 소스를 새 위치에 삽입
        fields.splice(targetIdx, 0, this.sourceField)

        // 서버에 push
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

// Cell Editor Hook (인라인 셀 편집 - 자동 포커스 & 텍스트 선택)
Hooks.CellEditor = {
  mounted() {
    this.el.focus()
    // select 요소는 .select() 메서드가 없으므로 방어 코드
    if (typeof this.el.select === "function") {
      this.el.select()
    }

    // select 요소일 때 change 이벤트 처리
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
  },
  updated() {
    this.el.focus()
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

