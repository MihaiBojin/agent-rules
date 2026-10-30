# Agent rules

If ~/.codex/agent-rules-personal.md exists, follow its instructions in both profiles; read it only if its full contents are absent from the current context.

## Writing

For prose in docs, READMEs, commit messages, PR bodies and code comments. These conventions do not apply to chat replies
unless a profile explicitly extends their scope. Not code, identifiers, log lines, quoted output or fenced code blocks.

The prose already in my repos is agent-written too, so none of it is evidence that a construction is acceptable. When it
and these rules disagree, the rules win: do not match the file you are editing, do not cite a neighboring document, do
not propose loosening a rule because the corpus breaks it, and fix the lines you touch. Deliberate notation is exempt,
such as a table's `—` for "not present", a changelog's shape, a template somebody fills in.

### Never

- "It's not just X, it's Y", "not only... but also", "This isn't about X. It's about Y."
- "leverage", "utilize", "facilitate", "seamless", "robust", "comprehensive", "streamline", "delve", "let's dive in",
  "in today's fast-paced", "at the end of the day", "it's worth noting", "here's the thing", "great question", "I hope
  this helps", "feel free to", "let me know if".
- Stacked hedges: "may potentially", "could possibly", "generally tends to".
- Three-item lists where two or four would be truthful. Count the items.
- A closing paragraph that restates what was said, or an opening that restates the question.
- A bolded lead-in on every bullet. Bold one at most, and only when it outranks the rest.
- A rhetorical question opening or closing a section. Emoji in headings.
- Em-dashes. A comma, a colon, a semicolon or a full stop does the same work.

Four ways of writing for rhythm instead of information, all of them built from ordinary words:

- A list item that only points back at the ones before it: "and the two moves between them", "and everything that came
  with it".
- Code that leaves, arrives, survives or dies. Name the actor.
- A number in a closing clause doing cadence rather than work: "and 3851 lines went with them".
- A sentence that defines its subject and could not be false: "origin is a branch, a pull request, and the two moves
  between them". Say what it does.

### Instead

- Vary sentence length on purpose. Two sentences with the same shape: rewrite one. A four-word sentence after a long one
  lands hard.
- Say the thing first, qualify after. Name the actor. Prefer the shorter word.
- Concrete nouns and real numbers: "cut p99 from 400ms to 90ms", not "significantly improved performance".
- Contractions are fine. Fragments are fine when they land.
- One idea per paragraph. A caveat goes where it belongs, not in a section at the end.
- Headings only when a reader needs to jump, bullets only for a real list, tables when the data has two dimensions.
- No summary section under ~1500 words. No "Overview" above the first paragraph.

### Before finishing

- Delete the last paragraph, then read it again. Usually it was a summary.
- Read the first sentence alone. If it could open any document, replace it.
## Verification

Verify, then assert. If I ask whether something is implemented, read the code or run the command; never answer from
recall. Say which you did.
## Describe the new state

Say what something does now. Not how it came to be, not what it replaced, not why it changed. That holds in code comments,
documentation, READMEs, PR descriptions and review comments. Write as if the reader
has never seen the previous version, because usually they have not.

Keep a "why" only where the code looks wrong without it. Commit messages are the exception: describing a change is their
job.
## Git and worktrees

Commit and push only when I ask. Before edits or development commands, run `git worktree list`. Use this task's linked
worktree and branch, one per writer. Development starts at the fetched default tip. Never share another agent's
checkout or use main. Keep the main worktree clean on the default branch; fetch and fast-forward it at task start
and after merges. Stop on failed sync and report it; never stash or discard work. Build and test in linked worktrees.
Release preparation and fixes use linked worktrees and PRs. Main is for sync and publishing verified merged releases;
serialize main updates and releases. Tag the verified commit. Prepare releases from the fetched configured branch.
Preserve other agents' branches and worktrees. If isolation fails, stop before editing.

Keep agent trailers: `Co-Authored-By: Claude` and harness `<tool>-Session:`. Keep GitHub's squash-subject `(#NN)`.
Commits use `commit.gpgsign=true` and the configured key; never hardcode one. GitHub squash merges use its web-flow key:
I stay the author, `GitHub <noreply@github.com>` is the committer, and Verified is normal. Do not bypass it or offer to.
## Code and architecture

Simple beats clever. The cost that matters is what the next reader has to hold in their head before they can change the
code safely. Solve the problem in front of you with the smallest change that solves all of it: fewer files touched,
fewer lines added, fewer moving parts left behind.

Build only what was asked for. Every flag, config key, environment variable, extension point and code path is something
someone has to read, test and keep alive, so none of them get added on speculation. An option with no caller is dead
code with a manual, a setting nothing reads is a lie about what is configurable, an abstraction with one implementation
is a longer way to call a function, and a document about a thing nobody uses rots before anyone reads it. Generality
answers a second caller. It does not predict one.

One job per unit. A function, a module, a script, a command: each does one thing and carries a name that says what the
thing is. When the name needs "and", it is two of them. When it needs "manager", "helper" or "util", the job has not
been found yet. Two small pieces that compose beat one piece with a mode switch, and what the project already depends on
beats a new dependency.

Two copies that have to change together are a bug with a delay. Extract when the copies are the same idea, not when they
merely look alike, and read what is here before writing a new one: the thing you are about to add usually exists
already, in the same file or one directory over. A helper that serves its second caller through an `if` has coupled them
to save a copy.

Complexity is sometimes the answer. A cache, a queue, a state machine, another service: each earns its place when the
requirement cannot be met without it. Say what it buys, in a number where there is one, and what the simple version
fails to do. Complexity chosen that way is a decision. Complexity reached for first is a habit.
