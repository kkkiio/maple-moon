///|
test "res VFS resolves priority and keeps relative references in one pack" {
  let files : Map[String, Bytes] = Map([
    (
      "packs/base/pack.json",
      @encoding/utf8.encode(
        "{\"schema\":1,\"id\":\"base\",\"files\":[\"Data/base.txt\",\"Data/config.json\",\"Data/icon.png\",\"Data/texture.json\",\"Map/Map1/demo.mx.json\",\"Map/tiles/demo.tmj\",\"Mob/demo/animation.png\"]}",
      ),
    ),
    (
      "packs/patch/pack.json",
      @encoding/utf8.encode(
        "{\"schema\":1,\"id\":\"patch\",\"files\":[\"Data/config.json\",\"Map/Map1/demo.mx.json\",\"Mob/demo/animation.json\"]}",
      ),
    ),
    ("packs/base/Data/base.txt", @encoding/utf8.encode("base")),
    ("packs/base/Data/icon.png", Bytes::from_array([0x89U.to_byte()])),
    (
      "packs/base/Data/texture.json",
      @encoding/utf8.encode(
        "{\"texture\":{\"__i\":\"icon.png\",\"__w\":1,\"__h\":1}}",
      ),
    ),
    (
      "packs/base/Data/config.json",
      @encoding/utf8.encode("{\"pack\":\"base\"}"),
    ),
    ("packs/base/Map/Map1/demo.mx.json", @encoding/utf8.encode("{}")),
    ("packs/base/Map/tiles/demo.tmj", @encoding/utf8.encode("{}")),
    ("packs/base/Mob/demo/animation.png", Bytes::from_array([0x89U.to_byte()])),
    (
      "packs/patch/Data/config.json",
      @encoding/utf8.encode("{\"pack\":\"patch\"}"),
    ),
    ("packs/patch/Map/Map1/demo.mx.json", @encoding/utf8.encode("{}")),
    (
      "packs/patch/Mob/demo/animation.json",
      @encoding/utf8.encode(
        "{\"frames\":[{\"frame\":{\"x\":0,\"y\":0,\"w\":1,\"h\":1},\"spriteSourceSize\":{\"x\":0,\"y\":0},\"duration\":100}],\"meta\":{\"image\":\"animation.png\",\"size\":{\"w\":1,\"h\":1},\"frameTags\":[{\"name\":\"stand\",\"from\":0,\"to\":0,\"direction\":\"forward\"}],\"slices\":[{\"name\":\"anchor_stand\",\"keys\":[{\"bounds\":{\"x\":0,\"y\":0,\"w\":1,\"h\":1},\"pivot\":{\"x\":0,\"y\":0}}]}]}}",
      ),
    ),
  ])
  @asset.set_io(fn(path) { files.get(path) })
  try! configure_packs([("base", "packs/base"), ("patch", "packs/patch")])

  inspect(
    (try! ResourceKey::parse("res://Mob/./0100100.img/../0100101.img/mx.json")).to_address(),
    content="res://Mob/0100101.img/mx.json",
  )
  inspect(
    try! resolve("res://Data/config.json"),
    content="packs/patch/Data/config.json",
  )
  inspect(
    try! resolve("res://Data/base.txt"),
    content="packs/base/Data/base.txt",
  )
  inspect(
    try! resolve_ref(
      try! resolve("res://Map/Map1/demo.mx.json"),
      "../tiles/demo.tmj",
    ),
    content="packs/patch/Map/tiles/demo.tmj",
  )
  inspect(
    try! resolve_ref("res://Map/Map1/demo.mx.json", "../tiles/demo.tmj"),
    content="res://Map/tiles/demo.tmj",
  )
  inspect(try! load_text("res://Data/base.txt"), content="base")
  json_inspect(try! load_json("res://Data/config.json"), content={
    "pack": "patch",
  })
  let texture_json = try! load_json("res://Data/texture.json")
  guard texture_json is { "texture": { "__i": String(image), .. }, .. } else {
    fail("expected resolved NX texture reference")
  }
  @debug.debug_inspect(image, content=(
    #|"packs/base/Data/icon.png"
  ))

  try ResourceKey::parse("res://../../outside.json") catch {
    ResourceLoadError::InvalidAddress(message) =>
      inspect(
        message,
        content="resource address escapes its root: res://../../outside.json",
      )
    _ => fail("expected invalid resource address")
  } noraise {
    _ => fail("expected invalid resource address")
  }
  try
    resolve_ref("packs/patch/Map/Map1/demo.mx.json", "../../../../outside.tmj")
  catch {
    ResourceLoadError::InvalidAddress(message) =>
      inspect(
        message,
        content="resource reference escapes pack patch: ../../../../outside.tmj, base=packs/patch/Map/Map1/demo.mx.json",
      )
    _ => fail("expected pack traversal error")
  } noraise {
    _ => fail("expected pack traversal error")
  }
  try
    AnimationLoader::AnimationLoader().load("res://Mob/demo/animation.json")
  catch {
    ResourceLoadError::NotFound(message) =>
      inspect(
        message,
        content="resource disappeared after resolution: address=packs/patch/Mob/demo/animation.png, physical=packs/patch/Mob/demo/animation.png",
      )
    _ => fail("expected same-pack image miss")
  } noraise {
    _ => fail("expected same-pack image miss")
  }
  try configure_packs([]) catch {
    ResourceLoadError::InvalidMount(message) =>
      inspect(
        message,
        content="resource pack configuration must contain at least one pack",
      )
    _ => fail("expected invalid resource mount")
  } noraise {
    _ => fail("expected invalid resource mount")
  }
  inspect(
    try! resolve("res://Data/config.json"),
    content="packs/patch/Data/config.json",
  )
  clear_mounts()
  @asset.set_io(fn(_path) { None })
}

test "res VFS rejects an invalid pack manifest atomically" {
  let files : Map[String, Bytes] = Map([
    (
      "packs/base/pack.json",
      @encoding/utf8.encode(
        "{\"schema\":1,\"id\":\"base\",\"files\":[\"Data/config.json\"]}",
      ),
    ),
    (
      "packs/base/Data/config.json",
      @encoding/utf8.encode("{\"pack\":\"base\"}"),
    ),
    (
      "packs/broken/pack.json",
      @encoding/utf8.encode(
        "{\"schema\":1,\"id\":\"broken\",\"files\":[\"../outside.json\"]}",
      ),
    ),
  ])
  @asset.set_io(fn(path) { files.get(path) })
  try! configure_packs([("base", "packs/base")])
  try configure_packs([("broken", "packs/broken")]) catch {
    ResourceLoadError::InvalidMount(message) =>
      @debug.debug_inspect(message, content=(
        #|"invalid resource path in pack broken: path=../outside.json, error=InvalidAddress(\"resource address escapes its root: res://../outside.json\")"
      ))
    _ => fail("expected invalid resource pack manifest")
  } noraise {
    _ => fail("expected invalid resource pack manifest")
  }
  @debug.debug_inspect(try! resolve("res://Data/config.json"), content=(#|"packs/base/Data/config.json"
  ))
  clear_mounts()
  @asset.set_io(fn(_path) { None })
}
