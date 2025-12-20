///|
test "parse nx frame" {
  let data : Json = {
    "__h": 58,
    "__w": 63,
    "delay": 180,
    "head": [2, -54],
    "lt": [-27, -58],
    "origin": [27, 58],
    "rb": [36, 0],
    "__i": "spritesheets/Mob/1210102.img#10728",
  }
  let frame : NxFrame = @json.from_json(data)
  inspect(
    frame,
    content=(
      #|{texture: {i: "spritesheets/Mob/1210102.img#10728", w: 63, h: 58, offset: {x: 0, y: 0}, origin: {x: 27, y: 58}}, delay: Some(180), head: Some({x: 2, y: -54}), bounds: Some({lt: {x: -27, y: -58}, rb: {x: 36, y: 0}})}
    ),
  )
}
