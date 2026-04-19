///|
test "char_look facade forwards afterimage api" {
  let resource_json : Json = {
    "0": {
      "shoot1": {
        "lt": [0, 0],
        "rb": [10, 10],
        "0": {
          "0": {
            "__h": 1,
            "__w": 1,
            "origin": [0, 0],
            "__off": [0, 0],
            "__i": "test.png",
          },
        },
      },
    },
  }
  let resources : NxAfterImages = @json.from_json(resource_json)
  set_after_images("compat-forward", resources)
  let collection = AfterImage::get_collection("compat-forward", 0)
  debug_inspect(
    collection.contains("shoot1"),
    content=(
      #|true
    ),
  )
}
