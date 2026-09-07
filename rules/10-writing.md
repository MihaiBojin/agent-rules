<!-- prose-check: skip -->
## Writing

These rules apply to prose written for humans: docs, READMEs, commit messages,
PR bodies, code comments, chat replies. They do not apply to code, identifiers,
log lines, quoted output, or anything inside a fenced code block.

The goal is writing that doesn't announce itself as machine-generated. Most of
that comes from removing a small set of habits, not from adding flourish.

### Do not calibrate against what is already there

The prose in my repositories is agent-written too: READMEs, skill files, code
comments, issue bodies, commit messages, pull request descriptions. None of it
is a sample of how I write, and none of it is evidence that a construction is
acceptable.

When the surrounding text and these rules disagree, the rules win. Do not match
the file you are editing, do not cite a neighboring document, and do not propose
loosening a rule because the corpus breaks it. When you edit a file that breaks
a rule, fix the lines you touch rather than matching the ones around them.

The exception is deliberate notation: a table's `—` for "not present", a
changelog's shape, a template somebody has to fill in. That is format, not
voice.

### Never use these constructions

- "It's not just X, it's Y" and its variants: "not only... but also",
  "This isn't about X. It's about Y."
- Three-item lists where two or four would be truthful. Count the items. If the
  third exists to complete a rhythm, cut it.
- A closing paragraph that restates what was already said. Stop at the last
  real point.
- An opening that restates the question before answering it.
- "Let's dive in", "delve", "in today's fast-paced", "at the end of the day",
  "it's worth noting that", "Here's the thing:", "Great question!"
- "leverage", "utilize", "facilitate", "seamless", "robust", "comprehensive",
  "streamline". Use "use" or "so".
- A bolded lead-in on every bullet ("**Speed**: it's fast"). Bold at most one
  bullet in a list, and only when it genuinely outranks the others.
- Stacked hedges: "may potentially", "could possibly", "generally tends to".
  One hedge or none.
- "I hope this helps", "Feel free to", "Let me know if".
- A rhetorical question as a section opener or closer.
- Emoji in headings.

### Do this instead

- Vary sentence length on purpose. If two sentences in a row have the same
  shape, rewrite one. A four-word sentence after a long one lands hard.
- Say the thing first. Qualify after, if at all.
- Use concrete nouns and real numbers. "Cut p99 from 400ms to 90ms" beats
  "significantly improved performance".
- Name the actor. "We deploy on Fridays" beats "deployments occur weekly".
- Prefer the shorter word. Use, not utilize. Start, not commence.
- Contractions are fine. Fragments are fine when they land.
- Put a caveat where it belongs, not in a "Caveats" section at the end.
- One idea per paragraph. When a paragraph turns, start a new one.

### Structure

- Headings only when a reader needs to jump. A 400-word doc rarely does.
- Bullets for things that are genuinely a list, not for three sentences that
  didn't get connected.
- No summary section unless the document runs past ~1500 words.
- No "Overview" heading above the first paragraph.
- Tables when the data has two or more dimensions. Otherwise a list.

### Before finishing

- Delete the last paragraph, then read it again. Usually it was a summary.
- Read the first sentence alone. If it could open any document on any topic,
  replace it.
- Count em-dashes. More than one per ~300 words is too many.
- Read one paragraph out loud. If it sounds like a press release, it is one.
