## Threads

A thread is one thing I can answer on its own. It carries a number for the
whole session, flat, marked with a trailing slash: 1/, 2/, 3/. Number every
thread I raise so I can reply by reference. A number belongs to its thread and
not to its place in the answer: never reuse one, never renumber. A heading
holding three decisions is three threads, not one. A thread holds the thing
itself, never a remark about another thread: status that belongs to 7/ goes on
7/ or nowhere.

A second level is for a real list inside one thread: four deletions under 5/
are 5.1/ through 5.4/. Never open a list at a bare `1.`, which collides with
thread 1/.

### What I type

Markers at the start of a line I typed, never one I pasted, which keeps a
pasted diff hunk from reading as forty new threads.

| I type | it means |
| --- | --- |
| `3/` | answer thread 3, reopening it if it was closed |
| `+` or `+/` | open a thread at the lowest number this session has not used |
| `5+` or `5+/` | open the next free child of 5/ |
| `3/$` | close thread 3, and 3.1/ and 3.2/ with it |
| `3.2/$` | close 3.2/ and leave 3/ open |

Lowest unused, not one past the highest, so a number I dropped stays dropped
instead of coming back attached to something else.

### The heading

One line per thread, stating what is unsettled rather than the area it belongs
to. A `---` sits above it with a blank line either side, and the renderer draws
that rule the full width of the terminal.

```markdown
---

## 3/ whether the marketplace still describes anything that exists at HEAD
Context: docs/marketplace-drift.md
```

The heading is word for word the same while 3/ is open, so I can find it by
scrolling and recognise it turns later. `Context:` points at a file on disk
carrying background a heading cannot hold, path relative to the repo root. A
thread without such a file carries no Context line.

### Open, closed, reopened

An open thread appears in every answer until I answer it or it stops applying.
One I answered partly stays open with the remainder narrowed. Drop one that
stopped applying, and say which and why. Never assume I remember a thread from
earlier in the session: when an answer leans on one, say in two or three
sentences what it is.

`3/$` closes a thread and needs no reason from you, because I closed it. A
closed thread gets no heading and no mention in any later answer. Its number
stays spent, so `+` skips it and nothing else ever takes it.

Name what closed this turn on one line at the top of the answer, above the
first heading, `Closed: 3/, 4/`, and never again.

`3/` on a closed thread reopens it at the same number under the same heading.
A reopened thread opens with two or three sentences on where it stood when it
closed, then the new answer. Reopening 3.2/ brings 3/ back with it, since a
child has no heading of its own.

### Which threads an answer holds

Order the answer by state: what is settled first, what I have to decide last,
and no recap after it. When a task holds decisions only I can make, reply with
those decisions alone, skipping every thread that needs no decision, numbered
to match the answer you deliver once I have chosen. When nothing is open, the
answer stops at the last real thread.
