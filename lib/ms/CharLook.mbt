struct CharLook {
  mut stance : @utils.Nominal[@char_look.StanceId]
  mut st_frame : @utils.Nominal[Int]
  mut st_elapsed : Int
  mut expression : @utils.Nominal[ExpressionId]
  mut exp_frame : @utils.Nominal[Int]
  mut exp_elapsed : Int
  mut flip : Bool
  mut actionstr : String
  mut actframe : Int
  mut body : @char_look.Body?
  mut hair : Hair?
  mut face : Face?
  mut action : @char_look.BodyAction?
  mut equips : CharEquips
}
// mut randomizer : Randomizer
// mut alerted : TimedBool

let draw_info : @char_look.BodyDrawInfo = @char_look.BodyDrawInfo::new()

let hair_styles : Map[Int, Hair] = Map::new()

let face_types : Map[Int, Face] = Map::new()

let body_types : Map[Int, @char_look.Body] = Map::new()

pub fn CharLook::new(entry : @login.LookEntry) -> CharLook! {
  let l = CharLook::default()
  l.set_body(entry.skin)
  l.set_hair(entry.hairid)
  l.set_face(entry.faceid)
  l.add_equip!(@clothing.top_default_id)
  l.add_equip!(@clothing.bottom_default_id)
  for _, itemid in entry.equips {
    l.add_equip!(itemid)
  }
  l
}

pub fn CharLook::default() -> CharLook {
  // LookEntry::default()
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
    body: None,
    hair: None,
    face: None,
    equips: CharEquips::new(),
    // randomizer: Randomizer::new(),
    // alerted: TimedBool::new(),
  }
  l.reset()
  l
}

pub fn reset(self : CharLook) -> Unit {
  self.stance = @utils.Nominal::default()
  self.st_frame = @utils.Nominal::default()
  self.st_elapsed = 0
  self.expression = @utils.Nominal::default()
  self.exp_frame = @utils.Nominal::default()
  self.exp_elapsed = 0
  self.flip = false
  // self.action = None
  self.actionstr = ""
  self.actframe = 0
  self.body = None
  self.hair = None
  self.face = None
  self.equips = CharEquips::new()
  // self.randomizer = Randomizer::new()
  // self.alerted = TimedBool::new()
}

fn updatetwohanded(self : CharLook) -> Unit {
  let basestance = @char_look.StanceId::baseof(self.stance.get())
  self.set_stance(basestance)
}

