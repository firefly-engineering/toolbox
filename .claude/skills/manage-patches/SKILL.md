---
name: manage-patches
description: Generate, refresh, or rebase vendored patches from fork branches for toolbox packages. Use when a fork branch has new commits, when bumping an upstream version that has patches, or when setting up patches on a new package.
argument-hint: <action> <package> [version]
allowed-tools: Bash Read Edit Write Glob Grep
---

# Manage Patches

You manage vendored patches for toolbox packages that augment upstream releases with changes from fork branches.

## Actions

The `$0` argument determines the action:

### `refresh <package> [version]`

Refresh the patch for an existing patched version. Fetches the latest commit from the fork branch and regenerates the patch.

1. Read `packages/$1/data.json` to find the version (use `$2` if provided, otherwise `_meta.default`)
2. Run: `${CLAUDE_SKILL_DIR}/generate-patch packages/$1 <version>`
3. Stage the patch file: `git add packages/$1/patches/*.patch`
4. Attempt a build: `nix build .#$1.<version_underscored>`
5. If vendorHash changed, update `data.json` with the hash from the error and rebuild

### `rebase <package> <new-version>`

Create a patch for a new upstream version. The fork branch must already be rebased onto the new tag.

1. Read `packages/$1/data.json` to understand the existing patch structure
2. Copy the latest patched version entry as a template for version `$2`:
   - Update `sha256` (compute via `nix-prefetch-url --type sha256 --unpack` on the upstream source)
   - Set `vendorHash` to `""`
   - Update the patch `file` path to include the new version (e.g. `patches/name-$2.patch`)
   - Keep the same `source` block (owner/repo/branch) but clear the commit (the script will resolve it)
3. Update `_meta.default` to `$2`
4. Run: `${CLAUDE_SKILL_DIR}/generate-patch packages/$1 $2`
5. Stage the patch file: `git add packages/$1/patches/*.patch`
6. Build to discover vendorHash, update, rebuild, verify

### `init <package> <version> <fork-owner> <fork-repo> <branch>`

Set up patches on a package that doesn't have them yet.

1. Read `packages/$1/data.json` and `packages/$1/default.nix`
2. Add to the version entry in `data.json`:
   ```json
   "patches": [{
     "file": "patches/<fork-owner>-<branch>-<version>.patch",
     "source": {
       "owner": "<fork-owner>",
       "repo": "<fork-repo>",
       "branch": "<branch>",
       "commit": ""
     }
   }]
   ```
3. If the builder doesn't already use `toolboxLib.resolvePatches`, update `default.nix`:
   - Add `patches = toolboxLib.resolvePatches ./. versionData;` to the derivation
   - If extra subPackages are needed, add `subPackages = versionData.subPackages or [ "existing/default" ];`
4. Run: `${CLAUDE_SKILL_DIR}/generate-patch packages/$1 $2`
5. Stage, build, discover vendorHash if needed, verify

## Current patched packages

!`cd "$(git rev-parse --show-toplevel)" && for f in packages/*/data.json; do if jq -e 'to_entries[] | select(.key != "_meta") | .value.patches // empty' "$f" > /dev/null 2>&1; then basename "$(dirname "$f")"; fi; done`

## Important

- Always stage patch files with `git add` before building — Nix flakes require tracked files
- Use `jj` for version control operations, not `git` directly (except `git add` for staging)
- The `scripts/generate-patch` script handles fetching the diff, verifying it applies cleanly, and updating the commit SHA
- Keep each semantic change in its own jj change
