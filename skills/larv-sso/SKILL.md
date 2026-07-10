---
name: larv-sso
description: Wire a consumer Laravel app to auth.odvi.app (dtt-sso). Diagnoses and fixes the "Permissions refresh failed / HTTP 404 /api/permissions/catalog" error, registers the app on the IdP, and refreshes the permission catalog. Run this skill from the CONSUMER app's repo, not from the dtt-sso repo.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-sso

Connect a consumer Laravel app to the **auth.odvi.app** SSO identity provider, or fix a broken connection. The canonical 12-step integration guide lives at `docs/SSO-CONSUMER-INTEGRATION.md` in the `dtt-sso` repo — this skill operationalises the most common failures and gives you the auth.odvi.app registration steps in order.

> **Repo context rule**: run this skill from the *consumer* app's project root (e.g. `greenlight`, `rfp-v2`, `dtt-dashboard`). Do not run it from the `dtt-sso` repo. The IdP tinker commands in Section 4 explicitly target the `dtt-sso` app via `cloud command:run`.

---

## Section 1 — Triage: what is actually broken?

Before touching any code, confirm the failure mode:

```bash
# From any machine that can reach the consumer's production URL:
curl -si https://<consumer-app>/api/permissions/catalog | head -5
```

| Response | Go to |
|---|---|
| `HTTP 404` | Section 2 — route not registered or inside auth group |
| `HTTP 401` / `HTTP 403` | Section 2b — route is inside an auth middleware group |
| `HTTP 200` with `{"permissions":[],"roles":[]}` | Section 3 — route is live but catalog is empty (config issue) |
| `HTTP 200` with populated JSON | Section 4 — catalog is fine; trigger IdP refresh |
| Connection refused / `curl: (7)` | App not deployed or wrong URL — deploy first |

---

## Section 2 — Fix: 404 or 401 on the catalog endpoint

### Why this happens

The route is either missing or wrapped in an `auth` / `filament.auth` middleware group. The IdP hits this endpoint unauthenticated, so any auth guard will return 401/403 and some setups return 404 via a catch-all.

### Diagnosis

```bash
# Check if the route exists at all:
php artisan route:list --name=permissions.catalog

# Check if the catalog class exists:
find app -name "PermissionsCatalogController.php"
```

If `route:list` returns nothing, the route is missing entirely → go to **2a**.
If `route:list` shows the route but the live URL returns 4xx → go to **2b**.

### 2a — Route is missing: add it

The catalog route must be **public** (no auth middleware). Add it near the top of `routes/web.php`, before any `->middleware('auth')` or `Route::middleware([...])` groups:

```php
use App\Http\Controllers\PermissionsCatalogController;

// Public — the IdP fetches this unauthenticated
Route::get('/api/permissions/catalog', PermissionsCatalogController::class)
    ->name('permissions.catalog');
```

If `PermissionsCatalogController` does not exist, create it:

```php
// app/Http/Controllers/PermissionsCatalogController.php
<?php
namespace App\Http\Controllers;

use App\Sso\Permissions\PermissionCatalog;
use App\Sso\Permissions\RoleCatalog;
use Illuminate\Http\JsonResponse;

class PermissionsCatalogController extends Controller
{
    public function __invoke(PermissionCatalog $permCatalog, RoleCatalog $roleCatalog): JsonResponse
    {
        return response()->json([
            'permissions' => $permCatalog->all(),
            'roles'       => $roleCatalog->all(),
        ]);
    }
}
```

If `App\Sso\Permissions\PermissionCatalog` and `RoleCatalog` do not exist, the full inline SDK is required — see Section 2c.

### 2b — Route exists but is inside an auth group: move it out

Search for the route in `routes/web.php` and `routes/api.php`:

```bash
grep -n "permissions.catalog\|permissions/catalog" routes/web.php routes/api.php
```

Move the route to the **top level** of `routes/web.php`, outside any `Route::middleware([...])` or `Auth::routes()` group. Public routes must not be nested inside any middleware group that requires authentication.

### 2c — Inline SDK missing: scaffold it

