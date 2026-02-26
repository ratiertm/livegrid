// Virtual Scroll Hook (가상 스크롤 - 보이는 행만 렌더링)
export const VirtualScroll = {
  mounted() {
    this.pending = false
    this.lastSentOffset = -1
    this.savedScrollTop = 0
    this.isRestoringScroll = false
    this.isServerReset = false

    const rowHeight = parseInt(this.el.dataset.rowHeight) || 40

    this.scrollHandler = () => {
      if (this.isRestoringScroll) return

      if (this.isServerReset) {
        this.isServerReset = false
        return
      }

      this.savedScrollTop = this.el.scrollTop

      if (!this.pending) {
        this.pending = true
        requestAnimationFrame(() => {
          this.pending = false
          const scrollTop = Math.round(this.el.scrollTop)
          const newOffset = Math.floor(scrollTop / rowHeight)

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

    this.wheelHandler = (e) => {
      e.preventDefault()
      this.el.scrollTop += e.deltaY
    }
    this.el.addEventListener("wheel", this.wheelHandler, {passive: false})

    this.handleEvent("reset_virtual_scroll", () => {
      this.savedScrollTop = 0
      this.lastSentOffset = -1
      this.isServerReset = true
      this.el.scrollTop = 0
    })
  },

  updated() {
    if (this.savedScrollTop > 0) {
      this.isRestoringScroll = true
      this.el.scrollTop = this.savedScrollTop
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
