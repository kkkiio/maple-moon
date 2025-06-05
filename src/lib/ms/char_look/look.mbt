///|
struct CharLook {
  stance : @utils.Nominal[@types.StanceId]
  st_frame : @utils.Nominal[Int]
  mut st_elapsed : Int
  expression : @utils.Nominal[ExpressionId]
  exp_frame : @utils.Nominal[Int]
  mut exp_elapsed : Int
  mut flip : Bool
  mut actionstr : String
  mut actframe : Int
  body : Body
  hair : Hair
  face : Face
  mut action : @types.BodyAction?
  equips : @equip.CharEquips
  randomizer : @utils.Randomizer
  alerted : @utils.TimedBool
  draw_info : @types.BodyDrawInfo
}

///|
pub(all) struct LookEntry {
  female : Bool
  skin : Int
  faceid : Int
  hairid : Int
  equips : Map[Int, Int]
  maskedequips : Map[Int, Int]
  petids : Array[Int]
} derive(Show, ToJson, Default)

///|
pub fn CharLook::new(
  entry : LookEntry,
  body : Body,
  hair : Hair,
  face : Face,
  string_loader : @resource.SyncLoader,
  draw_info : @types.BodyDrawInfo
) -> CharLook {
  let l = {
    stance: @utils.Nominal::default(),
    st_frame: @utils.Nominal::default(),
    st_elapsed: 0,
    expression: @utils.Nominal::default(),
    exp_frame: @utils.Nominal::default(),
    exp_elapsed: 0,
    flip: false,
    action: None,
    actionstr: "",
    actframe: 0,
    body,
    hair,
    face,
    equips: @equip.CharEquips::new(string_loader),
    randomizer: @utils.Randomizer::default(),
    alerted: @utils.TimedBool::default(),
    draw_info,
  }
  for slot_id, itemid in entry.equips {
    l.add_equip(itemid, @slot.Id::from_int(slot_id))
  }
  l
}

///|
fn updatetwohanded(self : CharLook) -> Unit {
  let basestance = @types.StanceId::baseof(self.stance.get())
  self.set_stance(basestance)
}

///|
fn draw_dead(
  self : CharLook,
  args : @graphics.DrawArgument,
  interstance : @types.StanceId,
  interexpression : ExpressionId,
  interframe : Int,
  interexpframe : Int
) -> Unit {
  let body = self.body
  let hair = self.hair
  let face = self.face
  let faceshift = self.draw_info.get_face_pos(@types.StanceId::STAND1, 1)
  let faceargs = args +
    @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default())
  fn draw_face(expression, frame) {
    face.draw(expression, frame, faceargs)
  }

  fn draw_interframe_hair(layer) {
    hair.draw(interstance, layer, interframe, args)
  }

  fn draw_hair(stance, layer, frame) {
    hair.draw(stance, layer, frame, args)
  }

  draw_interframe_hair(HairLayer::BELOW_BODY)
  self.equips.draw(
    @slot.Id::HAT,
    interstance,
    @clothing.Layer::CAP_BELOW_BODY,
    interframe,
    args,
  )
  body.draw(interstance, @types.BodyLayer::BODY, interframe, args)
  draw_interframe_hair(HairLayer::HAIR_LAYER_DEFAULT)
  body.draw(@types.StanceId::STAND1, @types.BodyLayer::HEAD, 1, args)
  draw_interframe_hair(HairLayer::SHADE)
  draw_interframe_hair(HairLayer::HAIR_LAYER_DEFAULT)
  body.draw(interstance, @types.BodyLayer::HEAD, interframe, args)
  draw_interframe_hair(HairLayer::SHADE)
  draw_face(interexpression, interexpframe)
  match self.equips.getcaptype() {
    @equip.CapType::NONE => draw_interframe_hair(HairLayer::OVER_HEAD)
    @equip.CapType::HEADBAND => {
      self.equips.draw(
        @slot.Id::HAT,
        @types.StanceId::STAND1,
        @clothing.Layer::CAP,
        1,
        args,
      )
      draw_hair(@types.StanceId::STAND1, HairLayer::HAIR_LAYER_DEFAULT, 1)
      draw_hair(@types.StanceId::STAND1, HairLayer::OVER_HEAD, 1)
      self.equips.draw(
        @slot.Id::HAT,
        @types.StanceId::STAND1,
        @clothing.Layer::CAP_OVER_HAIR,
        1,
        args,
      )
    }
    @equip.CapType::HALF_COVER => {
      draw_hair(@types.StanceId::STAND1, HairLayer::HAIR_LAYER_DEFAULT, 1)
      self.equips.draw(
        @slot.Id::HAT,
        @types.StanceId::STAND1,
        @clothing.Layer::CAP,
        1,
        args,
      )
    }
    @equip.CapType::FULL_COVER =>
      self.equips.draw(
        @slot.Id::HAT,
        @types.StanceId::STAND1,
        @clothing.Layer::CAP,
        1,
        args,
      )
    _ => ()
  }
  return
}

