#!/usr/bin/env bash
# agent-rules installer.
#
#   ./install.sh                  interactive menu (fzf if present)
#   ./install.sh global           full user-level rules for every tool detected
#   ./install.sh global-limited   limited user-level rules
#   ./install.sh project [path]   full per-repo rules (default: cwd)
#   ./install.sh project-limited [path] limited per-repo rules
#   ./install.sh build            regenerate both compiled profiles
#   ./install.sh status [path]    what is wired up right now
#   ./install.sh uninstall [path] undo both scopes
#
# profiles/*.list explicitly select sources under rules/. Codex uses a compiled
# artifact; Claude Code and project Antigravity use one symlink per selected source.
# Existing personal rule files and unrelated symlinks are left untouched.
# Global Codex personal text is migrated with a backup before replacing AGENTS.md.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$REPO/rules"
PROFILE=full
RULES="$REPO/generated/AGENTS.md"
GLOBAL_PROFILE="$HOME/.config/agent-rules/profile"
PERSONAL="$HOME/.codex/agent-rules-personal.md"
CODEX_HOOK="$REPO/hooks/codex-session-start.sh"
# Migration: the PostToolUse prose hook this installer used to wire. Kept
# only so an install that already has the entry drops it. Delete once every
# machine has run this version.
STALE_HOOK="$REPO/hooks/check-prose.sh"
STAMP="$(date +%Y%m%d%H%M%S)"
MARK_BEGIN="<!-- >>> agent-rules >>> -->"
MARK_END="<!-- <<< agent-rules <<< -->"
TOML_BEGIN="# >>> agent-rules >>>"
TOML_END="# <<< agent-rules <<<"

CHANGED=0
FORCE_ALL="${AGENT_RULES_ALL:-0}"

say()  { printf '%s\n' "$*"; }
note() { printf '%s\n' "$*" >&2; }
head2(){ printf '\n%s\n' "$*"; }

[ -d "$RULES_DIR" ] || { note "error: $RULES_DIR not found; run this from inside the repo"; exit 1; }

# ------------------------------------------------------------------- build

# Each profile names every source explicitly; unlisted files are never installed.
select_profile() {
  PROFILE="$1"
  case "$PROFILE" in
    full) RULES="$REPO/generated/AGENTS.md" ;;
    limited) RULES="$REPO/generated/AGENTS-limited.md" ;;
    *) note "error: unknown profile: $PROFILE"; return 1 ;;
  esac
}

sources() { cat "$REPO/profiles/$PROFILE.list"; }

render() {
  local f
  printf '%s\n\n' "# Agent rules" \
    'If ~/.codex/agent-rules-personal.md exists, follow its instructions in both profiles; read it only if its full contents are absent from the current context.'
  while IFS= read -r f; do
    cat "$REPO/$f"
  done < <(sources)
}

fresh() {
  local t rc=0
  t="$(mktemp)"; render > "$t"
  cmp -s "$RULES" "$t" || rc=$?
  rm -f "$t"; return "$rc"
}

build() {
  local profile t
  mkdir -p "$REPO/generated"
  for profile in full limited; do
    select_profile "$profile"
    if fresh; then
      say "  ok        $RULES (current)"
    else
      t="$(mktemp)"; render > "$t"
      chmod 644 "$t"
      mv "$t" "$RULES"
      say "  rebuilt   $RULES"
      CHANGED=1
    fi
  done
}

# ---------------------------------------------------------------- primitives

# link <dest> <src>
link() {
  local dest="$1" src="$2" bak new
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    say "  ok        $dest"
    return 0
  fi
  # Stage beside the destination so failed creation leaves its instructions intact.
  new="$(mktemp "$dest.new.XXXXXX")"
  rm "$new"
  if ! ln -s "$src" "$new" 2>/dev/null; then
    note "  FAILED    could not stage link for $dest"
    return 1
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    bak="$(mktemp "$dest.bak-$STAMP.XXXXXX")"
    if cp -Pp "$dest" "$bak" 2>/dev/null; then
      note "  backup    $dest -> $bak"
    else
      rm -f "$new"
      note "  FAILED    could not back up $dest; leaving it untouched"
      return 1
    fi
  fi
  if mv -f "$new" "$dest" 2>/dev/null; then
    say "  linked    $dest"
    CHANGED=1
  else
    rm -f "$new"
    note "  FAILED    could not replace $dest; leaving it untouched"
    return 1
  fi
}

