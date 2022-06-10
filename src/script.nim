import lua

proc cleanStack*(state: PState) =
  state.pop(state.gettop())

proc callInit*(state: PState) =
  state.getglobal("on_init")
  discard state.pcall(0, 0, 0)
  state.cleanStack()

proc callOnFinalize*(state: PState) =
  state.getglobal("on_finalize")
  discard state.pcall(0, 0, 0)
  state.cleanStack()

proc callUpdate*(state: PState) =
  state.getglobal("on_update")
  discard state.pcall(0, 0, 0)
  state.cleanStack()

proc callOnConnected*(state: PState, id: int) =
  state.getglobal("on_connected")
  state.pushinteger(Integer(id))
  discard state.pcall(1, 0, 0)
  state.cleanStack()

proc callOnDisconnected*(state: PState, id: int) =
  state.getglobal("on_disconnected")
  state.pushinteger(Integer(id))
  discard state.pcall(1, 0, 0)
  state.cleanStack()

proc callOnData*(state: PState, id: int, line: string) =
  state.getglobal("on_data")
  state.pushinteger(Integer(id))
  state.pushstring(line)
  discard state.pcall(2, 0, 0)
  state.cleanStack()