///|
fn draw_climbing(
  self : CharLook,
  args : @graphics.DrawArgument,
  interstance : @types.StanceId,
  interframe : Int
) -> Unit {
  let body = self.body
  let hair = self.hair
  fn draw_interframe_hair(layer) {
    hair.draw(interstance, layer, interframe, args)
  }

  body.draw(interstance, @types.BodyLayer::BODY, interframe, args)
  self.equips.draw(
    @slot.Id::GLOVES,
    interstance,
    @clothing.Layer::GLOVE,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::SHOES,
    interstance,
    @clothing.Layer::SHOES,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::BOTTOM_DEFAULT,
    interstance,
    @clothing.Layer::PANTS_DEFAULT,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::BOTTOM,
    interstance,
    @clothing.Layer::PANTS,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::TOP_DEFAULT,
    interstance,
    @clothing.Layer::TOP_DEFAULT,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::TOP,
    interstance,
    @clothing.Layer::TOP,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::TOP,
    interstance,
    @clothing.Layer::MAIL,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::CAPE,
    interstance,
    @clothing.Layer::CAPE,
    interframe,
    args,
  )
  body.draw(interstance, @types.BodyLayer::HEAD, interframe, args)
  self.equips.draw(
    @slot.Id::EARACC,
    interstance,
    @clothing.Layer::EARRINGS,
    interframe,
    args,
  )
  match self.equips.getcaptype() {
    @equip.CapType::NONE => draw_interframe_hair(HairLayer::BACK)
    @equip.CapType::HEADBAND => {
      self.equips.draw(
        @slot.Id::HAT,
        interstance,
        @clothing.Layer::CAP,
        interframe,
        args,
      )
      draw_interframe_hair(HairLayer::BACK)
    }
    @equip.CapType::HALF_COVER => {
      draw_interframe_hair(HairLayer::BELOW_CAP)
      self.equips.draw(
        @slot.Id::HAT,
        interstance,
        @clothing.Layer::CAP,
        interframe,
        args,
      )
    }
    @equip.CapType::FULL_COVER =>
      self.equips.draw(
        @slot.Id::HAT,
        interstance,
        @clothing.Layer::CAP,
        interframe,
        args,
      )
    _ => ()
  }
  self.equips.draw(
    @slot.Id::SHIELD,
    interstance,
    @clothing.Layer::BACK_SHIELD,
    interframe,
    args,
  )
  self.equips.draw(
    @slot.Id::WEAPON,
    interstance,
    @clothing.Layer::BACK_WEAPON,
    interframe,
    args,
  )
}

///|
fn draw_impl(
  self : CharLook,
  args : @graphics.DrawArgument,
  interstance : @types.StanceId,
  interexpression : ExpressionId,
  interframe : Int,
  interexpframe : Int
) -> Unit {
  if interstance == @types.StanceId::DEAD {
    return self.draw_dead(
      args, interstance, interexpression, interframe, interexpframe,
    )
  }
  if @types.StanceId::is_climbing(interstance) {
    return self.draw_climbing(args, interstance, interframe)
  }
  let drawables = self.make_draw_front(
    interstance, interexpression, interframe, interexpframe,
  )
  for drawable in drawables {
    drawable.draw(args)
  }
}

