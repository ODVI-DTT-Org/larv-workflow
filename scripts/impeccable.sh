#!/usr/bin/env bash
# Generate Impeccable PRODUCT.md/DESIGN.md from larv docs and run the design detector.
# Detector findings are warnings unless LARV_IMPECCABLE_STRICT=1.
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRICT="${LARV_IMPECCABLE_STRICT:-0}"
FORCE="${LARV_IMPECCABLE_FORCE:-0}"

usage() {
    cat <<'EOF'
Usage: impeccable.sh <command> [project-dir]

Commands:
  status [dir]    Check whether the impeccable CLI is available
  context [dir]   Write PRODUCT.md, DESIGN.md, and .impeccable/config.json from larv docs
  detect [dir]    Scan Blade/Vue/CSS UI paths; write docs/larv/09-verification/impeccable-detect.*
  install [dir]   Print the consumer-app install command (does not run npx unless LARV_IMPECCABLE_INSTALL=1)
  help            Show this help

Environment:
  LARV_IMPECCABLE_BIN       Override CLI path (tests). When unset, uses impeccable or npx impeccable@3.6.0
  LARV_IMPECCABLE_STRICT=1  Fail detect when the CLI reports findings
  LARV_IMPECCABLE_FORCE=1   Overwrite existing PRODUCT.md / DESIGN.md
  LARV_IMPECCABLE_INSTALL=1 Actually run npx impeccable install for the project
EOF
}

resolve_project() {
    local dir="${1:-.}"
    if [ ! -d "$dir" ]; then
        echo "ERROR: project dir not found: $dir" >&2
        exit 64
    fi
    (cd "$dir" && pwd -P)
}

cli_available() {
    local bin="${LARV_IMPECCABLE_BIN:-}"
    if [ -n "$bin" ]; then
        [ -x "$bin" ]
        return
    fi
    command -v impeccable >/dev/null 2>&1 && return 0
    command -v npx >/dev/null 2>&1 && return 0
    return 1
}

run_cli() {
    local bin="${LARV_IMPECCABLE_BIN:-}"
    if [ -n "$bin" ]; then
        "$bin" "$@"
        return
    fi
    if command -v impeccable >/dev/null 2>&1; then
        impeccable "$@"
        return
    fi
    npx --yes impeccable@3.6.0 "$@"
}

cmd_status() {
    local dir
    dir="$(resolve_project "${1:-.}")"
    echo "Impeccable check:"
    if cli_available; then
        echo "  ok: impeccable CLI available"
        echo "  info: design context via scripts/impeccable.sh context $dir"
        echo "  info: detector via scripts/impeccable.sh detect $dir"
    else
        echo "  missing: impeccable CLI (npx impeccable) — detector skipped"
        echo "  info: install with: npx impeccable install --scope=project --no-hooks"
    fi
}

extract_brief_text() {
    local file="$1"
    [ -f "$file" ] || return 0
    # Drop headings/frontmatter noise; keep the first prose lines.
    awk '
        /^---[[:space:]]*$/ { fm++; next }
        fm == 1 { next }
        /^#/ { next }
        /^[[:space:]]*$/ { if (body) print ""; next }
        { body=1; print }
    ' "$file" | head -n 24
}

