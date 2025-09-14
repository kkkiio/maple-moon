// The collection of platforms in a maple map
// Used for collision-detection

///|
struct FootholdTree {
  footholds : Map[Int, Foothold]
  seg_tree : SegTree
  null_fh : Foothold
  walls : @struct.Range[Int]
  borders : @struct.Range[Int]
}

///|
pub(all) struct NxFootholdTree {
  footholds : Map[Int, Map[Int, Map[Int, NxFoothold]]]
}

///|
pub impl @json.FromJson for NxFootholdTree with from_json(json, path) -> NxFootholdTree raise @json.JsonDecodeError {
  guard json is Object(footholds) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let l0 = {}
  for basefname, basef in footholds {
    let path = path.add_key(basefname)
    let layer = @strconv.parse_int(basefname) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path, "invalid foothold layer \{basefname}"),
        )
    }
    guard basef is Object(basef) else {
      raise @json.JsonDecodeError((path, "expect object"))
    }
    let l1 = {}
    for midfname, midf in basef {
      let path = path.add_key(midfname)
      let id = @strconv.parse_int(midfname) catch {
        _ =>
          raise @json.JsonDecodeError((path, "invalid foothold id \{midfname}"))
      }
      guard midf is Object(midf) else {
        raise @json.JsonDecodeError((path, "expect object"))
      }
      let l2 = {}
      for lastfname, lastf in midf {
        let path = path.add_key(lastfname)
        let id = @strconv.parse_int(lastfname) catch {
          _ =>
            raise @json.JsonDecodeError(
              (path, "invalid foothold id \{lastfname}"),
            )
        }
        let nx_foothold : NxFoothold = @json.from_json(lastf, path~)
        l2.set(id, nx_foothold)
      }
      l1.set(id, l2)
    }
    l0.set(layer, l1)
  }
  { footholds: l0 }
}

///|
pub fn FootholdTree::load_from_resource(
  src : NxFootholdTree,
) -> FootholdTree raise {
  let footholds = Map::new()
  let null_fh = Foothold::default()
  for layer, basef in src.footholds {
    for _, midf in basef {
      for id, lastf in midf {
        let foothold = Foothold::load_from_resource(lastf, id, layer)
        footholds.set(id, foothold)
      }
    }
  }
  if footholds.size() == 0 {
    raise @resource.LoadError("no footholds")
  }
  let leftw = footholds.values().map(fn(f) { f.l() }).minimum().unwrap_or(30000)
  let rightw = footholds
    .values()
    .map(fn(f) { f.r() })
    .maximum()
    .unwrap_or(-30000)
  let walls = @struct.Range::new(leftw + 25, rightw - 25)
  let topb = footholds.values().map(fn(f) { f.t() }).minimum().unwrap_or(30000)
  let botb = footholds.values().map(fn(f) { f.b() }).maximum().unwrap_or(-30000)
  let borders = @struct.Range::new(topb - 300, botb + 100)
  let seg_tree = SegTree::build(footholds)
  { footholds, seg_tree, null_fh, walls, borders }
}

