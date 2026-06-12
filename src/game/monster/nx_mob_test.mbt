///|
test "parse_nx_mob" {
  let content = @fs.read_file_to_string("assets/Mob/1210102.img.json")
  let json = @json.parse(content)
  let nx_mob : @monster.NxMob = @json.from_json(json)
  json_inspect(nx_mob.meta, content={
    "can_move": true,
    "can_jump": true,
    "can_fly": false,
  })
  json_inspect(nx_mob.info, content={
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
