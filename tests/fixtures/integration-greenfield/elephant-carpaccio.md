# Slice Plan

## slice-01-auth-scaffold
goal: Stand up Sanctum auth with seeded admin
depends_on: []
parallel: false

## slice-02-todos-crud
goal: CRUD for todo items, scoped per user
depends_on: [slice-01-auth-scaffold]
parallel: false
