// The collection of platforms in a maple map
// Used for collision-detection
struct FootholdTree {
  mut footholds : @hashmap.HashMap[Int, Foothold]
  mut footholds_by_x : @hashmap.HashMap[Int, Array[Int]]
  mut null_fh : Foothold
  mut walls : Range[Int]
  mut borders : Range[Int]
}

pub fn FootholdTree::default() -> FootholdTree {
  {
    footholds: @hashmap.HashMap::new(),
    footholds_by_x: @hashmap.HashMap::new(),
    null_fh: Foothold::default(),
    walls: Range::default(),
    borders: Range::default(),
  }
}

pub fn FootholdTree::from_resource(src : NxNode) -> FootholdTree {
  let tree = FootholdTree::default()
  let mut leftw : Int = 30000
  let mut rightw : Int = -30000
  let mut botb : Int = -30000
  let mut topb : Int = 30000
  src.each(
    fn(basef) {
      let basefname = basef.name
      let layer = match @strconv.parse_int(basefname)!! {
        Ok(v) => v
        Err(err) => {
          let path = basef.path
          println("Invalid layer: \(err). node=\(path)")
          return
        }
      }
      basef.each(
        fn(midf) {
          midf.each(
            fn(lastf) {
              let lastfname = lastf.name
              let id = match @strconv.parse_int(lastfname)!! {
                Ok(v) => v
                Err(err) => {
                  let path = lastf.path
                  println("Invalid foothold id: \(err). node=\(path)")
                  return
                }
              }
              let foothold = Foothold::from_resource(lastf, id, layer)
              tree.footholds.set(id, foothold)
              if foothold.l() < leftw {
                leftw = foothold.l()
              }
              if foothold.r() > rightw {
                rightw = foothold.r()
              }
              if foothold.b() > botb {
                botb = foothold.b()
              }
              if foothold.t() < topb {
                topb = foothold.t()
              }
              if foothold.is_wall() {
                return
              }
              let start = foothold.l()
              let end = foothold.r()
              let mut i = start
              while i <= end {
                let ids = match tree.footholds_by_x[i] {
                  Some(v) => v
                  None => {
                    let v = Array::new()
                    tree.footholds_by_x[i] = v
                    v
                  }
                }
                ids.push(id)
                i += 1
              }
            },
          )
        },
      )
    },
  )
  let walls = Range::new(leftw + 25, rightw - 25)
  if walls.a > walls.b {
    abort("invalid walls=\(walls)")
  }
  tree.walls = walls
  let borders = Range::new(topb - 300, botb + 100)
  if borders.a > borders.b {
    abort("invalid borders=\(borders)")
  }
  tree.borders = borders
  tree
}

pub fn limit_movement(self : FootholdTree, phobj : PhysicsObject) -> Unit {
  if phobj.moving_object.hmobile() {
    let crnt_x = phobj.moving_object.crnt_x()
    let next_x = phobj.moving_object.next_x()
    let left = phobj.moving_object.hspeed < 0.0
    let mut wall = self.get_wall(phobj.fhid, left, phobj.moving_object.next_y())
    let mut collision = if left {
      crnt_x >= wall && next_x <= wall
    } else {
      crnt_x <= wall && next_x >= wall
    }
    if collision.not() && phobj.is_flag_set(PhysicsObjectFlag::TURN_AT_EDGES) {
      wall = self.get_edge(phobj.fhid, left)
      collision = if left {
        crnt_x >= wall && next_x <= wall
      } else {
        crnt_x <= wall && next_x >= wall
      }
    }
    if collision {
      phobj.moving_object.limitx(wall)
      phobj.clear_flag(PhysicsObjectFlag::TURN_AT_EDGES)
    }
  }
  if phobj.moving_object.vmobile() {
    let crnt_y = phobj.moving_object.crnt_y()
    let next_y = phobj.moving_object.next_y()
    let ground = Range::new(
      self.get_fh(phobj.fhid).ground_below(phobj.moving_object.crnt_x()),
      self.get_fh(phobj.fhid).ground_below(phobj.moving_object.next_x()),
    )
    let collision = crnt_y <= ground.first() && next_y >= ground.second()
    if collision {
      phobj.moving_object.limity(ground.second())
      self.limit_movement(phobj)
    } else if next_y < self.borders.first().to_double() {
      phobj.moving_object.limity(self.borders.first().to_double())
    } else if next_y > self.borders.second().to_double() {
      phobj.moving_object.limity(self.borders.second().to_double())
    }
  }
}

