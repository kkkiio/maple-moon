///|
test "parse_mx_mob" {
  let content = @fs.read_file_to_string("assets/mob/1210102.img/mx.json")
  let json = @json.parse(content)
  let mx_mob : @monster.MxMob = @json.from_json(json)
  inspect(mx_mob.stance_nodes.contains("stand"), content="true")
  inspect(mx_mob.stance_nodes.contains("move"), content="true")
  inspect(mx_mob.stance_nodes.contains("jump"), content="true")
  inspect(mx_mob.stance_nodes.contains("hit1"), content="true")
  inspect(mx_mob.stance_nodes.contains("die1"), content="true")
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
