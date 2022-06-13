import std/[asyncnet]
import lua

type
  Conf* = ref object
    port*: int
    maxClients*: int
    lock*: bool
    firstScript*: string

  UID* = ref object
    highest_index*: int
    available_indices*: seq[int]

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