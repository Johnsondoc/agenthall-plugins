#!/usr/bin/env bash
set -euo pipefail

release_version="0.3.1-alpha.84"
release_tag="agenthall-v${release_version}"
marketplace_source="Johnsondoc/agenthall-plugins"
marketplace_name="agenthall"
plugin_id="agenthall@agenthall"
local_marketplace_source="${AGENTHALL_INSTALLER_LOCAL_MARKETPLACE_SOURCE:-}"
expected_plugin_manifest_sha="4cd500ac7b4337ba2ab769010e29809988643d587b1c031dc9ea6f6cfe49bf4a"
expected_mcp_config_sha="45581d920318e53b101ec07617a954d04e1b6f8eb9672d9a1320eaccea898ffc"
expected_mcp_server_sha="1df97ba5ababc4eeb329d54d4e9114a8b224100ab13c73ae9de016cbe746f02e"
expected_skill_sha="224dcd5dc6ed0033a22a04d78fee6e1399d7301b301d33e8b300339d6facae06"
expected_sidebar_sha="f75f1d687ef7ae977f633fe73557cdf8dabbd1330c500d455010be3213101344"
expected_logo_sha="e6366bec291df5c514a8da289ee7798f3cfc4a23aed21f91f59eb0a8849bc8a6"

fail() {
  printf 'AgentHall installation failed: %s\n' "$*" >&2
  exit 1
}

test_mode="${AGENTHALL_INSTALLER_TEST_MODE:-0}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command is unavailable: $1"
}

resolve_codex_bin() {
  local candidate=""
  local candidates=()
  if [[ "$test_mode" == "1" && -n "${AGENTHALL_TEST_CODEX_APP_BIN:-}" ]]; then
    candidates=("$AGENTHALL_TEST_CODEX_APP_BIN")
  else
    local pid=""
    local command=""
    while read -r pid command; do
      case "$command" in
        "/Applications/Codex.app/Contents/MacOS/Codex"*|"$HOME/Applications/Codex.app/Contents/MacOS/Codex"*)
          candidate="${command%%/Contents/MacOS/Codex*}/Contents/Resources/codex"
          [[ -x "$candidate" ]] && printf '%s\n' "$candidate" && return 0
          ;;
        "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT"*|"$HOME/Applications/ChatGPT.app/Contents/MacOS/ChatGPT"*)
          candidate="${command%%/Contents/MacOS/ChatGPT*}/Contents/Resources/codex"
          [[ -x "$candidate" ]] && printf '%s\n' "$candidate" && return 0
          ;;
      esac
    done < <(/bin/ps ax -o pid=,command= 2>/dev/null || true)
    candidates=(
      "/Applications/Codex.app/Contents/Resources/codex"
      "$HOME/Applications/Codex.app/Contents/Resources/codex"
      "/Applications/ChatGPT.app/Contents/Resources/codex"
      "$HOME/Applications/ChatGPT.app/Contents/Resources/codex"
    )
  fi
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if candidate="$(command -v codex 2>/dev/null)" && [[ -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  fail "Codex CLI was not found in PATH or the installed ChatGPT/Codex app"
}

if [[ "${AGENTHALL_INSTALLER_TEST_RESOLVE_CODEX_ONLY:-0}" == "1" ]]; then
  resolve_codex_bin
  exit 0
fi

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

if [[ "$test_mode" == "1" ]]; then
  codex_root="${AGENTHALL_TEST_CODEX_ROOT:?AGENTHALL_TEST_CODEX_ROOT is required}"
  codex_bin="${AGENTHALL_TEST_CODEX_BIN:?AGENTHALL_TEST_CODEX_BIN is required}"
  json_node="${AGENTHALL_TEST_NODE_BIN:-$(command -v node)}"
else
  [[ "$(uname -s)" == "Darwin" ]] || fail "this installer supports macOS only"
  require_command git
  require_command osascript
  [[ -x /usr/bin/nohup ]] || fail "required command is unavailable: /usr/bin/nohup"
  codex_root="${CODEX_HOME:-$HOME/.codex}"
  codex_bin="$(resolve_codex_bin)"
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

host_gui_is_running() {
  if [[ "$test_mode" == "1" ]]; then
    [[ -f "$codex_root/test-host.running" ]]
  else
    [[ "$(/usr/bin/osascript -e 'application id "com.openai.codex" is running' 2>/dev/null)" == "true" ]]
  fi
}

codex_app_server_pids() {
  if [[ "$test_mode" == "1" ]]; then
    [[ -f "$codex_root/test-app-server.running" ]] && printf '9001\n'
    return 0
  fi
  local pid=""
  local command=""
  local executable=""
  local trusted_executables=""
  trusted_executables="$(trusted_codex_app_bins)"
  while read -r pid command; do
    [[ -n "$pid" ]] || continue
    executable="${command%% *}"
    executable="$(realpath "$executable" 2>/dev/null || printf '%s' "$executable")"
    if [[ $'\n'"$trusted_executables"$'\n' == *$'\n'"$executable"$'\n'* && "$command" == *" app-server"* ]]; then
      printf '%s\n' "$pid"
    fi
  done < <(/bin/ps ax -o pid=,command= 2>/dev/null || true)
}

trusted_codex_app_bins() {
  local candidate=""
  local resolved=""
  for candidate in \
    "$codex_bin" \
    "/Applications/ChatGPT.app/Contents/Resources/codex" \
    "$HOME/Applications/ChatGPT.app/Contents/Resources/codex" \
    "/Applications/Codex.app/Contents/Resources/codex" \
    "$HOME/Applications/Codex.app/Contents/Resources/codex"; do
    [[ -x "$candidate" ]] || continue
    resolved="$(realpath "$candidate" 2>/dev/null || printf '%s' "$candidate")"
    printf '%s\n' "$resolved"
  done | /usr/bin/awk '!seen[$0]++'
}

codex_gui_pids() {
  if [[ "$test_mode" == "1" ]]; then
    [[ -f "$codex_root/test-host.running" ]] && printf '9000\n'
    return 0
  fi
  local pid=""
  local command=""
  while read -r pid command; do
    [[ -n "$pid" ]] || continue
    case "$command" in
      "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT"*|"$HOME/Applications/ChatGPT.app/Contents/MacOS/ChatGPT"*|"/Applications/Codex.app/Contents/MacOS/Codex"*|"$HOME/Applications/Codex.app/Contents/MacOS/Codex"*)
        printf '%s\n' "$pid"
        ;;
    esac
  done < <(/bin/ps ax -o pid=,command= 2>/dev/null || true)
}

