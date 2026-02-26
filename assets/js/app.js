// LiveView Grid - Modular Entry Point
// ====================================

// Phoenix dependencies
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Download handlers (side-effect: registers window event listeners)
import "./utils/download"

// Hook modules
import {VirtualScroll} from "./hooks/virtual-scroll"
import {FileImport} from "./hooks/file-import"
import {CellEditable} from "./hooks/cell-editable"
import {ColumnResize} from "./hooks/column-resize"
import {ColumnReorder} from "./hooks/column-reorder"
import {CellEditor} from "./hooks/cell-editor"
import {RowEditSave} from "./hooks/row-edit-save"
import {GridKeyboardNav} from "./hooks/keyboard-nav"

// Assemble hooks
let Hooks = {
  VirtualScroll,
  FileImport,
  CellEditable,
  ColumnResize,
  ColumnReorder,
  CellEditor,
  RowEditSave,
  GridKeyboardNav
}

// Progress bar
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// LiveSocket
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Connect
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
