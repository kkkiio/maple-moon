///|
/// Compare PNG bytes with a stored snapshot.
///
/// If the snapshot file exists, the frame is compared with it. If
/// `UPDATE_CANVAS_SNAPS` is `"true"` or the file is missing, the snapshot file
/// is written from `actual`.
///
/// # Example
/// ```moonbit nocheck
/// let captures = app.run_frames_capture(3, raw_delta=0.016)
/// @capture_app.snapshot(
///   "src/test/example/__snapshot__/frame.png",
///   captures[captures.length() - 1].png,
///   visual_desc="The expected frame is rendered.",
/// )
/// ```
pub fn snapshot(
  path : String,
  actual : Bytes,
  visual_desc~ : String,
) -> Unit raise {
  if defer_snapshot_for_external_runner(path, visual_desc) {
    return
  }
  match check_snapshot_with_external_runner(path, actual, visual_desc) {
    Some("") => return
    Some(message) => fail(message)
    None => ()
  }
  ignore(visual_desc)
  let update_snapshot = @env.get_env_var("UPDATE_CANVAS_SNAPS") is Some("true")
  let should_write_snapshot = update_snapshot || !@fs.path_exists(path)
  try {
    if should_write_snapshot {
      let snapshot_dir = parent_dir(path)
      if !@fs.path_exists(snapshot_dir) {
        @fs.create_dir(snapshot_dir) catch {
          err =>
            fail("failed to create snapshot dir: \{snapshot_dir}, error=\{err}")
        }
      }
      @fs.write_bytes_to_file(path, actual) catch {
        err => fail("failed to write snapshot: \{path}, error=\{err}")
      }
    } else {
      let expected = @fs.read_file_to_bytes(path) catch {
        err => fail("failed to read snapshot: \{path}, error=\{err}")
      }
      if actual == expected {
        return
      }
      raise SnapshotError::Mismatch(msg="snapshot mismatch: \{path}")
    }
  } catch {
    SnapshotError::Mismatch(msg~) => {
      let wrong_img_path = wrong_snapshot_path(path)
      @fs.write_bytes_to_file(wrong_img_path, actual) catch {
        err =>
          fail(
            "failed to write wrong snapshot: \{wrong_img_path}, error=\{err}",
          )
      }
      fail(msg + ", new snapshot saved to: \{wrong_img_path}")
    }
    e => raise e
  }
}

///|
priv suberror SnapshotError {
  Mismatch(msg~ : String)
}

///|
fn parent_dir(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path.view(end_offset=i).to_owned()
    None => "."
  }
}

///|
fn wrong_snapshot_path(path : String) -> String {
  match path.rev_find(".") {
    Some(i) =>
      path.view(end_offset=i).to_owned() + ".wrong" + path[i:].to_owned()
    None => path + ".wrong"
  }
}