agenthall_mcp_pids() {
  if [[ "$test_mode" == "1" ]]; then
    if [[ -f "$codex_root/test-current-runtime.running" || -f "$codex_root/test-backup-runtime.running" || -f "$codex_root/test-stale-runtime.running" || -f "$codex_root/test-personal-runtime.running" ]]; then
      printf '9002\n'
    fi
    return 0
  fi
  local pid=""
  local command=""
  local cwd=""
  while read -r pid command; do
    [[ -n "$pid" ]] || continue
    [[ "$command" == *"node ./mcp/server.cjs"* ]] || continue
    cwd="$(/usr/sbin/lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | /usr/bin/awk '/^n/{sub(/^n/,""); print; exit}')"
    case "$cwd" in
      "$codex_root"/plugins/cache/*/agenthall/*|"$codex_root"/.tmp/marketplaces/*/plugins/agenthall|"$codex_root"/.tmp/marketplaces/*/plugins/agenthall/*)
        printf '%s\n' "$pid"
        ;;
      *)
        if [[ -f "$cwd/.codex-plugin/plugin.json" ]] && AGENTHALL_RUNTIME_ROOT="$cwd" "$json_node" -e '
const fs = require("node:fs");
const path = require("node:path");
try {
  const manifest = JSON.parse(fs.readFileSync(path.join(process.env.AGENTHALL_RUNTIME_ROOT, ".codex-plugin/plugin.json"), "utf8"));
  process.exit(manifest.name === "agenthall" ? 0 : 1);
} catch {
  process.exit(1);
}' >/dev/null 2>&1; then
          printf '%s\n' "$pid"
        fi
        ;;
    esac
  done < <(/bin/ps ax -o pid=,command= 2>/dev/null || true)
}

host_is_running() {
  host_gui_is_running && return 0
  [[ -n "$(codex_app_server_pids)" ]] && return 0
  [[ -n "$(agenthall_mcp_pids)" ]]
}

record_test_event() {
  if [[ "$test_mode" == "1" ]]; then
    printf '%s\n' "$1" >>"$codex_root/test-events.log"
  fi
}

request_host_quit() {
  record_test_event "host_quit_requested"
  if [[ "$test_mode" == "1" ]]; then
    if [[ "${AGENTHALL_TEST_GUI_SURVIVES_QUIT:-0}" != "1" ]]; then
      rm -f "$codex_root/test-host.running"
    fi
    if [[ "${AGENTHALL_TEST_HOST_TREE_SURVIVES_QUIT:-0}" != "1" ]]; then
      rm -f \
        "$codex_root/test-app-server.running" \
        "$codex_root/test-current-runtime.running" \
        "$codex_root/test-backup-runtime.running" \
        "$codex_root/test-stale-runtime.running" \
        "$codex_root/test-personal-runtime.running"
    fi
  else
    /usr/bin/osascript -e 'tell application id "com.openai.codex" to quit'
  fi
}

terminate_exact_host_tree() {
  record_test_event "exact_host_tree_termination_requested"
  if [[ "$test_mode" == "1" ]]; then
    [[ "${AGENTHALL_TEST_HOST_TREE_UNOWNED:-0}" != "1" ]] || return 1
    rm -f \
      "$codex_root/test-host.running" \
      "$codex_root/test-app-server.running" \
      "$codex_root/test-current-runtime.running" \
      "$codex_root/test-backup-runtime.running" \
      "$codex_root/test-stale-runtime.running" \
      "$codex_root/test-personal-runtime.running"
    return 0
  fi

  local app_servers=""
  local gui_pids=""
  local mcp_pids=""
  local pid=""
  local ppid=""
  local mcp_started=""
  local observed_started=""
  app_servers="$(codex_app_server_pids)"
  gui_pids="$(codex_gui_pids)"
  mcp_pids="$(agenthall_mcp_pids)"

  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    mcp_started="$(process_start_fingerprint "$pid" || true)"
    [[ -n "$mcp_started" ]] || continue
    ppid="$(/bin/ps -p "$pid" -o ppid= 2>/dev/null | /usr/bin/tr -d ' ' || true)"
    if ! pid_list_contains "$app_servers" "$ppid"; then
      observed_started="$(process_start_fingerprint "$pid" || true)"
      [[ -z "$observed_started" || "$observed_started" != "$mcp_started" ]] && continue
      printf 'An active AgentHall runtime was not owned by a trusted Codex app-server.\n' >&2
      return 1
    fi
  done <<<"$mcp_pids"
  [[ -n "$app_servers" || -z "$mcp_pids" ]] || return 1
  terminate_pid_lines "$mcp_pids"
  terminate_pid_lines "$app_servers"
  terminate_pid_lines "$gui_pids"
}

pid_list_contains() {
  local lines="$1"
  local expected="$2"
  [[ -n "$expected" && $'\n'"$lines"$'\n' == *$'\n'"$expected"$'\n'* ]]
}

terminate_pid_lines() {
  local lines="$1"
  local pid=""
  local started=""
  local observed_started=""
  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    started="$(process_start_fingerprint "$pid" || true)"
    [[ -n "$started" ]] || continue
    if ! /bin/kill -TERM "$pid" 2>/dev/null; then
      observed_started="$(process_start_fingerprint "$pid" || true)"
      if [[ -n "$observed_started" && "$observed_started" == "$started" ]]; then
        printf 'A trusted Codex process remained alive after TERM.\n' >&2
        return 1
      fi
    fi
  done <<<"$lines"
}

stop_host_tree() {
  host_is_running || return 0
  request_host_quit
  if wait_for_host_state stopped; then
    return 0
  fi
  terminate_exact_host_tree || return 1
  wait_for_host_state stopped
}

launch_host() {
  local workspace="$1"
  record_test_event "host_launch_requested"
  if [[ "$test_mode" == "1" ]]; then
    : >"$codex_root/test-host.running"
    : >"$codex_root/test-app-server.running"
    if [[ "${AGENTHALL_TEST_BACKUP_RUNTIME_ALWAYS:-0}" == "1" || ("${AGENTHALL_TEST_BACKUP_RUNTIME_ON_FIRST_LAUNCH:-0}" == "1" && ! -f "$codex_root/test-host-launched-once") ]]; then
      : >"$codex_root/test-host-launched-once"
      : >"$codex_root/test-backup-runtime.running"
    else
      rm -f "$codex_root/test-backup-runtime.running"
      if [[ "${AGENTHALL_TEST_LAZY_RUNTIME_ON_LAUNCH:-0}" == "1" ]]; then
        rm -f "$codex_root/test-current-runtime.running"
      else
        : >"$codex_root/test-current-runtime.running"
      fi
    fi
    if [[ "${AGENTHALL_TEST_STALE_RUNTIME_ON_LAUNCH:-0}" == "1" ]]; then
      : >"$codex_root/test-stale-runtime.running"
    fi
  else
    "$codex_bin" app "$workspace" >/dev/null 2>&1
  fi
}

wait_for_host_state() {
  local wanted="$1"
  local attempts=0
  local limit=30
  [[ "$test_mode" != "1" ]] || limit=1
  while ((attempts < limit)); do
    if [[ "$wanted" == "stopped" ]] && ! host_is_running; then
      return 0
    fi
    if [[ "$wanted" == "running" ]] && host_is_running; then
      return 0
    fi
    [[ "$test_mode" == "1" ]] || /bin/sleep 1
    attempts=$((attempts + 1))
  done
  return 1
}

agenthall_runtime_state() {
  if [[ "$test_mode" == "1" ]]; then
    if [[ -f "$codex_root/test-backup-runtime.running" ]]; then
      printf 'backup\n'
    elif [[ -f "$codex_root/test-stale-runtime.running" || -f "$codex_root/test-personal-runtime.running" ]]; then
      printf 'stale\n'
    elif [[ -f "$codex_root/test-current-runtime.running" && -f "$codex_root/test-app-server.running" ]]; then
      printf 'current\n'
    elif host_is_running; then
      printf 'absent\n'
    else
      printf 'absent\n'
    fi
    return 0
  fi

  local current_found=0
  local invalid_found=0
  local pid=""
  local cwd=""
  local ppid=""
  local app_servers=""
  app_servers="$(codex_app_server_pids)"
  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    cwd="$(/usr/sbin/lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | /usr/bin/awk '/^n/{sub(/^n/,""); print; exit}')"
    case "$cwd" in
      "$codex_root"/plugins/cache/agenthall/plugin-backup-*/*)
        printf 'backup\n'
        return 0
        ;;
      "$codex_root"/plugins/cache/agenthall/agenthall/"$release_version")
        ppid="$(/bin/ps -p "$pid" -o ppid= 2>/dev/null | /usr/bin/tr -d ' ' || true)"
        if [[ $'\n'"$app_servers"$'\n' == *$'\n'"$ppid"$'\n'* ]]; then
          current_found=$((current_found + 1))
        else
          invalid_found=1
        fi
        ;;
      *) invalid_found=1 ;;
    esac
  done < <(agenthall_mcp_pids)

  if [[ "$invalid_found" == "1" ]]; then
    printf 'stale\n'
  elif ((current_found > 0)); then
    printf 'current\n'
  else
    printf 'absent\n'
  fi
}

