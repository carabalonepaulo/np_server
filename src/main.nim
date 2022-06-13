import ./types
import ./globals
import ./listener

server = newServer()
server.initScripts()

setControlCHook(proc() {.noconv.} =
  server.running = false)

server.run()
