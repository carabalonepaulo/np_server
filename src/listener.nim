import std/[asyncnet, asyncdispatch]
import os
import lua

import ./types
import ./config
import ./script
import ./uid
import ./libs/serverlib

proc newClient*(id: int, socket: AsyncSocket): Client =
  result = Client.new()
  result.id = id
  result.socket = socket

  let (ip, _) = socket.getPeerAddr()
  result.ip = ip

proc beginReceive(server: Server, id: int, client: Client) {.async.} =
  let line = await client.socket.recvLine()

  if line.len() == 0:
    server.uid.freeId(id)
    server.state.callOnDisconnected(server.onDisconnected, id)
    return

  server.state.callOnData(server.onData, id, line)
  asyncCheck server.beginReceive(id, client)

proc beginAccept*(server: Server) {.async.} =
  let id = server.uid.getNextId()
  let socket = await server.socket.accept()
  let client = newClient(id, socket)

  server.clients[id] = client
  server.state.callOnConnected(server.onConnected, id)

  asyncCheck server.beginReceive(id, client)
  asyncCheck server.beginAccept()

proc createWeakRefs*(server: Server) =
  server.state.getglobal("server")

  server.state.getfield(-1, "on_init")
  server.onInit = reference(server.state, REGISTRYINDEX)

  server.state.getfield(-1, "on_finalize")
  server.onFinalize = reference(server.state, REGISTRYINDEX)

  server.state.getfield(-1, "on_update")
  server.onUpdate = reference(server.state, REGISTRYINDEX)

  server.state.getfield(-1, "on_connected")
  server.onConnected = reference(server.state, REGISTRYINDEX)

  server.state.getfield(-1, "on_disconnected")
  server.onDisconnected = reference(server.state, REGISTRYINDEX)

  server.state.getfield(-1, "on_data")
  server.onData = reference(server.state, REGISTRYINDEX)

proc initScripts*(server: Server) =
  server.state = lua.newstate()
  server.state.openlibs()
  registerServerLib()

  discard server.state.dofile(server.conf.firstScript.cstring)
  server.createWeakRefs()

proc newServer*(): Server =
  result = Server.new()
  result.conf = loadConf()
  result.clients = newSeq[Client](result.conf.maxClients)
  result.uid = newUID()

  result.socket = newAsyncSocket()
  result.socket.setSockOpt(OptReuseAddr, true)
  result.socket.bindAddr(Port(result.conf.port))

proc start*(server: Server) =
  server.socket.listen()
  server.running = true
  server.state.callInit(server.onInit)
  asyncCheck server.beginAccept()

proc run*(server: Server) =
  server.start()
  while server.running:
    poll(0)
    if server.conf.lock: sleep(1)
    server.state.callUpdate(server.onUpdate)
  server.state.callOnFinalize(server.onFinalize)