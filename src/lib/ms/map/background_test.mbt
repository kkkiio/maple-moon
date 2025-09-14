///|
test "parse Background" {
  let spec : NxBackground = @json.from_json({
    "a": 255,
    "ani": 0,
    "bS": "",
    "cx": 0,
    "cy": 0,
    "front": 0,
    "no": 0,
    "rx": 0,
    "ry": 0,
    "type": 0,
    "x": 0,
    "y": 0,
  })
  inspect(
    spec,
    content=(
      #|{a: 255, ani: false, bS: "", cx: 0, cy: 0, f: false, front: false, no: 0, rx: 0, ry: 0, t: BG_NORMAL, x: 0, y: 0}
    ),
  )
}
