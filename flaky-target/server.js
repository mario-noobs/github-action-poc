const http = require('node:http')

const PORT = Number(process.env.PORT ?? 80)

let currentStatus = 200
let currentBody = 'ok'

function respond(res, status, body) {
  res.statusCode = status
  res.setHeader('Content-Type', 'text/plain')
  res.end(body)
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let raw = ''
    req.on('data', (chunk) => (raw += chunk))
    req.on('end', () => {
      if (!raw) return resolve({})
      try {
        resolve(JSON.parse(raw))
      } catch (err) {
        reject(err)
      }
    })
    req.on('error', reject)
  })
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`)

  if (req.method === 'GET' && url.pathname === '/health') {
    return respond(res, currentStatus, currentBody)
  }

  if (req.method === 'GET' && url.pathname === '/state') {
    res.setHeader('Content-Type', 'application/json')
    return respond(res, 200, JSON.stringify({ status: currentStatus, body: currentBody }))
  }

  if (req.method === 'POST' && url.pathname === '/control') {
    try {
      const payload = await readJson(req)
      if (typeof payload.status === 'number') currentStatus = payload.status
      if (typeof payload.body === 'string') currentBody = payload.body
      res.setHeader('Content-Type', 'application/json')
      return respond(res, 200, JSON.stringify({ status: currentStatus, body: currentBody }))
    } catch (err) {
      return respond(res, 400, `invalid json: ${err.message}`)
    }
  }

  respond(res, 404, 'not found')
})

server.listen(PORT, () => {
  console.log(`[flaky-target] listening on ${PORT} (initial status=${currentStatus})`)
})
