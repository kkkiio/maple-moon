class CanvasRenderingContext2D {
  clearRect() {}
  scale() {}
  save() {}
  restore() {}
  translate() {}
  rotate() {}
  beginPath() {}
  closePath() {}
  moveTo() {}
  lineTo() {}
  stroke() {}
  fill() {}
  fillRect() {}
  strokeRect() {}
  drawImage() {}
  fillText() {}
  strokeText() {}
  measureText() { return { width: 0 } }
  setTransform() {}
}

class HTMLCanvasElement {
  constructor() {
    this.width = 0
    this.height = 0
    this._ctx = new CanvasRenderingContext2D()
  }

  getContext(type) {
    if (type === "2d") {
      return this._ctx
    }
    return null
  }

  addEventListener() {}
  removeEventListener() {}

  getBoundingClientRect() {
    return { left: 0, top: 0, width: this.width, height: this.height }
  }
}

if (typeof globalThis.HTMLCanvasElement === "undefined") {
  globalThis.HTMLCanvasElement = HTMLCanvasElement
}
if (typeof globalThis.CanvasRenderingContext2D === "undefined") {
  globalThis.CanvasRenderingContext2D = CanvasRenderingContext2D
}

const canvas = new HTMLCanvasElement()

if (typeof globalThis.document === "undefined") {
  globalThis.document = {
    getElementById(id) {
      if (id === "canvas") {
        return canvas
      }
      return null
    },
    createElement(tag) {
      if (tag === "canvas") {
        return new HTMLCanvasElement()
      }
      return {}
    },
    body: { appendChild() {} },
  }
}

if (typeof globalThis.window === "undefined") {
  globalThis.window = {
    requestAnimationFrame(cb) {
      return setTimeout(() => cb(Date.now()), 16)
    },
    cancelAnimationFrame(id) {
      clearTimeout(id)
    },
    addEventListener() {},
    removeEventListener() {},
  }
}