log_runtime_observation() {
  local stage="$1"
  local state="$2"
  local app_servers=""
  local app_server_summary="none"
  local pid=""
  local ppid=""
  local cwd=""
  local display_cwd=""

  app_servers="$(codex_app_server_pids)"
  if [[ -n "$app_servers" ]]; then
    app_server_summary="$(printf '%s\n' "$app_servers" | /usr/bin/awk 'NF { if (out != "") out = out ","; out = out $0 } END { print out }')"
  fi
  printf 'AgentHall runtime observation: stage=%s state=%s app_server_pids=%s\n' \
    "$stage" "$state" "$app_server_summary"
  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    ppid="$(/bin/ps -p "$pid" -o ppid= 2>/dev/null | /usr/bin/tr -d ' ' || true)"
    if [[ "$test_mode" == "1" ]]; then
      cwd="test-runtime"
    else
      cwd="$(/usr/sbin/lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | /usr/bin/awk '/^n/{sub(/^n/,""); print; exit}')"
    fi
    display_cwd="${cwd/#$HOME/\$HOME}"
    printf 'AgentHall runtime process: stage=%s pid=%s ppid=%s cwd=%s\n' \
      "$stage" "$pid" "${ppid:-unknown}" "${display_cwd:-unknown}"
  done < <(agenthall_mcp_pids)
}

