///|
fn load_animations(src : Json) -> Map[StanceType, MobAnimation] raise {
  let mob_animations : MobAnimations = @json.from_json(src)
  let animations : Map[StanceType, MobAnimation] = Map::new()
  if mob_animations.fly is Some(fly) {
    let fly = nx_animation_to_mob_animation(fly)
    animations[StanceType::STAND] = fly
    animations[StanceType::MOVE] = fly
  } else if mob_animations.stand is Some(stand) &&
    mob_animations.move_ is Some(move_) {
    let stand = nx_animation_to_mob_animation(stand)
    animations[StanceType::STAND] = stand
    let move_ = nx_animation_to_mob_animation(move_)
    animations[StanceType::MOVE] = move_
  } else {
    fail("missing fly,stand,move animation, animations=\{mob_animations}")
  }
  if mob_animations.jump is Some(jump) {
    animations[StanceType::JUMP] = nx_animation_to_mob_animation(jump)
  }
  animations[StanceType::HIT] = nx_animation_to_mob_animation(
    mob_animations.hit1,
  )
  animations[StanceType::DIE] = mob_animations.die1
    |> nx_animation_to_mob_animation
  animations
}

///|
pub(all) struct MobAnimations {
  fly : @resource.NxAnimation?
  stand : @resource.NxAnimation?
  move_ : @resource.NxAnimation?
  jump : @resource.NxAnimation?
  hit1 : @resource.NxAnimation
  die1 : @resource.NxAnimation
} derive(@json.FromJson(fields(move_(rename="move"))), Show)

///|
fn load_animation(src : @resource.NxNode) -> MobAnimation raise {
  let nx : @resource.NxAnimation = @json.from_json(src.value())
  let selene_l = @graphics.nx_animation_to_selene_animation(nx, flip_x=false)
  let selene_r = @graphics.nx_animation_to_selene_animation(nx, flip_x=true)
  { nx, selene_l, selene_r }
}

///|
fn nx_animation_to_mob_animation(nx : @resource.NxAnimation) -> MobAnimation {
  let selene_l = @graphics.nx_animation_to_selene_animation(nx, flip_x=false)
  let selene_r = @graphics.nx_animation_to_selene_animation(nx, flip_x=true)
  { nx, selene_l, selene_r }
}

