///|
struct Module {
  packet_processor : @net.PacketProcessor
  login_img : @resource.NxNode
  pretty_logo : @resource.NxNode
  ui_container : &@ui.Container
  char_look_module : @char_look.Module
  io_service : @io_task.Service
  mut characters : Array[@character.CharEntry]
  mut selected_index : Int?
  mut receiving_server_list : Array[World]
  mut login_task : LoginTask?
  mut connect_task : ConnectChannelTask?
  // to reconnect
  mut input_acc_pass : (String, String)?
  mut select_cid : Int?
}

///|
pub fn Module::load(
  processor : @net.PacketProcessor,
  ui_container : &@ui.Container,
  char_look_module : @char_look.Module,
  io_service : @io_task.Service
) -> @utils.Future[Module] {
  get_map001_loader()
  .load_res(["Back", "login.img"])
  .combine(get_map_pretty_loader().load_res(["Back", "login.img", "ani", "16"]))
  .map(fn(it) {
    let (login_img, pretty_logo) = it
    {
      packet_processor: processor,
      login_img,
      pretty_logo,
      ui_container,
      char_look_module,
      characters: [],
      selected_index: None,
      receiving_server_list: [],
      login_task: None,
      connect_task: None,
      input_acc_pass: None,
      select_cid: None,
      io_service,
    }
  })
}

///|
pub fn make_handlers(
  self : Module,
  transition : (Int, Int) -> Unit,
  set_player_stage : (@character.CharEntry, (@player.Player) -> Unit!) -> Unit,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    (
      @net.LOGIN_RESULT,
      @net.with_log(@net.LOGIN_RESULT, fn(recv : @net.InPacket) {
        self.handle_login_result!(recv)
      }),
    ),
    (
      @net.SERVER_STATUS,
      @net.with_log(@net.SERVER_STATUS, fn(recv : @net.InPacket) {
        handle_server_status!(recv)
      }),
    ),
    (
      @net.SERVER_LIST,
      @net.with_log(@net.SERVER_LIST, fn(recv : @net.InPacket) {
        handle_server_list!(self, recv)
      }),
    ),
    @net.make_handler(@net.CHAR_LIST, log_recv=true, parse_char_list, fn(msg) {
      handle_char_list(self, msg)
    }),
    (
      @net.CHARNAME_RESPONSE,
      @net.with_log(@net.CHARNAME_RESPONSE, fn(recv : @net.InPacket) {
        let name = recv.read_string!()
        let used = recv.read_bool!()
        if used {
          @log.warn({ "name": name }, "Name already in use")
        } else {
          ...
        }
      }),
    ),
    (
      @net.SERVER_IP,
      @net.with_log(@net.SERVER_IP, fn(recv : @net.InPacket) {
        handle_server_ip!(self, recv)
      }),
    ),
    (
      @net.ADD_NEWCHAR_ENTRY,
      @net.with_log(@net.ADD_NEWCHAR_ENTRY, fn(recv : @net.InPacket) {
        handle_add_new_char_entry!(self, recv)
      }),
    ),
    (
      @net.SET_FIELD,
      @net.with_log(@net.SET_FIELD, fn(recv : @net.InPacket) {
        handle_set_field!(
          transition, self, set_player_stage, inventory, setup_game_ui, recv,
        )
      }),
    ),
  ]
  |> Map::from_array()
}

///|
pub fn get_selected_char(self : Module) -> @character.CharEntry? {
  self.selected_index.map(fn(index) { self.characters[index] })
}

///|
pub fn new_login_start_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::LOGIN_START)
}

///|
pub fn login(self : Module, account : String, password : String) -> Unit {
  self.input_acc_pass = Some((account, password))
  self.login_task = Some({
    processor: self.packet_processor,
    state: ACQ_CONN,
    account,
    password,
  })
  self.connect_task = None
}

///|
struct LoginTask {
  processor : @net.PacketProcessor
  mut state : LoginState
  account : String
  password : String
}

///|
enum LoginState {
  ACQ_CONN
  START_SEND
  LOGIN_SEND
}

