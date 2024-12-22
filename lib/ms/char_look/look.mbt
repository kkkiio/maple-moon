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
  mut body : @utils.Future[Body]
  mut hair : @utils.Future[Hair]
  mut face : @utils.Future[Face]
  mut action : @types.BodyAction?
  equips : @equip.CharEquips
  randomizer : @utils.Randomizer
  alerted : @utils.TimedBool
  draw_info : @types.BodyDrawInfo
  char_look_module : Module
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
}

///|
fn CharLook::new(entry : LookEntry, char_look_module : Module) -> CharLook {
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
    body: char_look_module.load_body_by_skin_id(entry.skin),
    hair: char_look_module.load_hair_by_id(entry.hairid),
    face: char_look_module.load_face_by_id(entry.faceid),
    equips: @equip.CharEquips::new(),
    randomizer: @utils.Randomizer::default(),
    alerted: @utils.TimedBool::default(),
    draw_info: char_look_module.get_body_draw_info(),
    char_look_module,
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
fn draw_impl(
  self : CharLook,
  args : @graphics.DrawArgument,
  interstance : @types.StanceId,
  interexpression : ExpressionId,
  interframe : Int,
  interexpframe : Int
) -> Unit {
  guard let Some(body) = self.body.poll() else { None => return }
  let hair = self.hair
  let face = self.face
  let faceshift : @struct.Point[Int] = self.draw_info.get_face_pos(
    interstance, interframe,
  )
  let faceargs : @graphics.DrawArgument = args +
    @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default())
  let draw_interframe_hair = fn(layer) {
    guard let Some(hair) = hair.poll() else { None => return }
    hair.draw(interstance, layer, interframe, args)
  }
  let draw_hair = fn(stance, layer, frame) {
    guard let Some(hair) = hair.poll() else { None => return }
    hair.draw(stance, layer, frame, args)
  }
  if interstance == @types.StanceId::DEAD {
    let faceshift = self.draw_info.get_face_pos(@types.StanceId::STAND1, 1)
    let faceargs = args +
      @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default())
    let draw_face = fn(expression, frame) {
      guard let Some(face) = face.poll() else { None => return }
      face.draw(expression, frame, faceargs)
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
  let draw_face = fn(expression, frame) {
    guard let Some(face) = face.poll() else { None => return }
    face.draw(expression, frame, faceargs)
  }
  if @types.StanceId::is_climbing(interstance) {
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
  } else {
    draw_interframe_hair(HairLayer::BELOW_BODY)
    self.equips.draw(
      @slot.Id::CAPE,
      interstance,
      @clothing.Layer::CAPE,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::SHIELD,
      interstance,
      @clothing.Layer::SHIELD_BELOW_BODY,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::WEAPON,
      interstance,
      @clothing.Layer::WEAPON_BELOW_BODY,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::HAT,
      interstance,
      @clothing.Layer::CAP_BELOW_BODY,
      interframe,
      args,
    )
    body.draw(interstance, @types.BodyLayer::BODY, interframe, args)
    self.equips.draw(
      @slot.Id::GLOVES,
      interstance,
      @clothing.Layer::WRIST_OVER_BODY,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::GLOVES,
      interstance,
      @clothing.Layer::GLOVE_OVER_BODY,
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
    body.draw(interstance, @types.BodyLayer::ARM_BELOW_HEAD, interframe, args)
    if self.equips.has_overall() {
      self.equips.draw(
        @slot.Id::TOP,
        interstance,
        @clothing.Layer::MAIL,
        interframe,
        args,
      )
    } else {
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
    }
    body.draw(
      interstance,
      @types.BodyLayer::ARM_BELOW_HEAD_OVER_MAIL,
      interframe,
      args,
    )
    draw_interframe_hair(HairLayer::HAIR_LAYER_DEFAULT)
    self.equips.draw(
      @slot.Id::SHIELD,
      interstance,
      @clothing.Layer::SHIELD_OVER_HAIR,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::EARACC,
      interstance,
      @clothing.Layer::EARRINGS,
      interframe,
      args,
    )
    body.draw(interstance, @types.BodyLayer::HEAD, interframe, args)
    draw_interframe_hair(HairLayer::SHADE)
    draw_face(interexpression, interexpframe)
    self.equips.draw(
      @slot.Id::FACE,
      interstance,
      @clothing.Layer::FACE_ACC,
      0,
      faceargs,
    )
    self.equips.draw(
      @slot.Id::EYE_ACC,
      interstance,
      @clothing.Layer::EYE_ACC,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::SHIELD,
      interstance,
      @clothing.Layer::SHIELD,
      interframe,
      args,
    )
    match self.equips.getcaptype() {
      @equip.CapType::NONE =>
        draw_hair(interstance, HairLayer::OVER_HEAD, interframe)
      @equip.CapType::HEADBAND => {
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP,
          interframe,
          args,
        )
        draw_hair(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe)
        draw_hair(interstance, HairLayer::OVER_HEAD, interframe)
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP_OVER_HAIR,
          interframe,
          args,
        )
      }
      @equip.CapType::HALF_COVER => {
        draw_hair(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe)
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
      @slot.Id::WEAPON,
      interstance,
      @clothing.Layer::WEAPON_BELOW_ARM,
      interframe,
      args,
    )
    let twohanded : Bool = self.is_twohanded(interstance)
    if twohanded {
      self.equips.draw(
        @slot.Id::TOP,
        interstance,
        @clothing.Layer::MAILARM,
        interframe,
        args,
      )
      body.draw(interstance, @types.BodyLayer::ARM, interframe, args)
      self.equips.draw(
        @slot.Id::WEAPON,
        interstance,
        @clothing.Layer::WEAPON,
        interframe,
        args,
      )
    } else {
      self.equips.draw(
        @slot.Id::WEAPON,
        interstance,
        @clothing.Layer::WEAPON,
        interframe,
        args,
      )
      body.draw(interstance, @types.BodyLayer::ARM, interframe, args)
      self.equips.draw(
        @slot.Id::TOP,
        interstance,
        @clothing.Layer::MAILARM,
        interframe,
        args,
      )
    }
    self.equips.draw(
      @slot.Id::GLOVES,
      interstance,
      @clothing.Layer::WRIST,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::GLOVES,
      interstance,
      @clothing.Layer::GLOVE,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::WEAPON,
      interstance,
      @clothing.Layer::WEAPON_OVER_GLOVE,
      interframe,
      args,
    )
    body.draw(
      interstance,
      @types.BodyLayer::HAND_BELOW_WEAPON,
      interframe,
      args,
    )
    body.draw(interstance, @types.BodyLayer::ARM_OVER_HAIR, interframe, args)
    body.draw(
      interstance,
      @types.BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::WEAPON,
      interstance,
      @clothing.Layer::WEAPON_OVER_HAND,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::WEAPON,
      interstance,
      @clothing.Layer::WEAPON_OVER_BODY,
      interframe,
      args,
    )
    body.draw(interstance, @types.BodyLayer::HAND_OVER_HAIR, interframe, args)
    body.draw(interstance, @types.BodyLayer::HAND_OVER_WEAPON, interframe, args)
    self.equips.draw(
      @slot.Id::GLOVES,
      interstance,
      @clothing.Layer::WRIST_OVER_HAIR,
      interframe,
      args,
    )
    self.equips.draw(
      @slot.Id::GLOVES,
      interstance,
      @clothing.Layer::GLOVE_OVER_HAIR,
      interframe,
      args,
    )
  }
}

///|
pub fn draw(
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
  draw_impl(
    self,
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
    @graphics.DrawArgument::new(position, flip~),
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

///|
pub fn set_direction(self : CharLook, f : Bool) -> Unit {
  self.flip = f
}

///|
pub fn set_stance(self : CharLook, st : @types.StanceId) -> Unit {
  if self.action.is_empty().not() || st == @types.StanceId::NONE {
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
fn set_body(self : CharLook, skin_id : Int) -> Unit {
  self.body = self.char_look_module.load_body_by_skin_id(skin_id)
}

///|
fn set_hair(self : CharLook, hair_id : Int) -> Unit {
  self.hair = self.char_look_module.load_hair_by_id(hair_id)
}

///|
fn set_face(self : CharLook, face_id : Int) -> Unit {
  self.face = self.char_look_module.load_face_by_id(face_id)
}

///|
pub fn update(self : CharLook, timestep : Int) -> Bool {
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
  update_face(self, timestep)
  aniend
}

///|
fn update_face(self : CharLook, timestep : Int) -> Unit {
  guard let Some(face) = self.face.poll() else { None => return }
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
pub fn get_delay(self : CharLook, st : @types.StanceId, fr : Int) -> Int {
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
  guard let Some(weapon) = self.equips.get_weapon() else { None => return }
  let attacktype = weapon.get_attack()
  if attacktype == 9 && degenerate.not() {
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
  if self.action.is_empty().not() || newstance == @types.StanceId::NONE {
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
