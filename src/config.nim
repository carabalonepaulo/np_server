import json

import ./types

proc loadConf*(): Conf =
  let text = readFile("./settings.json")
  let node = parseJson(text)
  result = node.to(Conf)