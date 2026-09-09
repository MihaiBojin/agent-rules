<!-- prose-check: skip -->
## Code and architecture

Simple beats clever. The cost that matters is what the next reader has to hold
in their head before they can change the code safely. Solve the problem in front
of you with the smallest change that solves all of it: fewer files touched,
fewer lines added, fewer moving parts left behind.

Build only what was asked for. Every flag, config key, environment variable,
extension point and code path is something someone has to read, test and keep
alive, so none of them get added on speculation. An option with no caller is
dead code with a manual, a setting nothing reads is a lie about what is
configurable, an abstraction with one implementation is a longer way to call a
function, and a document about a thing nobody uses rots before anyone reads it.
Generality answers a second caller. It does not predict one.

One job per unit. A function, a module, a script, a command: each does one thing
and carries a name that says what the thing is. When the name needs "and", it is
two of them. When it needs "manager", "helper" or "util", the job has not been
found yet. Two small pieces that compose beat one piece with a mode switch, and
what the project already depends on beats a new dependency.

Two copies that have to change together are a bug with a delay. Extract when the
copies are the same idea, not when they merely look alike, and read what is here
before writing a new one: the thing you are about to add usually exists already,
in the same file or one directory over. A helper that serves its second caller
through an `if` has coupled them to save a copy.

Complexity is sometimes the answer. A cache, a queue, a state machine, another
service: each earns its place when the requirement cannot be met without it. Say
what it buys, in a number where there is one, and what the simple version fails
to do. Complexity chosen that way is a decision. Complexity reached for first is
a habit.
