// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import SimplePeer from 'simple-peer'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let streamPromise = null;
const getStream = () => {
  if(!streamPromise) {
    streamPromise = navigator.mediaDevices.getUserMedia({
      audio: true,
      video: true
    })
  }

  return streamPromise
}

const Hooks = {}

Hooks.VideoAvatar = {
  async mounted(){
    const stream = await getStream();

    if ('srcObject' in this.el) {
      this.el.srcObject = stream
    } else {
      this.el.src = window.URL.createObjectURL(stream)
    }
    this.el.volume = 0;

    this.el.play()
  }
}

Hooks.VideoChat = {
  async mounted(){
    let {playerId, initiator, volume} = this.el.dataset
    this.el.volume = (+volume) / 100.0

    this.initiator = initiator == "true"
    this.playerId = playerId

    this.stream = await getStream();
    this.peer = new SimplePeer({
      initiator: this.initiator,
      trickle: false,
      stream: this.stream
    })

    this.handleEvent('signal', ({playerId, data}) => {
      if(playerId == this.playerId){
        this.peer.signal(data)
        if(this.resendInterval) {
          clearInterval(this.resendInterval)
          delete this.resendInterval
        }
      }
    })

    this.peer.on('signal', data => {
      this.pushEvent('signal', {playerId, data})
      
      if(this.initiator) {
        this.resendInterval = setInterval(() => {
          this.pushEvent('signal', {playerId, data})
        }, 1_000)
      }
    })

    this.peer.on('stream', stream => {
      if ('srcObject' in this.el) {
        this.el.srcObject = stream
      } else {
        this.el.src = window.URL.createObjectURL(stream)
      }

      this.el.play()
    })
  },

  updated() {
    let {volume} = this.el.dataset
    this.el.volume = (+volume) / 100.0
  }
}

let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket