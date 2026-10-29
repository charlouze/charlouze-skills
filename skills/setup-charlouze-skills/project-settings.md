# The project settings

The project's versioned Claude Code settings, `.claude/settings.json`, declare the plugin's marketplace and enable both plugins, so that every collaborator gets the same flow. Never write these values to `.claude/settings.local.json` or to the user's settings.

## The values

Each row is one value, at a JSON path of the settings:

| Path | Value |
|---|---|
| `extraKnownMarketplaces` → `charlouze-skills` → `source` | `{ "source": "github", "repo": "charlouze/charlouze-skills" }` |
| `extraKnownMarketplaces` → `charlouze-skills` → `autoUpdate` | `true` |
| `enabledPlugins` → `charlouze-skills@charlouze-skills` | `true` |
| `enabledPlugins` → `mattpocock-skills@claude-plugins-official` | `true` |

`claude-plugins-official` needs no marketplace entry: an `enabledPlugins` key naming it declares it.

## Planning the change

- **No file**: plan it with exactly these values, indented with two spaces.
- **The file exists**: parse it as JSON. For each row, a path that is missing is planned; a path that holds any value is kept, even `false` or another source, and goes under **Kept** when it differs. `additionalMarketplaces` is an alias of `extraKnownMarketplaces`: an entry there counts as present. Plan the missing paths as targeted insertions that keep the file's other keys, order and indentation.
- **The file is not valid JSON**: plan nothing for it, and list under **Left to you** the fix and the values it should hold.

`claude plugin install --scope project` rewrites this file in its own format; a file that holds every value is set up, however it is laid out.
