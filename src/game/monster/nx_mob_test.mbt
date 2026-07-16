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
test "parse_mx_mob" {
  let json = @res.require_json("res://Mob/1210102.img/mx.json")
  let mx_mob : @monster.MxMob = @json.from_json(json)
  let stance_names = mx_mob.stance_nodes.keys().collect()
  stance_names.sort()
  debug_inspect(
    stance_names,
    content=(
      #|["die1", "hit1", "jump", "move", "stand"]
    ),
  )
  json_inspect(mx_mob.info, content={
    "magic_damage": 0,
    "md_damage": 10,
    "pa_damage": 42,
    "pd_damage": 0,
    "acc": 42,
    "body_attack": true,
    "eva": 1,
    "exp": 15,
    "fs": 10,
    "fly_speed": 0,
    "level": 8,
    "max_hp": 80,
    "max_mp": 45,
    "mob_type": 4,
    "pushed": 1,
    "speed": 0,
    "summon_type": 1,
    "undead": false,
    "boss": false,
    "no_flip": false,
  })
}
