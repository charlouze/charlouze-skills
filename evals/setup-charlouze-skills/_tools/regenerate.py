"""Regenerates what the setup-charlouze-skills cases derive from other files.

- The charlouze-setup overlay: its docs/agents/ files are Matt's templates
  (matt-setup) with the sections and the layout of
  skills/setup-charlouze-skills/matt-files.md applied, and its CLAUDE.md gets
  the Domain docs line of that file.
- The `pattern:` line of every grader that matches a fixture file byte for
  byte, or keeps parts of it. The rest of each grader stays as written.

Run it from anywhere, after changing matt-files.md or a fixture:

    mise exec python -- python evals/setup-charlouze-skills/_tools/regenerate.py

With --check, it writes nothing and exits 1 when a file is out of date.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
SUITE = ROOT / 'evals/setup-charlouze-skills'
FIXTURES = ROOT / 'evals/_fixtures'
MATT_FILES = ROOT / 'skills/setup-charlouze-skills/matt-files.md'


def read(path):
    return path.read_bytes().decode('utf-8')


# The overlay -------------------------------------------------------------

def reference_block(ref, name):
    """The content of a matt-files.md section, between its outer fences."""
    m = re.search(r'\n## ' + re.escape(name) + r'\n\n````markdown\n(.*?)\n````\n', ref, re.S)
    assert m, f'no section {name!r} in {MATT_FILES}'
    return m.group(1)


def overlay():
    ref = read(MATT_FILES)
    line = re.search(r'\n## Domain docs line\n\n```markdown\n(.*?)\n```', ref, re.S).group(1)
    matt = FIXTURES / 'matt-setup'
    out = FIXTURES / 'charlouze-setup'

    domain = read(matt / 'docs/agents/domain.md')
    domain, n = re.subn(r'## File structure\n.*?(?=\n## )',
                        lambda m: reference_block(ref, 'File structure') + '\n', domain, flags=re.S)
    assert n == 1, "Matt's domain.md has no single `## File structure` section"
    domain = (domain.rstrip('\n') + '\n\n' + reference_block(ref, 'Glossary format')
              + '\n\n' + reference_block(ref, 'Context map') + '\n')

    triage = read(matt / 'docs/agents/triage-labels.md')
    triage = triage.rstrip('\n') + '\n\n' + reference_block(ref, 'Drift') + '\n'

    claude = read(out / 'CLAUDE.md')
    claude, n = re.subn(r'(### Domain docs\n\n)[^\n]*', lambda m: m.group(1) + line, claude)
    assert n == 1, 'charlouze-setup/CLAUDE.md has no single `### Domain docs` line'

    return {
        out / 'docs/agents/domain.md': domain,
        out / 'docs/agents/triage-labels.md': triage,
        out / 'CLAUDE.md': claude,
    }


# The graders -------------------------------------------------------------

def esc(text):
    """Text as a JS regex literal, ready for a YAML single-quoted string.

    A run of three dashes would end the grader's frontmatter, even inside the
    pattern: it is written as a counted repetition instead.
    """
    s = re.sub(r'([\\^$.*+?()\[\]{}|/])', r'\\\1', text).replace('\n', r'\n')
    s = re.sub(r'-{3,}', lambda m: '-{%d}' % len(m.group(0)), s)
    return s.replace("'", "''")


def replaced(text, *pairs):
    for old, new in pairs:
        assert old in text, f'{old!r} not found'
        text = text.replace(old, new)
    return text


def exact(text):
    return "'^" + esc(text) + "$'"


def graders(files):
    """Maps each grader to its pattern, from the fixtures as `files` leaves them."""
    def fx(rel):
        path = FIXTURES / rel
        return files.get(path) or read(path)

    charlouze_claude = fx('charlouze-setup/CLAUDE.md')
    charlouze_domain = fx('charlouze-setup/docs/agents/domain.md')
    charlouze_triage = fx('charlouze-setup/docs/agents/triage-labels.md')
    matt_claude = fx('matt-setup/CLAUDE.md')
    matt_domain = fx('matt-setup/docs/agents/domain.md')
    matt_triage = fx('matt-setup/docs/agents/triage-labels.md')
    competing = fx('competing-flow/CLAUDE.md')

    # What the rerun-after-hand-edit fixture changes by hand.
    french = ('Language of produced documents: English', 'Language of produced documents: Français')
    audit = ('"Audit <part> against the functional spec"', '"Audit <part> against its functional spec"')

    i = matt_domain.index('## File structure\n')
    j = matt_domain.index("## Use the glossary's vocabulary\n")
    k = matt_claude.index('### Domain docs\n\n') + len('### Domain docs\n\n')
    m = matt_claude.index('\n## Conventions\n')

    return {
        'rerun/graders/claude-md-untouched.md': exact(charlouze_claude),
        'rerun/graders/domain-untouched.md': exact(charlouze_domain),
        'rerun/graders/triage-labels-untouched.md': exact(charlouze_triage),
        'rerun-after-matt-rerun/graders/claude-md-redone.md': exact(charlouze_claude),
        'rerun-after-matt-rerun/graders/domain-redone.md': exact(charlouze_domain),
        'rerun-after-matt-rerun/graders/triage-labels-redone.md': exact(charlouze_triage),
        'rerun-after-hand-edit/graders/claude-md-untouched.md': exact(replaced(charlouze_claude, french)),
        'rerun-after-hand-edit/graders/domain-untouched.md': exact(charlouze_domain),
        'rerun-after-hand-edit/graders/triage-labels-untouched.md': exact(replaced(charlouze_triage, audit)),
        'without-github-remote/graders/claude-md-untouched.md': exact(matt_claude),
        'without-matt-setup/graders/claude-md-untouched.md': exact(read(SUITE / 'without-matt-setup/fixtures/CLAUDE.md')),
        'contrary-instructions/graders/claude-md-untouched.md': exact(competing),
        'competing-plugins/graders/contrary-instructions-kept.md':
            "'" + esc(competing[competing.index('\n## Conventions\n'):]) + "$'",
        'with-matt-setup/graders/surroundings-kept.md':
            "'^" + esc(matt_claude[:k]) + r'[\s\S]*' + esc(matt_claude[m:]) + "$'",
        'with-matt-setup/graders/domain-surroundings-kept.md':
            "'^" + esc(matt_domain[:i]) + r'## File structure[\s\S]*?\n' + esc(matt_domain[j:]) + r"[\s\S]*$'",
        'with-matt-setup/graders/triage-labels-surroundings-kept.md':
            "'^" + esc(matt_triage) + r"[\s\S]*$'",
    }


def with_pattern(grader, pattern):
    text = read(grader)
    new, n = re.subn(r'(?m)^pattern: .*$', lambda _: 'pattern: ' + pattern, text, count=1)
    assert n == 1, f'{grader} has no pattern line'
    return new


def main():
    check = '--check' in sys.argv[1:]
    files = overlay()
    for rel, pattern in graders(files).items():
        path = SUITE / rel
        files[path] = with_pattern(path, pattern)

    stale = [p for p, text in files.items() if not p.exists() or read(p) != text]
    for path in stale:
        print(('stale: ' if check else 'wrote: ') + path.relative_to(ROOT).as_posix())
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(files[path].encode('utf-8'))
    if not stale:
        print('up to date')
    return 1 if check and stale else 0


if __name__ == '__main__':
    sys.exit(main())
