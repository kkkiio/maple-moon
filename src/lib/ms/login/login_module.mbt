///|
struct Module {
  network : @net.Network
  ui_container : &@ui.Container
  char_look_module : @char_look.Module
  local_storage : @config.LocalStorage
  mut characters : Array[@character.CharEntry]
  mut selected_index : Int?
  mut receiving_server_list : Array[World] // temporary storage for unfinished server list
  mut login_task : LoginTask?
  mut connect_task : ConnectChannelTask?
  // to reconnect
  // mut input_acc_pass : (String, String)?
  mut select_cid : Int?
  login_loader : @resource.SyncLoader
  io_service : @io_task.IOService
}

///|
pub async fn Module::load(
  network : @net.Network,
  ui_container : &@ui.Container,
  char_look_module : @char_look.Module,
  io_service : @io_task.IOService,
  local_storage : @config.LocalStorage
) -> Module raise {
  let login_loader = @resource.SyncLoader::load(
    "Login",
    "https://maple-res.kkkiiox.work/UI/Login.img.json",
    @resource.ImageLoader::get_path_image_loader(),
  )
  Module::new(
    network, ui_container, char_look_module, local_storage, login_loader, io_service,
  )
}

///|
pub fn Module::new(
  network : @net.Network,
  ui_container : &@ui.Container,
  char_look_module : @char_look.Module,
  local_storage : @config.LocalStorage,
  login_loader : @resource.SyncLoader,
  io_service : @io_task.IOService
) -> Module {
  {
    network,
    ui_container,
    char_look_module,
    characters: [],
    selected_index: None,
    receiving_server_list: [],
    login_task: None,
    connect_task: None,
    // input_acc_pass: None,
    select_cid: None,
    io_service,
    local_storage,
    login_loader,
  }
}

///|
pub fn make_handlers(
  self : Module,
  transition : (Int, Int) -> Unit,
  set_player_stage : (
    @character.CharEntry,
    Map[Int, Int],
    (@player.Player) -> Unit raise,
  ) -> Unit,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit,
  quest_module : @quest.Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(
      @net.LOGIN_RESULT,
      parse_login_result,
      fn(res) { self.handle_login_result(res) },
      log_recv=true,
    ),
    @net.make_handler(@net.SERVER_STATUS, parse_server_status, fn(status) {
      @log.info({ "status": status }, "server status")
    }),
    @net.make_handler(
      @net.SERVER_LIST,
      fn(recv) { self.parse_server_list(recv) },
      fn(worlds) { self.handle_server_list(worlds) },
    ),
    @net.make_handler(@net.CHAR_LIST, log_recv=true, parse_char_list, fn(msg) {
      handle_char_list(self, msg)
    }),
    @net.make_handler(
      @net.CHARNAME_RESPONSE,
      fn(recv) {
        let name = recv.read_string()
        let used = recv.read_bool()
        (name, used)
      },
      fn(info) {
        let (name, used) = info
        if used {
          @log.warn({ "name": name }, "Name already in use")
        } else {
          ...
        }
      },
      log_recv=true,
    ),
    @net.make_handler(
      @net.SERVER_IP,
      parse_server_ip,
      fn(info) {
        let (port, cid) = info
        handle_server_ip(self, port, cid)
      },
      log_recv=true,
    ),
    @net.make_handler(
      @net.ADD_NEWCHAR_ENTRY,
      parse_add_new_char_entry,
      fn(character) { handle_add_new_char_entry(self, character) },
      log_recv=true,
    ),
    @net.make_handler(
      @net.SET_FIELD,
      parse_set_field,
      fn(msg) {
        handle_set_field(
          transition, self, quest_module, set_player_stage, inventory, setup_game_ui,
          msg,
        )
      },
      log_recv=true,
    ),
    @net.make_handler(@net.LAST_CONNECTED_WORLD, parse_last_connected_world, fn(
      _
    ) {

    }),
  ]
  |> Map::from_array()
}

///|
pub fn Module::get_selected_char(self : Module) -> @character.CharEntry? {
  self.selected_index.map(fn(index) { self.characters[index] })
}

///|
pub fn Module::login(
  self : Module,
  account : String,
  password : String,
  callback : (String) -> Unit
) -> Unit {
  // TODO: support token auth
  self.local_storage.set_item("last_account", account)
  self.local_storage.set_item("last_password", password)
  self.login_account(account, password, callback)
}

