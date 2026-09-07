# Where the prose hook is wired

Topic: the writing rules apply everywhere, the hook enforcing them only ran in wired repos
Status: decided 2026-09-07
Opened: 2026-09-07

## 2026-09-07

q: Should `install.sh global` wire the prose hook, not just `install.sh project`
a: yes, `~/.claude/settings.json` gets a PostToolUse entry alongside the rule symlinks
why: the rule it enforces is global, and the hook already fails open on jq, unreadable files and bad payloads
alt: leave it per-project — most repos get the rules with no check at all

q: Which path does the global entry call
a: `hooks/check-prose.sh` in this repo, absolute
why: `$CLAUDE_PROJECT_DIR/.claude/hooks/` does not exist in repos that were never wired per-project
alt: link the script into `~/.claude/hooks/` first — a second copy to keep pointing at the right patterns file

q: What happens in a repo wired at both scopes
a: nothing is done about it, the check runs twice and reports the same lines
why: the two entries live in different settings files and neither install can see the other
alt: have `project` skip the entry when the global one exists — couples the two scopes to save one duplicate message

q: Does `uninstall` remove the global entry
a: yes, and it leaves the project one
why: the global entry names an absolute path into this repo so nothing else can own it, while a project entry may be committed and shared

q: Does the global wiring stay once the prose check ships as a plugin
a: no, it comes out when MihaiBojin/agent-plugins#12 lands, and stays until then
why: no plugin exists yet, and without it the check runs only in repos wired with `install.sh project`
alt: leave the check project-only until the plugin exists — most repos go unchecked in the meantime