verify_agenthall_runtime_via_app_server() {
  record_test_event "app_server_runtime_probe_requested"
  if [[ "$test_mode" == "1" ]]; then
    local simulated="${AGENTHALL_TEST_RUNTIME_PROBE_RESULT:-current}"
    if [[ "$simulated" == "current" ]]; then
      record_test_event "app_server_runtime_probe_verified"
      printf 'AgentHall app-server probe: state=current version=%s resource=ui://agenthall/sidebar-v%s.html\n' \
        "$release_version" "$release_version"
      return 0
    fi
    record_test_event "app_server_runtime_probe_failed:$simulated"
    printf 'AgentHall app-server probe: state=%s\n' "$simulated" >&2
    return 1
  fi

  AGENTHALL_EXPECTED_RELEASE_VERSION="$release_version" \
    AGENTHALL_EXPECTED_SIDEBAR_SHA256="$expected_sidebar_sha" \
    "$json_node" - "$codex_bin" <<'NODE'
const { createHash } = require("node:crypto");
const { spawn } = require("node:child_process");
const readline = require("node:readline");

const codex = process.argv[2];
const expectedVersion = process.env.AGENTHALL_EXPECTED_RELEASE_VERSION;
const expectedSha256 = process.env.AGENTHALL_EXPECTED_SIDEBAR_SHA256;
const expectedUri = `ui://agenthall/sidebar-v${expectedVersion}.html`;
const child = spawn(codex, ["app-server", "--listen", "stdio://"], {
  cwd: process.cwd(),
  env: process.env,
  stdio: ["pipe", "pipe", "pipe"],
});
const pending = new Map();
let nextId = 1;
let closed = false;
let stderrSeen = false;

function failPending(category) {
  for (const waiter of pending.values()) {
    clearTimeout(waiter.timeout);
    waiter.reject(new Error(category));
  }
  pending.clear();
}

readline.createInterface({ input: child.stdout }).on("line", (line) => {
  let message;
  try {
    message = JSON.parse(line);
  } catch {
    return;
  }
  if (message.id == null || !pending.has(message.id)) return;
  const waiter = pending.get(message.id);
  pending.delete(message.id);
  clearTimeout(waiter.timeout);
  if (message.error) {
    const error = new Error(message.error.message || "rpc_error");
    error.code = message.error.code;
    waiter.reject(error);
  } else {
    waiter.resolve(message.result);
  }
});
readline.createInterface({ input: child.stderr }).on("line", (line) => {
  if (line.trim()) stderrSeen = true;
});
child.once("error", () => failPending("app_server_spawn_failed"));
child.once("exit", () => {
  closed = true;
  failPending("app_server_closed");
});

function send(message) {
  child.stdin.write(`${JSON.stringify(message)}\n`);
}

function request(method, params, timeoutMs) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`${method}_timeout`));
    }, timeoutMs);
    pending.set(id, { resolve, reject, timeout });
    send({ id, method, ...(params === undefined ? {} : { params }) });
  });
}

