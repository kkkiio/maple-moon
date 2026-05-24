///|
extern "js" fn defer_snapshot_for_external_runner(
  path : String,
  visual_desc : String,
) -> Bool =
  #| (path, visualDesc) => {
  #|   if (!globalThis.__MAPLE_DEFER_SNAPSHOTS) {
  #|     return false;
  #|   }
  #|   const queue = globalThis.__MAPLE_DEFERRED_SNAPSHOTS || [];
  #|   queue.push({ path, visual_desc: visualDesc ?? "" });
  #|   globalThis.__MAPLE_DEFERRED_SNAPSHOTS = queue;
  #|   return true;
  #| }

///|
extern "js" fn check_snapshot_with_external_runner(
  path : String,
  actual : Bytes,
  visual_desc : String,
) -> String? =
  #| (path, actual, visualDesc) => {
  #|   if (!globalThis.__MAPLE_EXTERNAL_SNAPSHOT_CHECK) {
  #|     return undefined;
  #|   }
  #|   const xhr = new XMLHttpRequest();
  #|   xhr.open("POST", "/__snapshot/check", false);
  #|   xhr.setRequestHeader("content-type", "application/json");
  #|   xhr.send(JSON.stringify({
  #|     path,
  #|     visual_desc: visualDesc ?? "",
  #|     bytes: Array.from(actual ?? []),
  #|   }));
  #|   if (xhr.status < 200 || xhr.status >= 300) {
  #|     return `snapshot check server failed: ${xhr.status}: ${xhr.responseText}`;
  #|   }
  #|   const result = JSON.parse(xhr.responseText || "{}");
  #|   return result.ok ? "" : (result.message || "snapshot mismatch");
  #| }
