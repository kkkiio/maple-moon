///|
fn create_test_resource() -> NxAfterImage {
  {
    animation: @resource.NxAnimation::{
      frames: [
        {
          texture: {
            i: "test.png",
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
    },
    range: @struct.Rectangle::from4(-50, 50, -50, 50),
    first_frame: 0,
  }
}

///|
fn is_after_image_displayed(entity : @entity.Entity) -> Bool {
  entity.is_alive() &&
  @sprite.sprites().get(entity) is Some(sprite) &&
  sprite.visible
}

///|
/// Black-box tests for AfterImage logic
test "AfterImage display logic" {
  let entity = @entity.Entity::new()
  let resource = create_test_resource()
  // Mock frame getter that we can control
  let current_frame = 0
  let get_frame_fn = fn() { current_frame }

  // Case 1: first_frame = 0, should display immediately
  add_after_image(entity, get_frame_fn, resource, true)
  update_after_image_system(0.016)

  // Verify display via child sprite presence
  let children = @entity.Entity::get_children(entity)
  inspect(children.length(), content="1")
  let child = children[0]
  inspect(is_after_image_displayed(child), content="true")
  clear_after_image(entity)
  inspect(is_after_image_displayed(child), content="false")
}

///|
test "AfterImage with first_frame > 0" {
  let entity = @entity.Entity::new()
  // Create a resource with first_frame = 5
  let resource = { ..create_test_resource(), first_frame: 5 }
  let mut current_frame = 0
  let get_frame_fn = fn() { current_frame }
  add_after_image(entity, get_frame_fn, resource, true)

  // Frame 0: should NOT display
  update_after_image_system(0.016)
  let child = @entity.Entity::get_children(entity)[0]
  inspect(is_after_image_displayed(child), content="false")

  // Frame 4: should NOT display
  current_frame = 4
  update_after_image_system(0.016)
  inspect(is_after_image_displayed(child), content="false")

  // Frame 5: should display
  current_frame = 5
  update_after_image_system(0.016)
  inspect(is_after_image_displayed(child), content="true")
  clear_after_image(entity)
}
