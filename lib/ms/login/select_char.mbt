let test_name = "kkkiio1"

struct ExplorerCreator {
  skins : @utils.BoolPair[Array[Int]]
  haircolors : @utils.BoolPair[Array[Int]]
  faces : @utils.BoolPair[Array[Int]]
  hairs : @utils.BoolPair[Array[Int]]
  tops : @utils.BoolPair[Array[Int]]
  bots : @utils.BoolPair[Array[Int]]
  shoes : @utils.BoolPair[Array[Int]]
  weapons : @utils.BoolPair[Array[Int]]
}

fn ExplorerCreator::new(src : @resource.NxNode) -> ExplorerCreator {
  let faces = @utils.BoolPair::new([], [])
  let hairs = @utils.BoolPair::new([], [])
  let haircolors = @utils.BoolPair::new([], [])
  let skins = @utils.BoolPair::new([], [])
  let tops = @utils.BoolPair::new([], [])
  let bots = @utils.BoolPair::new([], [])
  let shoes = @utils.BoolPair::new([], [])
  let weapons = @utils.BoolPair::new([], [])
  let mkinfo = src
  for i = 0; i < 2; i = i + 1 {
    let (f, char) = if i == 0 {
      (true, mkinfo["CharFemale"])
    } else {
      (false, mkinfo["CharMale"])
    }
    char.each(
      fn(node) {
        let num = @strconv.parse_int?(node.name()).unwrap()
        node.each(
          fn(idnode) {
            let value = idnode.get_int?().unwrap()
            match num {
              0 => faces[f].push(value)
              1 => hairs[f].push(value)
              2 => haircolors[f].push(value)
              3 => skins[f].push(value)
              4 => tops[f].push(value)
              5 => bots[f].push(value)
              6 => shoes[f].push(value)
              7 => weapons[f].push(value)
              _ => ()
            }
          },
        )
      },
    )
  }
  { faces, hairs, haircolors, skins, tops, bots, shoes, weapons }
}

fn send_naming_result(
  self : ExplorerCreator,
  cname : String,
  nameused : Bool
) -> Unit {
  let female = false
  if nameused.not() {
    let cface = self.faces[female][0]
    let chair = self.hairs[female][0]
    let chairc = self.haircolors[female][0]
    let cskin = self.skins[female][0]
    let ctop = self.tops[female][0]
    let cbot = self.bots[female][0]
    let cshoe = self.shoes[female][0]
    let cwep = self.weapons[female][0]
    fn_create_char(
      cname, 1, cface, chair, chairc, cskin, ctop, cbot, cshoe, cwep, female,
    )
  } else {
    @log.warn({ "name": cname }, "Name already in use")
  }
}

/// Reserve a name for the character to be created.
fn new_name_char_packet(name : String) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NAME_CHAR)..write_string(name)
}

fn fn_create_char(
  name : String,
  job : Int,
  face : Int,
  hair : Int,
  hairc : Int,
  skin : Int,
  top : Int,
  bot : Int,
  shoes : Int,
  weapon : Int,
  female : Bool
) -> Unit {
  new_create_char_packet(
    name, job, face, hair, hairc, skin, top, bot, shoes, weapon, female,
  ).dispatch()
}

/// Requests creation of a character with the specified stats.
fn new_create_char_packet(
  name : String,
  job : Int,
  face : Int,
  hair : Int,
  hairc : Int,
  skin : Int,
  top : Int,
  bot : Int,
  shoes : Int,
  weapon : Int,
  female : Bool
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::CREATE_CHAR)
  ..write_string(name)
  ..write_int(job)
  ..write_int(face)
  ..write_int(hair)
  ..write_int(hairc)
  ..write_int(skin)
  ..write_int(top)
  ..write_int(bot)
  ..write_int(shoes)
  ..write_int(weapon)
  ..write_byte(female.to_int().to_byte())
}

/// Tell the server which character was picked.
fn new_select_char_packet(character_id : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SELECT_CHAR)
  ..write_int(character_id)
  ..write_hardware_info()
}
