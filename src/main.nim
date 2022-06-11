import std/asyncnet
import lua

import ./script
import ./listener

var server: Server
server = newServer()

server.state.register("send_to", proc(state: PState): cint {.cdecl.} =
  let id = state.tointeger(1)
  let line = state.tostring(2)

  if server.clients[id] != nil:
    discard server.clients[id].socket.send($line)

  result = 0)

server.state.register("send_to_all", proc(state: PState): cint {.cdecl.} =
  let line = state.tostring(1)
  
  for i in 0..server.clients.len() - 1:
    if server.clients[i] != nil:
      discard server.clients[i].socket.send($line)

  result = 0)

server.state.register("finalize", proc(state: PState): cint {.cdecl.} =
  server.running = false
  result = 0)

server.state.register("get_ip", proc(state: PState): cint {.cdecl.} =
  let id = state.tointeger(1)
  
  if server.clients[id] == nil:
    server.state.pushstring("")
  else:
    server.state.pushstring($server.clients[id].ip)

  result = 1)

server.state.register("disconnect", proc(state: PState): cint {.cdecl.} =
  let id = state.tointeger(1)

  if server.clients[id] == nil:
    server.clients[id].socket.close()
    server.state.callOnDisconnected(server.onDisconnected, id)
    server.clients[id] = nil
  
  result = 0)

setControlCHook(proc() {.noconv.} =
  server.running = false)

server.run()
