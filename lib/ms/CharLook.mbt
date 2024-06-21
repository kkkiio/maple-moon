struct CharLook {
  mut stance : Nominal[StanceId]
  mut st_frame : Nominal[Int]
  mut st_elapsed : Int
  mut expression : Nominal[ExpressionId]
  mut exp_frame : Nominal[Int]
  mut exp_elapsed : Int
  mut flip : Bool
  mut actionstr : String
  mut actframe : Int
  mut body : Body?
  mut hair : Hair?
  mut face : Face?
  mut action : BodyAction?
}
// mut equips : CharEquips
// mut randomizer : Randomizer
// mut alerted : TimedBool

let draw_info : BodyDrawInfo = BodyDrawInfo::new()

let hair_styles : Map[Int, Hair] = Map::new()

let face_types : Map[Int, Face] = Map::new()

let body_types : Map[Int, Body] = Map::new()

pub fn CharLook::new(entry : LookEntry) -> CharLook {
  let l = CharLook::default()
  l.set_body(entry.skin)
  l.set_hair(entry.hairid)
  l.set_face(entry.faceid)
  // self.add_equip(Clothing::TOP_DEFAULT_ID)
  // self.add_equip(Clothing::BOTTOM_DEFAULT_ID)

  // entry.equips.iter().for_each(fn(equip) {
  //     self.add_equip(equip.second);
  // })
  l
}

pub fn CharLook::default() -> CharLook {
  // LookEntry::default()
  let l = {
    stance: Nominal::default(),
    st_frame: Nominal::default(),
    st_elapsed: 0,
    expression: Nominal::default(),
    exp_frame: Nominal::default(),
    exp_elapsed: 0,
    flip: false,
    action: None,
    actionstr: "",
    actframe: 0,
    body: None,
    hair: None,
    face: None,
    // equips: CharEquips::new(),
    // randomizer: Randomizer::new(),
    // alerted: TimedBool::new(),
  }
  l.reset()
  l
}

pub fn reset(self : CharLook) -> Unit {
  self.stance = Nominal::default()
  self.st_frame = Nominal::default()
  self.st_elapsed = 0
  self.expression = Nominal::default()
  self.exp_frame = Nominal::default()
  self.exp_elapsed = 0
  self.flip = false
  // self.action = None
  self.actionstr = ""
  self.actframe = 0
  self.body = None
  self.hair = None
  self.face = None
  // self.equips = CharEquips::new()
  // self.randomizer = Randomizer::new()
  // self.alerted = TimedBool::new()
}

fn updatetwohanded(self : CharLook) -> Unit {
  // Implementation of updatetwohanded method
}

