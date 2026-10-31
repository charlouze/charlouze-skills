# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the "Label in our tracker" column to match whatever vocabulary you actually use.

## Drift

<!-- charlouze-skills -->

A **drift** is code on `main` that contradicts its context's functional spec (a **violation**), or what no functional spec describes (a **gap**): a behaviour of the code, or an intention, wanted or still to decide. Every drift is corrective work, recorded as an issue.

- **One issue per violation and per gap**, labelled with the `needs-triage` role's label from the table above and with `context:<context>`, the context it concerns.
- **The issue names the section of the functional spec it targets**, and cites its source document when there is one (a brief, a change spec, a ticket).
- **Category.** A violation is a `bug`; an intention no functional spec describes is an `enhancement`. A behaviour of the code that no functional spec describes stays without a category until triage: the human decides whether it is wanted.
- **A part not yet audited against its functional spec** gets one issue, titled "Audit <part> against the functional spec" in the documents language.
- **The issue is the whole record**, kept in no other file. Its labels are ones the project already has, such as the triage role, `bug` or `enhancement`, plus `context:<context>`.
- **`context:<context>` exists from the context's birth**: the change that creates a context creates its label.
