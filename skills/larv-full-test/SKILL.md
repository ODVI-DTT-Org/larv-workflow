---
name: larv-full-test
description: Use when performing a full end-to-end production smoke test of a Laravel app — logs all bugs found across every feature before fixing any of them.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-full-test

Drive a complete production feature sweep: collect all bugs first, then fix them in one focused pass. Never stop to fix a bug while testing — finish the full feature tour first.

## Phase 1 — Pre-flight

### 1a. Ask the user for required inputs

Ask **all of these** before touching anything:

```
1. Production URL (e.g. https://myapp.com or http://46.250.229.188:8001)
2. Login credentials for each role you want tested
   (at minimum: a regular user + an admin)
3. Do you permit the AI to run database commands
   (e.g. `php artisan tinker`, `DB::` queries, seeders, rollbacks)
   to revert state changed during testing? [yes / no]
```

**Hard stop:** do not proceed until the user has answered all three.

Record answers in a session scratch file at `docs/larv/full-test/session.yaml`:

```yaml
production_url: ""
credentials:
  - role: user
    email: ""
    password: ""
  - role: admin
    email: ""
    password: ""
db_revert_permitted: false
```

### 1b. Confirm DB revert permission explicitly

If `db_revert_permitted: false`, testing is read-only. Warn the user:

```
⚠️  DB revert not permitted. Any data created or modified during testing
    (kudos posted, upvotes, follows, etc.) will persist in production.
    Proceed anyway? [yes / no]
```

If they say no, stop. If they say yes, continue in read-only mode and note it in every bug that involves side effects.

---

## Phase 2 — Feature sweep (collect bugs, do not fix)

**Rule: Log every bug. Fix none. Continue to the next feature immediately.**

Use the Playwright MCP tools to drive the browser. Navigate to each feature in order. After each feature block, write findings to `docs/larv/full-test/bugs.md`. Keep testing.

### Feature checklist

Work through every item below. Check it off in `session.yaml` as you go.

#### Auth & onboarding
- [ ] Unauthenticated visit → redirects to login
- [ ] Login with valid user credentials → lands on feed
- [ ] Login with invalid credentials → shows error, no redirect
- [ ] Logout → session cleared, redirect to login

#### Feed (`/`)
- [ ] Feed loads with kudos cards visible
- [ ] Featured kudos card (if any) shows `⭐ Featured Kudos` header
- [ ] Standard kudos cards show avatar, sender, recipient, message, award badge, upvote count
- [ ] Upvote button increments count (real-time via Reverb if configured)
- [ ] Remove upvote decrements count
- [ ] Own kudos: delete button visible, triggers confirmation, deletes card
- [ ] Other user's kudos: delete button not visible

#### Give Kudos form (`/give-kudos` or FAB)
- [ ] Form opens / navigates correctly
- [ ] Recipient search (search-as-you-type, Meilisearch)
- [ ] Award dropdown populated
- [ ] Message field accepts input
- [ ] Allowance counter visible and accurate
- [ ] Submit posts kudos → appears on feed
- [ ] Submitting when allowance is 0 → blocked with error

#### Directory (`/directory`)
- [ ] Page loads with user cards
- [ ] Search-as-you-type filters results
- [ ] Empty state shown when search has no match
- [ ] Clicking a user navigates to their profile

#### Leaderboard (`/leaderboard`)
- [ ] Podium (top 3) renders with avatars and counts
- [ ] Tab switching (e.g. week / month / all-time) reloads rankings
- [ ] Full list below podium matches expected order

#### Profile (`/profile` or `/profile/{user}`)
- [ ] Own profile: shows name, avatar, kudos wall, stats
- [ ] Other user profile: same, without edit controls
- [ ] Kudos wall shows sent and received tabs
- [ ] Follow button present; clicking follows the user
- [ ] Unfollow button present after follow

#### Notifications
- [ ] Notification indicator visible in nav when unread notifications exist
- [ ] Notification list shows recent activity
- [ ] Marking as read clears indicator

#### Admin panel (`/admin` or Filament path)
- [ ] Admin login redirects to Filament dashboard
- [ ] Non-admin user cannot access `/admin` (403 or redirect)

#### Admin — Kudos resource
- [ ] Kudos list loads with pagination
- [ ] Feature/unfeature action toggles featured state on feed
- [ ] Delete action removes the kudos

#### Admin — User resource
- [ ] User list loads
- [ ] Role assignment dropdown works
- [ ] Allowance override saves correctly

#### Admin — Award resource
- [ ] Award list loads
- [ ] Create new award → appears in Give Kudos dropdown
- [ ] Edit award → changes reflected
- [ ] Deactivate award → removed from Give Kudos dropdown

#### Admin — Audit log resource
- [ ] Audit log loads with filters (date, user, event)
- [ ] Entries are read-only (no edit/delete actions)

#### Admin — Pulse / Telescope (if configured)
- [ ] `/pulse` accessible to super-admin only
- [ ] `/telescope` accessible to super-admin only (dev only)

---

## Phase 3 — Bug report

After completing the full feature sweep, write `docs/larv/full-test/bugs.md`:

```markdown
# Full-Test Bug Report

**Date:** YYYY-MM-DD
**Production URL:** <url>
**Tested roles:** user, admin
**DB revert permitted:** yes/no

## Bug List

### BUG-001 — <short title>
- **Feature:** <feature block>
- **Steps to reproduce:** <numbered steps>
- **Expected:** <what should happen>
- **Actual:** <what happened>
- **Severity:** critical / high / medium / low
- **Screenshot:** `docs/larv/full-test/screenshots/<name>.png`
- **DB state affected:** yes/no — <description if yes>

### BUG-002 — ...
```

Show the user the full bug list and ask:

```
Found N bugs. Ready to fix them now?
Fix order: critical → high → medium → low.
Should I proceed? [yes / no / fix only: BUG-001, BUG-003]
```

---

## Phase 4 — Fix pass

Fix bugs in severity order. For each bug:

1. Identify root cause in source code.
2. Apply the fix.
3. Re-test the specific feature in production (or sandbox if DB revert was denied).
4. If DB revert is permitted and a test created dirty state (e.g. a duplicate kudos), run the revert:
   ```bash
   php artisan tinker --execute="<revert statement>"
   ```
5. Mark the bug `fixed` in `bugs.md` with the file(s) changed and a one-line explanation.

After all fixes, run the automated suite:

```bash
vendor/bin/pest
vendor/bin/pint --test
vendor/bin/phpstan analyse
```

Then do a targeted re-sweep of the affected features only (not the full Phase 2 tour).

---

## Subagent return contract

```yaml
status: complete | partial | failed
production_url: ""
bugs_found: 0
bugs_fixed: 0
bugs_deferred: []
files_written:
  - docs/larv/full-test/session.yaml
  - docs/larv/full-test/bugs.md
db_reverts_run: []
errors_unresolved: []
```
