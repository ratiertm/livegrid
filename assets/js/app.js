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

// CSV 다운로드 핸들러
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

// Cell Editor Hook (인라인 셀 편집 - 자동 포커스 & 텍스트 선택)
Hooks.CellEditor = {
  mounted() {
    this.el.focus()
    this.el.select()
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