async function listAgentHall() {
  let cursor = null;
  for (let page = 0; page < 10; page += 1) {
    const response = await request(
      "mcpServerStatus/list",
      { detail: "full", limit: 100, ...(cursor ? { cursor } : {}) },
      60_000,
    );
    const match = (response?.data || []).find((entry) => entry?.name === "agenthall");
    if (match) return match;
    cursor = response?.nextCursor || null;
    if (!cursor) break;
  }
  throw new Error("agenthall_server_missing");
}

(async () => {
  let reloadState = "supported";
  try {
    await request(
      "initialize",
      {
        clientInfo: {
          name: "agenthall-installer-runtime-probe",
          title: "AgentHall installer runtime probe",
          version: expectedVersion,
        },
        capabilities: { experimentalApi: false },
      },
      20_000,
    );
    send({ method: "initialized", params: {} });
    try {
      await request("config/mcpServer/reload", null, 45_000);
    } catch {
      reloadState = "unavailable";
    }
    const server = await listAgentHall();
    if (server?.serverInfo?.version !== expectedVersion) {
      throw new Error("version_mismatch");
    }
    if (!server.tools || Object.keys(server.tools).length === 0) {
      throw new Error("tool_catalog_empty");
    }
    const resource = (server.resources || []).find(
      (entry) => entry?.uri === expectedUri,
    );
    if (!resource) throw new Error("sidebar_resource_missing");
    const read = await request(
      "mcpServer/resource/read",
      { server: "agenthall", uri: expectedUri },
      30_000,
    );
    const text = (read?.contents || []).find(
      (entry) => typeof entry?.text === "string",
    )?.text;
    if (typeof text !== "string" || text.length === 0) {
      throw new Error("sidebar_resource_empty");
    }
    const sha256 = createHash("sha256").update(text).digest("hex");
    if (sha256 !== expectedSha256) throw new Error("sidebar_checksum_mismatch");
    process.stdout.write(
      `AgentHall app-server probe: state=current version=${expectedVersion} tools=${Object.keys(server.tools).length} resource=${expectedUri} sha256=${sha256} reload=${reloadState} stderr=${stderrSeen ? "warning" : "none"}\n`,
    );
  } catch (error) {
    process.stderr.write(
      `AgentHall app-server probe: state=failed category=${error instanceof Error ? error.message : "unknown"} stderr=${stderrSeen ? "warning" : "none"}\n`,
    );
    process.exitCode = 1;
  } finally {
    const finalCode = process.exitCode || 0;
    if (!closed) {
      child.stdin.end();
      child.kill("SIGTERM");
    }
    setTimeout(() => process.exit(finalCode), 100);
  }
})();
NODE
  local probe_status=$?
  if [[ "$probe_status" == "0" ]]; then
    record_test_event "app_server_runtime_probe_verified"
    return 0
  fi
  record_test_event "app_server_runtime_probe_failed:rpc"
  return "$probe_status"
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
  "$codex_bin" plugin list --json 2>/dev/null | AGENTHALL_EXPECTED_RELEASE_VERSION="$release_version" "$json_node" -e '
