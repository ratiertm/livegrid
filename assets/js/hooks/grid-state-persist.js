// FA-002: Grid State Persist Hook
// localStorage를 사용한 그리드 상태 저장/복원

export const GridStatePersist = {
  mounted() {
    this.gridId = this.el.dataset.gridId

    // 서버에서 상태 저장 요청
    this.handleEvent("save_grid_state", ({ state }) => {
      if (this.gridId && state) {
        const key = `lv_grid_state_${this.gridId}`
        try {
          localStorage.setItem(key, JSON.stringify(state))
        } catch (e) {
          console.warn("Grid state save failed:", e)
        }
      }
    })

    // 서버에서 상태 복원 요청
    this.handleEvent("load_grid_state", () => {
      if (this.gridId) {
        const key = `lv_grid_state_${this.gridId}`
        try {
          const saved = localStorage.getItem(key)
          if (saved) {
            const state = JSON.parse(saved)
            this.pushEvent("grid_restore_state", { state })
          }
        } catch (e) {
          console.warn("Grid state load failed:", e)
        }
      }
    })

    // 서버에서 상태 초기화 요청
    this.handleEvent("clear_grid_state", () => {
      if (this.gridId) {
        const key = `lv_grid_state_${this.gridId}`
        localStorage.removeItem(key)
      }
    })
  }
}