///|
fn Module::login_account(
  self : Module,
  account : String,
  password : String,
  callback : (String) -> Unit
) -> Unit {
  self.login_task = Some({
    processor: self.network,
    state: ACQ_CONN,
    account,
    password,
    callback,
  })
  self.connect_task = None
}

///| login last used account and character
pub fn Module::login_last_used(
  self : Module,
  callback : (String) -> Unit
) -> Unit {
  // TODO: support token auth
  let account = self.local_storage.get_item("last_account")
  let password = self.local_storage.get_item("last_password")
  if account is Some(account) && password is Some(password) {
    self.login_account(account, password, callback)
  } else {
    callback("No account or password found")
  }
}

///|
priv struct LoginTask {
  processor : @net.Network
  mut state : LoginState
  account : String
  password : String
  callback : (String) -> Unit
}

///|
priv enum LoginState {
  ACQ_CONN
  START_SEND
  LOGIN_SEND
}

///|
fn LoginTask::update(self : LoginTask) -> Unit {
  let p = self.processor
  match p.get_status() {
    READY =>
      match self.state {
        ACQ_CONN => {
          self.processor.send_message(LoginStartMessage(()))
          self.state = START_SEND
        }
        START_SEND => {
          self.processor.send_message({
            account: self.account,
            password: self.password,
          })
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
priv type LoginStartMessage Unit derive(Show)

///|
impl @net.OutMessage for LoginStartMessage with pack(self) -> @net.OutPacket {
  ignore(self)
  @net.OutPacket::new(@net.ClientOpcode::LOGIN_START)
}

///|
priv struct LoginMessage {
  account : String
  password : String
} derive(Show)

///|
impl @net.OutMessage for LoginMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::LOGIN)
  let volume_serial_number = @config.global().get_volume_serial_number()
  let part1 = volume_serial_number.substring(start=0, end=2)
  let part2 = volume_serial_number.substring(start=2, end=4)
  let part3 = volume_serial_number.substring(start=4, end=6)
  let part4 = volume_serial_number.substring(start=6, end=8)
  try {
    let h = @net.hex_to_dec(part4)
    let w = @net.hex_to_dec(part3)
    let i = @net.hex_to_dec(part2)
    let d = @net.hex_to_dec(part1)
    packet
    ..write_string(self.account)
    ..write_string(self.password)
    ..skip(6)
    ..write_byte(h)
    ..write_byte(w)
    ..write_byte(i)
    ..write_byte(d)
    packet
  } catch {
    e => abort(e.to_string())
  }
}

///|
enum LoginResult {
  Ok(Account)
  AlreadyLoggedIn
  RequireTermsOfService
  Err(String)
} derive(Show)

///|
fn parse_login_result(recv : @net.InPacket) -> LoginResult raise Error {
  match recv.read_int() {
    // Login successful
    // The packet contains information on the account, so we initialize
    // the account with it.
    0 => {
      let account = parse_account(recv)
      Ok(account)
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
    7 => AlreadyLoggedIn
    //             case 13:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::UNABLE_TO_LOGIN_WITH_IP,
    //                     okhandler);
    //                 break;
    23 => RequireTermsOfService
    //             default:
    //                 // Other reasons
    //                 if (reason > 0) {
    //                     auto reasonbyte = static_cast<int8_t>(reason - 1);

    //                     UI::get().emplace<UILoginNotice>(reasonbyte, okhandler);
    //                 }

    //                 break;
    //         }
    _ as reason => Err("Login failed with reason: \{reason}")
  }
}

///| handle_login_result handles a packet that contains the response to an
/// attempt at logging in
pub fn handle_login_result(self : Module, result : LoginResult) -> Unit {

  // The packet should contain a 'reason' integer which can signify
  // various things
  match result {
    // Login successful
    // The packet contains information on the account, so we initialize
    // the account with it.
    Ok(account) => {
      @config.global().set_admin(account.admin)
      if self.login_task is Some({ callback, .. }) {
        callback("")
      }
      self.login_task = None
      // Save the "Login ID" if the box for it on the login screen is
      // checked
      //             if (Setting<SaveLogin>::get().load()) {
      //                 Setting<DefaultAccount>::get().save(account.name);
      //             }

      // AfterLoginPacket("1111").dispatch();

      self.network.send_message(ServerRequest(()))
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
    //             case 13:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::UNABLE_TO_LOGIN_WITH_IP,
    //                     okhandler);
    //                 break;
    AlreadyLoggedIn => {
      self.network.close() // server require new connection
      if self.login_task is Some({ callback, .. }) {
        callback("Already logged in")
      }
      self.login_task = None // let user try again
    }
    RequireTermsOfService =>
      // UI::get().emplace<UITermsOfService>(okhandler); break;
      fn_tos(self.network)
    //             default:
    //                 // Other reasons
    //                 if (reason > 0) {
    //                     auto reasonbyte = static_cast<int8_t>(reason - 1);

    //                     UI::get().emplace<UILoginNotice>(reasonbyte, okhandler);
    //                 }

    //                 break;
    //         }
    Err(e) => {
      if self.login_task is Some({ callback, .. }) {
        callback(e)
      }
      self.login_task = None
    }
  }
  // }
}

///|
enum ServerStatus {
  Normal
  HighlyPopulated
  Full
} derive(Show)

///|
pub fn parse_server_status(recv : @net.InPacket) -> ServerStatus raise Error {
  match recv.read_short() {
    0 => Normal
    1 => HighlyPopulated
    2 => Full
    i => fail("Unknown server status: \{i}")
  }
}

///|
fn parse_server_list(
  self : Module,
  recv : @net.InPacket
) -> Array[World]? raise Error {
  while recv.available() > 0 {
    let world = parse_world(recv)
    if world.wid != -1 {
      self.receiving_server_list.push(world)
    } else { // end of list
      let worlds = self.receiving_server_list
      self.receiving_server_list = []
      return Some(worlds)
    }
  }
  None
}

///|
fn handle_server_list(self : Module, worlds : Array[World]?) -> Unit {
  guard worlds is Some(worlds) else { // unfinished server list
    return
  }
  let world = worlds[0]
  let channel = 0
  self.local_storage.set_item("last_world_id", world.wid.to_string())
  self.local_storage.set_item("last_channel_id", channel.to_string())
  self.network.send_message({ worldId: world.wid, channelId: channel })
}

///|
priv struct CharListRequestPacket {
  worldId : Int
  channelId : Int
} derive(Show)

///|
impl @net.OutMessage for CharListRequestPacket with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::CHAR_LIST_REQUEST)
  p
  ..write_byte((0).to_byte())
  ..write_byte(self.worldId.to_byte())
  ..write_byte(self.channelId.to_byte())
  p
}

///|
pub fn parse_char_list(recv : @net.InPacket) -> CharListMessage raise Error {
  recv.read_ubyte() |> ignore // channel_id
  let characters = []
  let charcount = recv.read_byte()
  for i = 0; i < charcount; i = i + 1 {
    characters.push(parse_charentry(recv))
  }
  let pic = recv.read_byte()
  recv.read_int() |> ignore // slots
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
        Some(cid) => mod.network.send_message({ character_id: cid })
        None =>
          mod.io_service.execute(async fn() {
            let resource = SelectCharUIResource::load(mod.login_loader)
            let char_looks = []
            for ce in mod.characters {
              let char_look = mod.char_look_module.load_char_look(ce.look)
              char_looks.push((ce.id, char_look, ce.stats.name))
            }
            let key = @ui.UIElementType::UI_ELEMENT_CHAR_SELECT
            let elem = @ui.Element::new(
              fn(hooks) {
                SelectCharUI::new(
                  resource,
                  char_looks,
                  on_select_character=fn(cid) {
                    mod.select_cid = Some(cid)
                    mod.network.send_message(SelectCharPacket::new(cid))
                  },
                  on_new_character=fn() {
                    mod.ui_container.remove_ui(key)
                    mod.io_service.execute(async fn() { on_new_character(mod) })
                  },
                  hooks,
                )
              },
              key,
            )
            mod.ui_container.add_ui(elem, false)
          })
      }
    _ => {
      @log.error({ "pic": pic }, "pic not ok") // TODO: show error
      panic()
    }
  }
}

