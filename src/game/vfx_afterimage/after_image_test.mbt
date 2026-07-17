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
fn create_test_resource(first_frame : Int) -> NxAfterImage {
  let clip = try! @res.compile_nx_animation(
    @res.NxAnimation::{
      frames: [
        {
          texture: {
            i: "res://Character/Afterimage/bow.img/animation.png",
            w: 10,
            h: 10,
            offset: Default::default(),
            origin: Default::default(),
          },
          delay: Some(100),
          head: None,
          bounds: None,
        },
      ],
      blend: false,
      zigzag: false,
    },
    name="test/afterimage",
  )
  NxAfterImage(clip, @struct.Rectangle::from4(-50, 50, -50, 50), first_frame)
}

///|
fn load_test_look(host : @entity.Entity) -> @cp.CharLook raise {
  let bodynode = @res.require_json("res://Character/Body/00002000.img.json")
  let stance_bodys_map : @cb.NxStanceLooks[@cb.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = @res.require_json("res://Character/Body/00012000.img.json")
  let stance_heads_map : @cb.NxStanceLooks[@cb.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @cb.BodyDrawInfo(stance_bodys_map.0, stance_heads_map.0)
  let hair_node : @cb.NxStanceLooks[@cb.NxMultiPartFrame] = @res.require_json(
      "res://Character/Hair/00030000.img.json",
    )
    |> @json.from_json
  @cp.CharLook(
    host,
    Map([]),
    @cp.FullBody(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @cp.Hair::parse(0, hair_node, draw_info),
    @cp.Face(20000, @res.require_json("res://Character/Face/00020000.img.json")),
    draw_info,
  )
}

///|
fn is_after_image_displayed(entity : @entity.Entity) -> Bool {
  entity.is_alive() &&
  @sprite.sprites().get(entity) is Some(_) &&
  @visibility.is_visible(entity)
}

///|
fn tick_look_until_frame(
  look : @cp.CharLook,
  target_frame : Int,
  max_ticks : Int,
) -> Unit {
  let mut ticks = 0
  while look.get_frame() < target_frame && ticks < max_ticks {
    @time.set_delta(0.016)
    @cp.char_look_animation_tick_system(@ecs.require_current_world())
    ticks += 1
  }
}

///|
test "AfterImage display logic" {
  let host = @entity.Entity()
  let entity = host.spawn_child()
  let resource = create_test_resource(0)
  let look = load_test_look(host)
  look.set_stance(@char_stance.StanceId::STAND1)
  look.play_animations()

  add_after_image(entity, look, resource, true)
  @time.set_delta(0.016)
  update_after_image_system(@ecs.require_current_world())

  let children = @entity.Entity::get_children(entity)
  inspect(
    children.length(),
    content=(
      #|1
    ),
  )
  let child = children[0]
  inspect(
    is_after_image_displayed(child),
    content=(
      #|true
    ),
  )
  clear_after_image(entity)
  inspect(
    is_after_image_displayed(child),
    content=(
      #|false
    ),
  )
}

///|
test "AfterImage with first_frame > 0" {
  let host = @entity.Entity()
  let entity = host.spawn_child()
  let look = load_test_look(host)
  look.set_stance(@char_stance.StanceId::STAND1)
  look.play_animations()
  let initial_frame = look.get_frame()
  let resource = create_test_resource(initial_frame + 1)
  add_after_image(entity, look, resource, true)

  @time.set_delta(0.016)
  update_after_image_system(@ecs.require_current_world())
  let child = @entity.Entity::get_children(entity)[0]
  inspect(
    is_after_image_displayed(child),
    content=(
      #|false
    ),
  )

  tick_look_until_frame(look, initial_frame + 1, 120)
  @time.set_delta(0.016)
  update_after_image_system(@ecs.require_current_world())
  inspect(
    is_after_image_displayed(child),
    content=(
      #|true
    ),
  )
  clear_after_image(entity)
}