fn draw_impl(
  self : CharLook,
  args : @graphics.DrawArgument,
  interstance : @char_look.StanceId,
  interexpression : ExpressionId,
  interframe : Int,
  interexpframe : Int
) -> Unit {
  let body = match self.body {
    Some(body) => body
    None => return
  }
  let hair = match self.hair {
    Some(hair) => hair
    None => return
  }
  let face = match self.face {
    Some(face) => face
    None => return
  }
  let faceshift : @struct.Point[Int] = draw_info.get_face_pos(
    interstance, interframe,
  )
  let faceargs : @graphics.DrawArgument = args +
    @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default())
  if interstance == @char_look.StanceId::DEAD {
    let faceshift = draw_info.get_face_pos(@char_look.StanceId::STAND1, 1)
    let faceargs = args +
      @graphics.DrawArgument::new9(faceshift, false, @struct.Point::default())
    hair.draw(interstance, HairLayer::BELOW_BODY, interframe, args)
    self.equips.draw(
      @slot.Id::HAT,
      interstance,
      @clothing.Layer::CAP_BELOW_BODY,
      interframe,
      args,
    )
    body.draw(interstance, @char_look.BodyLayer::BODY, interframe, args)
    hair.draw(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe, args)
    body.draw(@char_look.StanceId::STAND1, @char_look.BodyLayer::HEAD, 1, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    hair.draw(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe, args)
    body.draw(interstance, @char_look.BodyLayer::HEAD, interframe, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    face.draw(interexpression, interexpframe, faceargs)
    match self.equips.getcaptype() {
      CapType::NONE =>
        hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
      CapType::HEADBAND => {
        self.equips.draw(
          @slot.Id::HAT,
          @char_look.StanceId::STAND1,
          @clothing.Layer::CAP,
          1,
          args,
        )
        hair.draw(
          @char_look.StanceId::STAND1,
          HairLayer::HAIR_LAYER_DEFAULT,
          1,
          args,
        )
        hair.draw(@char_look.StanceId::STAND1, HairLayer::OVER_HEAD, 1, args)
        self.equips.draw(
          @slot.Id::HAT,
          @char_look.StanceId::STAND1,
          @clothing.Layer::CAP_OVER_HAIR,
          1,
          args,
        )
      }
      CapType::HALF_COVER => {
        hair.draw(
          @char_look.StanceId::STAND1,
          HairLayer::HAIR_LAYER_DEFAULT,
          1,
          args,
        )
        self.equips.draw(
          @slot.Id::HAT,
          @char_look.StanceId::STAND1,
          @clothing.Layer::CAP,
          1,
          args,
        )
      }
      CapType::FULL_COVER =>
        self.equips.draw(
          @slot.Id::HAT,
          @char_look.StanceId::STAND1,
          @clothing.Layer::CAP,
          1,
          args,
        )
      _ => ()
    }
    return
  }
  if @char_look.StanceId::is_climbing(interstance) {
    body.draw(interstance, @char_look.BodyLayer::BODY, interframe, args)
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
    body.draw(interstance, @char_look.BodyLayer::HEAD, interframe, args)
    self.equips.draw(
      @slot.Id::EARACC,
      interstance,
      @clothing.Layer::EARRINGS,
      interframe,
      args,
    )
    match self.equips.getcaptype() {
      CapType::NONE => hair.draw(interstance, HairLayer::BACK, interframe, args)
      CapType::HEADBAND => {
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP,
          interframe,
          args,
        )
        hair.draw(interstance, HairLayer::BACK, interframe, args)
      }
      CapType::HALF_COVER => {
        hair.draw(interstance, HairLayer::BELOW_CAP, interframe, args)
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP,
          interframe,
          args,
        )
      }
      CapType::FULL_COVER =>
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
    hair.draw(interstance, HairLayer::BELOW_BODY, interframe, args)
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
    body.draw(interstance, @char_look.BodyLayer::BODY, interframe, args)
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
    body.draw(
      interstance,
      @char_look.BodyLayer::ARM_BELOW_HEAD,
      interframe,
      args,
    )
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
      @char_look.BodyLayer::ARM_BELOW_HEAD_OVER_MAIL,
      interframe,
      args,
    )
    hair.draw(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe, args)
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
    body.draw(interstance, @char_look.BodyLayer::HEAD, interframe, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    face.draw(interexpression, interexpframe, faceargs)
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
      CapType::NONE =>
        hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
      CapType::HEADBAND => {
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP,
          interframe,
          args,
        )
        hair.draw(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe, args)
        hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP_OVER_HAIR,
          interframe,
          args,
        )
      }
      CapType::HALF_COVER => {
        hair.draw(interstance, HairLayer::HAIR_LAYER_DEFAULT, interframe, args)
        self.equips.draw(
          @slot.Id::HAT,
          interstance,
          @clothing.Layer::CAP,
          interframe,
          args,
        )
      }
      CapType::FULL_COVER =>
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
      body.draw(interstance, @char_look.BodyLayer::ARM, interframe, args)
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
      body.draw(interstance, @char_look.BodyLayer::ARM, interframe, args)
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
      @char_look.BodyLayer::HAND_BELOW_WEAPON,
      interframe,
      args,
    )
    body.draw(
      interstance,
      @char_look.BodyLayer::ARM_OVER_HAIR,
      interframe,
      args,
    )
    body.draw(
      interstance,
      @char_look.BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON,
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
    body.draw(
      interstance,
      @char_look.BodyLayer::HAND_OVER_HAIR,
      interframe,
      args,
    )
    body.draw(
      interstance,
      @char_look.BodyLayer::HAND_OVER_WEAPON,
      interframe,
      args,
    )
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

pub fn draw(
  self : CharLook,
  args : @graphics.DrawArgument,
  alpha : Double
) -> Unit {
  let acmove = @struct.Point::default()
  let relargs = @graphics.DrawArgument::new5(acmove, self.flip)
  let interstance = self.stance.get(~alpha)
  let interexpression = self.expression.get(~alpha)
  let interframe = self.st_frame.get(~alpha)
  let interexpframe = self.exp_frame.get(~alpha)
  draw_impl(
    self,
    relargs + args,
    interstance,
    interexpression,
    interframe,
    interexpframe,
  )
}

pub fn is_twohanded(self : CharLook, st : @char_look.StanceId) -> Bool {
  match st {
    @char_look.StanceId::STAND1 | @char_look.StanceId::WALK1 => false
    @char_look.StanceId::STAND2 | @char_look.StanceId::WALK2 => true
    _ => self.equips.is_twohanded()
  }
}

pub fn set_direction(self : CharLook, f : Bool) -> Unit {
  self.flip = f
}

pub fn set_stance(self : CharLook, st : @char_look.StanceId) -> Unit {
  if self.action.is_empty().not() || st == @char_look.StanceId::NONE {
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

fn set_body(self : CharLook, skin_id : Int) -> Unit {
  self.body = body_types[skin_id].or_else(
      fn() {
        let body = @char_look.Body::new(skin_id, draw_info)
        body_types[skin_id] = body
        body
      },
    )
    |> @option.some
}

fn set_hair(self : CharLook, hair_id : Int) -> Unit {
  self.hair = hair_styles[hair_id].or_else(
      fn() {
        let hair = Hair::new(hair_id, draw_info)
        hair_styles[hair_id] = hair
        hair
      },
    )
    |> @option.some
}

fn set_face(self : CharLook, face_id : Int) -> Unit {
  self.face = face_types[face_id].or_else(
      fn() {
        let face = Face::new(face_id)
        face_types[face_id] = face
        face
      },
    )
    |> @option.some
}

pub fn update(self : CharLook, timestep : Int) -> Bool {
  if timestep == 0 {
    self.stance.normalize()
    self.st_frame.normalize()
    self.expression.normalize()
    self.exp_frame.normalize()
    return false
  }
  // self.alerted.update()
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
        self.actframe = draw_info.next_action_frame(
          self.actionstr,
          self.actframe,
        )
        if self.actframe > 0 {
          self.action = draw_info.get_action(self.actionstr, self.actframe)
          let threshold : Double = delta.to_double() / timestep.to_double()
          self.stance.next(action.get_stance(), threshold)
          self.st_frame.next(action.get_frame(), threshold)
        } else {
          aniend = true
          self.action = None
          self.actionstr = ""
          self.set_stance(@char_look.StanceId::STAND1)
        }
      } else {
        self.stance.normalize()
        self.st_frame.normalize()
        self.st_elapsed += timestep
      }
    }
  }
  let expdelay : Int = self.face
    .unwrap()
    .get_delay(self.expression.get(), self.exp_frame.get())
  let expdelta : Int = expdelay - self.exp_elapsed
  if timestep >= expdelta {
    self.exp_elapsed = timestep - expdelta
    let nextexpframe : Int = self.face
      .unwrap()
      .nextframe(self.expression.get(), self.exp_frame.get())
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
  aniend
}

pub fn get_delay(self : CharLook, st : @char_look.StanceId, fr : Int) -> Int {
  draw_info.get_delay(st, fr)
}

pub fn getnextframe(self : CharLook, st : @char_look.StanceId, fr : Int) -> Int {
  draw_info.next_frame(st, fr)
}

pub fn get_equips(self : CharLook) -> CharEquips {
  self.equips
}

pub fn add_equip(self : CharLook, itemid : Int) -> Unit! {
  self.equips.add_equip!(itemid, draw_info)
  self.updatetwohanded()
}
