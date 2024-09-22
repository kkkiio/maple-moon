pub struct Physics {
  mut fh_tree : FootholdTree
}

pub let gravforce : Double = 0.14

pub let swimgravforce : Double = 0.03

pub let friction : Double = 0.3

pub let slopefactor : Double = 0.1

pub let groundslip : Double = 3.0

pub let flyfriction : Double = 0.05

pub let swimfriction : Double = 0.08

pub fn Physics::from_resource(src : @resource.NxNode) -> Physics {
  let fh_tree = FootholdTree::from_resource(src)
  { fh_tree, }
}

pub fn Physics::new() -> Physics {
  { fh_tree: FootholdTree::default() }
}

pub fn move_object(self : Physics, tomove : PhysicsObject) -> Unit {
  // Determine which platform the object is currently on
  self.fh_tree.update_fh(tomove)

  // Use the appropriate physics for the terrain the object is on
  match tomove.t {
    PhysicsObjectType::NORMAL => {
      self.move_normal(tomove)
      self.fh_tree.limit_movement(tomove)
    }
    PhysicsObjectType::FLYING => {
      self.move_flying(tomove)
      self.fh_tree.limit_movement(tomove)
    }
    PhysicsObjectType::SWIMMING => {
      self.move_swimming(tomove)
      self.fh_tree.limit_movement(tomove)
    }
    _ => ()
  }

  // Move the object forward
  tomove.moving_object.move()
}

fn move_normal(self : Physics, phobj : PhysicsObject) -> Unit {
  phobj.vacc = 0.0
  phobj.hacc = 0.0
  if phobj.onground {
    phobj.vacc += phobj.vforce
    phobj.hacc += phobj.hforce
    if phobj.hacc == 0.0 &&
      phobj.moving_object.hspeed < 0.1 &&
      phobj.moving_object.hspeed > -0.1 {
      phobj.moving_object.hspeed = 0.0
    } else {
      let inertia = phobj.moving_object.hspeed / groundslip
      let mut slopef = phobj.fhslope
      if slopef > 0.5 {
        slopef = 0.5
      } else if slopef < -0.5 {
        slopef = -0.5
      }
      phobj.hacc -= (friction + slopefactor * (1.0 + slopef * -inertia)) *
        inertia
    }
  } else if phobj.is_flag_not_set(PhysicsObjectFlag::NO_GRAVITY) {
    phobj.vacc += gravforce
  }
  phobj.hforce = 0.0
  phobj.vforce = 0.0
  phobj.moving_object.hspeed += phobj.hacc
  phobj.moving_object.vspeed += phobj.vacc
}

fn move_flying(self : Physics, phobj : PhysicsObject) -> Unit {
  phobj.hacc = phobj.hforce
  phobj.vacc = phobj.vforce
  phobj.hforce = 0.0
  phobj.vforce = 0.0
  phobj.hacc -= flyfriction * phobj.moving_object.hspeed
  phobj.vacc -= flyfriction * phobj.moving_object.vspeed
  phobj.moving_object.hspeed += phobj.hacc
  phobj.moving_object.vspeed += phobj.vacc
  if phobj.hacc == 0.0 &&
    phobj.moving_object.hspeed < 0.1 &&
    phobj.moving_object.hspeed > -0.1 {
    phobj.moving_object.hspeed = 0.0
  }
  if phobj.vacc == 0.0 &&
    phobj.moving_object.vspeed < 0.1 &&
    phobj.moving_object.vspeed > -0.1 {
    phobj.moving_object.vspeed = 0.0
  }
}

fn move_swimming(self : Physics, phobj : PhysicsObject) -> Unit {
  phobj.hacc = phobj.hforce
  phobj.vacc = phobj.vforce
  phobj.hforce = 0.0
  phobj.vforce = 0.0
  phobj.hacc -= swimfriction * phobj.moving_object.hspeed
  phobj.vacc -= swimfriction * phobj.moving_object.vspeed
  if phobj.is_flag_not_set(PhysicsObjectFlag::NO_GRAVITY) {
    phobj.vacc += swimgravforce
  }
  phobj.moving_object.hspeed += phobj.hacc
  phobj.moving_object.vspeed += phobj.vacc
  if phobj.hacc == 0.0 &&
    phobj.moving_object.hspeed < 0.1 &&
    phobj.moving_object.hspeed > -0.1 {
    phobj.moving_object.hspeed = 0.0
  }
  if phobj.vacc == 0.0 &&
    phobj.moving_object.vspeed < 0.1 &&
    phobj.moving_object.vspeed > -0.1 {
    phobj.moving_object.vspeed = 0.0
  }
}

pub fn get_y_below(self : Physics, position : Point[Int]) -> Point[Int] {
  let ground = self.fh_tree.get_y_below(position)
  { x: position.x, y: ground - 1 }
}

pub fn get_fht(self : Physics) -> FootholdTree {
  self.fh_tree
}