# block <dest> [full|ref|ptr]: replace/insert a managed block in a file that
# already holds your own content, so a symlink would clobber it. Three payloads:
#
#   full  the rules verbatim. Stale until the next run. Nothing uses this now.
#   ref   a one-line `@` include, resolved by the harness before the model runs.
#   ptr   an instruction telling the agent to open the file itself.
#
# ref and ptr both track the source live, so editing rules/*.md and rebuilding
# is enough. No reinstall.
block() {
  local dest="$1" mode="${2:-full}" tmp new bak
  mkdir -p "$(dirname "$dest")" 2>/dev/null || true
  tmp="$(mktemp)"; new="$(mktemp)"
  if [ -f "$dest" ]; then
    # Drop any previous block, then trim trailing blank lines so re-running
    # produces byte-identical output instead of growing the file.
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1} skip==0 {print} $0==e {skip=0}
    ' "$dest" \
    | awk 'NF{last=NR} {line[NR]=$0} END{for(i=1;i<=last;i++) print line[i]}' > "$tmp"
  else
    : > "$tmp"
  fi
  { cat "$tmp"
    [ -s "$tmp" ] && printf '\n'
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' "# Managed by agent-rules install.sh. Edits here are overwritten."
    printf '\n'
    if [ "$mode" = "ref" ]; then
      printf '@%s\n' "$RULES"
    elif [ "$mode" = "ptr" ]; then
      printf '%s\n' "## Rules"
      printf '%s\n' "Follow the rules in this file:"
      printf '%s\n' "$RULES"
      printf '\n'
      printf '%s\n' "Read it only if its full contents are absent from the current context."
      printf '\n'
      printf '%s\n' "It covers prose written for humans: commit messages, PR bodies,"
      printf '%s\n' "code comments, docs and chat replies, plus how to answer and how"
      printf '%s\n' "to treat git history."
    else
      printf '%s\n' "# Source: $RULES"
      printf '\n'
      cat "$RULES"
    fi
    printf '%s\n' "$MARK_END"
  } > "$new"

  if [ -f "$dest" ] && cmp -s "$dest" "$new"; then
    say "  ok        $dest (managed block)"
    rm -f "$tmp" "$new"; return 0
  fi
  if [ -s "${dest:-}" ] 2>/dev/null && [ -f "$dest" ]; then
    bak="$(mktemp "$dest.bak-$STAMP.XXXXXX")"
    cp "$dest" "$bak" && note "  backup    $dest -> $bak"
  fi
  mv "$new" "$dest" && say "  written   $dest (managed block)" && CHANGED=1
  rm -f "$tmp"
}

# codex_hook <config.toml>: managed TOML block registering the SessionStart
# hook. Codex injects the hook's output itself, so the rules cannot be skipped,
# and the hook re-reads the file each session, so `build` is enough.
codex_hook() {
  local dest="$1" tmp new bak command
  mkdir -p "$(dirname "$dest")" 2>/dev/null || true
  tmp="$(mktemp)"; new="$(mktemp)"
  if [ -f "$dest" ]; then
    awk -v b="$TOML_BEGIN" -v e="$TOML_END" '
      $0==b {skip=1} skip==0 {print} $0==e {skip=0}
    ' "$dest" \
    | awk 'NF{last=NR} {line[NR]=$0} END{for(i=1;i<=last;i++) print line[i]}' > "$tmp"
  else
    : > "$tmp"
  fi
  { cat "$tmp"
    [ -s "$tmp" ] && printf '\n'
    printf '%s\n' "$TOML_BEGIN"
    printf '%s\n' "# Managed by agent-rules install.sh. Edits here are overwritten."
    printf '\n'
    printf '%s\n' "[[hooks.SessionStart]]"
    printf '\n'
    printf '%s\n' "[[hooks.SessionStart.hooks]]"
    printf '%s\n' 'type = "command"'
    printf -v command '%q %q' "$CODEX_HOOK" "$RULES"
    command="${command//\\/\\\\}"
    command="${command//\"/\\\"}"
    printf 'command = "%s"\n' "$command"
    printf '%s\n' "timeout = 10"
    printf '%s\n' 'statusMessage = "loading agent rules"'
    printf '%s\n' "additionalContextLimit = 32768"
    printf '%s\n' "$TOML_END"
  } > "$new"

  if [ -f "$dest" ] && cmp -s "$dest" "$new"; then
    say "  ok        $dest (SessionStart hook)"
    rm -f "$tmp" "$new"; return 0
  fi
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    bak="$(mktemp "$dest.bak-$STAMP.XXXXXX")"
    cp "$dest" "$bak" && note "  backup    $dest -> $bak"
  fi
  mv "$new" "$dest" && say "  written   $dest (SessionStart hook)" && CHANGED=1
  rm -f "$tmp"
  say  "              Codex prompts once in the TUI to trust this hook. Until you"
  say  "              accept, it is skipped silently; the AGENTS.md symlink covers"
  say  "              that gap."
}