///|
async fn on_new_character(mod : Module) -> Unit raise {
  let res = ExplorerCreatorUIResource::load(mod.login_loader)
  mod.ui_container.add_ui(
    @ui.Element::new(
      fn(hooks) {
        ExplorerCreatorUI::new(
          res,
          hooks,
          fn(entry, cb) {
            mod.io_service.execute(async fn() {
              let char_look = mod.char_look_module.load_char_look(entry)
              cb(char_look)
            })
          },
          on_create_char=fn(s) {
            mod.network.send_message({
              name: s.name,
              job: s.job,
              face: s.face_id,
              hair: s.hair_id,
              hairc: s.hair_color_id,
              skin: s.skin_id,
              top: s.top_id,
              bot: s.bot_id,
              shoes: s.shoe_id,
              weapon: s.weapon_id,
              female: s.female,
            })
          },
        )
      },
      @ui.UIElementType::CLASS_CREATION,
    ),
    false,
  )
}

///| Parse server IP response packet
fn parse_server_ip(recv : @net.InPacket) -> (Int, Int) raise {
  recv.skip_byte()
  let (_, port) = parse_login(recv)
  let cid = recv.read_int()
  (port, cid)
}

///| Handle server IP response
pub fn handle_server_ip(mod : Module, port : Int, cid : Int) -> Unit {
  match mod.characters.search_by(fn(c) { c.id == cid }) {
    Some(i) => mod.selected_index = Some(i)
    None => {
      @log.error({ "cid": cid }, "no character with id=\{cid}")
      panic()
    }
  }
  mod.local_storage.set_item("last_port", port.to_string())
  mod.local_storage.set_item("last_character_id", cid.to_string())
  mod.connect_channel_with_character(cid, port)
}