///|
fn update(self : LoginTask) -> Unit {
  let p = self.processor
  match p.get_status() {
    READY =>
      match self.state {
        ACQ_CONN => {
          self.processor.send_packet(new_login_start_packet())
          self.state = START_SEND
        }
        START_SEND => {
          fn_login(self.processor, self.account, self.password) // TODO: allow select account
          self.state = LOGIN_SEND
        }
        LOGIN_SEND => ()
      }
    OPENED => ()
    CLOSED => {
      p.connect_login()
      self.state = ACQ_CONN
    }
  }
}

///|
fn fn_login(
  processor : @net.PacketProcessor,
  account : String,
  password : String
) -> Unit {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::LOGIN)
  let volume_serial_number = @config.global().get_volume_serial_number()
  let part1 = volume_serial_number.substring(start=0, end=2)
  let part2 = volume_serial_number.substring(start=2, end=4)
  let part3 = volume_serial_number.substring(start=4, end=6)
  let part4 = volume_serial_number.substring(start=6, end=8)
  let h = @net.hex_to_dec?(part4).unwrap()
  let w = @net.hex_to_dec?(part3).unwrap()
  let i = @net.hex_to_dec?(part2).unwrap()
  let d = @net.hex_to_dec?(part1).unwrap()
  let packet = packet
    ..write_string(account)
    ..write_string(password)
    ..skip(6)
    ..write_byte(h)
    ..write_byte(w)
    ..write_byte(i)
    ..write_byte(d)
  processor.send_packet(packet)
}

///| handle_login_result handles a packet that contains the response to an
/// attempt at logging in
pub fn handle_login_result(self : Module, recv : @net.InPacket) -> Unit!Error {
  self.login_task = None
  // auto loginwait = UI::get().get_element<UILoginWait>();

  // if (loginwait && loginwait->get().is_active()) {
  //     std::function<void()> okhandler = loginwait->get().get_handler();

  //     // Remove previous UIs
  //     UI::get().remove(UIElement::Type::LOGIN_NOTICE);
  //     UI::get().remove(UIElement::Type::LOGIN_WAIT);
  //     UI::get().remove(UIElement::Type::TOS);
  //     UI::get().remove(UIElement::Type::GENDER);

  // The packet should contain a 'reason' integer which can signify
  // various things
  match recv.read_int!() {
    // Login successful
    // The packet contains information on the account, so we initialize
    // the account with it.
    0 => {
      let account = parse_account!(recv)
      @config.global().set_admin(account.admin)
      // Save the "Login ID" if the box for it on the login screen is
      // checked
      //             if (Setting<SaveLogin>::get().load()) {
      //                 Setting<DefaultAccount>::get().save(account.name);
      //             }

      // AfterLoginPacket("1111").dispatch();

      // Request the list of worlds and channels online.

      let packet = new_server_request_packet()
      self.packet_processor.send_packet(packet)
    }
    //         // Login unsuccessful
    //         // The LoginNotice displayed will contain the specific information
    //         switch (reason) {
    //             case 2:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::BLOCKED_ID,
    //                     okhandler);
    //                 break;
    //             case 5:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::NOT_REGISTERED,
    //                     okhandler);
    //                 break;
    //             case 7:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::ALREADY_LOGGED_IN,
    //                     okhandler);
    //                 break;
    //             case 13:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::UNABLE_TO_LOGIN_WITH_IP,
    //                     okhandler);
    //                 break;
    23 =>
      // UI::get().emplace<UITermsOfService>(okhandler); break;
      fn_tos(self.packet_processor)
    //             default:
    //                 // Other reasons
    //                 if (reason > 0) {
    //                     auto reasonbyte = static_cast<int8_t>(reason - 1);

    //                     UI::get().emplace<UILoginNotice>(reasonbyte, okhandler);
    //                 }

    //                 break;
    //         }
    _ as reason => @log.warn({ "reason": reason }, "login failed")
  }
  // }
}

///|
pub fn handle_server_status(recv : @net.InPacket) -> Unit!Error {
  // Possible values for status:
  // 0 - Normal
  // 1 - Highly populated
  // 2 - Full
  recv.read_short!() |> ignore // status
}

///|
pub fn handle_server_list(self : Module, recv : @net.InPacket) -> Unit!Error {
  while recv.available() {
    let world = parse_world!(recv)
    if world.wid != -1 {
      self.receiving_server_list.push(world)
    } else { // end of list
      let worlds = self.receiving_server_list
      self.receiving_server_list = []
      @log.debug({ "worlds": worlds }, "server list")
      enter_world(0, 0, self.packet_processor)
      break
    }
  }
}