let body = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (body += chunk));
process.stdin.on("end", () => {
  const parsed = JSON.parse(body);
  const matches = (parsed.installed ?? []).filter((item) => item.name === "agenthall");
  const expectedVersion = process.env.AGENTHALL_EXPECTED_RELEASE_VERSION;
  const valid = matches.length === 1 && matches[0].pluginId === "agenthall@agenthall" && matches[0].version === expectedVersion && matches[0].enabled === true;
  process.exit(valid ? 0 : 1);
});'
}

verify_active_cache_layout() {
  local active_root="$codex_root/plugins/cache/agenthall/agenthall"
  local version_path=""
  local count=0
  while IFS= read -r version_path; do
    [[ -n "$version_path" ]] || continue
    count=$((count + 1))
    [[ "$version_path" == "$active_root/$release_version" ]] || return 1
  done < <(find "$active_root" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null || true)
  [[ "$count" == "1" ]] || return 1
  [[ -z "$(find "$codex_root/plugins/cache/agenthall" -type d -name 'plugin-backup-*' -print -quit 2>/dev/null || true)" ]]
}

verify_operation_journals() {
  local connector_root="${AGENTHALL_CREDENTIAL_DIRECTORY:-$HOME/.config/agenthall/connectors}"
  [[ -d "$connector_root" ]] || return 0
  "$json_node" - "$connector_root" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const files = fs.readdirSync(root).filter((name) => name.endsWith(".local-operations.json"));
for (const name of files) {
  const target = path.join(root, name);
  const mode = fs.statSync(target).mode & 0o777;
  if (mode !== 0o600) process.exit(2);
  const store = JSON.parse(fs.readFileSync(target, "utf8"));
  if (store?.version !== 1 || !Array.isArray(store.operations)) process.exit(3);
  const ids = new Set();
  const keys = new Set();
  for (const operation of store.operations) {
    if (operation?.version !== 1 || typeof operation.operationId !== "string" || typeof operation.operationKey !== "string") process.exit(4);
    if (ids.has(operation.operationId) || keys.has(operation.operationKey)) process.exit(5);
    ids.add(operation.operationId);
    keys.add(operation.operationKey);
    const owner = operation.owner;
    if (operation.status === "running") {
      if (!owner || typeof owner.ownerId !== "string" || !Number.isSafeInteger(owner.generation) || owner.generation < 1 || !Number.isFinite(Date.parse(owner.leaseExpiresAt))) process.exit(6);
    } else if (operation.status === "awaiting_ack" || operation.status === "succeeded" || operation.status === "failed") {
      if (owner !== null) process.exit(7);
    }
  }
}
NODE
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

process_start_fingerprint() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  if [[ "$test_mode" == "1" ]]; then
    if [[ "$pid" == "$$" ]]; then
      printf 'test-worker\n'
      return 0
    fi
    if [[ -n "${AGENTHALL_TEST_LIVE_LOCK_PID:-}" && "$pid" == "$AGENTHALL_TEST_LIVE_LOCK_PID" ]]; then
      printf '%s\n' "${AGENTHALL_TEST_LIVE_LOCK_STARTED:-test-live-owner}"
      return 0
    fi
    return 1
  fi
  /bin/ps -p "$pid" -o lstart= 2>/dev/null | /usr/bin/awk '{$1=$1; print}'
}

release_install_lock() {
  local lock_dir="$1"
  rm -f \
    "$lock_dir/owner.pid" \
    "$lock_dir/owner.started" \
    "$lock_dir/mutation-started"
  rmdir "$lock_dir" 2>/dev/null || true
}