///|
pub fn make_draw_front(
  self : CharLook,
  stance : @types.StanceId,
  expression : ExpressionId,
  stance_frame : Int,
  expr_frame : Int
) -> Array[&@graphics.Drawable] {
  let drawables : Array[&@graphics.Drawable] = []
  fn make_hair_draw(layer) {
    { hair: self.hair, layer, frame: stance_frame, stance }
  }

  fn make_face_draw() {
    {
      face: self.face,
      expression,
      exp_frame: expr_frame,
      draw_info: self.draw_info,
      stance,
      stance_frame,
    }
  }

  fn make_body_draw(layer) {
    { body: self.body, layer, frame: stance_frame, stance }
  }

  fn make_equip_draw(slot, layer) {
    {
      equips: self.equips,
      stance,
      slot,
      layer,
      frame: stance_frame,
      draw_info: self.draw_info,
    }
  }

  drawables.push(make_hair_draw(HairLayer::BELOW_BODY))
  drawables.push(make_equip_draw(@slot.Id::CAPE, @clothing.Layer::CAPE))
  drawables.push(
    make_equip_draw(@slot.Id::SHIELD, @clothing.Layer::SHIELD_BELOW_BODY),
  )
  drawables.push(
    make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON_BELOW_BODY),
  )
  drawables.push(
    make_equip_draw(@slot.Id::HAT, @clothing.Layer::CAP_BELOW_BODY),
  )
  drawables.push(make_body_draw(@types.BodyLayer::BODY))
  drawables.push(
    make_equip_draw(@slot.Id::GLOVES, @clothing.Layer::WRIST_OVER_BODY),
  )
  drawables.push(
    make_equip_draw(@slot.Id::GLOVES, @clothing.Layer::GLOVE_OVER_BODY),
  )
  drawables.push(make_equip_draw(@slot.Id::SHOES, @clothing.Layer::SHOES))
  drawables.push(make_body_draw(@types.BodyLayer::ARM_BELOW_HEAD))
  if self.equips.has_overall() {
    drawables.push(make_equip_draw(@slot.Id::TOP, @clothing.Layer::MAIL))
  } else {
    drawables.push(
      make_equip_draw(@slot.Id::BOTTOM_DEFAULT, @clothing.Layer::PANTS_DEFAULT),
    )
    drawables.push(make_equip_draw(@slot.Id::BOTTOM, @clothing.Layer::PANTS))
    drawables.push(
      make_equip_draw(@slot.Id::TOP_DEFAULT, @clothing.Layer::TOP_DEFAULT),
    )
    drawables.push(make_equip_draw(@slot.Id::TOP, @clothing.Layer::TOP))
  }
  drawables.push(make_body_draw(@types.BodyLayer::ARM_BELOW_HEAD_OVER_MAIL))
  drawables.push(make_hair_draw(HairLayer::HAIR_LAYER_DEFAULT))
  drawables.push(
    make_equip_draw(@slot.Id::SHIELD, @clothing.Layer::SHIELD_OVER_HAIR),
  )
  drawables.push(make_equip_draw(@slot.Id::EARACC, @clothing.Layer::EARRINGS))
  drawables.push(make_body_draw(@types.BodyLayer::HEAD))
  drawables.push(make_hair_draw(HairLayer::SHADE))
  drawables.push(make_face_draw())
  drawables.push(make_equip_draw(@slot.Id::FACE, @clothing.Layer::FACE_ACC))
  drawables.push(make_equip_draw(@slot.Id::EYE_ACC, @clothing.Layer::EYE_ACC))
  drawables.push(make_equip_draw(@slot.Id::SHIELD, @clothing.Layer::SHIELD))
  match self.equips.getcaptype() {
    @equip.CapType::NONE => drawables.push(make_hair_draw(HairLayer::OVER_HEAD))
    @equip.CapType::HEADBAND => {
      drawables.push(make_equip_draw(@slot.Id::HAT, @clothing.Layer::CAP))
      drawables.push(make_hair_draw(HairLayer::HAIR_LAYER_DEFAULT))
      drawables.push(make_hair_draw(HairLayer::OVER_HEAD))
      drawables.push(
        make_equip_draw(@slot.Id::HAT, @clothing.Layer::CAP_OVER_HAIR),
      )
    }
    @equip.CapType::HALF_COVER => {
      drawables.push(make_hair_draw(HairLayer::HAIR_LAYER_DEFAULT))
      drawables.push(make_equip_draw(@slot.Id::HAT, @clothing.Layer::CAP))
    }
    @equip.CapType::FULL_COVER =>
      drawables.push(make_equip_draw(@slot.Id::HAT, @clothing.Layer::CAP))
    _ => ()
  }
  drawables.push(
    make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON_BELOW_ARM),
  )
  let twohanded : Bool = self.is_twohanded(stance)
  if twohanded {
    drawables.push(make_equip_draw(@slot.Id::TOP, @clothing.Layer::MAILARM))
    drawables.push(make_body_draw(@types.BodyLayer::ARM))
    drawables.push(make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON))
  } else {
    drawables.push(make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON))
    drawables.push(make_body_draw(@types.BodyLayer::ARM))
    drawables.push(make_equip_draw(@slot.Id::TOP, @clothing.Layer::MAILARM))
  }
  drawables.push(make_equip_draw(@slot.Id::GLOVES, @clothing.Layer::WRIST))
  drawables.push(make_equip_draw(@slot.Id::GLOVES, @clothing.Layer::GLOVE))
  drawables.push(
    make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON_OVER_GLOVE),
  )
  drawables.push(make_body_draw(@types.BodyLayer::HAND_BELOW_WEAPON))
  drawables.push(make_body_draw(@types.BodyLayer::ARM_OVER_HAIR))
  drawables.push(make_body_draw(@types.BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON))
  drawables.push(
    make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON_OVER_HAND),
  )
  drawables.push(
    make_equip_draw(@slot.Id::WEAPON, @clothing.Layer::WEAPON_OVER_BODY),
  )
  drawables.push(make_body_draw(@types.BodyLayer::HAND_OVER_HAIR))
  drawables.push(make_body_draw(@types.BodyLayer::HAND_OVER_WEAPON))
  drawables.push(
    make_equip_draw(@slot.Id::GLOVES, @clothing.Layer::WRIST_OVER_HAIR),
  )
  drawables.push(
    make_equip_draw(@slot.Id::GLOVES, @clothing.Layer::GLOVE_OVER_HAIR),
  )
  drawables
}

