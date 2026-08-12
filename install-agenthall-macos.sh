#!/usr/bin/env bash
set -euo pipefail

release_version="0.3.1-alpha.76"
release_tag="agenthall-v${release_version}"
marketplace_source="Johnsondoc/agenthall-plugins"
marketplace_name="agenthall"
plugin_id="agenthall@agenthall"
expected_plugin_manifest_sha="d7102b23482eb5e8dbd68d2deeb5297ead86fce8da0ba72f88792de10509748f"
expected_mcp_config_sha="45581d920318e53b101ec07617a954d04e1b6f8eb9672d9a1320eaccea898ffc"
expected_mcp_server_sha="7c6e1293f1954c90d5d8f16fb7700558f62a5096b0b804a864732a4bd0a35573"
expected_skill_sha="224dcd5dc6ed0033a22a04d78fee6e1399d7301b301d33e8b300339d6facae06"
expected_sidebar_sha="0d9db5c286d51369c4f06065ecf87aea5c9e4ca27a814fca586832688b2d1bb6"
expected_logo_sha="e6366bec291df5c514a8da289ee7798f3cfc4a23aed21f91f59eb0a8849bc8a6"

fail() {
  printf 'AgentHall installation failed: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command is unavailable: $1"
}

sha256_file() {
  /usr/bin/shasum -a 256 "$1" | /usr/bin/awk '{print $1}'
}

verify_file() {
  local root="$1"
  local relative_path="$2"
  local expected="$3"
  local target="$root/$relative_path"
  [[ -f "$target" ]] || fail "release file is missing: $relative_path"
  [[ "$(sha256_file "$target")" == "$expected" ]] ||
    fail "release file checksum mismatch: $relative_path"
}

verify_plugin_tree() {
  local root="$1"
  verify_file "$root" ".codex-plugin/plugin.json" "$expected_plugin_manifest_sha"
  verify_file "$root" ".mcp.json" "$expected_mcp_config_sha"
  verify_file "$root" "mcp/server.cjs" "$expected_mcp_server_sha"
  verify_file "$root" "skills/open-agenthall/SKILL.md" "$expected_skill_sha"
  verify_file "$root" "assets/agenthall-sidebar.html" "$expected_sidebar_sha"
  verify_file "$root" "assets/logo.png" "$expected_logo_sha"
}

test_mode="${AGENTHALL_INSTALLER_TEST_MODE:-0}"
if [[ "$test_mode" == "1" ]]; then
  codex_root="${AGENTHALL_TEST_CODEX_ROOT:?AGENTHALL_TEST_CODEX_ROOT is required}"
  codex_bin="${AGENTHALL_TEST_CODEX_BIN:?AGENTHALL_TEST_CODEX_BIN is required}"
  json_node="${AGENTHALL_TEST_NODE_BIN:-$(command -v node)}"
else
  [[ "$(uname -s)" == "Darwin" ]] || fail "this installer supports macOS only"
  require_command codex
  require_command git
  require_command osascript
  require_command launchctl
  codex_root="${CODEX_HOME:-$HOME/.codex}"
  codex_bin="$(command -v codex)"
  if command -v node >/dev/null 2>&1; then
    json_node="$(command -v node)"
  elif [[ -x "/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node" ]]; then
    json_node="/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node"
  else
    fail "Node.js is unavailable; the AgentHall Companion cannot run"
  fi
fi

state_root="$codex_root/agenthall-installer"
downloads_root="$state_root/downloads"
worker_script="$downloads_root/install-agenthall-macos-${release_version}.sh"
mkdir -p "$downloads_root"
chmod 700 "$state_root" "$downloads_root"

host_is_running() {
  if [[ "$test_mode" == "1" ]]; then
    [[ -f "$codex_root/test-host.running" ]]
  else
    [[ "$(/usr/bin/osascript -e 'application id "com.openai.codex" is running' 2>/dev/null)" == "true" ]]
  fi
}

record_test_event() {
  if [[ "$test_mode" == "1" ]]; then
    printf '%s\n' "$1" >>"$codex_root/test-events.log"
  fi
}

request_host_quit() {
  record_test_event "host_quit_requested"
  if [[ "$test_mode" == "1" ]]; then
    rm -f "$codex_root/test-host.running"
  else
    /usr/bin/osascript -e 'tell application id "com.openai.codex" to quit'
  fi
}

