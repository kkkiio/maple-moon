///|
/// Test that process_bitmap_resource works with match-filtered JSON
async test "process bitmap with matched entry" {
  let teleport_json : Json = {
    "0": {
      "__b": 1902,
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
    },
    "1": {
      "__b": 1903,
      "__h": 143,
      "__w": 45,
      "delay": 80,
      "origin": [25, 105],
    },
  }

  // Skip image operations by not providing load_bitmap and save_image
  let res = process_bitmap_resource(
    teleport_json, "Effect/BasicEff.img", "Teleport",
  )

  // Verify the output has unified dimensions and __i + __off format
  json_inspect(res, content={
    "0": {
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
      "__i": "Effect/BasicEff.img/Teleport.png",
      "__off": [0, 0],
    },
    "1": {
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
      "__i": "Effect/BasicEff.img/Teleport.png",
      "__off": [62, 0],
    },
  })
}
