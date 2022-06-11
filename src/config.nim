import json

type
  Conf* = ref object
    port*: int
    maxClients*: int
    lock*: bool

proc loadConf*(): Conf =
  let text = readFile("./settings.json")
  let node = parseJson(text)
  result = node.to(Conf)