launch_host() {
  local workspace="$1"
  record_test_event "host_launch_requested"
  if [[ "$test_mode" == "1" ]]; then
    : >"$codex_root/test-host.running"
  else
    "$codex_bin" app "$workspace" >/dev/null 2>&1
  fi
}

wait_for_host_state() {
  local wanted="$1"
  local attempts=0
  while ((attempts < 120)); do
    if [[ "$wanted" == "stopped" ]] && ! host_is_running; then
      return 0
    fi
    if [[ "$wanted" == "running" ]] && host_is_running; then
      return 0
    fi
    /bin/sleep 1
    attempts=$((attempts + 1))
  done
  return 1
}

installed_agenthall_ids() {
  "$codex_bin" plugin list --json 2>/dev/null | "$json_node" -e '
let body = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (body += chunk));
process.stdin.on("end", () => {
  const parsed = JSON.parse(body);
  for (const plugin of parsed.installed ?? []) {
    if (plugin.name === "agenthall") process.stdout.write(`${plugin.pluginId}\n`);
  }
});'
}

marketplace_exists() {
  "$codex_bin" plugin marketplace list --json 2>/dev/null | "$json_node" -e '
let body = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (body += chunk));
process.stdin.on("end", () => {
  const parsed = JSON.parse(body);
  process.exit((parsed.marketplaces ?? []).some((item) => item.name === "agenthall") ? 0 : 1);
});'
}

verify_installed_record() {
  "$codex_bin" plugin list --json 2>/dev/null | "$json_node" -e '
let body = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (body += chunk));
process.stdin.on("end", () => {
  const parsed = JSON.parse(body);
  const matches = (parsed.installed ?? []).filter((item) => item.name === "agenthall");
  const valid = matches.length === 1 && matches[0].pluginId === "agenthall@agenthall" && matches[0].version === "0.3.1-alpha.76" && matches[0].enabled === true;
  process.exit(valid ? 0 : 1);
});'
}

copy_if_present() {
  local source="$1"
  local destination="$2"
  if [[ -e "$source" ]]; then
    mkdir -p "$(dirname "$destination")"
    cp -Rp "$source" "$destination"
  fi
}

move_if_present() {
  local source="$1"
  local destination="$2"
  if [[ -e "$source" ]]; then
    mkdir -p "$(dirname "$destination")"
    mv "$source" "$destination"
  fi
}

