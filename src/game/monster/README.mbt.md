# Mob

怪物

## 资源加载

- `MxMob` 从 `Mob/<id>.img/mx.json` 读取属性、碰撞框、head 点、攻击范围和
  Aseprite 动画引用。
- `@res.AnimationLoader` 把引用编译为不带播放策略的 `SpriteClip`。
- monster package 按获胜 resource pack 中的物理 `mx.json` 缓存一份包含全部
  stance/effect clip 的 AnimationGraph，同资源的怪物实例共享 graph；渲染 system
  为每个实例维护 player，根据 stance 启动对应 node，并由资源中的 `loop` 元数据
  决定是否循环。

## link

有些怪物借用其他怪物的动画，比如战士二转任务里的火野猪和猴子。

```mbt nocheck
///|
test {
  let src : Json = {
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
  json_inspect(info, content={
    "magic_damage": 120,
    "md_damage": 50,
    "pa_damage": 110,
    "pd_damage": 30,
    "acc": 90,
    "body_attack": true,
    "eva": 10,
    "exp": 0,
    "fs": 10,
    "fly_speed": 0,
    "level": 35,
    "link": 3210800,
    "max_hp": 800,
    "max_mp": 100,
    "mob_type": 0,
    "pushed": 1,
    "speed": 35,
    "summon_type": 1,
    "undead": false,
    "boss": false,
    "no_flip": false,
  })
}
```
