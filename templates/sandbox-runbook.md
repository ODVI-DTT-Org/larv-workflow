# Sandbox Runbook - {{project-name}}

## App URL

{{app-url}}
Login: {{seeded-email}} / {{seeded-password}}

## VM

Host: {{vm-host}}
User: {{vm-user}}
Runtime: local on this VM. Do not SSH to {{vm-host}} for the normal larv flow.

## Docker Stack

Compose: ~/apps/{{slug}}/docker-compose.yml
Services: {{services-list}}
Up: docker compose up -d
Logs: docker compose logs -f app
Reset: docker compose exec app php artisan migrate:fresh --seed

## Firewall

ufw allow from any to any port 80,443,{{additional-ports}}

## Reverse Proxy

nginx to app:8000
TLS: Let's Encrypt
DNS: A record {{slug}}.{{vm-base-domain}} to VM