///|
struct BodyLayerDrawable {
  body : Body
  stance : @types.StanceId
  layer : @types.BodyLayer
  frame : Int
}

///|
pub impl ToJson for BodyLayerDrawable with to_json(self) -> Json {
  {
    "body": self.body.to_json(),
    "stance": self.stance.to_json(),
    "layer": self.layer.to_json(),
    "frame": self.frame.to_json(),
  }
}

///|
pub impl @graphics.Drawable for BodyLayerDrawable with draw(
  self : BodyLayerDrawable,
  args : @graphics.DrawArgument
) -> Unit {
  self.body.draw(self.stance, self.layer, self.frame, args)
}

///|
struct EquipLayerDrawable {
  equips : @equip.CharEquips
  stance : @types.StanceId
  slot : @slot.Id
  layer : @clothing.Layer
  frame : Int
  draw_info : @types.BodyDrawInfo
}

///|
pub impl ToJson for EquipLayerDrawable with to_json(self) -> Json {
  {
    "equips": self.equips.to_json(),
    "stance": self.stance.to_json(),
    "slot": self.slot.to_json(),
    "layer": self.layer.to_json(),
    "frame": self.frame.to_json(),
  }
}

///|
pub impl @graphics.Drawable for EquipLayerDrawable with draw(
  self : EquipLayerDrawable,
  args : @graphics.DrawArgument
) -> Unit {
  let args = match self.layer {
    @clothing.FACE_ACC => {
      let faceshift = self.draw_info.get_face_pos(self.stance, self.frame)
      args +
      @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default())
    }
    _ => args
  }
  self.equips.draw(self.slot, self.stance, self.layer, self.frame, args)
}

///|
struct FaceDrawable {
  face : Face
  expression : ExpressionId
  exp_frame : Int
  draw_info : @types.BodyDrawInfo
  stance : @types.StanceId
  stance_frame : Int
}