pub fn update_fh(self : FootholdTree, phobj : PhysicsObject) -> Unit {
  if phobj.type_ == PhysicsObjectType::FIXATED && phobj.fhid > 0 {
    return
  }
  let curfh = self.get_fh(phobj.fhid)
  let mut checkslope = false
  let x = phobj.moving_object.crnt_x()
  let y = phobj.moving_object.crnt_y()
  if phobj.onground {
    if x.floor() > curfh.r().to_double() {
      phobj.fhid = curfh.next()
    } else if x.ceil() < curfh.l().to_double() {
      phobj.fhid = curfh.prev()
    }
    if phobj.fhid == 0 {
      phobj.fhid = self.get_fhid_below(x, y)
    } else {
      checkslope = true
    }
  } else {
    phobj.fhid = self.get_fhid_below(x, y)
    if phobj.fhid == 0 {
      return
    }
  }
  let nextfh = self.get_fh(phobj.fhid)
  phobj.fhslope = nextfh.slope()
  let ground = nextfh.ground_below(x)
  if phobj.moving_object.vspeed == 0.0 && checkslope {
    let mut vdelta = phobj.fhslope.abs()
    if phobj.fhslope < 0.0 {
      vdelta *= ground - y
    } else if phobj.fhslope > 0.0 {
      vdelta *= y - ground
    }
    if curfh.slope() != 0.0 || nextfh.slope() != 0.0 {
      if phobj.moving_object.hspeed > 0.0 && vdelta <= phobj.moving_object.hspeed {
        phobj.moving_object.set_y(ground)
      } else if phobj.moving_object.hspeed < 0.0 && vdelta >= phobj.moving_object.hspeed {
        phobj.moving_object.set_y(ground)
      }
    }
  }
  phobj.onground = phobj.moving_object.y.now == ground
  if phobj.enablejd || phobj.is_flag_set(PhysicsObjectFlag::CHECK_BELOW) {
    let belowid = self.get_fhid_below(x, nextfh.ground_below(x) + 1.0)
    if belowid > 0 {
      let nextground = self.get_fh(belowid).ground_below(x)
      phobj.enablejd = nextground - ground < 600.0
      phobj.groundbelow = ground + 1.0
    } else {
      phobj.enablejd = false
    }
    phobj.clear_flag(PhysicsObjectFlag::CHECK_BELOW)
  }
  if phobj.fhlayer == 0 || phobj.onground {
    phobj.fhlayer = nextfh.layer()
  }
  if phobj.fhid == 0 {
    phobj.fhid = curfh.id()
    phobj.moving_object.limitx(curfh.x1().to_double())
  }
}

pub fn get_fh(self : FootholdTree, fhid : Int) -> Foothold {
  self.footholds.get(fhid).or(self.null_fh)
}

pub fn get_wall(
  self : FootholdTree,
  curid : Int,
  left : Bool,
  fy : Double
) -> Double {
  let shorty = fy.to_int()
  let vertical = Range::new(shorty - 50, shorty - 1)
  let cur = self.get_fh(curid)
  if left {
    let prev = self.get_fh(cur.prev())
    if prev.is_blocking(vertical) {
      return cur.l().to_double()
    }
    let prev_prev = self.get_fh(prev.prev())
    if prev_prev.is_blocking(vertical) {
      return prev.l().to_double()
    }
    return self.walls.first().to_double()
  }
  let next = self.get_fh(cur.next())
  if next.is_blocking(vertical) {
    return cur.r().to_double()
  }
  let next_next = self.get_fh(next.next())
  if next_next.is_blocking(vertical) {
    return next.r().to_double()
  }
  return self.walls.second().to_double()
}

pub fn get_edge(self : FootholdTree, curid : Int, left : Bool) -> Double {
  let fh = self.get_fh(curid)
  if left {
    let previd = fh.prev()
    if previd == 0 {
      return fh.l().to_double()
    }
    let prev = self.get_fh(previd)
    if prev.prev() == 0 {
      return prev.l().to_double()
    }
    return self.walls.first().to_double()
  }
  let nextid = fh.next()
  if nextid == 0 {
    return fh.r().to_double()
  }
  let next = self.get_fh(nextid)
  if next.next() == 0 {
    return next.r().to_double()
  }
  return self.walls.second().to_double()
}

pub fn get_fhid_below(self : FootholdTree, fx : Double, fy : Double) -> Int {
  let mut ret = 0
  let mut comp = self.borders.second().to_double()
  let x = fx.to_int()
  let range = self.footholds_by_x.get(x).or(Array::new())
  range.each(
    fn(id) {
      let fh = self.footholds.get(id).unwrap()
      let ycomp = fh.ground_below(fx)
      if comp >= ycomp && ycomp >= fy {
        comp = ycomp
        ret = fh.id()
      }
    },
  )
  ret
}

pub fn get_y_below(self : FootholdTree, position : Point[Int]) -> Int {
  let fhid = self.get_fhid_below(position.x.to_double(), position.y.to_double())
  if fhid > 0 {
    let fh = self.get_fh(fhid)
    return fh.ground_below(position.x.to_double()).to_int()
  }
  self.borders.second()
}

pub fn get_walls(self : FootholdTree) -> Range[Int] {
  self.walls
}

pub fn get_borders(self : FootholdTree) -> Range[Int] {
  self.borders
}
