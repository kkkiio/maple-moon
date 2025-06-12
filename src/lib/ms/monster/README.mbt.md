# Mob

怪物

## link

有些怪物借用其他怪物的动画，比如战士二转任务里的火野猪和猴子。

```mbt
test {
  let src : Json =
     {
      "MADamage": 120,
      "MDDamage": 50,
      "PADamage": 110,
      "PDDamage": 30,
      "acc": 90,
      "bodyAttack": 1,
      "eva": 10,
      "exp": 0,
      "fs": 10,
      "level": 35,
      "link": "3210800",
      "maxHP": 800,
      "maxMP": 100,
      "mobType": 0,
      "pushed": 1,
      "speed": 35,
      "summonType": 1,
      "undead": 0,
    }

  let info : MobInfo = src |> @json.from_json
  @json.inspect(info, content={"magic_damage":120,"md_damage":50,"pa_damage":110,"pd_damage":30,"acc":90,"body_attack":true,"eva":10,"exp":0,"fs":10,"fly_speed":0,"level":35,"link":3210800,"max_hp":800,"max_mp":100,"mob_type":0,"pushed":1,"speed":35,"summon_type":1,"undead":false,"boss":false,"no_flip":false})
}
```