cmd_context() {
    local dir
    dir="$(resolve_project "${1:-.}")"
    if [ "${2:-}" = "--force" ]; then
        FORCE=1
    fi

    python3 - "$dir" "$FORCE" "$PLUGIN_ROOT" "${LARV_IMPECCABLE_PRODUCT_ONLY:-0}" <<'PY'
import json, os, re, sys
from pathlib import Path

project = Path(sys.argv[1])
force = sys.argv[2] == "1"
product_only = len(sys.argv) > 4 and sys.argv[4] == "1"

def read(rel):
    p = project / rel
    if p.is_file():
        return p.read_text(encoding="utf-8")
    return ""

brief = read("docs/larv/00-discuss/product-brief.md")
brand = read("docs/larv/03-design/brand-spec.md")
decision = read("docs/larv/03-design/design-decision.md")
ui = read("docs/larv/03-design/ui-design.md")
contract = read("docs/larv/03-design/visual-implementation-contract.md")
prefs = read("docs/larv/00-discuss/design-preferences.md")
blob = "\n".join([brief, brand, decision, ui, contract, prefs])

def first_prose(text, fallback):
    lines = []
    in_fm = 0
    for raw in text.splitlines():
        line = raw.strip()
        if line == "---":
            in_fm += 1
            continue
        if in_fm == 1:
            continue
        if not line or line.startswith("#"):
            continue
        lines.append(line)
        if len(lines) >= 8:
            break
    return " ".join(lines).strip() or fallback

users = "Application users of this Laravel product."
purpose = "Operate a Laravel application whose visual system is locked by approved larv mockups."
for line in brief.splitlines():
    low = line.lower()
    if "user" in low and ":" in line:
        users = line.split(":", 1)[-1].strip() or users
    if "purpose" in low and ":" in line:
        purpose = line.split(":", 1)[-1].strip() or purpose
if users == "Application users of this Laravel product.":
    users = first_prose(brief, users)
if "underwrite" in brief.lower() or "credit" in brief.lower():
    purpose = first_prose(brief, purpose)

decision_l = (decision + "\n" + brand + "\n" + prefs).lower()
if "attio finance" in decision_l or "attio-finance" in decision_l:
    variant = "Attio Finance"
    colors = {
        "surface": "#FFFFFF",
        "surface-muted": "#F9FAFB",
        "border": "#E5E7EB",
        "text": "#111827",
        "text-muted": "#6B7280",
        "primary": "#FAA000",
        "accent": "#1B5E7F",
        "danger": "#EF4444",
        "success": "#10B981",
    }
elif "custom" in decision_l and ("667eea" in decision_l or "purple" in decision_l):
    variant = "Attio Custom"
    colors = {
        "surface": "#FFFFFF",
        "surface-muted": "#F9FAFB",
        "border": "#E5E7EB",
        "text": "#111827",
        "text-muted": "#6B7280",
        "primary": "#667eea",
        "accent": "#764ba2",
        "danger": "#EF4444",
        "success": "#10B981",
    }
else:
    variant = "Attio Venture"
    colors = {
        "surface": "#FFFFFF",
        "surface-muted": "#F9FAFB",
        "border": "#E5E7EB",
        "text": "#111827",
        "text-muted": "#6B7280",
        "primary": "#9B6632",
        "accent": "#ECCDAE",
        "danger": "#EF4444",
        "success": "#10B981",
    }

named = {
    "Primary": "primary",
    "Accent": "accent",
    "Text": "text",
    "Surface": "surface",
    "Muted": "text-muted",
    "Border": "border",
}
for label, key in named.items():
    m = re.search(rf"{label}\s*:\s*(#[0-9A-Fa-f]{{3,8}})", brand)
    if m:
        colors[key] = m.group(1).upper() if len(m.group(1)) in (4, 7) else m.group(1)

# Preserve additional hexes from the brand spec as extra named colors.
extra_hexes = []
for hx in re.findall(r"#[0-9A-Fa-f]{6}", brand):
    if hx.upper() not in {v.upper() for v in colors.values()}:
        extra_hexes.append(hx)
        if len(extra_hexes) >= 8:
            break

font = "Segoe UI"
fm = re.search(r"Font\s*:\s*(.+)$", brand, re.I | re.M)
if fm:
    font = fm.group(1).strip().strip("`") or font

font_stack = f"{font}, -apple-system, BlinkMacSystemFont, Roboto, Helvetica Neue, Arial, sans-serif"
mono_stack = "SF Mono, Monaco, Cascadia Code, Roboto Mono, Consolas, monospace"

product_path = project / "PRODUCT.md"
design_path = project / "DESIGN.md"

product = f"""# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

{users}

## Product Purpose

{purpose}

## Brand Personality

Restrained, dense, operational. This is an Operate-mode Laravel workspace, not a marketing site.

## Anti-references

- Purple-to-blue gradients, glassmorphism, neon glow, Inter-as-default, and generic SaaS hero-metric layouts.
- Nested marketing cards, side-tab accent borders, gradient text, and bounce/elastic easing.
- Do not invent a new visual world. Approved mockups and `docs/larv/03-design/visual-implementation-contract.md` win.

## Constraints

- Visual source of truth: `docs/larv/03-design/visual-implementation-contract.md` and `docs/larv/03-design/mockups/`.
- Design system variant: {variant}.
- Impeccable polishes implementation against that contract. It does not replace Phase 3 mockups.
- Do not run Anthropic `frontend-design` in this project.
"""

color_yaml = "\n".join(f'  {k}: "{v}"' for k, v in colors.items())
for i, hx in enumerate(extra_hexes, start=1):
    color_yaml += f'\n  extra-{i}: "{hx}"'

design = f"""---
name: {variant}
description: Laravel app visual system derived from larv brand-spec and Attio tokens.
colors:
{color_yaml}
typography:
  display:
    fontFamily: "{font_stack}"
    fontSize: "1.5rem"
    fontWeight: 600
    lineHeight: 1.2
  title:
    fontFamily: "{font_stack}"
    fontSize: "1.125rem"
    fontWeight: 600
    lineHeight: 1.35
  body:
    fontFamily: "{font_stack}"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
  mono:
    fontFamily: "{mono_stack}"
    fontSize: "0.875rem"
    fontWeight: 500
rounded:
  sm: "4px"
  md: "6px"
  lg: "8px"
  xl: "12px"
  "2xl": "16px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
---

# Design System: {variant}

## 1. Visual Theme

Operate-mode Laravel CRM/workspace. Dense, readable, restrained. Brand lives in precise tokens, not decoration.

## 2. Color Palette

- **Surface** ({colors['surface']}) — page and panel ground
- **Primary** ({colors['primary']}) — actions, focus, brand
- **Accent** ({colors['accent']}) — secondary emphasis
- **Text** ({colors['text']}) — primary copy
- **Muted** ({colors['text-muted']}) — meta and secondary copy
- **Border** ({colors['border']}) — hairlines

## 3. Typography

- **UI/body:** {font}
- **Mono:** SF Mono / Consolas for numbers and IDs
- System stack is intentional for Attio-derived apps. Do not switch the product to Inter or a display serif.

## 4. Shape

Card radius 8px, controls 6px, small chips may be pill. Do not over-round small cards.

## 5. Do and Do Not

### Do

- Match approved mockups route-for-route.
- Keep one shared app shell for every role.
- Use documented tokens before inventing colors or type sizes.

### Do Not

- Do not use purple-to-blue gradients, glassmorphism, gradient text, or side-tab accent borders.
- Do not nest cards unless the approved mockup does; if it does, document an ignore with a reason.
- Do not replace this system with an Impeccable world roll.
"""

wrote = []
if force or not product_path.exists():
    product_path.write_text(product, encoding="utf-8")
    wrote.append("PRODUCT.md")
else:
    print(f"context: keep existing {product_path}")

if product_only:
    print("context: product-only, DESIGN.md left for the direction pick")
elif force or not design_path.exists():
    design_path.write_text(design, encoding="utf-8")
    wrote.append("DESIGN.md")
else:
    print(f"context: keep existing {design_path}")

cfg_dir = project / ".impeccable"
cfg_dir.mkdir(parents=True, exist_ok=True)
cfg_path = cfg_dir / "config.json"
desired = {
    "detector": {
        "extensions": [".blade.php", ".vue", ".php", ".css", ".scss", ".html"],
        "ignoreRules": [],
        "ignoreFiles": [
            "vendor/**",
            "node_modules/**",
            "storage/**",
            "bootstrap/cache/**",
            "public/build/**",
            "docs/larv/03-design/mockups/**",
            "attio-*-html-effectiveness*/**",
        ],
        "ignoreValues": [
            {"rule": "overused-font", "value": "Arial", "reason": "Attio system stack fallback"},
            {"rule": "overused-font", "value": "Segoe UI", "reason": "Attio system stack"},
            {"rule": "overused-font", "value": "system-ui", "reason": "Attio system stack"},
            {"rule": "overused-font", "value": "Roboto", "reason": "Attio system stack fallback"},
        ],
        "designSystem": {"enabled": True},
    },
    "hook": {"enabled": False},
}
data = {}
if cfg_path.is_file():
    try:
        data = json.loads(cfg_path.read_text(encoding="utf-8"))
    except Exception:
        data = {}
if not isinstance(data, dict):
    data = {}
det = data.get("detector")
if not isinstance(det, dict):
    det = {}
# Union extensions and ignore files; do not drop user extras.
ext = list(dict.fromkeys(list(det.get("extensions") or []) + desired["detector"]["extensions"]))
ign_f = list(dict.fromkeys(list(det.get("ignoreFiles") or []) + desired["detector"]["ignoreFiles"]))
ign_v = det.get("ignoreValues") if isinstance(det.get("ignoreValues"), list) else []
seen = {(x.get("rule"), x.get("value")) for x in ign_v if isinstance(x, dict)}
for item in desired["detector"]["ignoreValues"]:
    key = (item["rule"], item["value"])
    if key not in seen:
        ign_v.append(item)
        seen.add(key)
det["extensions"] = ext
det["ignoreFiles"] = ign_f
det["ignoreValues"] = ign_v
if "ignoreRules" not in det:
    det["ignoreRules"] = []
ds = det.get("designSystem")
if not isinstance(ds, dict):
    ds = {}
if "enabled" not in ds:
    ds["enabled"] = True
det["designSystem"] = ds
data["detector"] = det
hook = data.get("hook")
if not isinstance(hook, dict):
    hook = {"enabled": False}
data["hook"] = hook
cfg_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
wrote.append(".impeccable/config.json")
print("context: wrote " + ", ".join(wrote))
PY
}

