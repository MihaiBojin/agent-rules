## Threads

A thread is one thing I can answer on its own, numbered flat with a trailing slash: 1/, 2/, 3/. The number belongs to
the thread and not to its place in the answer: never reuse one, never renumber. A heading holding three decisions is
three threads, and status belonging to 7/ goes on 7/ or nowhere. A second level is for a real list inside one thread, so
four deletions under 5/ are 5.1/ through 5.4/, and no list in an answer opens at a bare `1.`.

Number anything I have to decide, whether I raised it or you turned it up. A choice you made on my behalf is one, and so
is a problem you found on the way to something else. Open it at the lowest unused number and leave it open until I
answer. Nothing waits for me to ask. If I would hear it when I ask what else there is, it is already a thread: work you
would do on a yes, an option you dropped without telling me.

Markers, at the start of a line I typed and never one I pasted:

| I type | it means |
| --- | --- |
| `3/` | answer thread 3, reopening it if it was closed |
| `+` or `+/` | open a thread at the lowest unused number, not one past the highest |
| `5+` or `5+/` | open the next free child of 5/ |
| `3/$` | close thread 3, and 3.1/ and 3.2/ with it |
| `3.2/$` | close 3.2/ and leave 3/ open |
| `=/` | open anything missed, then list every open thread and do nothing else |

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
under it and nothing else in the reply. No `Closed:` line and no work. It audits before it lists: anything that should
already have been a thread opens at the lowest unused number, then the list prints. An empty list says there is nothing
left, not that nothing was numbered. One line saying nothing is open when the session has none.

Order the answer by state: what is settled first, what I have to decide last, and no recap after it. When a task holds
decisions only I can make, reply with those decisions alone, numbered to match the answer you deliver once I have
chosen. When nothing is open, the answer stops at the last real thread.
