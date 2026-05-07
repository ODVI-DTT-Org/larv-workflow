# Slice {{NN}} - {{slice-name}}

## Status

{{Ready for QA | Partial | Blocked}}

## What Was Built

- {{files}}
- {{migrations}}
- {{tests}}

## How To QA

URL: {{app-url}}/{{path}}
Login: {{seeded-creds}}

1. {{step}}
2. {{step}}
3. {{step}}

## Sandbox Controls

Runtime: local on {{vm-host}}; do not SSH for the normal larv flow.
Logs: docker compose logs -f app
Reset: docker compose exec app php artisan migrate:fresh --seed

## Tests

Pest: {{passed}}/{{total}}
Playwright: {{passed}}/{{total}}

## Plugin Improvement Notes

- (none) | [plugin] {{theme}} - {{body}} | [project] {{body}}

## Next

slice-{{NN+1}}-{{name}}