# Reconcile only links whose targets belong to this checkout's rules directory.
link_rules() {
  local rdir="$1" f old tgt
  mkdir -p "$rdir"
  for old in "$rdir"/*.md; do
    [ -L "$old" ] || continue
    tgt="$(readlink "$old")"
    case "$tgt" in
      "$RULES_DIR"/*)
        if ! sources | grep -Fxq "${tgt#"$REPO/"}"; then
          rm "$old"; say "  removed   $old (excluded from $PROFILE)"; CHANGED=1
        fi ;;
    esac
  done
  while IFS= read -r f; do
    old="$rdir/$(basename "$f")"
    if [ -e "$old" ] || [ -L "$old" ]; then
      if ! owned_rule_link "$old"; then
        say "  kept      $old (not ours)"; continue
      fi
    fi
    link "$old" "$REPO/$f"
  done < <(sources)
}

owned_link() {
  [ -L "$1" ] || return 1
  case "$(readlink "$1")" in
    "$REPO/generated/AGENTS.md"|"$REPO/generated/AGENTS-limited.md") return 0 ;;
    *) return 1 ;;
  esac
}

owned_rule_link() {
  [ -L "$1" ] || return 1
  case "$(readlink "$1")" in "$RULES_DIR"/*) return 0 ;; *) return 1 ;; esac
}

unlink_rules() {
  local f
  for f in "$1"/*.md; do
    [ -L "$f" ] || continue
    case "$(readlink "$f")" in "$RULES_DIR"/*) unlink_ours "$f" ;; esac
  done
}

# Preserve personal text byte for byte outside a validated managed block.
codex_personal() {
  local dest="$HOME/.codex/AGENTS.md" tmp final_newline
  if [ -L "$dest" ]; then
    owned_link "$dest" && return 0
    note "error: $dest is a personal symlink; leaving it untouched"; return 1
  fi
  [ ! -e "$dest" ] || [ -f "$dest" ] || { note "error: $dest is not a file"; return 1; }
  [ -f "$dest" ] || return 0
  tmp="$(mktemp)"
  final_newline="$(tail -c 1 "$dest" | wc -l)"
  if ! awk -v b="$MARK_BEGIN" -v e="$MARK_END" -v nl="$final_newline" '
    $0==b {if (skip || seen) {bad=1; exit}; skip=1; seen=1; next}
    $0==e {if (!skip) {bad=1; exit}; skip=0; next}
    !skip {text=text $0 "\n"; last_kept=NR}
    END {
      if (skip || bad) exit 1
      if (!nl && last_kept==NR && length(text)) text=substr(text, 1, length(text)-1)
      printf "%s", text
    }
  ' "$dest" > "$tmp"; then
    rm "$tmp"; note "error: malformed managed block in $dest; leaving it untouched"; return 1
  fi
  if [ -e "$PERSONAL" ] || [ -L "$PERSONAL" ]; then
    if [ -s "$tmp" ] && ! cmp -s "$tmp" "$PERSONAL"; then
      rm "$tmp"; note "error: personal migration conflicts with $PERSONAL; leaving both files untouched"; return 1
    fi
  elif [ -s "$tmp" ]; then
    mkdir -p "$(dirname "$PERSONAL")"
    (umask 077; cp "$tmp" "$PERSONAL") || { rm -f "$tmp"; return 1; }
  fi
  rm "$tmp"
}

save_profile() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$PROFILE" > "$1"
}

unlink_ours() {
  local dest="$1" tgt
  if [ -L "$dest" ] && case "$(readlink "$dest")" in "$REPO"/*) true ;; *) false ;; esac; then
    rm -f "$dest" && say "  removed   $dest"; CHANGED=1
  elif [ -e "$dest" ]; then
    say "  kept      $dest (not ours)"
  fi
}

unblock() {
  local dest="$1" b="${2:-$MARK_BEGIN}" e="${3:-$MARK_END}" tmp
  [ -f "$dest" ] || return 0
  grep -qF "$b" "$dest" 2>/dev/null || return 0
  tmp="$(mktemp)"
  awk -v b="$b" -v e="$e" '
    $0==b {skip=1} skip==0 {print} $0==e {skip=0}
  ' "$dest" > "$tmp"
  mv "$tmp" "$dest" && say "  cleaned   $dest (managed block removed)"; CHANGED=1
}

# want <dir>: act on a tool only if it looks installed, unless AGENT_RULES_ALL=1
want() { [ "$FORCE_ALL" = "1" ] || [ -d "$1" ]; }

# dir_state <dir>: how many of rules/*.md are linked into <dir>
dir_state() {
  local d="$1" f rp n=0 total=0
  while IFS= read -r f; do
    f="$REPO/$f"
    total=$((total+1))
    rp="$d/$(basename "$f")"
    if [ -L "$rp" ] && [ "$(readlink "$rp")" = "$f" ]; then n=$((n+1)); fi
  done < <(sources)
  if   [ "$n" = "0" ];      then printf -- '-'
  elif [ "$n" = "$total" ]; then printf 'linked (%d)' "$n"
  else printf 'partial (%d/%d)' "$n" "$total"
  fi
}

state() {
  local dest="$1" tgt
  if [ -L "$dest" ]; then
    tgt="$(readlink "$dest")"
    case "$tgt" in
      "$REPO/generated/AGENTS.md") printf 'linked (full)' ;;
      "$REPO/generated/AGENTS-limited.md") printf 'linked (limited)' ;;
      "$REPO"/*) printf 'linked' ;; *) printf 'other link' ;; esac
  elif [ -f "$dest" ] && grep -qF "$MARK_BEGIN" "$dest" 2>/dev/null; then
    printf 'block'
  elif [ -e "$dest" ]; then
    printf 'occupied'
  else
    printf '-'
  fi
}

# ------------------------------------------------------------------- global

do_global() {
  local selected="${1:-full}"
  select_profile "$selected"
  # An override would suppress the requested global symlink.
  if want "$HOME/.codex"; then
    if [ -s "$HOME/.codex/AGENTS.override.md" ]; then
      note "error: AGENTS.override.md suppresses AGENTS.md; leaving global installation untouched"; return 1
    fi
    codex_personal || return 1
  fi
  head2 "Global (user-level): $selected"

  say " Compiled profiles"
  build
  select_profile "$selected"

  if want "$HOME/.claude"; then
    say " Claude Code"
    link_rules "$HOME/.claude/rules"
    unwire_settings "$HOME/.claude/settings.json" "$STALE_HOOK"
  else
    say  " Claude Code  not detected (~/.claude missing); AGENT_RULES_ALL=1 to force"
  fi

  if want "$HOME/.codex"; then
    say " Codex"
    # The trusted hook injects the selected artifact and migrated personal text.
    # The symlink loads the rules even before the hook is trusted.
    codex_hook "$HOME/.codex/config.toml"
    link "$HOME/.codex/AGENTS.md" "$RULES"
  else
    say  " Codex        not detected (~/.codex missing); AGENT_RULES_ALL=1 to force"
  fi

  if want "$HOME/.gemini"; then
    say " Antigravity"
    # Antigravity resolves `@/absolute/path` against the filesystem, so this is
    # a live reference rather than a copy. It never needs a refresh run.
    block "$HOME/.gemini/GEMINI.md" ref
  else
    say  " Antigravity  not detected (~/.gemini missing); AGENT_RULES_ALL=1 to force"
  fi
  save_profile "$GLOBAL_PROFILE"
}

# ------------------------------------------------------------------ project

do_project() {
  local selected="${2:-full}"
  dir="${1:-$PWD}"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || { note "error: no such directory: ${1:-$PWD}"; return 1; }
  head2 "Project: $dir"

  say " Compiled profiles"
  build
  select_profile "$selected"

  say " Claude Code"
  link_rules "$dir/.claude/rules"

  say " Antigravity"
  link_rules "$dir/.agents/rules"
  say  "              set each new rule's activation to \"Always On\" in the Antigravity UI"

  say " Codex"
  if owned_link "$dir/AGENTS.md" || { [ ! -e "$dir/AGENTS.md" ] && [ ! -L "$dir/AGENTS.md" ]; }; then
    link "$dir/AGENTS.md" "$RULES"
  else
    say "  kept      $dir/AGENTS.md (already has its own; not replaced)"
    say  "              Codex has no import syntax; paste the rules in, or rely"
    say  "              on the global install"
  fi
  save_profile "$dir/.agent-rules-profile"
}

unwire_settings() {
  f="$1"; cmd="$2"
  [ -f "$f" ] || return 0
  command -v jq >/dev/null 2>&1 || {
    note "  manual    jq not found; drop the $cmd hook from $f yourself"
    return 0
  }
  jq -e --arg c "$cmd" '
        [ .hooks.PostToolUse[]?.hooks[]?.command ] | index($c) != null
      ' "$f" >/dev/null 2>&1 || return 0
  tmp="$(mktemp)"
  if jq --arg c "$cmd" '
        .hooks.PostToolUse |= ( map(
          .hooks |= map(select(.command != $c))
        ) | map(select((.hooks | length) > 0)) )
        | if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end
        | if (.hooks | length) == 0 then del(.hooks) else . end
      ' "$f" > "$tmp" 2>/dev/null; then
    bak="$(mktemp "$f.bak-$STAMP.XXXXXX")"
    cp "$f" "$bak" && note "  backup    $f -> $bak"
    mv "$tmp" "$f" && say "  updated   $f (hook removed)"; CHANGED=1
  else
    rm -f "$tmp"
    note "  FAILED    could not edit $f. Is it valid JSON?"
  fi
}

# ------------------------------------------------------------------- status

# Infer older installations which predate persisted profile selection.
scope_profile() {
  local marker="$1" agents="$2" rules_dir="$3" extra="${4:-}" f
  if [ -f "$marker" ]; then cat "$marker"; return; fi
  for f in "$agents" "$extra"; do
    [ -f "$f" ] || [ -L "$f" ] || continue
    if owned_link "$f"; then
      case "$(readlink "$f")" in *AGENTS-limited.md) printf limited ;; *) printf full ;; esac
      return
    fi
    if [ -f "$f" ]; then
      if grep -qF "$REPO/generated/AGENTS-limited.md" "$f"; then printf limited; return; fi
      if grep -qF "$REPO/generated/AGENTS.md" "$f"; then printf full; return; fi
    fi
  done
  if owned_rule_link "$rules_dir/25-threads.md"; then printf full
  elif owned_rule_link "$rules_dir/10-writing.md"; then printf unknown
  else printf none
  fi
}

do_status() {
  dir="${1:-$PWD}"
  head2 "Rules source: $RULES_DIR"
  local global=none project=none profile
  global="$(scope_profile "$GLOBAL_PROFILE" "$HOME/.codex/AGENTS.md" "$HOME/.claude/rules" "$HOME/.gemini/GEMINI.md")"
  project="$(scope_profile "$dir/.agent-rules-profile" "$dir/AGENTS.md" "$dir/.claude/rules")"
  say "global: $global"
  say "project: $project"
  if [ "$global" != none ] && [ "$project" != none ] && [ "$global" != "$project" ]; then
    say "WARNING: mixed profiles; global rules still apply in this project"
  fi
  for profile in full limited; do
    select_profile "$profile"
    if fresh; then say "$RULES: current"; else say "$RULES: STALE; run make build"; fi
  done

  printf '\n%-46s %s\n' "PATH" "STATE"
  for p in \
    "$HOME/.claude/rules" \
    "$dir/.claude/rules" \
    "$dir/.agents/rules"
  do
    case "$p" in "$HOME/.claude/rules") profile="$global" ;; *) profile="$project" ;; esac
    case "$profile" in full|limited) select_profile "$profile" ;; *) select_profile full ;; esac
    short="$(printf '%s' "$p" | sed "s|^$HOME/|~/|")/"
    printf '%-46s %s\n' "$short" "$(dir_state "$p")"
  done
  for p in \
    "$HOME/.codex/AGENTS.md" \
    "$HOME/.gemini/GEMINI.md" \
    "$dir/AGENTS.md"
  do
    short="$(printf '%s' "$p" | sed "s|^$HOME/|~/|")"
    printf '%-46s %s\n' "$short" "$(state "$p")"
  done
  short="$(printf '%s' "$HOME/.codex/config.toml" | sed "s|^$HOME/|~/|")"
  if [ -f "$HOME/.codex/config.toml" ] && grep -qF "$TOML_BEGIN" "$HOME/.codex/config.toml" 2>/dev/null; then
    printf '%-46s %s\n' "$short" "hook"
  else
    printf '%-46s %s\n' "$short" "-"
  fi
  printf '\nlinked (n) = all n sources of the selected profile are linked\n'
  printf 'block = managed section inside a bigger file   hook = hook registered\n'
  printf 'occupied = something else is there   - = nothing\n'
}

# ---------------------------------------------------------------- uninstall

do_uninstall() {
  dir="${1:-$PWD}"
  head2 "Removing agent-rules links"
  unlink_rules "$HOME/.claude/rules"
  if owned_link "$HOME/.codex/AGENTS.md"; then
    unlink_ours "$HOME/.codex/AGENTS.md"
    if [ -f "$PERSONAL" ]; then cp -p "$PERSONAL" "$HOME/.codex/AGENTS.md"; fi
  elif [ ! -L "$HOME/.codex/AGENTS.md" ]; then
    unblock "$HOME/.codex/AGENTS.md"
  fi
  unblock     "$HOME/.codex/config.toml" "$TOML_BEGIN" "$TOML_END"
  unblock     "$HOME/.gemini/GEMINI.md"
  unlink_rules "$dir/.claude/rules"
  unlink_ours "$dir/.claude/hooks/check-prose.sh"
  unlink_ours "$dir/.claude/hooks/prose-patterns.txt"
  unlink_rules "$dir/.agents/rules"
  if owned_link "$dir/AGENTS.md"; then unlink_ours "$dir/AGENTS.md"; fi
  unwire_settings "$HOME/.claude/settings.json" "$STALE_HOOK"
  say  "project settings.json hook entry left in place; remove it by hand if you want it gone"
  rm -f "$GLOBAL_PROFILE" "$dir/.agent-rules-profile"
  say  "backups (*.bak-*) and migrated personal instructions are never deleted"
}

# ---------------------------------------------------------------- interactive

menu() {
  opts="global	wire full user-level rules for every tool detected
global-limited	wire limited user-level rules
project	wire full project rules
project-limited	wire limited project rules
build	regenerate both compiled profiles
status	show what is wired up right now
uninstall	remove every link this installer made"

  if command -v fzf >/dev/null 2>&1; then
    pick="$(printf '%s\n' "$opts" | fzf --height 40% --reverse --with-nth=1,2 \
              --delimiter='\t' --prompt='agent-rules > ' \
              --header='enter to run, esc to cancel' | cut -f1)"
  else
    say "fzf not found; falling back to a numbered prompt."
    PS3="choose > "
    select pick in global global-limited project project-limited build status uninstall quit; do
      [ -n "${pick:-}" ] && break
    done
    [ "${pick:-quit}" = "quit" ] && pick=""
  fi

  [ -n "${pick:-}" ] || { say "nothing to do"; return 0; }
  case "$pick" in
    build) head2 "Compiled profiles"; build ;;
    project-limited)
      printf 'path [%s]: ' "$PWD"; read -r ans
      do_project "${ans:-$PWD}" limited ;;
    global-limited) do_global limited ;;
    project|status|uninstall)
      printf 'path [%s]: ' "$PWD"
      read -r ans
      target="${ans:-$PWD}"
      "do_$pick" "$target"
      ;;
    global) do_global ;;
  esac
}

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  global)     do_global full ;;
  global-limited) do_global limited ;;
  project)    do_project "${2:-$PWD}" full ;;
  project-limited) do_project "${2:-$PWD}" limited ;;
  build)      head2 "Compiled profiles"; build ;;
  status)     do_status  "${2:-$PWD}" ;;
  uninstall)  do_uninstall "${2:-$PWD}" ;;
  -h|--help|help) usage ;;
  "")         menu ;;
  *)          note "unknown command: $1"; usage; exit 2 ;;
esac

if [ "$CHANGED" = "1" ]; then say ""; fi
exit 0
