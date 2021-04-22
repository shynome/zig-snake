// @ts-check
const { createElement: h, useEffect, useState, useMemo } = React

// @ts-ignore
const snake = (window.snake = await fetch(`./wasm/snake.wasm?v=${n}`)
  .then((resp) => resp.arrayBuffer())
  .then((bytes) =>
    WebAssembly.instantiate(bytes, {
      env: {
      },
    }),
  )
  .then((wasm) => {
    var mExports = /**@type {import("./snake")} */ (wasm.instance.exports)
    const ptrBase = 100_000_000n
    /**
     * @param {bigint} p
     * @param {bigint} base
     */
    function readBuffer(p, base = ptrBase) {
      var postion = p / base
      var len = p - postion * base
      var buf = new Uint8Array(
        mExports.memory.buffer,
        Number(postion),
        Number(len),
      )
      return buf
    }
    return {
      ...mExports,
      readBuffer: readBuffer,
    }
  }))

/**
 * @returns {number[][]}
 */
function getDisplay() {
  /**@type {number[]} */
  let display = Array.from(snake.readBuffer(snake.display()))
  return _.chunk(display, x)
}

const BlockColor = {
  0: 'empty',
  1: 'fill',
  2: 'food',
  3: 'head',
}

var x = 20
var y = 10
class App extends React.Component {
  constructor(props) {
    super(props)
    this.init()
    this.lastMoveTime = Date.now()
    this.state = {
      blocks: getDisplay(),
      end: false,
    }
    /**
     * @param {KeyboardEvent} ev
     */
    this.handleKeyboard = (ev) => {
      if (this.state.end) {
        if (ev.key == ' ') {
          this.start()
        }
        return
      }
      switch (ev.key) {
        case 'ArrowUp':
        case 'w':
          this.snakeMove(0)
          break
        case 'ArrowDown':
        case 's':
          this.snakeMove(1)
          break
        case 'ArrowLeft':
        case 'a':
          this.snakeMove(2)
          break
        case 'ArrowRight':
        case 'd':
          this.snakeMove(3)
          break
        default:
          return
      }
    }
  }
  rerender() {
    this.setState((s) => ({ ...s, blocks: getDisplay() }))
  }
  end() {
    this.deinit()
    this.setState((s) => ({ ...s, end: true }))
  }
  start() {
    this.setState((s) => ({ ...s, end: false }))
    this.init()
  }
  /**
   * @param {number} [direction]
   */
  snakeMove(direction) {
    this.lastMoveTime = Date.now()
    var r = 0n
    if (typeof direction == 'undefined') {
      r = snake.keepMove()
    } else {
      r = snake.move(direction)
    }
    if (r == 1n) {
      this.end()
      return
    }
    this.rerender()
  }
  timer() {
    this.rid = setInterval(() => {
      if (Date.now() - this.lastMoveTime < 400) {
        return
      }
      this.snakeMove()
    }, 200)
  }
  init() {
    snake.init(x, y)
    this.timer()
  }
  deinit() {
    clearInterval(this.rid)
  }

  componentDidMount() {
    window.addEventListener('keydown', this.handleKeyboard)
  }
  componentWillUnmount() {
    this.deinit()
    window.removeEventListener('keydown', this.handleKeyboard)
  }
  render() {
    return h('div', { className: 'root' }, [
      this.state.end &&
        h(
          'div',
          {
            key: 'shadow',
            className: 'shadow',
            title: '重新开始游戏',
            onClick: () => this.start(),
          },
          h('span', { className: 'shadow-content' }, '失败, 点击/空格重新开始'),
        ),
      h(
        'table',
        { key: 'app' },
        h(
          'tbody',
          {},
          this.state.blocks.map((tds, x) => {
            return h(
              'tr',
              { key: x },
              tds.map((value, y) => {
                return h(
                  'td',
                  { key: `${x}-${y}`, className: BlockColor[value] },
                  value,
                )
              }),
            )
          }),
        ),
      ),
    ])
  }
}

/**@type {import("react-dom")}*/
ReactDOM.render(h(App), document.getElementById('app'))