///|
fn enter_world(
  worldId : Int,
  channelId : Int,
  processor : @net.PacketProcessor
) -> Unit {
  @config.global().set_worldid(worldId)
  @config.global().set_channelid(channelId)
  fn_char_list_req(worldId, channelId, processor)
}

///|
fn fn_char_list_req(
  worldId : Int,
  channelId : Int,
  processor : @net.PacketProcessor
) -> Unit {
  let packet = new_char_list_request_packet(worldId, channelId)
  processor.send_packet(packet)
}

///|
fn new_char_list_request_packet(
  worldId : Int,
  channelId : Int
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::CHAR_LIST_REQUEST)
  ..write_byte((0).to_byte())
  ..write_byte(worldId.to_byte())
  ..write_byte(channelId.to_byte())
}

///|
pub fn parse_char_list(recv : @net.InPacket) -> CharListMessage!Error {
  recv.read_ubyte!() |> ignore // channel_id
  let characters = []
  let charcount = recv.read_byte!()
  for i = 0; i < charcount; i = i + 1 {
    characters.push(parse_charentry!(recv))
  }
  let pic = recv.read_byte!()
  recv.read_int!() |> ignore // slots
  { characters, pic }
}

///|
struct CharListMessage {
  characters : Array[@character.CharEntry]
  pic : Int
} derive(Show, ToJson)

///|
fn handle_char_list(mod : Module, message : CharListMessage) -> Unit {
  let { characters, pic } = message
  mod.characters = characters
  mod.selected_index = None
  match pic {
    2 =>
      match mod.select_cid {
        Some(cid) => {
          let packet = new_select_char_packet(cid)
          mod.packet_processor.send_packet(packet)
        }
        None => {
          mod.ui_container.remove_ui(@ui.UIElementType::LOGIN)
          let resource_f = SelectCharUIResource::load()
          let char_looks_f = mod.characters.map(fn(ce) {
              mod.char_look_module
              .load_char_look(ce.look)
              .map(fn(char_look) { (ce.id, char_look, ce.stats.name) })
            })
            |> @utils.Future::all_of()
          mod.io_service.on_complete(resource_f.combine(char_looks_f), fn(it) {
            let (resource, char_looks) = it
            let key = @ui.UIElementType::UI_ELEMENT_CHAR_SELECT
            let elem = @ui.Element::new(
              fn(hooks) {
                SelectCharUI::new(
                  resource,
                  char_looks,
                  on_select_character=fn(cid) {
                    mod.select_cid = Some(cid)
                    mod.packet_processor.send_packet(
                      new_select_char_packet(cid),
                    )
                  },
                  on_new_character=fn() {
                    mod.ui_container.remove_ui(key)
                    mod.io_service.on_complete(
                      ExplorerCreatorUIResource::load(),
                      fn(res) {
                        mod.ui_container.add_ui(
                          @ui.Element::new(
                            fn(hooks) {
                              ExplorerCreatorUI::new(
                                res,
                                hooks,
                                fn(entry, cb) {
                                  mod.io_service.on_complete(
                                    mod.char_look_module.load_char_look(entry),
                                    cb,
                                  )
                                },
                                on_create_char=fn(s) {
                                  let packet = new_create_char_packet(
                                    s.name,
                                    s.job,
                                    s.face_id,
                                    s.hair_id,
                                    s.hair_color_id,
                                    s.skin_id,
                                    s.top_id,
                                    s.bot_id,
                                    s.shoe_id,
                                    s.weapon_id,
                                    s.female,
                                  )
                                  mod.packet_processor.send_packet(packet)
                                },
                              )
                            },
                            @ui.UIElementType::CLASS_CREATION,
                          ),
                          false,
                        )
                      },
                    )
                  },
                  hooks,
                )
              },
              key,
            )
            mod.ui_container.add_ui(elem, false)
          })
        }
      }
    _ => {
      @log.error({ "pic": pic }, "pic not ok") // TODO: show error
      panic()
    }
  }
}