fn draw_impl(
  self : CharLook,
  args : DrawArgument,
  interstance : StanceId,
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
  let faceshift : Point[Int] = draw_info.get_face_pos(interstance, interframe)
  let faceargs : DrawArgument = args + DrawArgument::new9(
      faceshift,
      false,
      Point::default(),
    )
  if interstance == StanceId::DEAD {
    let faceshift = draw_info.get_face_pos(StanceId::STAND1, 1)
    let faceargs = args + DrawArgument::new9(faceshift, false, Point::default())
    hair.draw(interstance, HairLayer::BELOW_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP_BELOW_BODY, interframe, args)
    body.draw(interstance, BodyLayer::BODY, interframe, args)
    hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    body.draw(StanceId::STAND1, BodyLayer::HEAD, 1, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    body.draw(interstance, BodyLayer::HEAD, interframe, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    face.draw(interexpression, interexpframe, faceargs)

    // match self.equips.getcaptype() {
    //   CharEquipsCapType::NONE => hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
    //   CharEquipsCapType::HEADBAND => {
    //     self.equips.draw(EquipSlotId::HAT, StanceId::STAND1, ClothingLayer::CAP, 1, args)
    //     hair.draw(StanceId::STAND1, HairLayer::DEFAULT, 1, args)
    //     hair.draw(StanceId::STAND1, HairLayer::OVER_HEAD, 1, args)
    //     self.equips.draw(EquipSlotId::HAT, StanceId::STAND1, ClothingLayer::CAP_OVER_HAIR, 1, args)
    //   }
    //   CharEquipsCapType::HALF_COVER => {
    //     hair.draw(StanceId::STAND1, HairLayer::DEFAULT, 1, args)
    //     self.equips.draw(EquipSlotId::HAT, StanceId::STAND1, ClothingLayer::CAP, 1, args)
    //   }
    //   CharEquipsCapType::FULL_COVER => self.equips.draw(EquipSlotId::HAT, StanceId::STAND1, ClothingLayer::CAP, 1, args)
    // }

    return
  }
  if StanceId::is_climbing(interstance) {
    body.draw(interstance, BodyLayer::BODY, interframe, args)
    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::GLOVE, interframe, args)
    // self.equips.draw(EquipSlotId::SHOES, interstance, ClothingLayer::SHOES, interframe, args)
    // self.equips.draw(EquipSlotId::BOTTOM_DEFAULT, interstance, ClothingLayer::PANTS_DEFAULT, interframe, args)
    // self.equips.draw(EquipSlotId::BOTTOM, interstance, ClothingLayer::PANTS, interframe, args)
    // self.equips.draw(EquipSlotId::TOP_DEFAULT, interstance, ClothingLayer::TOP_DEFAULT, interframe, args)
    // self.equips.draw(EquipSlotId::TOP, interstance, ClothingLayer::TOP, interframe, args)
    // self.equips.draw(EquipSlotId::TOP, interstance, ClothingLayer::MAIL, interframe, args)
    // self.equips.draw(EquipSlotId::CAPE, interstance, ClothingLayer::CAPE, interframe, args)
    body.draw(interstance, BodyLayer::HEAD, interframe, args)
    // self.equips.draw(EquipSlotId::EARACC, interstance, ClothingLayer::EARRINGS, interframe, args)

    // match self.equips.getcaptype() {
    //   CharEquipsCapType::NONE => hair.draw(interstance, HairLayer::BACK, interframe, args)
    //   CharEquipsCapType::HEADBAND => {
    //     self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP, interframe, args)
    //     hair.draw(interstance, HairLayer::BACK, interframe, args)
    //   }
    //   CharEquipsCapType::HALF_COVER => {
    //     hair.draw(interstance, HairLayer::BELOW_CAP, interframe, args)
    //     self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP, interframe, args)
    //   }
    //   CharEquipsCapType::FULL_COVER => self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP, interframe, args)
    // }

    // self.equips.draw(EquipSlotId::SHIELD, interstance, ClothingLayer::BACK_SHIELD, interframe, args)
    // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::BACK_WEAPON, interframe, args)
  } else {
    hair.draw(interstance, HairLayer::BELOW_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::CAPE, interstance, ClothingLayer::CAPE, interframe, args)
    // self.equips.draw(EquipSlotId::SHIELD, interstance, ClothingLayer::SHIELD_BELOW_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON_BELOW_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP_BELOW_BODY, interframe, args)
    body.draw(interstance, BodyLayer::BODY, interframe, args)
    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::WRIST_OVER_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::GLOVE_OVER_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::SHOES, interstance, ClothingLayer::SHOES, interframe, args)
    body.draw(interstance, BodyLayer::ARM_BELOW_HEAD, interframe, args)

    // if self.equips.has_overall() {
    //   self.equips.draw(EquipSlotId::TOP, interstance, ClothingLayer::MAIL, interframe, args)
    // } else {
    //   self.equips.draw(EquipSlotId::BOTTOM_DEFAULT, interstance, ClothingLayer::PANTS_DEFAULT, interframe, args)
    //   self.equips.draw(EquipSlotId::BOTTOM, interstance, ClothingLayer::PANTS, interframe, args)
    //   self.equips.draw(EquipSlotId::TOP_DEFAULT, interstance, ClothingLayer::TOP_DEFAULT, interframe, args)
    //   self.equips.draw(EquipSlotId::TOP, interstance, ClothingLayer::TOP, interframe, args)
    // }

    body.draw(
      interstance,
      BodyLayer::ARM_BELOW_HEAD_OVER_MAIL,
      interframe,
      args,
    )
    hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    // self.equips.draw(EquipSlotId::SHIELD, interstance, ClothingLayer::SHIELD_OVER_HAIR, interframe, args)
    // self.equips.draw(EquipSlotId::EARACC, interstance, ClothingLayer::EARRINGS, interframe, args)
    body.draw(interstance, BodyLayer::HEAD, interframe, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    face.draw(interexpression, interexpframe, faceargs)
    // self.equips.draw(EquipSlotId::FACE, interstance, ClothingLayer::FACE_ACC, 0, faceargs)
    // self.equips.draw(EquipSlotId::EYE_ACC, interstance, ClothingLayer::EYE_ACC, interframe, args)
    // self.equips.draw(EquipSlotId::SHIELD, interstance, ClothingLayer::SHIELD, interframe, args)

    // match self.equips.getcaptype() {
    //   CharEquipsCapType::NONE => hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
    //   CharEquipsCapType::HEADBAND => {
    //     self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP, interframe, args)
    //     hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    //     hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
    //     self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP_OVER_HAIR, interframe, args)
    //   }
    //   CharEquipsCapType::HALF_COVER => {
    //     hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    //     self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP, interframe, args)
    //   }
    //   CharEquipsCapType::FULL_COVER => self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP, interframe, args)
    // }

    // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON_BELOW_ARM, interframe, args)
    let twohanded : Bool = self.is_twohanded(interstance)
    if twohanded {
      // self.equips.draw(EquipSlotId::TOP, interstance, ClothingLayer::MAILARM, interframe, args)
      body.draw(interstance, BodyLayer::ARM, interframe, args)
      // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON, interframe, args)
    } else {
      // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON, interframe, args)
      body.draw(interstance, BodyLayer::ARM, interframe, args)
      // self.equips.draw(EquipSlotId::TOP, interstance, ClothingLayer::MAILARM, interframe, args)
    }

    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::WRIST, interframe, args)
    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::GLOVE, interframe, args)
    // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON_OVER_GLOVE, interframe, args)

    body.draw(interstance, BodyLayer::HAND_BELOW_WEAPON, interframe, args)
    body.draw(interstance, BodyLayer::ARM_OVER_HAIR, interframe, args)
    body.draw(
      interstance,
      BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON,
      interframe,
      args,
    )
    // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON_OVER_HAND, interframe, args)
    // self.equips.draw(EquipSlotId::WEAPON, interstance, ClothingLayer::WEAPON_OVER_BODY, interframe, args)
    body.draw(interstance, BodyLayer::HAND_OVER_HAIR, interframe, args)
    body.draw(interstance, BodyLayer::HAND_OVER_WEAPON, interframe, args)

    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::WRIST_OVER_HAIR, interframe, args)
    // self.equips.draw(EquipSlotId::GLOVES, interstance, ClothingLayer::GLOVE_OVER_HAIR, interframe, args)
  }
}