///|
fn Module::connect_channel_with_character(
  self : Module,
  cid : Int,
  port : Int
) -> Unit {
  self.network.connect_channel(port)
  self.connect_task = Some({ network: self.network, cid })
}

///|
fn parse_add_new_char_entry(recv : @net.InPacket) -> @character.CharEntry raise {
  recv.skip(1)
  parse_charentry(recv)
}

///|
pub fn handle_add_new_char_entry(
  mod : Module,
  character : @character.CharEntry
) -> Unit {
  mod.characters.push(character)
  mod.ui_container.remove_ui(@ui.UIElementType::CLASS_CREATION)
  // TODO: show character selection UI
}

///| Request the list of worlds and channels online.
priv type ServerRequest Unit derive(Show)

///|
impl @net.OutMessage for ServerRequest with pack(self) -> @net.OutPacket {
  ignore(self)
  @net.OutPacket::new(@net.ClientOpcode::SERVERLIST_REQUEST)
}

///|
fn fn_tos(processor : @net.Network) -> Unit {
  processor.send_message(AcceptTosPacket::default())
}

///|
priv struct AcceptTosPacket {} derive(Show, Default)

///|
impl @net.OutMessage for AcceptTosPacket with pack(_self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::ACCEPT_TOS)
  p..write_byte((1).to_byte())
  p
}

///|
fn parse_account(recv : @net.InPacket) -> Account raise Error {
  recv.skip_short()
  let accid = recv.read_int()
  let female = recv.read_byte()
  let admin = recv.read_bool()
  recv.skip_byte() // Admin
  recv.skip_byte() // Country Code
  let name = recv.read_string()
  recv.skip_byte()
  let muted = recv.read_bool()
  recv.skip_long() // muted until
  recv.skip_long() // creation date
  recv.skip_int() // Remove "Select the world you want to play in"
  let pin = recv.read_bool() // 0 - Enabled, 1 - Disabled
  let pic = recv.read_byte() // 0 - Register, 1 - Ask, 2 - Disabled
  { accid, female, admin, name, muted, pin, pic }
}

///|
priv struct Account {
  accid : Int
  female : Int
  admin : Bool
  name : String
  muted : Bool
  pin : Bool
  pic : Int
} derive(Show)

///|
priv struct World {
  name : String
  message : String
  chloads : Array[Int]
  channelcount : Int
  flag : Int
  wid : Int
} derive(Show)

///|
fn parse_world(recv : @net.InPacket) -> World raise {
  let wid = recv.read_byte()
  if wid == -1 {
    return { name: "", message: "", chloads: [], channelcount: 0, flag: 0, wid }
  }
  let name = recv.read_string()
  let flag = recv.read_ubyte()
  let message = recv.read_string()
  recv.skip(5)
  let chloads = []
  let channelcount = recv.read_ubyte()
  for i = 0; i < channelcount; i = i + 1 {
    recv.read_string() |> ignore // channel name
    chloads.push(recv.read_int())
    recv.skip(1)
    recv.skip(2)
  }
  recv.skip(2) // balloon size
  // recv.skip(10);  // balloon size 1 and msg "test"

  { name, message, chloads, channelcount, flag, wid }
}