acquire_install_lock() {
  local lock_dir="$1"
  local owner_pid=""
  local owner_started=""
  local observed_started=""
  local unexpected=""

  if ! mkdir "$lock_dir" 2>/dev/null; then
    [[ -d "$lock_dir" && ! -L "$lock_dir" ]] || fail "the installer lock is not a safe directory"
    owner_pid="$(cat "$lock_dir/owner.pid" 2>/dev/null || true)"
    owner_started="$(cat "$lock_dir/owner.started" 2>/dev/null || true)"
    observed_started="$(process_start_fingerprint "$owner_pid" || true)"
    if [[ -n "$owner_started" && "$observed_started" == "$owner_started" ]]; then
      fail "another AgentHall installation is already running"
    fi
    [[ ! -e "$lock_dir/mutation-started" ]] ||
      fail "a previous AgentHall installation may have changed plugin state; automatic lock recovery was refused"
    unexpected="$(find "$lock_dir" -mindepth 1 -maxdepth 1 ! -name owner.pid ! -name owner.started -print -quit)"
    [[ -z "$unexpected" ]] || fail "the installer lock contains unexpected state"
    rm -f "$lock_dir/owner.pid" "$lock_dir/owner.started"
    rmdir "$lock_dir" 2>/dev/null || fail "the stale installer lock could not be recovered safely"
    mkdir "$lock_dir" 2>/dev/null || fail "another AgentHall installation acquired the lock"
  fi

  chmod 700 "$lock_dir"
  printf '%s\n' "$$" >"$lock_dir/owner.pid"
  process_start_fingerprint "$$" >"$lock_dir/owner.started"
  chmod 600 "$lock_dir/owner.pid" "$lock_dir/owner.started"
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
  local lock_safe_to_release=1

  mkdir -p "$run_root"
  exec >>"$log_file" 2>&1
  printf 'AgentHall %s one-pass installer started.\n' "$release_version"

  acquire_install_lock "$lock_dir"

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
        if stop_host_tree; then
          restore_previous_install
        else
          printf 'The exact Codex process tree could not be stopped; rollback was not applied over a live runtime.\n' >&2
          lock_safe_to_release=0
        fi
      fi
      if ! host_is_running; then
        launch_host "$workspace" || true
      fi
      if [[ "$test_mode" != "1" ]]; then
        /usr/bin/osascript -e 'display notification "已保留原有安装，请查看安装日志。" with title "AgentHall 安装失败"' || true
      fi
    fi
    if [[ "$lock_safe_to_release" == "1" ]]; then
      release_install_lock "$lock_dir"
    fi
    exit "$exit_code"
  }
  trap finish_worker EXIT

  if [[ -n "$local_marketplace_source" ]]; then
    [[ "$local_marketplace_source" == /* ]] || fail "the internal local marketplace path must be absolute"
    [[ -d "$local_marketplace_source" && ! -L "$local_marketplace_source" ]] || fail "the internal local marketplace path is unavailable"
    if [[ -n "$(find "$local_marketplace_source" -type l -print -quit)" ]]; then
      fail "the internal local marketplace must not contain symbolic links"
    fi
    local_marketplace_source="$(cd "$local_marketplace_source" && pwd -P)"
    cp -Rp "$local_marketplace_source" "$source_checkout"
  elif [[ "$test_mode" == "1" ]]; then
    cp -Rp "${AGENTHALL_TEST_MARKETPLACE_ROOT:?AGENTHALL_TEST_MARKETPLACE_ROOT is required}" "$source_checkout"
  else
    git clone --quiet --depth 1 --branch "$release_tag" "https://github.com/${marketplace_source}.git" "$source_checkout"
  fi
  verify_plugin_tree "$source_checkout/plugins/agenthall"
  record_test_event "target_verified"

  stop_host_tree || fail "the exact Codex process tree could not be stopped safely; no plugin files were changed"
  record_test_event "host_stopped"

  mkdir -p "$backup_root"
  copy_if_present "$codex_root/config.toml" "$backup_root/config.toml"
  copy_if_present "$codex_root/.tmp/marketplaces/agenthall" "$backup_root/marketplace-agenthall"
  copy_if_present "$codex_root/.tmp/plugins.sha" "$backup_root/plugins.sha"
  copy_if_present "$codex_root/plugins/cache/agenthall" "$backup_root/cache-agenthall"
  copy_if_present "$codex_root/plugins/cache/personal/agenthall" "$backup_root/cache-personal-agenthall"
  : >"$lock_dir/mutation-started"
  chmod 600 "$lock_dir/mutation-started"
  mutation_started=1
  record_test_event "mutation_started"

  while IFS= read -r existing_plugin_id; do
    [[ -n "$existing_plugin_id" ]] || continue
    "$codex_bin" plugin remove "$existing_plugin_id" --json >/dev/null
  done < <(installed_agenthall_ids)

  if marketplace_exists; then
    "$codex_bin" plugin marketplace remove "$marketplace_name" --json >/dev/null
  fi
  if [[ -n "$local_marketplace_source" ]]; then
    "$codex_bin" plugin marketplace add "$local_marketplace_source" --json >/dev/null
  else
    "$codex_bin" plugin marketplace add "$marketplace_source" --ref "$release_tag" --json >/dev/null
  fi
  "$codex_bin" plugin add "$plugin_id" --json >/dev/null

  verify_installed_record || fail "Codex did not register exactly one enabled ${release_version} plugin"
  verify_active_cache_layout || fail "Codex active AgentHall cache layout is not immutable and unique"
  verify_plugin_tree "$codex_root/plugins/cache/agenthall/agenthall/$release_version"
  "$json_node" --check "$codex_root/plugins/cache/agenthall/agenthall/$release_version/mcp/server.cjs" >/dev/null
  record_test_event "installed_verified"

  launch_host "$workspace"
  wait_for_host_state running || fail "Codex could not be restarted after installation"
  record_test_event "host_running"

  runtime_state="$(agenthall_runtime_state)"
  log_runtime_observation "before_app_server_probe" "$runtime_state"
  if [[ "$runtime_state" == "backup" || "$runtime_state" == "stale" ]]; then
    record_test_event "invalid_runtime_detected:$runtime_state"
    fail "Codex loaded an invalid AgentHall runtime after installation: ${runtime_state}"
  fi
  verify_agenthall_runtime_via_app_server || fail "Codex app-server could not verify the current ${release_version} AgentHall runtime"
  runtime_state="$(agenthall_runtime_state)"
  log_runtime_observation "after_app_server_probe" "$runtime_state"
  if [[ "$runtime_state" == "backup" || "$runtime_state" == "stale" ]]; then
    record_test_event "invalid_runtime_detected:$runtime_state"
    fail "Codex loaded an invalid AgentHall runtime after active verification: ${runtime_state}"
  fi
  verify_operation_journals || fail "AgentHall local operation journal ownership is invalid"
  record_test_event "current_runtime_verified"

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
  release_install_lock "$lock_dir"
}

if [[ "${1:-}" == "--runtime-probe-only" ]]; then
  [[ $# -eq 1 ]] || fail "invalid Runtime probe invocation"
  runtime_state="$(agenthall_runtime_state)"
  log_runtime_observation "probe_only_before" "$runtime_state"
  [[ "$runtime_state" != "backup" && "$runtime_state" != "stale" ]] ||
    fail "an invalid AgentHall runtime is already active: ${runtime_state}"
  verify_agenthall_runtime_via_app_server ||
    fail "Codex app-server could not verify the current ${release_version} AgentHall runtime"
  runtime_state="$(agenthall_runtime_state)"
  log_runtime_observation "probe_only_after" "$runtime_state"
  [[ "$runtime_state" != "backup" && "$runtime_state" != "stale" ]] ||
    fail "an invalid AgentHall runtime appeared during active verification: ${runtime_state}"
  printf 'AgentHall %s Runtime probe verified.\n' "$release_version"
  exit 0
fi

if [[ "${1:-}" == "--pid-list-self-test" ]]; then
  [[ $# -eq 1 ]] || fail "invalid PID list self-test invocation"
  pid_list_contains $'17\n23' "23" || fail "PID list membership self-test failed"
  if pid_list_contains "" "23"; then
    fail "empty PID list membership self-test failed"
  fi
  terminate_pid_lines ""
  /bin/sleep 30 &
  live_pid=$!
  if process_start_fingerprint "$live_pid" >/dev/null 2>&1; then
    terminate_pid_lines "$live_pid"
    fingerprint_probe="available"
  else
    /bin/kill -TERM "$live_pid"
    fingerprint_probe="sandbox-unavailable"
  fi
  wait "$live_pid" 2>/dev/null || true
  if process_start_fingerprint "$live_pid" >/dev/null 2>&1; then
    fail "live PID termination self-test failed"
  fi
  /usr/bin/true &
  exited_pid=$!
  wait "$exited_pid"
  terminate_pid_lines "$exited_pid"
  printf 'pid_list_compatibility=ok bash=%s fingerprint=%s\n' "${BASH_VERSION}" "$fingerprint_probe"
  exit 0
fi

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
  /usr/bin/nohup /usr/bin/env "PATH=$PATH" /bin/bash "$worker_script" --worker "$workspace" "$log_file" >/dev/null 2>&1 &
  worker_pid=$!
  kill -0 "$worker_pid" 2>/dev/null || fail "one-pass installer worker did not start"
  printf 'AgentHall %s installation started. Codex will close and reopen automatically.\n' "$release_version"
  printf 'Log: %s\n' "$log_file"
fi
