type
  UID* = ref object
    highest_index: int
    available_indices: seq[int]

proc getNextId*(uid: UID): int =
  if uid.available_indices.len() > 0:
    return uid.available_indices.pop()
  inc(uid.highest_index)
  return uid.highest_index

proc freeId*(uid: UID, id: int) =
  uid.available_indices.add(id)

proc newUID*(): UID =
  result = UID.new()
  result.highest_index = -1
  result.available_indices = newSeq[int]()