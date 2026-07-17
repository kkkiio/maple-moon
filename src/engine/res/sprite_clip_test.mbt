///|
test "NX sprite clips preserve exact atlas rects and per-frame origins" {
  let files : Map[String, Bytes] = Map([
    (
      "packs/nx/pack.json",
      @encoding/utf8.encode(
        (
          {
            "schema": 2,
            "id": "nx",
            "overrides": [],
            "files": ["Data/sheet.png"],
          } : Json).stringify(),
      ),
    ),
    ("packs/nx/Data/sheet.png", Bytes::from_array([0x89U.to_byte()])),
  ])
  @asset.set_io(fn(path) { files.get(path) })
  defer @asset.set_io(fn(_path) { None })
  try! configure_packs([("nx", "packs/nx")])
  defer clear_mounts()

  let clip = try! compile_nx_animation(
    {
      frames: [
        {
          texture: {
            i: "res://Data/sheet.png",
            w: 10,
            h: 12,
            offset: { x: 2, y: 3 },
            origin: { x: 4, y: 9 },
          },
          delay: Some(100),
          head: None,
          bounds: None,
        },
        {
          texture: {
            i: "res://Data/sheet.png",
            w: 8,
            h: 14,
            offset: { x: 15, y: 5 },
            origin: { x: 2, y: 7 },
          },
          delay: Some(200),
          head: None,
          bounds: None,
        },
      ],
      blend: false,
      zigzag: false,
    },
    name="test/nx-exact-rects",
  )
  guard @sprite.texture_atlas_layout(clip.layout) is Some(layout) else {
    fail("compiled NX clip is missing its atlas layout")
  }
  guard @selene_animation.animation_clip_asset(clip.clip) is Some(asset) else {
    fail("compiled NX clip is missing its animation asset")
  }
  guard asset.curves.get(@selene_animation.AnimationTargetId("self"))
    is Some(
      [
        @selene_animation.VariableCurve::Scalar(_, frame_keys, _),
        @selene_animation.VariableCurve::Vec3(_, anchor_keys, _),
      ]
    ) else {
    fail("compiled NX clip must animate atlas index and sprite anchor")
  }
  let @sprite.Anchor(initial_anchor) = clip.anchor
  @debug.debug_inspect(
    (
      clip.first_frame_index,
      clip.dimensions,
      layout.size,
      layout.rects.map(fn(rect) {
        (rect.position.0, rect.position.1, rect.size.0, rect.size.1)
      }),
      initial_anchor,
      frame_keys.map(fn(key) { (key.time, key.value) }),
      anchor_keys.map(fn(key) { (key.time, key.value) }),
    ),
    content=(
      #|(
      #|  0,
      #|  { x: 10, y: 16 },
      #|  Vec2(23, 19),
      #|  [(2, 3, 10, 12), (15, 5, 8, 14)],
      #|  Vec2(-0.09999999999999998, -0.25),
      #|  [(0, 0), (0.1, 1)],
      #|  [
      #|    (0, { x: -0.09999999999999998, y: -0.25, z: 0 }),
      #|    (0.1, { x: -0.25, y: 0, z: 0 }),
      #|  ],
      #|)
    ),
  )
}

///|
test "Aseprite tag sprites start at their own first atlas frame" {
  let animation_json : Json = {
    "frames": [
      {
        "frame": { "x": 0, "y": 0, "w": 8, "h": 10 },
        "spriteSourceSize": { "x": 0, "y": 0 },
        "duration": 100,
      },
      {
        "frame": { "x": 8, "y": 0, "w": 12, "h": 10 },
        "spriteSourceSize": { "x": 0, "y": 0 },
        "duration": 150,
      },
    ],
    "meta": {
      "image": "animation.png",
      "size": { "w": 20, "h": 10 },
      "frameTags": [
        { "name": "eye", "from": 0, "to": 0, "direction": "forward" },
        { "name": "stand", "from": 1, "to": 1, "direction": "forward" },
      ],
      "slices": [
        {
          "name": "anchor_eye",
          "keys": [
            {
              "bounds": { "x": 0, "y": 0, "w": 8, "h": 10 },
              "pivot": { "x": 4, "y": 10 },
            },
          ],
        },
        {
          "name": "anchor_stand",
          "keys": [
            {
              "bounds": { "x": 0, "y": 0, "w": 12, "h": 10 },
              "pivot": { "x": 6, "y": 10 },
            },
          ],
        },
      ],
    },
  }
  let files : Map[String, Bytes] = Map([
    (
      "packs/ase/pack.json",
      @encoding/utf8.encode(
        (
          {
            "schema": 2,
            "id": "ase",
            "overrides": [],
            "files": ["Npc/demo/animation.json", "Npc/demo/animation.png"],
          } : Json).stringify(),
      ),
    ),
    (
      "packs/ase/Npc/demo/animation.json",
      @encoding/utf8.encode(animation_json.stringify()),
    ),
    ("packs/ase/Npc/demo/animation.png", Bytes::from_array([0x89U.to_byte()])),
  ])
  @asset.set_io(fn(path) { files.get(path) })
  defer @asset.set_io(fn(_path) { None })
  try! configure_packs([("ase", "packs/ase")])
  defer clear_mounts()

  let loaded = try! AnimationLoader::AnimationLoader().load(
    "res://Npc/demo/animation.json",
  )
  let stand = try! loaded.clip("stand")
  guard stand.sprite().texture_atlas is Some(atlas) else {
    fail("stand sprite must use its compiled atlas")
  }
  @debug.debug_inspect(
    (loaded.list_tags(), stand.first_frame_index, atlas.index),
    content=(
      #|(["eye", "stand"], 1, 1)
    ),
  )
}
