# The GitHub settings

The git history policy needs the GitHub repository to merge a stack as one merge commit, titled by its top pull request, and to dismiss an approval when its layer changes: on `main`, `git log --first-parent` then shows one line per stack, and what lands is what was approved. These settings live on GitHub, not in the working tree: the setup reads them with `gh`, proposes those that are missing, and applies them only after their own yes.

`<owner>/<repo>` is the GitHub remote step 1 found, `origin` when several remotes point at `github.com`, and `<branch>` the repository's default branch, `.default_branch` of the first read below.

Unlike a value in a file, a setting set otherwise is not the human's to keep: the policy does not hold without it. It is proposed again at each run, and the separate yes of step 4 leaves the human free to refuse it each time.

## The settings

| Setting | In place when |
|---|---|
| Merge commit only | `gh api repos/<owner>/<repo>` gives `allow_merge_commit` `true`, `allow_squash_merge` `false` and `allow_rebase_merge` `false` |
| Merge commit titled by the pull request | the same read gives `merge_commit_title` `PR_TITLE` |
| Merge commit with an empty body | the same read gives `merge_commit_message` `BLANK` |
| Dismiss stale approvals on the default branch | `gh api repos/<owner>/<repo>/rules/branches/<branch>` holds a rule of type `pull_request` whose `parameters.dismiss_stale_reviews_on_push` is `true`, or `gh api repos/<owner>/<repo>/branches/<branch>/protection/required_pull_request_reviews` gives `dismiss_stale_reviews` `true` |

The branch protection read needs admin rights: an HTTP 403 or 404 there is not an error, and the rules read decides alone. The first read leaves out the merge fields for a token without push rights: a field it leaves out is unread, not missing.

## Planning the change

- **A setting in place plans nothing**, and goes in no part of the report.
- **An unread setting**, because `gh` is disconnected (step 2), a read fails, or a field is left out: plan nothing to apply for it. List its command below under **Left to you**, to run after checking the setting.
- **A missing setting**: plan its command below.

The merge settings, in one command that sends only the fields of the missing settings. `merge_commit_title` and `merge_commit_message` go together: when either is missing, send both.

```
gh api -X PATCH repos/<owner>/<repo> -F allow_merge_commit=true -F allow_squash_merge=false -F allow_rebase_merge=false -f merge_commit_title=PR_TITLE -f merge_commit_message=BLANK
```

Dismissing stale approvals, by a ruleset of its own. It adds to the branch protection and the rulesets already there, without changing them: when several apply, GitHub enforces the strictest.

```
gh api -X POST repos/<owner>/<repo>/rulesets --input - <<'EOF'
{
  "name": "Dismiss stale approvals",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_approving_review_count": 0,
        "required_review_thread_resolution": false
      }
    }
  ]
}
EOF
```

When showing this ruleset, say what it changes beyond the dismissal: GitHub dismisses stale approvals only on a branch that requires a pull request, so every change to the default branch then goes through one. It requires no approval, so the human can still merge their own pull requests.

## Applying

Run each accepted command with `gh`, then read its settings again as the table says. A command that fails, for want of rights or for any other reason, or whose settings still do not hold, stays unapplied: list it under **Left to you**, written out in full with `<owner>/<repo>` filled in, and the error GitHub gave.
