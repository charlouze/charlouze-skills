# The CLAUDE.md block

The plugin's instructions live in one block of the instructions file (the file holding `## Agent skills`, `CLAUDE.md` or `AGENTS.md`). The plugin owns the block; the human may still edit its values, and an edited value holds.

## The block

```markdown
## charlouze-skills

Language of produced documents: <language>
```

- **`Language of produced documents`** is the language of the documents the agents produce in this project, for this plugin's skills and Matt's alike. Its label stays in English in every project. `<language>` is the human's answer, which may come with the command; offer English as the default.

## Planning the change

- **No `## charlouze-skills` heading in the file**: plan the whole block, placed right after the `## Agent skills` section: after its last line, before the next `#` or `##` heading, or at the end of the file. One blank line separates it from its neighbours.
- **The heading exists**: keep the block where it is. Plan only the lines it lacks, appended at the block's end. A line that is present keeps its value, whatever it is: when `Language of produced documents` is present, do not ask for the language.
