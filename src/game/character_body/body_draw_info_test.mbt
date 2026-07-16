///|
test "parse stand1" {
  let stand1 : Json = {
    "0": {
      "arm": {
        "__h": 19,
        "__w": 10,
        "group": "skin",
        "map": { "hand": [-1, 5], "navel": [-13, -1] },
        "origin": [5, 9],
        "z": "arm",
        "__i": "res://Character/Body/basic_bodys.png",
        "__off": [493, 264],
      },
      "body": {
        "__h": 31,
        "__w": 21,
        "group": "skin",
        "map": { "navel": [-8, -21], "neck": [-4, -32] },
        "origin": [16, 31],
        "z": "body",
        "__i": "res://Character/Body/basic_bodys.png",
        "__off": [369, 218],
      },
      "delay": 500,
      "face": 1,
    },
    "1": {
      "arm": {
        "__h": 19,
        "__w": 10,
        "group": "skin",
        "map": { "hand": [-1, 5], "navel": [-13, 0] },
        "origin": [5, 9],
        "z": "arm",
        "__i": "res://Character/Body/basic_bodys.png",
        "__off": [438, 322],
      },
      "body": {
        "__h": 31,
        "__w": 22,
        "group": "skin",
        "map": { "navel": [-7, -20], "neck": [-4, -32] },
        "origin": [17, 31],
        "z": "body",
        "__i": "res://Character/Body/basic_bodys.png",
        "__off": [391, 244],
      },
      "delay": 500,
      "face": 1,
    },
    "2": {
      "arm": {
        "__h": 19,
        "__w": 11,
        "group": "skin",
        "map": { "hand": [-1, 5], "navel": [-13, -1] },
        "origin": [6, 9],
        "z": "arm",
        "__i": "res://Character/Body/basic_bodys.png",
        "__off": [470, 262],
      },
      "body": {
        "__h": 31,
        "__w": 23,
        "group": "skin",
        "map": { "navel": [-6, -21], "neck": [-4, -32] },
        "origin": [18, 31],
        "z": "body",
        "__i": "res://Character/Body/basic_bodys.png",
        "__off": [391, 213],
      },
      "delay": 500,
      "face": 1,
    },
  }
  let _ : @res.MapBasedArray[NxStanceBody] = @json.from_json(stand1)
}
