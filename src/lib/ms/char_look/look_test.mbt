///|
test "test basic char look" {
  let draw_info = @char_look.get_draw_info()
  let _ = @char_look.CharLook::new(
    @entity.Entity::new(),
    {},
    @char_look.FullBody::new(
      0,
      draw_info,
      @char_look.get_stance_bodys_map(),
      @char_look.get_stance_heads_map(),
    ),
    @char_look.Hair::parse(
      0,
      @json.from_json(@char_look.male_1_white_hair),
      draw_info,
    ),
    @char_look.Face::new(20800, @char_look.male_1_white_face),
    draw_info,
  )

}