///|
fn parse_charentry(recv : @net.InPacket) -> @character.CharEntry raise {
  let id = recv.read_int()
  let stats = parse_stats(recv)
  let look = parse_look(recv)
  recv.read_bool() |> ignore // 'rankinfo' bool
  if recv.read_bool() {
    let _currank = recv.read_int()
    let rankmv = recv.read_int()
    let _curjobrank = recv.read_int()
    let jobrankmv = recv.read_int()
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
fn parse_stats(recv : @net.InPacket) -> @char_stats.StatsEntry raise {
  let name = recv.read_padded_string(13)
  let female = recv.read_bool()
  recv.read_byte() |> ignore // skin
  recv.read_int() |> ignore // face
  recv.read_int() |> ignore // hair
  let petids = []
  for i = 0; i < 3; i = i + 1 {
    petids.push(recv.read_long())
  }
  let stats = {}
  stats.set(@maple_stat.Id::LEVEL, recv.read_ubyte())
  stats.set(@maple_stat.Id::JOB, recv.read_ushort())
  stats.set(@maple_stat.Id::STR, recv.read_ushort())
  stats.set(@maple_stat.Id::DEX, recv.read_ushort())
  stats.set(@maple_stat.Id::INT, recv.read_ushort())
  stats.set(@maple_stat.Id::LUK, recv.read_ushort())
  stats.set(@maple_stat.Id::HP, recv.read_ushort())
  stats.set(@maple_stat.Id::MAXHP, recv.read_ushort())
  stats.set(@maple_stat.Id::MP, recv.read_ushort())
  stats.set(@maple_stat.Id::MAXMP, recv.read_ushort())
  stats.set(@maple_stat.Id::AP, recv.read_ushort())
  stats.set(@maple_stat.Id::SP, recv.read_ushort())
  let i64stats = {}
  i64stats.set(@maple_stat.Id::EXP, recv.read_uint().to_int64())
  stats.set(@maple_stat.Id::FAME, recv.read_short())
  recv.skip(4) // gachaexp
  let mapid = recv.read_int()
  let portal = recv.read_ubyte()
  recv.skip(4) // timestamp
  { name, female, stats, i64stats, mapid, portal }
}

///|
fn parse_look(recv : @net.InPacket) -> @char_look.LookEntry raise {
  let female = recv.read_bool()
  let skin = recv.read_ubyte()
  let faceid = recv.read_int()
  recv.read_bool() |> ignore // megaphone
  let hairid = recv.read_int()
  let equips = {}
  loop recv.read_ubyte() {
    0xFF => ()
    eqslot => {
      equips.set(eqslot, recv.read_int())
      continue recv.read_ubyte()
    }
  }
  let maskedequips = {}
  loop recv.read_ubyte() {
    0xFF => ()
    mskeqslot => {
      maskedequips.set(mskeqslot, recv.read_int())
      continue recv.read_ubyte()
    }
  }
  maskedequips.set(-111, recv.read_int())
  let petids = []
  for i in 0..<3 {
    petids.push(recv.read_int())
  }
  { female, skin, faceid, hairid, equips, maskedequips, petids }
}

///|
fn parse_login(recv : @net.InPacket) -> (String, Int) raise {
  recv.skip_byte()
  let addrstr = []
  for i = 0; i < 4; i = i + 1 {
    addrstr.push(recv.read_byte())
  }
  let portstr = recv.read_short()
  (Array::join(addrstr.map(fn(b) { b.to_string() }), "."), portstr)
}

///| Represents a request to log in to a channel server with a specific character
priv struct PlayerLoginPacket {
  cid : Int
} derive(Show)

///|
impl @net.OutMessage for PlayerLoginPacket with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::PLAYER_LOGIN)
  p..write_int(self.cid)
  p
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
  network : @net.Network
  cid : Int
}

///|
pub fn ConnectChannelTask::update(self : ConnectChannelTask) -> Bool {
  if self.network.get_status() is @net.ConnectionStatus::READY {
    self.network.send_message({ cid: self.cid })
    true
  } else {
    false
  }
}

///|
pub fn Module::update(self : Module) -> Unit {
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
pub fn get_map001_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("map001")
}

///|
pub fn get_map_pretty_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("map_pretty")
}

///| Tell the server which character was picked.
priv struct SelectCharPacket {
  character_id : Int
} derive(Show)

///|
fn SelectCharPacket::new(character_id : Int) -> SelectCharPacket {
  { character_id, }
}

///|
impl @net.OutMessage for SelectCharPacket with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::SELECT_CHAR)
  p..write_int(self.character_id)..write_hardware_info()
  p
}

///|
priv struct LastConnectedWorldMessage {
  world : Int
} derive(Show)

///|
fn parse_last_connected_world(
  recv : @net.InPacket
) -> LastConnectedWorldMessage raise {
  { world: recv.read_int() }
}
