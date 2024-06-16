struct CharLook {
  mut stance : Nominal[@Stance.Id]
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
}
// mut action : BodyAction?
// mut equips : CharEquips
// mut randomizer : Randomizer
// mut alerted : TimedBool

let draw_info : BodyDrawInfo = BodyDrawInfo::new()

let hairstyles : Map[Int, Hair] = Map::new()

let face_types : Map[Int, Face] = Map::new()

let bodytypes : Map[Int, Body] = Map::new()

pub fn CharLook::new(
// entry : LookEntry
) -> CharLook {
  {
    stance: Nominal::default(),
    st_frame: Nominal::default(),
    st_elapsed: 0,
    expression: Nominal::default(),
    exp_frame: Nominal::default(),
    exp_elapsed: 0,
    flip: false,
    // action: None,
    actionstr: "",
    actframe: 0,
    body: None,
    hair: None,
    face: None,
    // equips: CharEquips::new(),
    // randomizer: Randomizer::new(),
    // alerted: TimedBool::new(),
  }
}

pub fn CharLook::default() -> CharLook {
  // LookEntry::default()
  CharLook::new()
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

// pub fn draw(self : CharLook, args : DrawArgument, alpha : Double) -> Unit {
//   // Implementation of draw method
// }

// pub fn draw(
//   self : CharLook,
//   pos : Point[Int],
//   flip : Bool,
//   stance : @Stance.Id,
//   expression : ExpressionId
// ) -> Unit {
//   // Implementation of draw method
// }

fn updatetwohanded(self : CharLook) -> Unit {
  // Implementation of updatetwohanded method
}

fn draw_impl(
  self : CharLook,
  args : DrawArgument,
  interstance : @Stance.Id,
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
  if interstance == @Stance.Id::DEAD {
    let faceshift = draw_info.get_face_pos(@Stance.Id::STAND1, 1)
    let faceargs = args + DrawArgument::new9(faceshift, false, Point::default())
    hair.draw(interstance, HairLayer::BELOW_BODY, interframe, args)
    // self.equips.draw(EquipSlotId::HAT, interstance, ClothingLayer::CAP_BELOW_BODY, interframe, args)
    body.draw(interstance, BodyLayer::BODY, interframe, args)
    hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    body.draw(@Stance.Id::STAND1, BodyLayer::HEAD, 1, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    hair.draw(interstance, HairLayer::DEFAULT, interframe, args)
    body.draw(interstance, BodyLayer::HEAD, interframe, args)
    hair.draw(interstance, HairLayer::SHADE, interframe, args)
    face.draw(interexpression, interexpframe, faceargs)

    // match self.equips.getcaptype() {
    //   CharEquipsCapType::NONE => hair.draw(interstance, HairLayer::OVER_HEAD, interframe, args)
    //   CharEquipsCapType::HEADBAND => {
    //     self.equips.draw(EquipSlotId::HAT, @Stance.Id::STAND1, ClothingLayer::CAP, 1, args)
    //     hair.draw(@Stance.Id::STAND1, HairLayer::DEFAULT, 1, args)
    //     hair.draw(@Stance.Id::STAND1, HairLayer::OVER_HEAD, 1, args)
    //     self.equips.draw(EquipSlotId::HAT, @Stance.Id::STAND1, ClothingLayer::CAP_OVER_HAIR, 1, args)
    //   }
    //   CharEquipsCapType::HALF_COVER => {
    //     hair.draw(@Stance.Id::STAND1, HairLayer::DEFAULT, 1, args)
    //     self.equips.draw(EquipSlotId::HAT, @Stance.Id::STAND1, ClothingLayer::CAP, 1, args)
    //   }
    //   CharEquipsCapType::FULL_COVER => self.equips.draw(EquipSlotId::HAT, @Stance.Id::STAND1, ClothingLayer::CAP, 1, args)
    // }

    return
  }
  if @Stance.is_climbing(interstance) {
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

pub fn is_twohanded(self : CharLook, st : @Stance.Id) -> Bool {
  match st {
    @Stance.Id::STAND1 | @Stance.Id::WALK1 => false
    @Stance.Id::STAND2 | @Stance.Id::WALK2 => true
    // _ => self.equips.is_twohanded()
    _ => false
  }
}