///|
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
    if not(collision) && phobj.is_flag_set(PhysicsObjectFlag::TURN_AT_EDGES) {
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

///|
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

///|
fn FootholdTree::get_fh(self : FootholdTree, fhid : Int) -> Foothold {
  self.footholds.get(fhid).unwrap_or(self.null_fh)
}

///|
pub fn get_wall(
  self : FootholdTree,
  curid : Int,
  left : Bool,
  fy : Double,
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

///|
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

///|
pub fn get_fhid_below(self : FootholdTree, fx : Double, fy : Double) -> Int {
  let ix = fx.floor().to_int()
  let mut best_id = 0
  let mut best_y = self.borders.second().to_double()
  self.seg_tree.for_each_ids_at(ix, fn(id) {
    let fh = self.footholds.get(id).unwrap()
    let ycomp = fh.ground_below(fx)
    if best_y >= ycomp && ycomp >= fy {
      best_id = fh.id()
      best_y = ycomp
    }
  })
  best_id
}

///|
pub fn get_y_below(self : FootholdTree, position : Point[Int]) -> Int {
  let fhid = self.get_fhid_below(position.x.to_double(), position.y.to_double())
  if fhid > 0 {
    let fh = self.get_fh(fhid)
    return fh.ground_below(position.x.to_double()).to_int()
  }
  self.borders.second()
}

///|
pub fn get_walls(self : FootholdTree) -> @struct.Range[Int] {
  self.walls
}

///|
pub fn get_borders(self : FootholdTree) -> @struct.Range[Int] {
  self.borders
}

///|
priv struct SegNode {
  lo : Int
  hi : Int
  left : Int
  right : Int
  ids : Array[Int]
}

///|
priv struct SegTree {
  xs : Array[Int]
  nodes : Array[SegNode]
  root : Int
}

///|
fn SegTree::build(footholds : Map[Int, Foothold]) -> SegTree {
  // 1) 收集端点（跳过墙）; 使用半开区间 [l, r+1)
  let xs = {
    let tmp : Set[Int] = Set::new()
    for _, f in footholds {
      if f.is_wall() {
        continue
      }
      tmp.add(f.l())
      tmp.add(f.r() + 1)
    }
    let xs = tmp.to_array()
    xs.sort()
    xs
  }
  if xs.length() < 2 {
    return { xs, nodes: Array::new(), root: -1 }
  }
  // 2) 建树节点（基于基本区间索引 [0, xs.len-2]）
  let nodes : Array[SegNode] = Array::new()
  let root = 0
  nodes.push({ lo: 0, hi: xs.length() - 2, left: -1, right: -1, ids: [] })
  let build_tasks : Array[Int] = [root]
  for p = 0; p < build_tasks.length(); p = p + 1 {
    let idx = build_tasks[p]
    let node = nodes[idx]
    if node.lo < node.hi {
      let mid = (node.lo + node.hi) / 2
      let left_idx = nodes.length()
      nodes.push({ lo: node.lo, hi: mid, left: -1, right: -1, ids: [] })
      let right_idx = nodes.length()
      nodes.push({ lo: mid + 1, hi: node.hi, left: -1, right: -1, ids: [] })
      nodes[idx] = {
        lo: node.lo,
        hi: node.hi,
        left: left_idx,
        right: right_idx,
        ids: node.ids,
      }
      build_tasks.push(left_idx)
      build_tasks.push(right_idx)
    }
  }
  // 3) 把每个水平段分发到“最高完全覆盖”的节点（基于 [l, r+1)）
  for _, f in footholds {
    if f.is_wall() {
      continue
    }
    let l = f.l()
    let r1 = f.r() + 1
    let stack : Array[Int] = [root]
    let mut sp = 0
    while sp < stack.length() {
      let i = stack[sp]
      sp = sp + 1
      let n = nodes[i]
      let left_bound = xs[n.lo]
      let right_bound = xs[n.hi + 1]
      if r1 <= left_bound || right_bound <= l {
        continue
      }
      if l <= left_bound && right_bound <= r1 {
        nodes[i].ids.push(f.id())
      } else {
        if n.left >= 0 {
          stack.push(n.left)
        }
        if n.right >= 0 {
          stack.push(n.right)
        }
      }
    }
  }
  { xs, nodes, root }
}

///|
fn SegTree::for_each_ids_at(
  self : SegTree,
  ix : Int,
  on_id : (Int) -> Unit,
) -> Unit {
  if self.root < 0 || self.xs.length() < 2 {
    return
  }
  let xmin = self.xs[0]
  let xmax = self.xs[self.xs.length() - 1]
  if ix < xmin || ix >= xmax {
    return
  }
  let mut idx = self.root
  while idx >= 0 {
    let node = self.nodes[idx]
    for id in node.ids {
      on_id(id)
    }
    if node.lo == node.hi {
      break
    }
    let mid = (node.lo + node.hi) / 2
    let boundary = self.xs[mid + 1]
    if ix < boundary {
      idx = node.left
    } else {
      idx = node.right
    }
  }
}
