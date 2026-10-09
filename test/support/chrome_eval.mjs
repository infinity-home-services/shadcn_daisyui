// Loads a page in headless Chrome and prints `window.__result` once the page
// sets it. Talks to Chrome over --remote-debugging-pipe (fds 3/4, NUL-framed
// JSON), so it needs nothing beyond Node itself.
//
//   node chrome_eval.mjs <chrome-binary> <page.html> <profile-dir>
import { spawn } from "node:child_process"
import { pathToFileURL } from "node:url"

const [chrome, page, profile] = process.argv.slice(2)
const proc = spawn(chrome, [
  "--headless", "--disable-gpu", "--no-sandbox", "--no-first-run",
  "--remote-debugging-pipe", `--user-data-dir=${profile}`, "--window-size=1280,900",
], { stdio: ["ignore", "ignore", "ignore", "pipe", "pipe"] })
const toChrome = proc.stdio[3]
const fromChrome = proc.stdio[4]

let nextId = 1
const pending = new Map()
function send(method, params = {}, sessionId) {
  const id = nextId++
  toChrome.write(JSON.stringify({ id, method, params, sessionId }) + "\0")
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }))
}
let buf = ""
fromChrome.on("data", (chunk) => {
  buf += chunk
  let i
  while ((i = buf.indexOf("\0")) >= 0) {
    const msg = JSON.parse(buf.slice(0, i))
    buf = buf.slice(i + 1)
    const p = msg.id && pending.get(msg.id)
    if (!p) continue
    pending.delete(msg.id)
    msg.error ? p.reject(new Error(msg.error.message)) : p.resolve(msg.result)
  }
})

const timer = setTimeout(() => { console.error("timed out"); proc.kill("SIGKILL"); process.exit(2) }, 30000)
try {
  const { targetId } = await send("Target.createTarget", { url: "about:blank" })
  const { sessionId } = await send("Target.attachToTarget", { targetId, flatten: true })
  await send("Page.navigate", { url: pathToFileURL(page).href }, sessionId)
  const evaluate = () => send("Runtime.evaluate", {
    expression: `new Promise((r) => { const t = () => window.__result ? r(window.__result) : setTimeout(t, 20); t() })`,
    awaitPromise: true,
    returnByValue: true,
  }, sessionId)
  // the first attempt can land on the outgoing about:blank document
  let res
  for (let tries = 0; !res; tries++) {
    try { res = await evaluate() } catch (e) { if (tries > 20) throw e }
  }
  const { result, exceptionDetails } = res
  if (exceptionDetails) throw new Error(exceptionDetails.text)
  process.stdout.write(result.value)
  await send("Browser.close").catch(() => {})
} catch (e) {
  console.error(e.message)
  process.exitCode = 1
} finally {
  clearTimeout(timer)
  proc.kill("SIGKILL")
}