ui_targets() {
    local dir="$1"
    local d
    local found=()
    for d in \
        resources/views \
        resources/js \
        resources/css \
        resources/sass \
        resources/client \
        public/css \
        public/js \
        app/Livewire \
        app/View
    do
        if [ -d "$dir/$d" ]; then
            found+=("$dir/$d")
        fi
    done
    if [ "${#found[@]}" -eq 0 ]; then
        return 1
    fi
    printf '%s\n' "${found[@]}"
}

cmd_detect() {
    local dir
    dir="$(resolve_project "${1:-.}")"
    local report_dir="$dir/docs/larv/09-verification"
    mkdir -p "$report_dir"
    local md="$report_dir/impeccable-detect.md"
    local jsonf="$report_dir/impeccable-detect.json"

    local targets
    if ! targets="$(ui_targets "$dir")"; then
        echo "detect: skip (no Blade/Vue/CSS UI paths)"
        cat >"$md" <<EOF
# Impeccable detector

Status: skipped
Reason: no Blade/Vue/CSS UI paths in $dir
EOF
        echo '{"status":"skipped","reason":"no UI paths"}' >"$jsonf"
        return 0
    fi

    if ! cli_available; then
        echo "detect: skip (impeccable CLI missing)"
        cat >"$md" <<EOF
# Impeccable detector

Status: skipped
Reason: impeccable CLI missing
EOF
        echo '{"status":"skipped","reason":"missing CLI"}' >"$jsonf"
        return 0
    fi

    local out err status
    out="$(mktemp)"
    err="$(mktemp)"
    status=0
    # shellcheck disable=SC2086
    set +e
    # Word-split targets on newlines.
    local -a args=()
    while IFS= read -r t; do
        [ -n "$t" ] && args+=("$t")
    done <<<"$targets"
    run_cli detect --json "${args[@]}" >"$out" 2>"$err"
    status=$?
    set -e

    cp "$out" "$jsonf"
    {
        echo "# Impeccable detector"
        echo
        echo "Status: exit $status"
        echo "Targets:"
        printf -- "- %s\n" "${args[@]}"
        echo
        echo "## stdout"
        echo
        echo '```json'
        cat "$out"
        echo '```'
        echo
        echo "## stderr"
        echo
        echo '```'
        cat "$err"
        echo '```'
    } >"$md"

    if grep -q "nested-cards" "$out" "$err" 2>/dev/null; then
        :
    fi

    echo "detect: wrote $md (cli exit $status)"
    if [ "$status" -eq 0 ]; then
        rm -f "$out" "$err"
        return 0
    fi
    if [ "$STRICT" = "1" ]; then
        rm -f "$out" "$err"
        return "$status"
    fi
    echo "detect: findings or CLI error recorded as warnings (set LARV_IMPECCABLE_STRICT=1 to fail)"
    rm -f "$out" "$err"
    return 0
}

cmd_install() {
    local dir
    dir="$(resolve_project "${1:-.}")"
    cat <<EOF
Install Impeccable into the consumer Laravel app at $dir (not into the larv plugin repo).

  npx impeccable install --providers=grok,claude,cursor,codex --scope=project --no-hooks

Then in the agent chat:

  /impeccable init

Do not run Anthropic frontend-design in the same project.
Enable hooks later with /impeccable hooks on after the harness trusts the folder.
EOF
    if [ "${LARV_IMPECCABLE_INSTALL:-0}" = "1" ]; then
        (cd "$dir" && npx --yes impeccable@3.6.0 install --providers=grok,claude,cursor,codex --scope=project --no-hooks)
    fi
}

main() {
    local cmd="${1:-help}"
    shift || true
    case "$cmd" in
        help|-h|--help) usage ;;
        status) cmd_status "${1:-.}" ;;
        context) cmd_context "${1:-.}" "${2:-}" ;;
        detect) cmd_detect "${1:-.}" ;;
        install) cmd_install "${1:-.}" ;;
        *)
            echo "Unknown command: $cmd" >&2
            usage >&2
            exit 64
            ;;
    esac
}

main "$@"
