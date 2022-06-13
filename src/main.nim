import ./types
import ./globals
import ./listener
import ./libs/serverlib

server = newServer()

registerServerLib()

setControlCHook(proc() {.noconv.} =
  server.running = false)

server.run()
