# Issue tracker: Beadwork (`bw`)

Issues for this repo are tracked with **beadwork** (`bw`), a lightweight git-native
issue tracker. Issues live on the `beadwork` branch and persist to git, so plans,
progress, and decisions survive compaction and session boundaries.

## Orientation

- **Always run `bw prime` before starting work** — it prints current state, ready
  work, and repo-hygiene warnings.
- Issue IDs look like `tb-XYZ`.
- Status flow: `open` → `in_progress` → `closed` (or `deferred`).
- Priority: `P0`–`P4` (default `P2`; `0` = highest).
- Epics have children (`--parent`) and dependencies
  (`bw dep add <blocker> blocks <blocked>`).

## When a skill says "publish to the issue tracker" / "create a ticket"

    bw create "Title" -t task --description "..."

Use `-t epic` for a multi-step effort, then create children with `--parent <epic-id>`
and wire ordering with `bw dep add <blocker> blocks <blocked>`.

## When a skill says "fetch the relevant ticket"

    bw show <id>

For discovery: `bw list` (filters `--status`, `--label`, `--type`, `-g/--grep`),
`bw ready` (unblocked work), `bw blocked`. Add `--json` for raw data.

## Triage state

Triage roles are recorded as **labels**, applied with `bw label`:

    bw label <id> +needs-triage                    # add a label
    bw label <id> +ready-for-agent -needs-triage   # swap one for another

Filter by triage state with `bw list --label <label>`. See `triage-labels.md` for
the role → label mapping.

## Comments

    bw comment <id> "breadcrumb text"

## Landing work

Commit referencing the ticket ID, then `bw close <id>`, then `bw sync` (fetch,
rebase/replay, push). Work that isn't committed, closed, and synced pollutes the
next session.

## PRs as a request surface

Not applicable — beadwork tracks issues in-repo; there is no external PR queue to
triage.