run_worker() {
  local workspace="$1"
  local log_file="$2"
  local run_id
  run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
  local run_root="$state_root/runs/$run_id"
  local source_checkout="$run_root/marketplace"
  local backup_root="$run_root/backup"
  local failed_root="$run_root/failed-state"
  local lock_dir="$state_root/install.lock"
  local mutation_started=0
  local install_succeeded=0

  mkdir -p "$run_root"
  exec >>"$log_file" 2>&1
  printf 'AgentHall %s one-pass installer started.\n' "$release_version"

  if ! mkdir "$lock_dir" 2>/dev/null; then
    fail "another AgentHall installation is already running"
  fi

  restore_previous_install() {
    set +e
    printf 'Restoring the previous AgentHall installation.\n'
    move_if_present "$codex_root/.tmp/marketplaces/agenthall" "$failed_root/marketplace-agenthall"
    move_if_present "$codex_root/.tmp/plugins.sha" "$failed_root/plugins.sha"
    move_if_present "$codex_root/plugins/cache/agenthall" "$failed_root/cache-agenthall"
    move_if_present "$codex_root/plugins/cache/personal/agenthall" "$failed_root/cache-personal-agenthall"
    if [[ -f "$backup_root/config.toml" ]]; then
      cp -p "$backup_root/config.toml" "$codex_root/config.toml"
    fi
    copy_if_present "$backup_root/marketplace-agenthall" "$codex_root/.tmp/marketplaces/agenthall"
    copy_if_present "$backup_root/plugins.sha" "$codex_root/.tmp/plugins.sha"
    copy_if_present "$backup_root/cache-agenthall" "$codex_root/plugins/cache/agenthall"
    copy_if_present "$backup_root/cache-personal-agenthall" "$codex_root/plugins/cache/personal/agenthall"
    set -e
  }

  finish_worker() {
    local exit_code=$?
    trap - EXIT
    if [[ "$install_succeeded" != "1" ]]; then
      if [[ "$mutation_started" == "1" ]]; then
        restore_previous_install
      fi
      if ! host_is_running; then
        launch_host "$workspace" || true
      fi
      if [[ "$test_mode" != "1" ]]; then
        /usr/bin/osascript -e 'display notification "已保留原有安装，请查看安装日志。" with title "AgentHall 安装失败"' || true
      fi
    fi
    rmdir "$lock_dir" 2>/dev/null || true
    exit "$exit_code"
  }
  trap finish_worker EXIT

  if [[ "$test_mode" == "1" ]]; then
    cp -Rp "${AGENTHALL_TEST_MARKETPLACE_ROOT:?AGENTHALL_TEST_MARKETPLACE_ROOT is required}" "$source_checkout"
  else
    git clone --quiet --depth 1 --branch "$release_tag" "https://github.com/${marketplace_source}.git" "$source_checkout"
  fi
  verify_plugin_tree "$source_checkout/plugins/agenthall"
  record_test_event "target_verified"

  if host_is_running; then
    request_host_quit
    wait_for_host_state stopped || fail "Codex did not exit normally; no plugin files were changed"
  fi
  record_test_event "host_stopped"

  mkdir -p "$backup_root"
  copy_if_present "$codex_root/config.toml" "$backup_root/config.toml"
  copy_if_present "$codex_root/.tmp/marketplaces/agenthall" "$backup_root/marketplace-agenthall"
  copy_if_present "$codex_root/.tmp/plugins.sha" "$backup_root/plugins.sha"
  copy_if_present "$codex_root/plugins/cache/agenthall" "$backup_root/cache-agenthall"
  copy_if_present "$codex_root/plugins/cache/personal/agenthall" "$backup_root/cache-personal-agenthall"
  mutation_started=1
  record_test_event "mutation_started"

  while IFS= read -r existing_plugin_id; do
    [[ -n "$existing_plugin_id" ]] || continue
    "$codex_bin" plugin remove "$existing_plugin_id" --json >/dev/null
  done < <(installed_agenthall_ids)

  if marketplace_exists; then
    "$codex_bin" plugin marketplace remove "$marketplace_name" --json >/dev/null
  fi
  "$codex_bin" plugin marketplace add "$marketplace_source" --ref "$release_tag" --json >/dev/null
  "$codex_bin" plugin add "$plugin_id" --json >/dev/null

  verify_installed_record || fail "Codex did not register exactly one enabled ${release_version} plugin"
  verify_plugin_tree "$codex_root/plugins/cache/agenthall/agenthall/$release_version"
  "$json_node" --check "$codex_root/plugins/cache/agenthall/agenthall/$release_version/mcp/server.cjs" >/dev/null
  record_test_event "installed_verified"

  launch_host "$workspace"
  wait_for_host_state running || fail "Codex could not be restarted after installation"
  record_test_event "host_running"

  mkdir -p "$state_root"
  printf '{"release_version":"%s","status":"installed_and_restarted","sidebar_resource":"ui://agenthall/sidebar-v%s.html"}\n' \
    "$release_version" "$release_version" >"$state_root/last-success.json"
  chmod 600 "$state_root/last-success.json"
  install_succeeded=1
  if [[ "$test_mode" != "1" ]]; then
    /usr/bin/osascript -e 'display notification "插件已校验，Codex 已重新启动。请在新任务打开 AgentHall。" with title "AgentHall 安装完成"' || true
  fi
  printf 'AgentHall %s installed, verified, and Codex restarted.\n' "$release_version"
  trap - EXIT
  rmdir "$lock_dir" 2>/dev/null || true
}

if [[ "${1:-}" == "--worker" ]]; then
  [[ $# -eq 3 ]] || fail "invalid worker invocation"
  run_worker "$2" "$3"
  exit 0
fi

workspace="${1:-$PWD}"
[[ -d "$workspace" ]] || workspace="$HOME"
cp -p "$0" "$worker_script"
chmod 700 "$worker_script"
log_file="$state_root/install-${release_version}-$(date -u +%Y%m%dT%H%M%SZ).log"

if [[ "$test_mode" == "1" ]]; then
  run_worker "$workspace" "$log_file"
else
  launch_label="com.agenthall.installer.${release_version//[^A-Za-z0-9]/-}.$$"
  launchctl submit -l "$launch_label" -- /usr/bin/env "PATH=$PATH" /bin/bash "$worker_script" --worker "$workspace" "$log_file"
  printf 'AgentHall %s installation started. Codex will close and reopen automatically.\n' "$release_version"
  printf 'Log: %s\n' "$log_file"
fi
