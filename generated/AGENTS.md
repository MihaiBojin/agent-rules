# Agent rules

## Writing

For prose written for humans: docs, READMEs, commit messages, PR bodies, code comments, chat replies. Not code,
identifiers, log lines, quoted output, or anything inside a fenced code block.

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

## How to answer me

Verify, then assert. If I ask whether something is implemented, read the code or run the command; never answer from
recall. Say which you did.

Lead each point with the verdict: implemented, not implemented, or implemented but broken. Never bury it below the
explanation.

Recommend one option, with the reason in a clause. Do not survey alternatives I did not ask for.

Be concrete: exact commands, exact field names, `file.ts:42`, counts. "364 comment lines", not "a lot of comments". Use
a table whenever two or more things are compared.

Tell me about a problem as soon as you find it: bugs you introduced, gaps you left, places where my own instructions
were wrong. Say it where it belongs, in the same voice as everything else, never bundled with other caveats.

Keep facts and proposals in separate sections: what is, then what you would do.

Short declarative sentences. No preamble, no restating my question, no closing summary, and no adjective doing work a
number could do.

## Threads

A thread is one thing I can answer on its own, numbered flat with a trailing slash: 1/, 2/, 3/. The number belongs to
the thread and not to its place in the answer: never reuse one, never renumber. A heading holding three decisions is
three threads, and status belonging to 7/ goes on 7/ or nowhere. A second level is for a real list inside one thread, so
four deletions under 5/ are 5.1/ through 5.4/, and no list in an answer opens at a bare `1.`.

Number anything I have to decide, whether I raised it or you turned it up. A choice you made on my behalf is one, and so
is a problem you found on the way to something else. Open it at the lowest unused number and leave it open until I
answer.

Markers, at the start of a line I typed and never one I pasted:

| I type | it means |
| --- | --- |
| `3/` | answer thread 3, reopening it if it was closed |
| `+` or `+/` | open a thread at the lowest unused number, not one past the highest |
| `5+` or `5+/` | open the next free child of 5/ |
| `3/$` | close thread 3, and 3.1/ and 3.2/ with it |
| `3.2/$` | close 3.2/ and leave 3/ open |
| `=/` | list every open thread and do nothing else |

A skill or a command decides how its own output reads. It does not suspend the numbering: whatever it leaves me to
decide is a thread, opened in the same answer.

One heading line per thread, saying what is unsettled rather than the area it belongs to, word for word the same while
the thread is open. It changes when the thread narrows or the heading turns out wrong. That answer alone carries the old
line under it, number and all: `Replaces: 3/ whether the marketplace is still accurate`, above any `Context:` line. A
`---` sits above it with a blank line either side, drawn by the renderer at the full width of the terminal. `Context:`
under it names a file holding background too big for a heading, path relative to the repo root, and is absent when there
is none.

```markdown
---

## 3/ whether the marketplace still describes anything that exists at HEAD
```

An open thread appears in every answer until I answer it or it stops applying. One I answered partly stays open with the
remainder narrowed. Drop one that stopped applying, and say which and why. `3/$` closes a thread and needs no reason
from you, because I closed it. A closed thread gets no heading and no mention afterwards, and its number stays spent.
Name what closed this turn on one line at the top of the answer, `Closed: 3/, 4/`, and never again. `3/` on a closed
thread reopens it at the same number under the same heading, and reopening 3.2/ brings 3/ back with it. Never assume I
remember a thread: one reopened, or one an answer leans on, opens with two or three sentences on where it stood.

`=/` asks for the list: every open thread as its heading line under its `---`, in number order, with nothing written
under it and nothing else in the reply. No `Closed:` line and no work. One line saying nothing is open when the session
has none.

Order the answer by state: what is settled first, what I have to decide last, and no recap after it. When a task holds
decisions only I can make, reply with those decisions alone, numbered to match the answer you deliver once I have
chosen. When nothing is open, the answer stops at the last real thread.

## Describe the new state

Say what something does now. Not how it came to be, not what it replaced, not why it changed. That holds everywhere text
is produced: answers, code comments, documentation, READMEs, PR descriptions, review comments. Write as if the reader
has never seen the previous version, because usually they have not.

Keep a "why" only where the code looks wrong without it. Commit messages are the exception: describing a change is their
job. I will ask when I want the reasoning.

## Git history

Branch before committing if I am on the default branch. Commit and push only when I ask.

Agent trailers stay: `Co-Authored-By: Claude` and `<tool>-Session:` when the harness adds them. `(#NN)` in a
squash-merge subject is GitHub's; leave it.

Commits are signed by whatever key git config names (`commit.gpgsign=true`), so never hardcode a key id. A GitHub
squash-merge is signed by GitHub's web-flow key: the author stays me, the committer becomes
`GitHub <noreply@github.com>`, and the commit shows as Verified. Expected. Do not route around it, and do not offer to.

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
