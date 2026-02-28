// Scroll Sync Hook (두 Grid의 스크롤 동기화)
export const ScrollSync = {
  mounted() {
    const targetId = this.el.dataset.syncTarget
    if (!targetId) return

    this.handleScroll = () => {
      const target = document.getElementById(targetId)
      if (target) {
        const targetBody = target.querySelector('.lv-grid__body')
        const myBody = this.el.querySelector('.lv-grid__body')
        if (targetBody && myBody) {
          targetBody.scrollTop = myBody.scrollTop
        }
      }
    }

    const body = this.el.querySelector('.lv-grid__body')
    if (body) {
      body.addEventListener('scroll', this.handleScroll)
    }
  },

  destroyed() {
    const body = this.el.querySelector('.lv-grid__body')
    if (body) {
      body.removeEventListener('scroll', this.handleScroll)
    }
  }
}
