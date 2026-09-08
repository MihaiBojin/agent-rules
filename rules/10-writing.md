<!-- prose-check: skip -->
## Writing

For prose written for humans: docs, READMEs, commit messages, PR bodies, code
comments, chat replies. Not code, identifiers, log lines, quoted output, or
anything inside a fenced code block.

The prose already in my repos is agent-written too, so none of it is evidence
that a construction is acceptable. When it and these rules disagree, the rules
win: do not match the file you are editing, do not cite a neighboring document,
do not propose loosening a rule because the corpus breaks it, and fix the lines
you touch. Deliberate notation is exempt, such as a table's `—` for "not
present", a changelog's shape, a template somebody fills in.

### Never

- "It's not just X, it's Y", "not only... but also", "This isn't about X. It's
  about Y."
- "leverage", "utilize", "facilitate", "seamless", "robust", "comprehensive",
  "streamline", "delve", "let's dive in", "in today's fast-paced", "at the end
  of the day", "it's worth noting", "here's the thing", "great question",
  "I hope this helps", "feel free to", "let me know if".
- Stacked hedges: "may potentially", "could possibly", "generally tends to".
- Three-item lists where two or four would be truthful. Count the items.
- A closing paragraph that restates what was said, or an opening that restates
  the question.
- A bolded lead-in on every bullet. Bold one at most, and only when it outranks
  the rest.
- A rhetorical question opening or closing a section. Emoji in headings.

### Instead

- Vary sentence length on purpose. Two sentences with the same shape: rewrite
  one. A four-word sentence after a long one lands hard.
- Say the thing first, qualify after. Name the actor. Prefer the shorter word.
- Concrete nouns and real numbers: "cut p99 from 400ms to 90ms", not
  "significantly improved performance".
- Contractions are fine. Fragments are fine when they land.
- One idea per paragraph. A caveat goes where it belongs, not in a section at
  the end.
- Headings only when a reader needs to jump, bullets only for a real list,
  tables when the data has two dimensions.
- No summary section under ~1500 words. No "Overview" above the first paragraph.

### Before finishing

- Delete the last paragraph, then read it again. Usually it was a summary.
- Read the first sentence alone. If it could open any document, replace it.
- Count em-dashes. More than one per ~300 words is too many.