///|
pub impl @graphics.Drawable for FaceDrawable with draw(
  self : FaceDrawable,
  args : @graphics.DrawArgument
) -> Unit {
  let faceshift = self.draw_info.get_face_pos(self.stance, self.stance_frame)
  self.face.draw(
    self.expression,
    self.exp_frame,
    args +
    @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default()),
  )
}

///|
pub impl ToJson for FaceDrawable with to_json(self) -> Json {
  {
    "face": self.face.to_json(),
    "expression": self.expression.to_json(),
    "exp_frame": self.exp_frame.to_json(),
    "stance": self.stance.to_json(),
    "stance_frame": self.stance_frame.to_json(),
  }
}

///|
struct HairDrawable {
  hair : Hair
  stance : @types.StanceId
  layer : HairLayer
  frame : Int
}

///|
pub impl ToJson for HairDrawable with to_json(self) -> Json {
  {
    "hair": self.hair.to_json(),
    "stance": self.stance.to_json(),
    "layer": self.layer.to_json(),
    "frame": self.frame.to_json(),
  }
}

///|
pub impl @graphics.Drawable for HairDrawable with draw(
  self : HairDrawable,
  args : @graphics.DrawArgument
) -> Unit {
  self.hair.draw(self.stance, self.layer, self.frame, args)
}

///|
pub fn CharLook::draw(
  self : CharLook,
  args : @graphics.DrawArgument,
  alpha : Double
) -> Unit {
  let acmove = @struct.Point::default()
  let relargs = @graphics.DrawArgument::new14(acmove, self.flip)
  let interstance = self.stance.get(alpha~)
  let interexpression = self.expression.get(alpha~)
  let interframe = self.st_frame.get(alpha~)
  let interexpframe = self.exp_frame.get(alpha~)
  self.draw_impl(
    relargs + args,
    interstance,
    interexpression,
    interframe,
    interexpframe,
  )
}

///|
pub fn draw_with_stance(
  self : CharLook,
  position : @struct.Point[Int],
  flip : Bool,
  interstance : @types.StanceId,
  interexpression : ExpressionId
) -> Unit {
  let interstance = self.equips.adjust_stance(interstance)
  self.draw_impl(
    @graphics.DrawArgument::new(pos=position, flip~),
    interstance,
    interexpression,
    0,
    0,
  )
}

///|
pub fn is_twohanded(self : CharLook, st : @types.StanceId) -> Bool {
  match st {
    @types.StanceId::STAND1 | @types.StanceId::WALK1 => false
    @types.StanceId::STAND2 | @types.StanceId::WALK2 => true
    _ => self.equips.is_twohanded()
  }
}

///| Sets the direction of the character
pub fn set_direction(self : CharLook, facing_right : Bool) -> Unit {
  self.flip = facing_right
}

///|
pub fn set_stance(self : CharLook, st : @types.StanceId) -> Unit {
  if not(self.action.is_empty()) || st == @types.StanceId::NONE {
    return
  }
  // let adjstance = self.equips.adjust_stance(st)
  let adjstance = st
  if self.stance.get() != adjstance {
    self.stance.set(adjstance)
    self.st_frame.set(0)
    self.st_elapsed = 0
  }
}

///|
fn change_body(self : CharLook, body : Body) -> CharLook {
  { ..self, body, }
}

///|
fn change_hair(self : CharLook, hair : Hair) -> CharLook {
  { ..self, hair, }
}

///|
fn change_face(self : CharLook, face : Face) -> CharLook {
  { ..self, face, }
}

