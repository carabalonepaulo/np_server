import json

type
  Conf* = ref object
    port*: int
    max_clients*: int
    lock*: bool

proc loadConf*(): Conf =
  let text = readFile("./settings.json")
  let node = parseJson(text)

  result = Conf(lock: node["lock"].getBool(),
                port: node["port"].getInt(),
                max_clients: node["max_clients"].getInt())