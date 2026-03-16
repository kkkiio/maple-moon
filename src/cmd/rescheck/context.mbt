///|
struct RescheckContext {
  assets_root : String
  all_files : Array[String]
}

///|
struct CheckIssue {
  module_name : String
  severity : Severity
  path : String
  detail : String
}

///|
enum Severity {
  Error
}

///|
struct Checker {
  name : String
  run : (RescheckContext) -> Array[CheckIssue]
}

///|
fn normalize_path(path : String) -> String {
  let s = path.replace_all(old="\\", new="/")
  if s.has_prefix("./") {
    return s[2:s.length()].to_string()
  }
  s
}

///|
fn path_join(left : String, right : String) -> String {
  if left == "" {
    return right
  }
  if right == "" {
    return left
  }
  let l = normalize_path(left)
  let r = normalize_path(right)
  if l.has_suffix("/") {
    return l + r
  }
  l + "/" + r
}

///|
fn path_relative(abs_path : String, root : String) -> String {
  let a = normalize_path(abs_path)
  let r = normalize_path(root)
  if a.has_prefix(r + "/") {
    return a[r.length() + 1:a.length()].to_string()
  }
  a
}

///|
extern "js" fn list_files_recursive_ffi(root : String) -> Array[String] =
  #| (root) => {
  #|   const fs = process.getBuiltinModule('node:fs');
  #|   const path = process.getBuiltinModule('node:path');
  #|   const out = [];
  #|   if (!fs.existsSync(root)) {
  #|     return out;
  #|   }
  #|   const walk = (dir) => {
  #|     for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
  #|       const full = path.join(dir, ent.name);
  #|       if (ent.isDirectory()) {
  #|         walk(full);
  #|       } else if (ent.isFile()) {
  #|         out.push(full.split(path.sep).join('/'));
  #|       }
  #|     }
  #|   };
  #|   walk(root);
  #|   return out;
  #| }

///|
extern "js" fn path_exists_ffi(path : String) -> Bool =
  #| (path) => {
  #|   const fs = process.getBuiltinModule('node:fs');
  #|   return fs.existsSync(path);
  #| }

///|
extern "js" fn read_file_to_string_ffi(path : String) -> String =
  #| (path) => {
  #|   const fs = process.getBuiltinModule('node:fs');
  #|   return fs.readFileSync(path, 'utf-8');
  #| }

///|
fn build_context(assets_root : String) -> RescheckContext {
  let root = normalize_path(assets_root)
  let files = list_files_recursive_ffi(root)
  { assets_root: root, all_files: files }
}

///|
fn file_exists(path : String) -> Bool {
  path_exists_ffi(path)
}

///|
fn read_text_file(path : String) -> String {
  read_file_to_string_ffi(path)
}

///|
fn is_json_file(path : String) -> Bool {
  normalize_path(path).has_suffix(".json")
}