///|
pub fn handle_server_ip(mod : Module, recv : @net.InPacket) -> Unit! {
  recv.skip_byte!()
  let (_, port) = parse_login!(recv)
  let cid = recv.read_int!()
  match mod.characters.search_by(fn(c) { c.id == cid }) {
    Some(i) => mod.selected_index = Some(i)
    None => fail!("no character with id=\{cid}")
  }
  mod.packet_processor.connect_channel(port)
  mod.connect_task = Some({ processor: mod.packet_processor, cid })
}

///|
pub fn handle_add_new_char_entry(mod : Module, recv : @net.InPacket) -> Unit! {
  recv.skip!(1)
  let character = parse_charentry!(recv)
  mod.characters.push(character)
  mod.ui_container.remove_ui(@ui.UIElementType::CLASS_CREATION)
  mod.ui_container.add_ui(new_login_ui(mod), false)
}

///|
fn new_server_request_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SERVERLIST_REQUEST)
}

///|
fn fn_tos(processor : @net.PacketProcessor) -> Unit {
  let packet = new_tos_packet()
  processor.send_packet(packet)
}

///|
fn new_tos_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::ACCEPT_TOS)..write_byte(
    (1).to_byte(),
  )
}

///|
fn parse_account(recv : @net.InPacket) -> Account!Error {
  recv.skip_short!()
  let accid = recv.read_int!()
  let female = recv.read_byte!()
  let admin = recv.read_bool!()
  recv.skip_byte!() // Admin
  recv.skip_byte!() // Country Code
  let name = recv.read_string!()
  recv.skip_byte!()
  let muted = recv.read_bool!()
  recv.skip_long!() // muted until
  recv.skip_long!() // creation date
  recv.skip_int!() // Remove "Select the world you want to play in"
  let pin = recv.read_bool!() // 0 - Enabled, 1 - Disabled
  let pic = recv.read_byte!() // 0 - Register, 1 - Ask, 2 - Disabled
  { accid, female, admin, name, muted, pin, pic }
}

///|
struct Account {
  accid : Int
  female : Int
  admin : Bool
  name : String
  muted : Bool
  pin : Bool
  pic : Int
} derive(Show)

///|
struct World {
  name : String
  message : String
  chloads : Array[Int]
  channelcount : Int
  flag : Int
  wid : Int
} derive(Show)

///|
fn parse_world(recv : @net.InPacket) -> World! {
  let wid = recv.read_byte!()
  if wid == -1 {
    return { name: "", message: "", chloads: [], channelcount: 0, flag: 0, wid }
  }
  let name = recv.read_string!()
  let flag = recv.read_ubyte!()
  let message = recv.read_string!()
  recv.skip!(5)
  let chloads = []
  let channelcount = recv.read_ubyte!()
  for i = 0; i < channelcount; i = i + 1 {
    recv.read_string!() |> ignore // channel name
    chloads.push(recv.read_int!())
    recv.skip!(1)
    recv.skip!(2)
  }
  recv.skip!(2) // balloon size
  // recv.skip(10);  // balloon size 1 and msg "test"

  { name, message, chloads, channelcount, flag, wid }
}

///|
fn parse_charentry(recv : @net.InPacket) -> @character.CharEntry! {
  let id = recv.read_int!()
  let stats = parse_stats!(recv)
  let look = parse_look!(recv)
  recv.read_bool!() |> ignore // 'rankinfo' bool
  if recv.read_bool!() {
    let _currank = recv.read_int!()
    let rankmv = recv.read_int!()
    let _curjobrank = recv.read_int!()
    let jobrankmv = recv.read_int!()
    let _rankmc = if rankmv > 0 { '+' } else if rankmv < 0 { '-' } else { '=' }
    let _jobrankmc = if jobrankmv > 0 {
      '+'
    } else if jobrankmv < 0 {
      '-'
    } else {
      '='
    }
    // stats.rank = (currank, rankmc)
    // stats.jobrank = (curjobrank, jobrankmc)
  }
  { stats, look, id }
}

