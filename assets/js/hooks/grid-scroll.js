// Grid Scroll Hook (스크롤 위치 감지 - 미리 로딩)
export const GridScroll = {
  mounted() {
    let isLoading = false
    let hasMoreData = true
    let savedScrollTop = 0
    let loadCount = 0

    this.el.addEventListener("scroll", (e) => {
      const scrollTop = e.target.scrollTop
      const scrollHeight = e.target.scrollHeight
      const clientHeight = e.target.clientHeight

      savedScrollTop = scrollTop

      const distanceToBottom = scrollHeight - scrollTop - clientHeight

      if (distanceToBottom < 300 && !isLoading && hasMoreData) {
        loadCount++
        isLoading = true
        this.pushEvent("load_more", {})

        setTimeout(() => {
          isLoading = false
        }, 1000)
      }
    })

    this.updated = () => {
      if (savedScrollTop > 0) {
        this.el.scrollTop = savedScrollTop
      }
    }

    this.handleEvent("no_more_data", () => {
      hasMoreData = false
    })

    this.handleEvent("reset_scroll", () => {
      hasMoreData = true
      isLoading = false
      savedScrollTop = 0
      loadCount = 0
      this.el.scrollTop = 0
    })
  }
}
