///|
async test "process_spritesheet copies referenced source sheets into assets" {
  let root = "/tmp/maple-moon-reanim-keep-source-test"
  let source_dir = "\{root}/source/spritesheets/Mob"
  let assets_dir = "\{root}/assets/Mob"
  @fsx.mkdir_sync_recursive(source_dir)
  @fsx.mkdir_sync_recursive(assets_dir)

  let input_json : Json = {
    "stand": {
      "0": { "__h": 20, "__w": 30, "__i": "spritesheets/Mob/9999999.img#1" },
    },
  }
  @fsx.write_file_sync(
    "\{root}/source/9999999.img.json",
    input_json.stringify(indent=2),
  )

  let atlas_json : Json = {
    "meta": {
      "image": "9999999.img.png",
      "size": { "w": 64, "h": 32 },
      "scale": "1",
    },
    "frames": {
      "1.png": {
        "frame": { "x": 7, "y": 9, "w": 30, "h": 20 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 30, "h": 20 },
        "sourceSize": { "w": 30, "h": 20 },
      },
    },
  }
  @fsx.write_file_sync(
    "\{source_dir}/9999999.img.json",
    atlas_json.stringify(indent=2),
  )
  @fsx.write_file_sync("\{source_dir}/9999999.img.png", "fake-png")

  process_spritesheet({
    input: "\{root}/source/9999999.img.json",
    output: assets_dir,
    spritesheet_dir: source_dir,
    bitmaps_dir: "",
    match_pattern: None,
    resize: false,
    keep_source_sheets: true,
  })

  let output_json = @json.parse(
    @fsx.read_file_sync("\{assets_dir}/9999999.img.json", "utf-8"),
  )
  json_inspect(output_json, content={
    "stand": {
      "0": {
        "__h": 20,
        "__w": 30,
        "__i": "spritesheets/Mob/9999999.img.png",
        "__off": [7, 9],
      },
    },
  })
  inspect(
    @fsx.read_file_sync(
      "\{root}/assets/spritesheets/Mob/9999999.img.json",
      "utf-8",
    ),
    content=atlas_json.stringify(indent=2),
  )
  inspect(
    @fsx.read_file_sync(
      "\{root}/assets/spritesheets/Mob/9999999.img.png",
      "utf-8",
    ),
    content="fake-png",
  )
}