///|
pub fn CharLook::update(self : CharLook, timestep : Int) -> Bool {
  if timestep == 0 {
    self.stance.normalize()
    self.st_frame.normalize()
    self.expression.normalize()
    self.exp_frame.normalize()
    return false
  }
  self.alerted.update(timestep~)
  let mut aniend : Bool = false
  match self.action {
    None => {
      let delay : Int = self.get_delay(self.stance.get(), self.st_frame.get())
      let delta : Int = delay - self.st_elapsed
      if timestep >= delta {
        self.st_elapsed = timestep - delta
        let nextframe : Int = self.getnextframe(
          self.stance.get(),
          self.st_frame.get(),
        )
        let threshold : Double = delta.to_double() / timestep.to_double()
        self.st_frame.next(nextframe, threshold)
        if self.st_frame.get() == 0 {
          aniend = true
        }
      } else {
        self.stance.normalize()
        self.st_frame.normalize()
        self.st_elapsed += timestep
      }
    }
    Some(action) => {
      let delay : Int = action.get_delay()
      let delta : Int = delay - self.st_elapsed
      if timestep >= delta {
        self.st_elapsed = timestep - delta
        self.actframe = self.draw_info.next_action_frame(
          self.actionstr,
          self.actframe,
        )
        if self.actframe > 0 {
          self.action = self.draw_info.get_action(self.actionstr, self.actframe)
          let threshold : Double = delta.to_double() / timestep.to_double()
          self.stance.next(action.get_stance(), threshold)
          self.st_frame.next(action.get_frame(), threshold)
        } else {
          aniend = true
          self.action = None
          self.actionstr = ""
          self.set_stance(@types.StanceId::STAND1)
        }
      } else {
        self.stance.normalize()
        self.st_frame.normalize()
        self.st_elapsed += timestep
      }
    }
  }
  self.update_face(timestep)
  aniend
}

///|
fn update_face(self : CharLook, timestep : Int) -> Unit {
  let face = self.face
  let expdelay : Int = face.get_delay(
    self.expression.get(),
    self.exp_frame.get(),
  )
  let expdelta : Int = expdelay - self.exp_elapsed
  if timestep >= expdelta {
    self.exp_elapsed = timestep - expdelta
    let nextexpframe : Int = face.nextframe(
      self.expression.get(),
      self.exp_frame.get(),
    )
    let fcthreshold : Double = expdelta.to_double() / timestep.to_double()
    self.exp_frame.next(nextexpframe, fcthreshold)
    if self.exp_frame.get() == 0 {
      if self.expression.get() == ExpressionId::DEFAULT {
        self.expression.next(ExpressionId::BLINK, fcthreshold)
      } else {
        self.expression.next(ExpressionId::DEFAULT, fcthreshold)
      }
    }
  } else {
    self.expression.normalize()
    self.exp_frame.normalize()
    self.exp_elapsed += timestep
  }
}

///|
pub fn CharLook::get_delay(
  self : CharLook,
  st : @types.StanceId,
  fr : Int
) -> Int {
  self.draw_info.get_delay(st, fr)
}

///|
pub fn getnextframe(self : CharLook, st : @types.StanceId, fr : Int) -> Int {
  self.draw_info.next_frame(st, fr)
}

///|
pub fn get_equips(self : CharLook) -> @equip.CharEquips {
  self.equips
}

///|
pub fn add_equip(self : CharLook, itemid : Int, slot : @slot.Id) -> Unit {
  self.equips.add_equip(itemid, slot, self.draw_info)
  self.updatetwohanded()
}

///|
pub fn remove_equip(self : CharLook, slot : @slot.Id) -> Unit {
  self.equips.remove_equip(slot)
  if slot == @slot.Id::WEAPON {
    self.updatetwohanded()
  }
}

///|
pub fn get_stance(self : CharLook) -> @types.StanceId {
  self.stance.get()
}

///|
pub fn get_attackdelay(self : CharLook, no : Int, first_frame : Int) -> Int {
  match self.action {
    Some(_) => return self.draw_info.get_attack_delay(self.actionstr, no)
    None => ()
  }
  let mut delay : Int = 0
  for frame in 0..<first_frame {
    delay += self.get_delay(self.stance.get(), frame)
  }
  return delay
}

///|
pub fn attack(self : CharLook, degenerate : Bool) -> Unit {
  guard self.equips.get_weapon() is Some(weapon) else { return }
  let attacktype = weapon.get_attack()
  if attacktype == 9 && not(degenerate) {
    self.set_stance(@types.StanceId::SHOT)
    self.set_action("handgun")
  } else {
    self.set_stance(self.getattackstance(attacktype, degenerate))
    self.st_frame.set(0)
    self.st_elapsed = 0
  }
  // TODO: weapon sound
  // weapon.get_usesound(degenerate).play()
}

