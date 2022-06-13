import lua
import std/asyncnet

import ../script
import ../types
import ../globals

proc registerServerLib*() =
  server.state.createtable(0, 5)

  # server.send_to(id, message)
  server.state.pushcfunction(proc(state: PState): cint {.cdecl.} =
    let id = state.tointeger(1)
    let line = state.tostring(2)

    if server.clients[id] != nil:
      discard server.clients[id].socket.send($line)

    return 0)
  server.state.setfield(-2, "send_to")

  # server.send_to_all(message)
  server.state.pushcfunction(proc(state: PState): cint {.cdecl.} =
    let line = state.tostring(1)
    
    for i in 0..server.clients.len() - 1:
      if server.clients[i] != nil:
        discard server.clients[i].socket.send($line)

    result = 0)
  server.state.setfield(-2, "send_to_all")

  # server.get_ip(id)
  server.state.pushcfunction(proc(state: PState): cint {.cdecl.} =
    let id = state.tointeger(1)
    
    if server.clients[id] == nil:
      server.state.pushstring("")
    else:
      server.state.pushstring($server.clients[id].ip)

    result = 1)
  server.state.setfield(-2, "get_ip")

  # server.disconnect(id)
  server.state.pushcfunction(proc(state: PState): cint {.cdecl.} =
    let id = state.tointeger(1)

    if server.clients[id] == nil:
      server.clients[id].socket.close()
      server.state.callOnDisconnected(server.onDisconnected, id)
      server.clients[id] = nil

    result = 0)
  server.state.setfield(-2, "disconnect")

  # server.finalize()
  server.state.pushcfunction(proc(state: PState): cint {.cdecl.} =
    server.running = false
    result = 0)
  server.state.setfield(-2, "finalize")

  server.state.setglobal("server")