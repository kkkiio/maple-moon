///|
using @char_stance {type StanceId}

///|
fn init {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  try! @res.configure_packs([("base", "assets/base")])
}

///|
fn load_draw_info() -> @types.BodyDrawInfo raise {
  let bodynode = @res.require_json("res://Character/Body/00002000.img.json")
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = @res.require_json("res://Character/Body/00012000.img.json")
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  @cb.BodyDrawInfo(stance_bodys_map.0, stance_heads_map.0)
}

///|
fn assert_decode_failed_as_weapon_part(json : Json) -> Unit raise {
  let failed = try {
    let _ : NxWeaponPart = @json.from_json(json)
    false
  } catch {
    _ => true
  }
  guard failed else { fail("expected NxWeaponPart decode failure") }
}

///|
test "NxWeapon parses shoot2 anchor origin and z" {
  let src = @res.require_json("res://Character/Weapon/01462000.img.json")
  let nx_weapon : NxWeapon = @json.from_json(src)
  guard nx_weapon.get_part("shoot2", 0, "weapon") is Some(part) else {
    fail("missing shoot2/0/weapon part")
  }
  debug_inspect(
    (
      part.anchor.parent_key,
      part.anchor.parent_pos,
      part.texture.origin,
      part.z,
    ),
    content=(
      #|("navel", { x: 20, y: 11 }, { x: 13, y: 5 }, "weapon")
    ),
  )
}

///|
test "NxWeapon skips empty frame placeholders" {
  let src : Json = {
    "heal": {
      "0": {
        "weapon": {
          "__i": "res://Character/Weapon/spritesheets/01402000.img.png",
          "__w": 62,
          "__h": 21,
          "origin": [23, 10],
          "z": "weaponOverArm",
          "map": { "hand": [37, 9] },
        },
      },
      "1": { "weapon": null },
      "2": { "weapon": Json::empty_object() },
    },
  }
  let nx_weapon : NxWeapon = @json.from_json(src)
  guard nx_weapon.get_part("heal", 0, "weapon") is Some(_) else {
    fail("expected renderable weapon part")
  }
  guard nx_weapon.get_part("heal", 1, "weapon") is None else {
    fail("expected null placeholder to be skipped")
  }
  guard nx_weapon.get_part("heal", 2, "weapon") is None else {
    fail("expected empty object placeholder to be skipped")
  }
}

///|
test "NxWeaponPart decode should fail when required fields are missing" {
  assert_decode_failed_as_weapon_part({
    "__i": "res://Character/Weapon/spritesheets/01462000.img.png",
    "__w": 1,
    "__h": 1,
    "origin": [0, 0],
    "map": { "navel": [0, 0] },
  })
  assert_decode_failed_as_weapon_part({
    "__i": "res://Character/Weapon/spritesheets/01462000.img.png",
    "__w": 1,
    "__h": 1,
    "z": "weapon",
    "map": { "navel": [0, 0] },
  })
  assert_decode_failed_as_weapon_part({
    "__i": "res://Character/Weapon/spritesheets/01462000.img.png",
    "__w": 1,
    "__h": 1,
    "z": "weapon",
    "origin": [0, 0],
  })
}

///|
test "resolve_anchor_shift should match previous weapon navel rule" {
  let draw_info = load_draw_info()
  let parent_pos = Point(20, 11)
  let shift = resolve_anchor_shift(
    draw_info,
    StanceId::SHOOT2,
    0,
    "navel",
    parent_pos,
  )
  let expected = draw_info.get_body_position(StanceId::SHOOT2, 0) - parent_pos
  assert_eq(shift.x, expected.x)
  assert_eq(shift.y, expected.y)
}

///|
using @struct {type Point}
