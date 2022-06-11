import lua

proc cleanStack*(state: PState) =
  state.pop(state.gettop())

proc callInit*(state: PState, funcRef: cint) =
  state.rawgeti(REGISTRYINDEX, funcRef)
  discard state.pcall(0, 0, 0)
  state.cleanStack()

proc callOnFinalize*(state: PState, funcRef: cint) =
  state.rawgeti(REGISTRYINDEX, funcRef)
  discard state.pcall(0, 0, 0)
  state.cleanStack()

proc callUpdate*(state: PState, funcRef: cint) =
  state.rawgeti(REGISTRYINDEX, funcRef)
  discard state.pcall(0, 0, 0)
  state.cleanStack()

proc callOnConnected*(state: PState, funcRef: cint, id: int) =
  state.rawgeti(REGISTRYINDEX, funcRef)
  state.pushinteger(Integer(id))
  discard state.pcall(1, 0, 0)
  state.cleanStack()

proc callOnDisconnected*(state: PState, funcRef: cint, id: int) =
  state.rawgeti(REGISTRYINDEX, funcRef)
  state.pushinteger(Integer(id))
  discard state.pcall(1, 0, 0)
  state.cleanStack()

proc callOnData*(state: PState, funcRef: cint, id: int, line: string) =
  state.rawgeti(REGISTRYINDEX, funcRef)
  state.pushinteger(Integer(id))
  state.pushstring(line)
  discard state.pcall(2, 0, 0)
  state.cleanStack()