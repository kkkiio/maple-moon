test "char look" {
  // let body_json = @fs.read_file_to_string!(path="00002000.img.json")
  // let head_json = @fs.read_file_to_string!(path="00012000.img.json")
  let look : @char_look.CharLook = @char_look.CharLook::new(
    {
      female: false,
      skin: 0,
      faceid: 0,
      hairid: 0,
      equips: {},
      maskedequips: {},
      petids: [],
    },
    @char_look.Body::default(),
    @char_look.Hair::default(),
    @char_look.Face::default(),
    @types.BodyDrawInfo::default(),
  )
  let rs = look.make_draw_front(
    @types.StanceId::STAND1,
    @char_look.ExpressionId::DEFAULT,
    0,
    0,
  )
  @json.inspect!(rs, content=[{"hair":{"name":"","color":""},"stance":"stand1","layer":"BELOW_BODY","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"CAPE","layer":"CAPE","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"SHIELD","layer":"SHIELD_BELOW_BODY","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"WEAPON","layer":"WEAPON_BELOW_BODY","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"HAT","layer":"CAP_BELOW_BODY","frame":0},{"body":{"name":""},"stance":"stand1","layer":"BODY","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"GLOVES","layer":"WRIST_OVER_BODY","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"GLOVES","layer":"GLOVE_OVER_BODY","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"SHOES","layer":"SHOES","frame":0},{"body":{"name":""},"stance":"stand1","layer":"ARM_BELOW_HEAD","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"BOTTOM_DEFAULT","layer":"PANTS_DEFAULT","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"BOTTOM","layer":"PANTS","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"TOP_DEFAULT","layer":"TOP_DEFAULT","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"TOP","layer":"TOP","frame":0},{"body":{"name":""},"stance":"stand1","layer":"ARM_BELOW_HEAD_OVER_MAIL","frame":0},{"hair":{"name":"","color":""},"stance":"stand1","layer":"HAIR_LAYER_DEFAULT","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"SHIELD","layer":"SHIELD_OVER_HAIR","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"EARACC","layer":"EARRINGS","frame":0},{"body":{"name":""},"stance":"stand1","layer":"HEAD","frame":0},{"hair":{"name":"","color":""},"stance":"stand1","layer":"SHADE","frame":0},{"face":{"name":""},"expression":"default","exp_frame":0,"stance":"stand1","stance_frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"FACE","layer":"FACE_ACC","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"EYE_ACC","layer":"EYE_ACC","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"SHIELD","layer":"SHIELD","frame":0},{"hair":{"name":"","color":""},"stance":"stand1","layer":"OVER_HEAD","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"WEAPON","layer":"WEAPON_BELOW_ARM","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"WEAPON","layer":"WEAPON","frame":0},{"body":{"name":""},"stance":"stand1","layer":"ARM","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"TOP","layer":"MAILARM","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"GLOVES","layer":"WRIST","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"GLOVES","layer":"GLOVE","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"WEAPON","layer":"WEAPON_OVER_GLOVE","frame":0},{"body":{"name":""},"stance":"stand1","layer":"HAND_BELOW_WEAPON","frame":0},{"body":{"name":""},"stance":"stand1","layer":"ARM_OVER_HAIR","frame":0},{"body":{"name":""},"stance":"stand1","layer":"ARM_OVER_HAIR_BELOW_WEAPON","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"WEAPON","layer":"WEAPON_OVER_HAND","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"WEAPON","layer":"WEAPON_OVER_BODY","frame":0},{"body":{"name":""},"stance":"stand1","layer":"HAND_OVER_HAIR","frame":0},{"body":{"name":""},"stance":"stand1","layer":"HAND_OVER_WEAPON","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"GLOVES","layer":"WRIST_OVER_HAIR","frame":0},{"equips":{"clothes":{}},"stance":"stand1","slot":"GLOVES","layer":"GLOVE_OVER_HAIR","frame":0}])
}
