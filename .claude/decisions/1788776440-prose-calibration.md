# Whether existing repository prose can loosen the writing rules

Topic: agent-written prose in my repos gets used as evidence that a banned construction is fine
Status: decided 2026-09-07
Opened: 2026-09-07

## 2026-09-07

q: When repository prose and the writing rules disagree, which one wins
a: the rules, and the lines being edited get fixed rather than matched
why: the surrounding prose has the same author as the text being checked, so it is not a sample of how I write
alt: match the surrounding file — every generated document becomes evidence for the next one

q: Does a table's `—` count against the em-dash budget
a: no, deliberate notation is exempt: table cells meaning "not present", changelog shape, fill-in templates
why: a style review counted table cells as prose and reported MihaiBojin/origin#1 at 5.1x the budget; prose only it was 8 em-dashes in 1,324 words, 1.8x

q: US or British spelling in these repos
a: US
why: agent-rules has zero British spellings, and across the MihaiBojin repos it runs 142 US to 34 British with most of the British inside vendored files
alt: match a neighboring repo, which is the calibration this section exists to stop
