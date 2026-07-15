#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <spawn.h>
#include <stddef.h>
#include <sys/stat.h>
#include <unistd.h>

extern char **environ;

int maple_moon_spawn_detached(
    const char *executable,
    const char *log_path,
    const char *cdp_port,
    const char *game_url) {
  posix_spawn_file_actions_t actions;
  posix_spawnattr_t attributes;
  sigset_t empty_mask;
  sigset_t default_signals;
  pid_t pid;
  int error = posix_spawn_file_actions_init(&actions);
  if (error != 0) return error;
  error = posix_spawn_file_actions_addopen(
      &actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
  if (error == 0) {
    error = posix_spawn_file_actions_addopen(
        &actions, STDOUT_FILENO, log_path, O_WRONLY | O_CREAT | O_APPEND, 0600);
  }
  if (error == 0) {
    error = posix_spawn_file_actions_adddup2(
        &actions, STDOUT_FILENO, STDERR_FILENO);
  }
  if (error != 0) {
    posix_spawn_file_actions_destroy(&actions);
    return error;
  }
  error = posix_spawnattr_init(&attributes);
  if (error != 0) {
    posix_spawn_file_actions_destroy(&actions);
    return error;
  }
  if (sigemptyset(&empty_mask) != 0 ||
      sigemptyset(&default_signals) != 0 ||
      sigaddset(&default_signals, SIGINT) != 0 ||
      sigaddset(&default_signals, SIGTERM) != 0 ||
      sigaddset(&default_signals, SIGHUP) != 0) {
    error = errno;
  }
  if (error == 0) {
    error = posix_spawnattr_setsigmask(&attributes, &empty_mask);
  }
  if (error == 0) {
    error = posix_spawnattr_setsigdefault(&attributes, &default_signals);
  }
  if (error == 0) {
    error = posix_spawnattr_setflags(
        &attributes,
        POSIX_SPAWN_SETSID | POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF);
  }
  char *const argv[] = {
      (char *)executable,
      "--cdp-port",
      (char *)cdp_port,
      "--url",
      (char *)game_url,
      NULL,
  };
  if (error == 0) {
    error = posix_spawn(
        &pid, executable, &actions, &attributes, argv, environ);
  }
  posix_spawnattr_destroy(&attributes);
  posix_spawn_file_actions_destroy(&actions);
  return error;
}
