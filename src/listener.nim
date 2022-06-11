import std/[asyncnet, asyncdispatch]
import os
import lua

import ./config
import ./script
import ./uid

type
  Client* = ref object
    id*: int
    socket*: AsyncSocket
    ip*: string

  Server* = ref object
    conf*: Conf
    socket*: AsyncSocket
    clients*: seq[Client]
    state*: PState
    running*: bool
    uid*: UID

    onInit*: cint
    onFinalize*: cint
    onUpdate*: cint
    onConnected*: cint
    onDisconnected*: cint
    onData*: cint

  LuaFunction* = proc(state: PState): cint {.cdecl.}

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

proc createWeakRefs(server: Server) =
  server.state.getglobal("on_init")
  server.onInit = reference(server.state, REGISTRYINDEX)

  server.state.getglobal("on_finalize")
  server.onFinalize = reference(server.state, REGISTRYINDEX)

  server.state.getglobal("on_update")
  server.onUpdate = reference(server.state, REGISTRYINDEX)

  server.state.getglobal("on_connected")
  server.onConnected = reference(server.state, REGISTRYINDEX)

  server.state.getglobal("on_disconnected")
  server.onDisconnected = reference(server.state, REGISTRYINDEX)

  server.state.getglobal("on_data")
  server.onData = reference(server.state, REGISTRYINDEX)

proc newServer*(): Server =
  result = Server.new()
  result.conf = loadConf()
  result.clients = newSeq[Client](result.conf.maxClients)
  result.uid = newUID()

  result.socket = newAsyncSocket()
  result.socket.setSockOpt(OptReuseAddr, true)
  result.socket.bindAddr(Port(result.conf.port))

  result.state = lua.newstate()
  result.state.openlibs()
  discard result.state.dofile(result.conf.firstScript.cstring)

  result.createWeakRefs()

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