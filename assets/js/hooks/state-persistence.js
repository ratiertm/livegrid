// FA-002: Grid State Persistence Hook
// localStorage를 통한 Grid 상태 자동 저장/복원
export const StatePersistence = {
  mounted() {
    this.gridId = this.el.dataset.gridId

    // 저장된 상태가 있으면 서버에 전송
    const saved = localStorage.getItem(this._storageKey())
    if (saved) {
      try {
        const state = JSON.parse(saved)
        this.pushEventTo(this.el, "restore_grid_state", { state: state })
      } catch (e) {
        // 파싱 실패 시 무시
        localStorage.removeItem(this._storageKey())
      }
    }

    // 서버에서 상태 저장 이벤트 수신
    this.handleEvent("state_saved", ({ state }) => {
      localStorage.setItem(this._storageKey(), JSON.stringify(state))
    })

    // 서버에서 상태 삭제 이벤트 수신
    this.handleEvent("state_cleared", () => {
      localStorage.removeItem(this._storageKey())
    })
  },

  _storageKey() {
    return `lv-grid-state-${this.gridId}`
  }
}
