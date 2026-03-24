---
name: finish
description: "Post-merge branch cleanup. Switches to main, pulls latest, and deletes the current feature branch locally (and optionally the remote tracking branch). Use after a PR has been merged — e.g. 'finish', 'clean up branch', 'PR merged', or 'switch back to main'."
argument-hint: "[branch-name] (optional — defaults to the branch you were just on)"
allowed-tools: Bash, Read
---

# Finish — Post-Merge Branch Cleanup

The user triggered `/finish` with: **$ARGUMENTS**

## Steps

1. **Identify the branch to clean up**
   - If `$ARGUMENTS` is provided, use that as the branch name
   - Otherwise, detect the current branch (`git branch --show-current`)
   - If already on `main`, check `git reflog` for the previously checked-out branch
   - Confirm the branch name before proceeding

2. **Switch to main and pull latest**
   ```
   git checkout main
   git pull origin main
   ```

3. **Delete the local branch**
   - Run `git branch -d <branch>` (safe delete — only works if merged)
   - If it fails with "not fully merged", warn the user and ask before using `-D`

4. **Check for remote tracking branch**
   - Run `git branch -r | grep <branch>` to see if a remote branch exists
   - If it exists, ask the user: "Remote branch `origin/<branch>` still exists. Delete it? (GitHub usually auto-deletes after PR merge)"
   - Only run `git push origin --delete <branch>` if the user confirms

5. **Show final state**
   - Run `git branch` to show remaining local branches
   - Confirm cleanup is complete

## Safety Rules

- NEVER force-delete (`-D`) without explicit user confirmation
- NEVER delete `main` or `master` branches
- NEVER run `git push origin --delete` without asking first
- If the branch has unmerged commits, warn and stop