///|
pub fn attack_by_stance(self : CharLook, newstance : @types.StanceId) -> Unit {
  if not(self.action.is_empty()) || newstance == @types.StanceId::NONE {
    return
  }
  match newstance {
    @types.StanceId::SHOT => self.set_action("handgun")
    _ => self.set_stance(newstance)
  }
}

///|
pub fn set_action(self : CharLook, acstr : String) -> Unit {
  if acstr == self.actionstr || acstr.is_empty() {
    return
  }
  let ac_stance = @types.StanceId::by_string(acstr)
  if ac_stance != NONE {
    self.set_stance(ac_stance)
  } else {
    self.action = self.draw_info.get_action(acstr, 0)
    match self.action {
      Some(action) => {
        self.actframe = 0
        self.st_elapsed = 0
        self.actionstr = acstr
        self.set_stance(action.get_stance())
        self.st_frame.set(action.get_frame())
      }
      None => ()
    }
  }
}

///|
fn getattackstance(
  self : CharLook,
  attack : Int,
  degenerate : Bool
) -> @types.StanceId {
  if self.stance.get() == @types.StanceId::PRONE {
    return @types.StanceId::PRONESTAB
  }
  if attack <= 0 || attack >= degen_stances.length() {
    return @types.StanceId::STAND1
  }
  let stances = if degenerate {
    degen_stances[attack]
  } else {
    attack_stances[attack]
  }
  if stances.length() == 0 {
    return @types.StanceId::STAND1
  }
  let index = self.randomizer.next_int(stances.length())
  return stances[index]
}

// let attack_S1A1M1D = 1
// let attack_SPEAR = 2
// let attack_BOW = 3
// let attack_CROSSBOW = 4
// let attack_S2A2M2 = 5
// let attack_WAND = 6
// let attack_CLAW = 7
// let attack_GUN = 9

///|
let degen_stances : FixedArray[FixedArray[@types.StanceId]] = [
  [@types.StanceId::NONE],
  [@types.StanceId::NONE],
  [@types.StanceId::NONE],
  [@types.StanceId::SWINGT1, @types.StanceId::SWINGT3],
  [@types.StanceId::SWINGT1, @types.StanceId::STABT1],
  [@types.StanceId::NONE],
  [@types.StanceId::NONE],
  [@types.StanceId::SWINGT1, @types.StanceId::STABT1],
  [@types.StanceId::NONE],
  [@types.StanceId::SWINGP1, @types.StanceId::STABT2],
]

///|
let attack_stances : FixedArray[FixedArray[@types.StanceId]] = [
  [@types.StanceId::NONE],
  [
    @types.StanceId::STABO1,
    @types.StanceId::STABO2,
    @types.StanceId::SWINGO1,
    @types.StanceId::SWINGO2,
    @types.StanceId::SWINGO3,
  ],
  [@types.StanceId::STABT1, @types.StanceId::SWINGP1],
  [@types.StanceId::SHOOT1],
  [@types.StanceId::SHOOT2],
  [
    @types.StanceId::STABO1,
    @types.StanceId::STABO2,
    @types.StanceId::SWINGT1,
    @types.StanceId::SWINGT2,
    @types.StanceId::SWINGT3,
  ],
  [@types.StanceId::SWINGO1, @types.StanceId::SWINGO2],
  [@types.StanceId::SWINGO1, @types.StanceId::SWINGO2],
  [@types.StanceId::NONE],
  [@types.StanceId::SHOT],
]

///|
pub fn set_alerted(self : CharLook, millis : Int) -> Unit {
  self.alerted.set_for(millis)
}

///|
pub fn get_frame(self : CharLook) -> Int {
  self.st_frame.get()
}

///|
pub fn get_alerted(self : CharLook) -> Bool {
  self.alerted.get()
}

///|
pub impl ToJson for CharLook with to_json(_) -> Json {
  {} // TODO
}

///|
pub fn get_face(self : CharLook) -> Face {
  self.face
}

///|
pub fn get_hair(self : CharLook) -> Hair {
  self.hair
}

///|
pub fn get_body(self : CharLook) -> Body {
  self.body
}