///|
test "parse monster" {
  let src : Json = {
    "die1": {
      "0": {
        "__h": 32,
        "__w": 56,
        "delay": 180,
        "head": [-4, -34],
        "origin": [30, 32],
        "__i": "mob/0100101.img_die1.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 32,
        "__w": 56,
        "delay": 180,
        "head": [-6, -22],
        "origin": [30, 32],
        "__i": "mob/0100101.img_die1.png",
        "__off": [56, 0],
      },
      "2": {
        "__h": 32,
        "__w": 56,
        "a0": 255,
        "a1": 0,
        "delay": 300,
        "head": [-10, -12],
        "origin": [30, 32],
        "__i": "mob/0100101.img_die1.png",
        "__off": [112, 0],
      },
    },
    "hit1": {
      "0": {
        "__h": 39,
        "__w": 41,
        "delay": 600,
        "head": [-3, -37],
        "lt": [-16, -39],
        "origin": [16, 39],
        "rb": [25, 0],
        "__i": "mob/0100101.img_hit1.png",
        "__off": [0, 0],
      },
    },
    "info": {
      "MADamage": 0,
      "MDDamage": 0,
      "PADamage": 17,
      "PDDamage": 0,
      "acc": 20,
      "bodyAttack": 1,
      "eva": 0,
      "exp": 4,
      "fs": 10,
      "level": 2,
      "maxHP": 15,
      "maxMP": 15,
      "mobType": 0,
      "pushed": 1,
      "speed": -50,
      "summonType": 1,
      "undead": 0,
    },
    "move": {
      "0": {
        "__h": 34,
        "__w": 44,
        "delay": 120,
        "head": [-4, -34],
        "lt": [-16, -34],
        "origin": [16, 34],
        "rb": [19, 0],
        "__i": "mob/0100101.img_move.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 34,
        "__w": 44,
        "delay": 120,
        "head": [-3, -34],
        "lt": [-13, -34],
        "origin": [16, 34],
        "rb": [24, 0],
        "__i": "mob/0100101.img_move.png",
        "__off": [44, 0],
      },
      "2": {
        "__h": 34,
        "__w": 44,
        "delay": 120,
        "head": [-2, -34],
        "lt": [-10, -34],
        "origin": [16, 34],
        "rb": [29, 0],
        "__i": "mob/0100101.img_move.png",
        "__off": [88, 0],
      },
      "3": {
        "__h": 34,
        "__w": 44,
        "delay": 120,
        "head": [-1, -34],
        "lt": [-7, -34],
        "origin": [16, 34],
        "rb": [34, 0],
        "__i": "mob/0100101.img_move.png",
        "__off": [132, 0],
      },
      "zigzag": 1,
    },
    "stand": {
      "0": {
        "__h": 34,
        "__w": 35,
        "head": [-4, -34],
        "lt": [-16, -34],
        "origin": [16, 34],
        "rb": [19, 0],
        "__i": "mob/0100101.img_stand.png",
        "__off": [0, 0],
      },
    },
  }
  let animations : MobAnimations = @json.from_json(src)
  inspect(
    animations,
    content=(
      #|{fly: None, stand: Some({frames: [{texture: {i: "mob/0100101.img_stand.png", w: 35, h: 34, offset: {x: 0, y: 0}, origin: {x: 16, y: 34}}, delay: None, head: Some({x: -4, y: -34}), bounds: Some({lt: {x: -16, y: -34}, rb: {x: 19, y: 0}})}], blend: false, zigzag: false}), move_: Some({frames: [{texture: {i: "mob/0100101.img_move.png", w: 44, h: 34, offset: {x: 0, y: 0}, origin: {x: 16, y: 34}}, delay: Some(120), head: Some({x: -4, y: -34}), bounds: Some({lt: {x: -16, y: -34}, rb: {x: 19, y: 0}})}, {texture: {i: "mob/0100101.img_move.png", w: 44, h: 34, offset: {x: 44, y: 0}, origin: {x: 16, y: 34}}, delay: Some(120), head: Some({x: -3, y: -34}), bounds: Some({lt: {x: -13, y: -34}, rb: {x: 24, y: 0}})}, {texture: {i: "mob/0100101.img_move.png", w: 44, h: 34, offset: {x: 88, y: 0}, origin: {x: 16, y: 34}}, delay: Some(120), head: Some({x: -2, y: -34}), bounds: Some({lt: {x: -10, y: -34}, rb: {x: 29, y: 0}})}, {texture: {i: "mob/0100101.img_move.png", w: 44, h: 34, offset: {x: 132, y: 0}, origin: {x: 16, y: 34}}, delay: Some(120), head: Some({x: -1, y: -34}), bounds: Some({lt: {x: -7, y: -34}, rb: {x: 34, y: 0}})}], blend: false, zigzag: true}), jump: None, hit1: {frames: [{texture: {i: "mob/0100101.img_hit1.png", w: 41, h: 39, offset: {x: 0, y: 0}, origin: {x: 16, y: 39}}, delay: Some(600), head: Some({x: -3, y: -37}), bounds: Some({lt: {x: -16, y: -39}, rb: {x: 25, y: 0}})}], blend: false, zigzag: false}, die1: {frames: [{texture: {i: "mob/0100101.img_die1.png", w: 56, h: 32, offset: {x: 0, y: 0}, origin: {x: 30, y: 32}}, delay: Some(180), head: Some({x: -4, y: -34}), bounds: None}, {texture: {i: "mob/0100101.img_die1.png", w: 56, h: 32, offset: {x: 56, y: 0}, origin: {x: 30, y: 32}}, delay: Some(180), head: Some({x: -6, y: -22}), bounds: None}, {texture: {i: "mob/0100101.img_die1.png", w: 56, h: 32, offset: {x: 112, y: 0}, origin: {x: 30, y: 32}}, delay: Some(300), head: Some({x: -10, y: -12}), bounds: None}], blend: false, zigzag: false}}
    ),
  )
}