pub fn draw(self : CharLook, args : DrawArgument, alpha : Double) -> Unit {
  let acmove = Point::default()
  let relargs = DrawArgument::new5(acmove, self.flip)
  let interstance = self.stance.get(alpha)
  let interexpression = self.expression.get(alpha)
  let interframe = self.st_frame.get(alpha)
  let interexpframe = self.exp_frame.get(alpha)
  draw_impl(
    self,
    relargs + args,
    interstance,
    interexpression,
    interframe,
    interexpframe,
  )
}

pub fn is_twohanded(self : CharLook, st : StanceId) -> Bool {
  match st {
    StanceId::STAND1 | StanceId::WALK1 => false
    StanceId::STAND2 | StanceId::WALK2 => true
    // _ => self.equips.is_twohanded()
    _ => false
  }
}

pub fn set_direction(self : CharLook, f : Bool) -> Unit {
  self.flip = f
}

pub fn set_stance(self : CharLook, st : StanceId) -> Unit {
  if self.action.is_empty().not() || st == StanceId::NONE {
    return
  }
  // let adjstance = self.equips.adjust_stance(st)
  let adjstance = st
  if self.stance.now != adjstance {
    self.stance.set(adjstance)
    self.st_frame.set(0)
    self.st_elapsed = 0
  }
}

fn set_body(self : CharLook, skin_id : Int) -> Unit {
  self.body = body_types[skin_id].or_else(
      fn() {
        let body = Body::new(skin_id, draw_info)
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
      let delay : Int = self.get_delay(self.stance.now, self.st_frame.now)
      let delta : Int = delay - self.st_elapsed
      if timestep >= delta {
        self.st_elapsed = timestep - delta
        let nextframe : Int = self.getnextframe(
          self.stance.now,
          self.st_frame.now,
        )
        let threshold : Double = delta.to_double() / timestep.to_double()
        self.st_frame.next(nextframe, threshold)
        if self.st_frame.now == 0 {
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
          self.set_stance(StanceId::STAND1)
        }
      } else {
        self.stance.normalize()
        self.st_frame.normalize()
        self.st_elapsed += timestep
      }
    }
  }
  let expdelay : Int = self.face.unwrap().get_delay(
    self.expression.now,
    self.exp_frame.now,
  )
  let expdelta : Int = expdelay - self.exp_elapsed
  if timestep >= expdelta {
    self.exp_elapsed = timestep - expdelta
    let nextexpframe : Int = self.face.unwrap().nextframe(
      self.expression.now,
      self.exp_frame.now,
    )
    let fcthreshold : Double = expdelta.to_double() / timestep.to_double()
    self.exp_frame.next(nextexpframe, fcthreshold)
    if self.exp_frame.now == 0 {
      if self.expression.now == ExpressionId::DEFAULT {
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

pub fn get_delay(self : CharLook, st : StanceId, fr : Int) -> Int {
  draw_info.get_delay(st, fr)
}

pub fn getnextframe(self : CharLook, st : StanceId, fr : Int) -> Int {
  draw_info.next_frame(st, fr)
}
