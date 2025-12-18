///|
async test "process bitmap resource" {
  let test_bitmap_json : Json = {
    "Teleport": {
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
    },
    // Non-animation node
    "info": { "foo": "bar" },
  }

  // Skip image operations
  let res = process_bitmap_resource(
    test_bitmap_json, "BasicEff.img", "BasicEff.img",
  )
  @json.inspect(res, content={
    "Teleport": {
      "0": {
        "__h": 172,
        "__w": 62,
        "delay": 80,
        "origin": [34, 122],
        "__i": "BasicEff.img/Teleport.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 172,
        "__w": 62,
        "delay": 80,
        "origin": [34, 122],
        "__i": "BasicEff.img/Teleport.png",
        "__off": [62, 0],
      },
    },
    "info": { "foo": "bar" },
  })
}