///|
fn parse_stats(recv : @net.InPacket) -> @char_stats.StatsEntry! {
  let name = recv.read_padded_string!(13)
  let female = recv.read_bool!()
  recv.read_byte!() |> ignore // skin
  recv.read_int!() |> ignore // face
  recv.read_int!() |> ignore // hair
  let petids = []
  for i = 0; i < 3; i = i + 1 {
    petids.push(recv.read_long!())
  }
  let stats = {}
  stats.set(@maple_stat.Id::LEVEL, recv.read_ubyte!())
  stats.set(@maple_stat.Id::JOB, recv.read_ushort!())
  stats.set(@maple_stat.Id::STR, recv.read_ushort!())
  stats.set(@maple_stat.Id::DEX, recv.read_ushort!())
  stats.set(@maple_stat.Id::INT, recv.read_ushort!())
  stats.set(@maple_stat.Id::LUK, recv.read_ushort!())
  stats.set(@maple_stat.Id::HP, recv.read_ushort!())
  stats.set(@maple_stat.Id::MAXHP, recv.read_ushort!())
  stats.set(@maple_stat.Id::MP, recv.read_ushort!())
  stats.set(@maple_stat.Id::MAXMP, recv.read_ushort!())
  stats.set(@maple_stat.Id::AP, recv.read_ushort!())
  stats.set(@maple_stat.Id::SP, recv.read_ushort!())
  let i64stats = {}
  i64stats.set(@maple_stat.Id::EXP, recv.read_uint!().to_int64())
  stats.set(@maple_stat.Id::FAME, recv.read_short!())
  recv.skip!(4) // gachaexp
  let mapid = recv.read_int!()
  let portal = recv.read_ubyte!()
  recv.skip!(4) // timestamp
  { name, female, stats, i64stats, mapid, portal }
}

///|
fn parse_look(recv : @net.InPacket) -> @char_look.LookEntry! {
  let female = recv.read_bool!()
  let skin = recv.read_ubyte!()
  let faceid = recv.read_int!()
  recv.read_bool!() |> ignore // megaphone
  let hairid = recv.read_int!()
  let equips = {}
  loop recv.read_ubyte!() {
    0xFF => ()
    eqslot => {
      equips.set(eqslot, recv.read_int!())
      continue recv.read_ubyte!()
    }
  }
  let maskedequips = {}
  loop recv.read_ubyte!() {
    0xFF => ()
    mskeqslot => {
      maskedequips.set(mskeqslot, recv.read_int!())
      continue recv.read_ubyte!()
    }
  }
  maskedequips.set(-111, recv.read_int!())
  let petids = []
  for i in 0..<3 {
    petids.push(recv.read_int!())
  }
  { female, skin, faceid, hairid, equips, maskedequips, petids }
}

///|
fn parse_login(recv : @net.InPacket) -> (String, Int)! {
  recv.skip_byte!()
  let addrstr = []
  for i = 0; i < 4; i = i + 1 {
    addrstr.push(recv.read_byte!())
  }
  let portstr = recv.read_short!()
  (String::concat(addrstr.map(fn(b) { b.to_string() }), separator="."), portstr)
}

///| Requests being logged-in to a channel server with the specified character
pub fn new_player_login_packet(cid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_LOGIN)..write_int(cid)
}

///|
fn get_etc_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("Etc")
}

///|
pub(open) trait BgTask {
  update(Self) -> Bool
}

///|
struct ConnectChannelTask {
  processor : @net.PacketProcessor
  cid : Int
}

///|
pub fn update(self : ConnectChannelTask) -> Bool {
  if self.processor.get_status() == @net.READY {
    let packet = new_player_login_packet(self.cid)
    self.processor.send_packet(packet)
    true
  } else {
    false
  }
}

///|
pub fn reconnect_if_needed(self : Module) -> Unit {
  guard let Some((acc, pass)) = self.input_acc_pass else { None => return }
  login(self, acc, pass)
}

///|
pub fn update(self : Module) -> Unit {
  match self.login_task {
    Some(task) => task.update()
    None => ()
  }
  match self.connect_task {
    Some(task) => if task.update() { self.connect_task = None }
    None => ()
  }
}

///|
pub fn new_login_ui(self : Module) -> @ui.Element {
  @ui.Element::new(
    fn(_hooks) { UILogin::new(self, self.login_img, self.pretty_logo) },
    @ui.UIElementType::LOGIN,
  )
}

///|
pub fn get_map001_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("map001")
}

///|
pub fn get_map_pretty_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("map_pretty")
}

///| Tell the server which character was picked.
fn new_select_char_packet(character_id : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SELECT_CHAR)
  ..write_int(character_id)
  ..write_hardware_info()
}
