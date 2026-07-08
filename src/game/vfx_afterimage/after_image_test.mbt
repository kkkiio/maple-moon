///|
fn create_test_resource(first_frame : Int) -> NxAfterImage {
  {
    animation: @ms_animation.from_nx_animation(@resource.NxAnimation::{
      frames: [
        {
          texture: {
            i: "assets/Character/Afterimage/bow.img/animation.png",
            w: 10,
            h: 10,
            offset: @struct.Point::default(),
            origin: @struct.Point::default(),
          },
          delay: Some(100),
          head: None,
          bounds: None,
        },
      ],
      blend: false,
      zigzag: false,
    }),
    range: @struct.Rectangle::from4(-50, 50, -50, 50),
    first_frame,
  }
}

///|
fn load_test_look(host : @entity.Entity) -> @cp.CharLook raise {
  let bodynode = @fs.read_file_to_string(
      "assets/Character/Body/00002000.img.json",
    )
    |> @json.parse
  let stance_bodys_map : @cb.NxStanceLooks[@cb.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = @fs.read_file_to_string(
      "assets/Character/Body/00012000.img.json",
    )
    |> @json.parse
  let stance_heads_map : @cb.NxStanceLooks[@cb.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @cb.BodyDrawInfo::new(stance_bodys_map.0, stance_heads_map.0)
  let hair_node : @cb.NxStanceLooks[@cb.NxMultiPartFrame] = @fs.read_file_to_string(
      "assets/Character/Hair/00030000.img.json",
    )
    |> @json.parse
    |> @json.from_json
  @cp.CharLook::new(
    host,
    {},
    @cp.FullBody::new(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @cp.Hair::parse(0, hair_node, draw_info),
    @cp.Face::new(
      20000,
      @fs.read_file_to_string("assets/Character/Face/00020000.img.json")
      |> @json.parse,
    ),
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
  inspect(children.length(), content="1")
  let child = children[0]
  inspect(is_after_image_displayed(child), content="true")
  clear_after_image(entity)
  inspect(is_after_image_displayed(child), content="false")
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
  inspect(is_after_image_displayed(child), content="false")

  tick_look_until_frame(look, initial_frame + 1, 120)
  @time.set_delta(0.016)
  update_after_image_system(@ecs.require_current_world())
  inspect(is_after_image_displayed(child), content="true")
  clear_after_image(entity)
}