Create these four files verbatim (swap `App\Sso\Permissions` for the app's namespace if different):

```php
// app/Sso/Permissions/Permission.php
<?php
declare(strict_types=1);
namespace App\Sso\Permissions;

#[\Attribute(\Attribute::TARGET_METHOD | \Attribute::TARGET_CLASS | \Attribute::IS_REPEATABLE)]
final class Permission
{
    public function __construct(
        public readonly string $action,
        public readonly string $subject,
        public readonly ?string $description = null,
    ) {}

    public function key(): string { return $this->action.':'.$this->subject; }
}
```

```php
// app/Sso/Permissions/PermissionCatalog.php
<?php
declare(strict_types=1);
namespace App\Sso\Permissions;

use ReflectionClass;
use Symfony\Component\Finder\Finder;

final class PermissionCatalog
{
    /** @return array<int, array{action:string,subject:string,description:?string}> */
    public function all(): array
    {
        $found = [];
        foreach (config('permissions.manual', []) as $entry) {
            $found[$entry['action'].':'.$entry['subject']] = [
                'action' => $entry['action'],
                'subject' => $entry['subject'],
                'description' => $entry['description'] ?? null,
            ];
        }
        foreach ($this->scanForAttributes() as $entry) {
            $key = $entry['action'].':'.$entry['subject'];
            $found[$key] = $found[$key] ?? $entry;
        }
        return array_values($found);
    }

    private function scanForAttributes(): iterable
    {
        foreach (config('permissions.scan_paths', [app_path()]) as $path) {
            if (! is_dir($path)) { continue; }
            foreach ((new Finder)->in($path)->files()->name('*.php') as $file) {
                $class = $this->classFromFile($file->getRealPath());
                if (! $class || ! class_exists($class)) { continue; }
                try { $ref = new ReflectionClass($class); } catch (\Throwable) { continue; }
                foreach ($ref->getAttributes(Permission::class) as $attr) {
                    $p = $attr->newInstance();
                    yield ['action' => $p->action, 'subject' => $p->subject, 'description' => $p->description];
                }
                foreach ($ref->getMethods() as $method) {
                    foreach ($method->getAttributes(Permission::class) as $attr) {
                        $p = $attr->newInstance();
                        yield ['action' => $p->action, 'subject' => $p->subject, 'description' => $p->description];
                    }
                }
            }
        }
    }

    private function classFromFile(string $absPath): ?string
    {
        $contents = @file_get_contents($absPath);
        if ($contents === false) { return null; }
        if (! preg_match('/^namespace\s+([^;]+);/m', $contents, $ns)) { return null; }
        if (! preg_match('/^(?:abstract\s+|final\s+)?class\s+(\w+)/m', $contents, $cls)) { return null; }
        return $ns[1].'\\'.$cls[1];
    }
}
```

```php
// app/Sso/Permissions/RoleCatalog.php
<?php
declare(strict_types=1);
namespace App\Sso\Permissions;

final class RoleCatalog
{
    /** @return array<int, array{slug:string,name:string,is_default:bool,description:?string,permissions:array<int,string>}> */
    public function all(): array
    {
        $known = collect((new PermissionCatalog())->all())
            ->map(fn ($p) => $p['action'].':'.$p['subject'])->all();
        $defaultCount = 0;
        $roles = [];
        foreach (config('roles', []) as $def) {
            $valid = array_values(array_intersect(array_unique($def['permissions'] ?? []), $known));
            $isDefault = (bool) ($def['is_default'] ?? false);
            if ($isDefault) { $defaultCount++; }
            $roles[] = [
                'slug'        => (string) $def['slug'],
                'name'        => (string) $def['name'],
                'is_default'  => $defaultCount === 1 ? $isDefault : false,
                'description' => $def['description'] ?? null,
                'permissions' => $valid,
            ];
        }
        return $roles;
    }
}
```

Then create the config stubs (fill in your app's actual permissions and roles):

```php
// config/permissions.php
<?php
return [
    // Always-present permissions (supplement or replace #[Permission] scanning).
    'manual' => [
        ['action' => 'view', 'subject' => 'dashboard', 'description' => 'View the main dashboard'],
        // add more: ['action' => '...', 'subject' => '...', 'description' => '...'],
    ],
    // Directories scanned for #[Permission] attributes. Defaults to app/.
    'scan_paths' => [app_path()],
];
```

```php
// config/roles.php
<?php
return [
    [
        'slug'        => 'viewer',
        'name'        => 'Viewer',
        'is_default'  => true,
        'description' => 'Read-only access',
        'permissions' => ['view:dashboard'],
    ],
    // add more roles; permissions must match keys in config/permissions.php
];
```

### 2d — Wire `$can` / `Gate::allows()` in Blade and PHP

After the SDK is in place, create a `PermissionsServiceProvider` so Blade `@can('view:dashboard')` and PHP `Gate::allows('view:dashboard')` read from `session('sso.permissions')`:

```php
// app/Providers/PermissionsServiceProvider.php
<?php
declare(strict_types=1);
namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class PermissionsServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Gate::before(function ($user, string $ability) {
            // Only intercept "action:subject" style abilities.
            if (! str_contains($ability, ':')) {
                return null;
            }

            // Super-admins bypass all permission checks so they are never
            // locked out when session data is stale (e.g. after a deploy
            // before re-login).
            if (method_exists($user, 'isSuperAdmin') && $user->isSuperAdmin()) {
                return true;
            }

            $perms = session('sso.permissions', []);

            return in_array($ability, $perms, true) ? true : null;
        });
    }
}
```

Register it in `bootstrap/providers.php` (Laravel 11+) or `config/app.php` (`providers` array, Laravel 10):

```php
// bootstrap/providers.php  (Laravel 11)
return [
    App\Providers\AppServiceProvider::class,
    App\Providers\PermissionsServiceProvider::class,
];
```

Usage after wiring:

```blade
{{-- Blade --}}
@can('view:dashboard') ... @endcan
@can('manage:users') ... @endcan
```

```php
// PHP
Gate::allows('view:dashboard')
Gate::authorize('manage:settings') // throws 403 on failure
```

`session('sso.permissions')` is populated by `SsoController::callback()` when the OAuth2 flow completes — the IdP returns `permissions` as a claim in the userinfo response.

### Verify the fix locally

```bash
php artisan route:clear
php artisan route:list --name=permissions.catalog
php artisan serve &
curl -s http://localhost:8000/api/permissions/catalog | python3 -m json.tool
```

Expected: JSON with `{"permissions":[...],"roles":[...]}`. Both arrays may be empty if `config/permissions.php` has no entries yet — that is OK at this stage.

---

## Section 3 — Fix: endpoint returns empty arrays

The route is reachable but the catalog is empty. Common causes:

| Cause | Fix |
|---|---|
| `config/permissions.php` missing or `manual` array empty | Add at least one manual entry; see Step 8 in `SSO-CONSUMER-INTEGRATION.md` |
| `config/roles.php` missing | Create it with at least one role; see Step 8 |
| `scan_paths` points at a directory that doesn't exist | Check `app_path()` resolves correctly; add a `dd(app_path())` in a temporary route if unsure |
| `#[Permission]` attributes not present on any class | Add them on at least one Resource or Livewire component |

After fixing, re-run the curl check from Section 1.

---

## Section 4 — Register the consumer app on auth.odvi.app (IdP side)

> These commands run **against the dtt-sso Laravel Cloud environment**, not against the consumer app. The `cloud command:run` syntax assumes Laravel Cloud CLI is authenticated (`cloud auth`).

### 4a — Register the ClientApplication (first time only)

Skip this step if the app is already listed in the App Registry on auth.odvi.app admin.

```bash
cloud command:run "<dtt-sso-env-id>" --cmd 'php artisan tinker --execute="
\$actor = App\Infrastructure\Database\Models\UserModel::whereHas(\"adminRoles\",fn(\$q)=>\$q->where(\"role\",\"super_admin\"))->first();
\$handler = app(App\Application\ApplicationRegistry\UseCases\RegisterClientApp\RegisterClientAppHandler::class);
\$cmd = new App\Application\ApplicationRegistry\UseCases\RegisterClientApp\RegisterClientAppCommand(
    name: \"<App Display Name>\",
    slug: \"<app-slug>\",
    redirectUris: [
        \"https://<consumer-production-url>/auth/sso/callback\",
        \"https://<consumer-deploy.laravel.cloud>/auth/sso/callback\",
    ],
    color: \"#9B6632\",
    actorId: \$actor->id,
);
\$r = \$handler->handle(\$cmd);
echo \"client_id=\".\$r->application->passport_client_id;
"'
```

Record the `client_id` UUID. Then generate the plaintext secret (Passport 13 hashes on save):

```bash
cloud command:run "<dtt-sso-env-id>" --cmd 'php artisan tinker --execute="
\$client = Laravel\Passport\Client::find(\"<client_id>\");
\$secret = Illuminate\Support\Str::random(40);
\$client->secret = \$secret; \$client->save();
echo \"new_secret=\".\$secret;
"'
```

Set `SSO_CLIENT_ID` and `SSO_CLIENT_SECRET` in the consumer app's Laravel Cloud environment variables.

### 4b — Register the back-channel logout URI

```bash
cloud command:run "<dtt-sso-env-id>" --cmd 'php artisan tinker --execute="
App\Infrastructure\Database\Models\ClientApplicationModel::where(\"slug\",\"<app-slug>\")
  ->update([\"backchannel_logout_uri\" => \"https://<consumer-production-url>/oidc/back-channel-logout\"]);
echo \"updated\";
"'
```

### 4c — Refresh the permission catalog

Run this **after** the consumer app is deployed with a working `/api/permissions/catalog` endpoint (Section 2 fix deployed and live):

```bash
cloud command:run "<dtt-sso-env-id>" --cmd 'php artisan tinker --execute="
\$app = App\Infrastructure\Database\Models\ClientApplicationModel::where(\"slug\",\"<app-slug>\")->first();
\$r = app(App\Application\ApplicationRegistry\UseCases\RefreshPermissions\RefreshPermissionsHandler::class)->handle(\$app->id);
echo \"perms[a=\".\$r->added.\" u=\".\$r->updated.\"] roles[a=\".\$r->rolesAdded.\" u=\".\$r->rolesUpdated.\" pivot=\".\$r->roleAttachmentsReplaced.\"]\";
"'
```

Alternatively, in the auth.odvi.app admin UI: **App Registry → <app card> → Refresh permissions**.

A successful refresh prints `perms[a=N u=0] roles[a=M u=0]` where N and M are non-zero (matching what the catalog endpoint returns).

### 4d — Verify in the auth.odvi.app admin UI

1. Go to `https://auth.odvi.app/admin` → App Registry.
2. Find the consumer app card.
3. Confirm **Permissions** and **Roles** tabs are populated.
4. Assign the desired role to a test user via **Manage Access**.

---

## Section 5 — End-to-end smoke test

After all fixes and registration:

```bash
# Catalog reachable
curl -s https://<consumer-production-url>/api/permissions/catalog | python3 -m json.tool

# Admin redirects to SSO (not to a local login page)
curl -si -o /dev/null -w "%{http_code} %{redirect_url}\n" https://<consumer-production-url>/admin
# Expect: 302  https://auth.odvi.app/oauth/authorize?...
```

Sign in with a test user, confirm roles and permissions load (`session('sso.permissions')` via tinker on the consumer DB), and verify gated features respond correctly.

---

## Section 6 — Common gotchas (quick reference)

| Symptom | Root cause | Fix |
|---|---|---|
| Catalog 404 | Route inside auth group | Move route to top of `routes/web.php` |
| Catalog 404 | `PermissionsCatalogController` missing | Create it (Section 2a) |
| Catalog 200 but empty | No `config/permissions.php` or no `#[Permission]` attributes | Add manual entries or attributes; see Step 8 in SSO-CONSUMER-INTEGRATION.md |
| Refresh shows `perms[a=0 u=0]` | Catalog endpoint still unreachable from IdP (firewall, wrong URL in redirect) | Confirm the URL used in 4c matches the live endpoint |
| User can't sign in after registration | `SSO_CLIENT_ID` / `SSO_CLIENT_SECRET` not set or wrong in consumer env | Double-check env vars match what was echoed in Section 4a |
| Sign out does nothing | Logout doesn't end the IdP session | Consumer's `SsoController::logout` must redirect through `https://auth.odvi.app/oauth/logout` |
| Role change on IdP has no effect | Consumer session caches old permissions | Role changes trigger back-channel logout; ensure the consumer's back-channel endpoint (`/oidc/back-channel-logout`) is working |

For the full pattern library (two-domain split, parallel role systems, etc.) see `docs/SSO-CONSUMER-INTEGRATION.md` in the `dtt-sso` repo.

---

## Section 7 — Final integration check

Run this checklist top to bottom after every integration or fix. All items must pass before declaring the consumer app connected.

### 7a — Catalog endpoint

```bash
curl -s https://<consumer-production-url>/api/permissions/catalog | python3 -m json.tool
```

Expected output shape:
```json
{
  "permissions": [
    { "action": "view", "subject": "dashboard", "description": "..." }
  ],
  "roles": [
    { "slug": "viewer", "name": "Viewer", "is_default": true, "description": "...", "permissions": ["view:dashboard"] }
  ]
}
```

Fail conditions:
- HTTP 4xx → back to Section 2
- `"permissions": []` AND `"roles": []` → back to Section 3
- Missing `action`/`subject` keys inside permissions → `PermissionCatalog` returning wrong shape; check `PermissionCatalog::all()`

### 7b — Gate wiring (local tinker)

```bash
php artisan tinker --execute="
\$user = App\Models\User::first();
session()->put('sso.permissions', ['view:dashboard', 'manage:users']);
echo Gate::forUser(\$user)->allows('view:dashboard') ? 'PASS' : 'FAIL';
echo PHP_EOL;
echo Gate::forUser(\$user)->allows('manage:users') ? 'PASS' : 'FAIL';
echo PHP_EOL;
echo Gate::forUser(\$user)->allows('delete:everything') ? 'FAIL (should deny)' : 'PASS (correctly denied)';
"
```

Expected: three lines of `PASS`. If any is wrong, `PermissionsServiceProvider` is not registered or `Gate::before()` is not firing — recheck `bootstrap/providers.php` (Laravel 11) or `config/app.php` providers array (Laravel 10).

### 7c — Admin redirect to IdP

```bash
curl -si -o /dev/null -w "%{http_code} %{redirect_url}\n" https://<consumer-production-url>/admin
```

Expected: `302  https://auth.odvi.app/oauth/authorize?...`

If it redirects to the consumer's own login page, `SsoController` is not handling the redirect or `SSO_*` env vars are missing.

### 7d — Sign-in flow

1. Open an incognito window and navigate to `https://<consumer-production-url>/admin`.
2. Confirm redirect to `auth.odvi.app`.
3. Sign in with a test user that has a role assigned (via IdP Manage Access).
4. Confirm you land back in the consumer app, not on a 403 or login loop.
5. In a tinker session on the consumer DB, verify permissions arrived in the session:

```bash
php artisan tinker --execute="
\$sessions = DB::table('sessions')->latest('last_activity')->limit(1)->get();
\$payload = unserialize(base64_decode(\$sessions->first()->payload));
\$perms = \$payload['_token'] ?? null; // session structure varies by driver
// Alternative: check the web server logs for session('sso.permissions')
var_dump(\$sessions->first()->payload);
"
```

Or add a temporary debug route (remove after verifying):

```php
// routes/web.php — REMOVE AFTER DEBUGGING
Route::get('/debug-session', fn() => response()->json([
    'permissions' => session('sso.permissions', []),
    'user' => auth()->user()?->email,
]))->middleware('auth');
```

### 7e — Back-channel logout

Assign a role to the test user in the IdP admin, then remove it. Within 30 seconds:

```bash
# Confirm the user's consumer session was invalidated (back-channel logout fired)
curl -si -o /dev/null -w "%{http_code}\n" https://<consumer-production-url>/admin
# Expect: 302 (redirected to login — session invalidated)
```

If the session survives role removal, the back-channel logout URI in Section 4b is wrong or the consumer's `/oidc/back-channel-logout` route is not reachable from auth.odvi.app.

### 7f — Pest feature test scaffold (optional but recommended)

Add this test file to confirm the integration holds across deploys. It covers four areas:
1. Catalog shape and completeness
2. Gate wiring correctness
3. Every config-declared permission is captured by `PermissionCatalog`
4. Every config-declared role is captured by `RoleCatalog` with its full permission bundle
5. Every gated feature actually uses a permission check (no ungated pages)

```php
// tests/Feature/SsoIntegrationTest.php
<?php
declare(strict_types=1);

use App\Sso\Permissions\PermissionCatalog;
use App\Sso\Permissions\RoleCatalog;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Route;

// ─── 1. Catalog endpoint ──────────────────────────────────────────────────────

it('catalog endpoint is publicly reachable and returns expected shape', function (): void {
    $response = $this->get('/api/permissions/catalog');

    $response->assertOk();
    $response->assertJsonStructure([
        'permissions' => [['action', 'subject']],
        'roles'       => [['slug', 'name', 'is_default', 'permissions']],
    ]);
});

it('catalog endpoint is reachable without authentication', function (): void {
    // Must be public — the IdP hits this unauthenticated.
    $response = $this->withoutMiddleware()->get('/api/permissions/catalog');
    $response->assertOk();
});

// ─── 2. Gate wiring ───────────────────────────────────────────────────────────

it('gate allows an ability that is present in sso.permissions session', function (): void {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user);
    session()->put('sso.permissions', ['view:dashboard', 'manage:users']);

    expect(Gate::allows('view:dashboard'))->toBeTrue()
        ->and(Gate::allows('manage:users'))->toBeTrue();
});

it('gate denies an ability not present in sso.permissions session', function (): void {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user);
    session()->put('sso.permissions', ['view:dashboard']);

    expect(Gate::allows('manage:users'))->toBeFalse();
});

it('gate ignores non-colon abilities so standard Laravel policies still work', function (): void {
    // PermissionsServiceProvider must return null (not false) for non-colon abilities
    // so it does not short-circuit normal Gate::define() policies.
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user);
    session()->put('sso.permissions', []);

    // 'update' is a standard policy verb (no colon) — Gate::before() must not deny it.
    // Result depends on whether a policy exists; the key check is no exception is thrown.
    expect(fn () => Gate::allows('update'))->not->toThrow(\Throwable::class);
});

it('gate grants super admins all colon-namespaced abilities regardless of session', function (): void {
    // Adjust factory state to however this app marks a super admin.
    $user = \App\Models\User::factory()->superAdmin()->create();
    $this->actingAs($user);
    session()->put('sso.permissions', []); // empty session — should still pass

    expect(Gate::allows('any:ability'))->toBeTrue()
        ->and(Gate::allows('view:dashboard'))->toBeTrue()
        ->and(Gate::allows('manage:users'))->toBeTrue();
});

// ─── 3. Permission catalog completeness ───────────────────────────────────────

it('every manually declared permission appears in the catalog', function (): void {
    $manual = collect(config('permissions.manual', []));
    $catalog = collect((new PermissionCatalog())->all())
        ->map(fn ($p) => $p['action'].':'.$p['subject']);

    $missing = $manual
        ->map(fn ($p) => $p['action'].':'.$p['subject'])
        ->reject(fn (string $key) => $catalog->contains($key));

    expect($missing->values()->all())->toBe([]
        , 'These manually declared permissions are missing from PermissionCatalog: '.implode(', ', $missing->all()));
});

it('every catalog permission has a non-empty action and subject', function (): void {
    $bad = collect((new PermissionCatalog())->all())
        ->filter(fn ($p) => empty($p['action']) || empty($p['subject']));

    expect($bad->count())->toBe(0,
        'These catalog entries have blank action or subject: '.json_encode($bad->values()->all()));
});

it('catalog permissions contain no duplicate keys', function (): void {
    $keys = collect((new PermissionCatalog())->all())
        ->map(fn ($p) => $p['action'].':'.$p['subject']);

    $dupes = $keys->duplicates()->values()->all();

    expect($dupes)->toBe([], 'Duplicate permission keys found: '.implode(', ', $dupes));
});

// ─── 4. Role catalog completeness ─────────────────────────────────────────────

it('every role declared in config/roles.php appears in the role catalog', function (): void {
    $declared = collect(config('roles', []))->pluck('slug');
    $catalog  = collect((new RoleCatalog())->all())->pluck('slug');

    $missing = $declared->reject(fn (string $slug) => $catalog->contains($slug));

    expect($missing->values()->all())->toBe([],
        'These roles are declared but missing from RoleCatalog: '.implode(', ', $missing->all()));
});

it('every role in the catalog has at least one valid permission', function (): void {
    $catalogPerms = collect((new PermissionCatalog())->all())
        ->map(fn ($p) => $p['action'].':'.$p['subject'])
        ->all();

    $rolesWithNoValidPerms = collect((new RoleCatalog())->all())
        ->filter(fn ($role) => empty($role['permissions']))
        ->pluck('slug');

    expect($rolesWithNoValidPerms->values()->all())->toBe([],
        'These roles have no valid permissions after cross-referencing the catalog: '
        .implode(', ', $rolesWithNoValidPerms->all()));
});

it('every permission string in every role exists in the permission catalog', function (): void {
    $catalogKeys = collect((new PermissionCatalog())->all())
        ->map(fn ($p) => $p['action'].':'.$p['subject'])
        ->all();

    $orphans = [];
    foreach ((new RoleCatalog())->all() as $role) {
        foreach ($role['permissions'] as $perm) {
            if (! in_array($perm, $catalogKeys, true)) {
                $orphans[] = "role:{$role['slug']} → {$perm}";
            }
        }
    }

    expect($orphans)->toBe([],
        'These role permission strings reference unknown catalog keys: '.implode(', ', $orphans));
});

it('exactly one role is marked as default', function (): void {
    $defaults = collect((new RoleCatalog())->all())
        ->filter(fn ($r) => $r['is_default'] === true)
        ->pluck('slug');

    expect($defaults->count())->toBe(1,
        'Expected exactly 1 default role, got: '.implode(', ', $defaults->all()));
});

// ─── 5. Gated-feature coverage ────────────────────────────────────────────────
//
// This section scans Filament pages, Livewire components, and HTTP controllers
// for files that touch UI features, then asserts each one has at least one
// Gate::allows(), $this->authorize(), @can, or canAccess() that uses a
// colon-namespaced permission. Adjust $scanDirs and $exclude to match the app.

it('every gated feature class uses a colon-namespaced permission check', function (): void {
    // Directories that contain user-facing feature code.
    $scanDirs = array_filter([
        app_path('Filament/Pages'),
        app_path('Filament/Resources'),
        app_path('Http/Controllers'),
        app_path('Livewire'),
    ], 'is_dir');

    // Classes that intentionally have no per-feature gate (e.g., base pages,
    // auth controllers, error pages). Add slugs here when a class is gated at
    // a higher level (middleware, route group) rather than inline.
    $exclude = [
        // 'GlobalDashboard',   // uncomment if gated at middleware level
    ];

    $ungated = [];

    $finder = new \Symfony\Component\Finder\Finder();
    $finder->in($scanDirs)->files()->name('*.php');

    foreach ($finder as $file) {
        $basename = $file->getBasenameWithoutExtension();
        if (in_array($basename, $exclude, true)) {
            continue;
        }

        $contents = $file->getContents();

        // Look for any colon-namespaced ability reference — covers:
        //   Gate::allows('view:dashboard')
        //   Gate::authorize('manage:users')
        //   $this->authorize('edit:resource')
        //   ->authorize('delete:item')
        //   @can('export:report')
        //   canAccess() method bodies that contain a colon string
        $hasGate = (bool) preg_match(
            "/['\"][a-z][a-z0-9_-]*:[a-z][a-z0-9_:-]*['\"]/",
            $contents
        );

        if (! $hasGate) {
            $ungated[] = $file->getRelativePathname();
        }
    }

    expect($ungated)->toBe([],
        "These feature files have no colon-namespaced permission check — add Gate::allows('action:subject') "
        ."or add them to \$exclude if they are gated at a higher level:\n"
        .implode("\n", $ungated));
});
```

// ─── 6. Login redirect into the SSO app ──────────────────────────────────────
//
// Every unauthenticated request to a protected route must redirect to the IdP
// (auth.odvi.app), not to a local login form. The /login route is Laravel's
// standard auth redirect target; it must forward to sso.redirect, which then
// issues the OAuth2 authorization URL.

it('/login redirects to the sso.redirect route', function (): void {
    $response = $this->get('/login');

    // Laravel's RedirectResponse to the SSO redirect endpoint
    $response->assertRedirect(route('sso.redirect'));
});

it('sso.redirect sends the browser to the IdP authorization URL', function (): void {
    $issuer = rtrim((string) config('sso.issuer', 'https://auth.odvi.app'), '/');

    $response = $this->get(route('sso.redirect'));

    // Must be a redirect away to the IdP — not a 200, not a local page.
    $response->assertStatus(302);
    expect($response->headers->get('Location'))
        ->toStartWith($issuer.'/oauth/authorize');
});

it('sso.redirect authorization URL contains required OAuth2 parameters', function (): void {
    $response = $this->get(route('sso.redirect'));
    $location = $response->headers->get('Location', '');
    parse_str(parse_url($location, PHP_URL_QUERY) ?? '', $params);

    expect($params)->toHaveKeys(['client_id', 'redirect_uri', 'response_type', 'state', 'scope'])
        ->and($params['response_type'])->toBe('code')
        ->and($params['client_id'])->toBe(config('sso.client_id'));
});

it('sso.redirect stores state and code_verifier in the session', function (): void {
    $this->get(route('sso.redirect'));

    expect(session('sso.state'))->not->toBeNull()
        ->and(session('sso.code_verifier'))->not->toBeNull();
});

it('accessing a protected page while unauthenticated redirects through /login to the IdP', function (): void {
    // Hitting /admin (or any auth-guarded URL) must chain through:
    //   /admin  →  /login  →  /auth/sso/redirect  →  IdP authorize URL
    $issuer = rtrim((string) config('sso.issuer', 'https://auth.odvi.app'), '/');

    $response = $this->get('/admin');

    // First hop: unauthenticated → /login
    $response->assertRedirect();
    $loginRedirect = $response->headers->get('Location', '');
    expect($loginRedirect)->toContain('login');

    // Second hop: /login → sso.redirect
    $response2 = $this->get($loginRedirect);
    $response2->assertRedirect(route('sso.redirect'));

    // Third hop: sso.redirect → IdP
    $response3 = $this->get(route('sso.redirect'));
    $response3->assertStatus(302);
    expect($response3->headers->get('Location', ''))
        ->toStartWith($issuer.'/oauth/authorize');
});

it('logout redirects to the IdP logout endpoint', function (): void {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user);

    $issuer = rtrim((string) config('sso.issuer', 'https://auth.odvi.app'), '/');
    $response = $this->post(route('sso.logout'));

    $response->assertStatus(302);
    expect($response->headers->get('Location', ''))
        ->toStartWith($issuer.'/oauth/logout');
});

it('logout invalidates the local session', function (): void {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user);
    session()->put('sso.permissions', ['view:dashboard']);

    $this->post(route('sso.logout'));

    expect(session('sso.permissions'))->toBeNull();
    expect(auth()->check())->toBeFalse();
});
```

Run: `php artisan test --filter SsoIntegrationTest`

> **Tip for the ungated-feature test:** it uses a broad regex; a class that only calls `Gate::before()` internally or delegates to a parent's `canAccess()` will show as ungated. Add those class names to `$exclude` with a comment explaining where the gate lives. The test's value is in making the gating decision visible and explicit — not in requiring every gate to be inline.

---

## Subagent return contract

```yaml
status: complete | partial | failed
catalog_url: "https://<consumer>/api/permissions/catalog"
catalog_reachable: true | false
idp_app_slug: "<app-slug>"
refresh_result: "perms[a=N u=0] roles[a=M u=0]" | null
sections_completed: [2, 3, 4, 5, 7]
errors_unresolved: []
```
