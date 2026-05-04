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

SSH: ssh {{vm-user}}@{{vm-host}}
Logs: docker compose -f /srv/{{slug}}/docker-compose.yml logs -f app
Reset: docker compose exec app php artisan migrate:fresh --seed

## Tests

Pest: {{passed}}/{{total}}
Playwright: {{passed}}/{{total}}

## Plugin Improvement Notes

- (none) | [plugin] {{theme}} - {{body}} | [project] {{body}}

## Next

slice-{{NN+1}}-{{name}}
