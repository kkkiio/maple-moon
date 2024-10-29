// The collection of platforms in a maple map
// Used for collision-detection
struct FootholdTree {
  footholds : Map[Int, Foothold]
  footholds_by_x : Map[Int, Array[Int]]
  null_fh : Foothold
  walls : @struct.Range[Int]
  borders : @struct.Range[Int]
}

pub fn FootholdTree::load_from_resource(
  src : @resource.NxNode
) -> FootholdTree!@resource.LoadError {
  let footholds = Map::new()
  let footholds_by_x = Map::new()
  let null_fh = Foothold::default()
  for basef in src {
    let basefname = basef.name()
    let layer = try {
      @strconv.parse_int!(basefname)
    } catch {
      @strconv.StrConvError(e) =>
        raise @resource.LoadError("invalid foothold layer \{e}")
    }
    for midf in basef {
      for lastf in midf {
        let lastfname = lastf.name()
        let id = try {
          @strconv.parse_int!(lastfname)
        } catch {
          @strconv.StrConvError(e) =>
            raise @resource.LoadError("invalid foothold id \{e}")
        }
        let foothold = Foothold::load_from_resource!(lastf, id, layer)
        footholds.set(id, foothold)
        if foothold.is_wall() {
          continue
        }
        let start = foothold.l()
        let end = foothold.r()
        for i in start..=end {
          footholds_by_x.get_or_init(i, fn() { Array::new() }).push(id)
        }
      }
    }
  }
  if footholds.size() == 0 {
    raise @resource.LoadError("no footholds")
  }
  let leftw = footholds
    .values()
    .iter()
    .map(fn(f) { f.l() })
    .fold(init=30000, @math.minimum)
  let rightw = footholds
    .values()
    .iter()
    .map(fn(f) { f.r() })
    .fold(init=-30000, @math.maximum)
  let walls = @struct.Range::new(leftw + 25, rightw - 25)
  let topb = footholds
    .values()
    .iter()
    .map(fn(f) { f.t() })
    .fold(init=30000, @math.minimum)
  let botb = footholds
    .values()
    .iter()
    .map(fn(f) { f.b() })
    .fold(init=-30000, @math.maximum)
  let borders = @struct.Range::new(topb - 300, botb + 100)
  { footholds, footholds_by_x, null_fh, walls, borders }
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
    let ground = @struct.Range::new(
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
  if phobj.t == PhysicsObjectType::FIXATED && phobj.fhid > 0 {
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
      if phobj.moving_object.hspeed > 0.0 &&
        vdelta <= phobj.moving_object.hspeed {
        phobj.moving_object.set_y(ground)
      } else if phobj.moving_object.hspeed < 0.0 &&
        vdelta >= phobj.moving_object.hspeed {
        phobj.moving_object.set_y(ground)
      }
    }
  }
  phobj.onground = phobj.moving_object.y.get() == ground
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

fn get_fh(self : FootholdTree, fhid : Int) -> Foothold {
  self.footholds.get(fhid).or(self.null_fh)
}

pub fn get_wall(
  self : FootholdTree,
  curid : Int,
  left : Bool,
  fy : Double
) -> Double {
  let shorty = fy.to_int()
  let vertical = @struct.Range::new(shorty - 50, shorty - 1)
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
  guard let Some(range) = self.footholds_by_x.get(fx.to_int()) else {
    None => return 0
  }
  range.fold(
    init=(0, self.borders.second().to_double()),
    fn(acc, id) {
      let fh = self.footholds.get(id).unwrap()
      let ycomp = fh.ground_below(fx)
      let (_, comp) = acc
      if comp >= ycomp && ycomp >= fy {
        (fh.id(), ycomp)
      } else {
        acc
      }
    },
  ).0
}

pub fn get_y_below(self : FootholdTree, position : Point[Int]) -> Int {
  let fhid = self.get_fhid_below(position.x.to_double(), position.y.to_double())
  if fhid > 0 {
    let fh = self.get_fh(fhid)
    return fh.ground_below(position.x.to_double()).to_int()
  }
  self.borders.second()
}

pub fn get_walls(self : FootholdTree) -> @struct.Range[Int] {
  self.walls
}

pub fn get_borders(self : FootholdTree) -> @struct.Range[Int] {
  self.borders
}
