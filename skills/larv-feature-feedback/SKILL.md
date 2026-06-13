---
name: larv-feature-feedback
description: Use when the user types /larv-feature-feedback or asks to add in-app feedback, bug report, idea report, screenshot feedback, or developer feedback to a Laravel app.
---

# larv-feature-feedback

Add a production in-app feedback feature to the current Laravel app. The feature must let authenticated users submit feedback from inside the app and let an admin/developer triage reports.

## Reference Sources

Read these local examples before designing or implementing:

- `examples/rfp/app/Domain/Feedback/Actions/SubmitFeedback.php` - Laravel action that stores feedback, stores screenshot, sends email/webhook, and swallows delivery failures.
- `examples/rfp/app/Models/FeedbackReport.php` and `examples/rfp/database/migrations/2026_05_29_175007_create_feedback_reports_table.php` - report schema, types, statuses, severities.
- `examples/rfp/app/Livewire/Feedback/FeedbackWidget.php` and `examples/rfp/resources/views/livewire/feedback/feedback-widget.blade.php` - floating authenticated widget, modal, validation, context and screenshot capture.
- `examples/rfp/app/Livewire/Feedback/FeedbackAdmin.php` and `examples/rfp/resources/views/livewire/feedback/feedback-admin.blade.php` - admin list, filters, details, status triage, screenshot preview.
- `examples/rfp/app/Mail/FeedbackSubmittedMail.php`, `examples/rfp/app/Mail/FeedbackResolvedMail.php`, and `examples/rfp/resources/views/mail/feedback-*.blade.php` - email notification patterns.
- `examples/rfp/config/feedback.php`, `examples/rfp/config/mail.php`, and `examples/rfp/config/services.php` - config/env pattern, including Laravel's `resend` transport.
- `examples/imu/backend-imu/src/routes/feedback.ts` and `examples/imu/frontend-web-imu/src/components/feedback/FeedbackWidget.vue` - API validation, Vue widget, context capture, admin API, and non-blocking email behavior.

## Required Feature Shape

- Authenticated floating feedback entry point visible in the app shell.
- Feedback types: `bug`, `idea`, `question`, `other`.
- Bug severities: `low`, `medium`, `high`, `critical`.
- Statuses: `open`, `in_progress`, `done`, `wont_fix`.
- Fields: user id/email when available, type, title, description, severity, status, notify user flag, context JSON, optional screenshot/attachment path, resolved timestamp.
- Context capture: URL, route, user agent, viewport, app/version when available.
- Optional screenshot capture where the frontend stack supports it. Limit image payload size and validate MIME/data URL.
- Admin triage page with filters, detail view, status update, screenshot preview, and notification option.
- Email delivery through Resend for Laravel apps.

## Resend Requirements

Use Laravel's Resend transport when the app is Laravel 10+ or already supports it:

- `MAIL_MAILER=resend`
- `RESEND_API_KEY=<user-provided-secret>`
- `MAIL_FROM_ADDRESS=<verified Resend sender/domain>`
- `MAIL_FROM_NAME=<app name>`
- `FEEDBACK_RECIPIENT_EMAIL=<developer/admin recipient>`

If `resend/resend-laravel` or required mail transport support is missing, add the package/config needed for the app's Laravel version. Never hardcode the API key. Update `.env.example`, `docs/Handsoff/env-guide.md` when present, and `docs/user-manual/feedback.md` with where to get and set Resend values.

Feedback persistence must not depend on email success. Catch and log email/webhook exceptions after the report is saved.

## Workflow

1. Verify the app stack: Livewire, Blade, Filament, Inertia, Vue, React, or API frontend.
2. Create `docs/larv/features/feedback/design.md` with selected implementation shape, referenced example files, DB fields, routes/components, Resend env vars, and test plan.
3. Implement the database/model/action/controller/component/page in the native stack.
4. Add widget or navigation entry in the existing shared app shell.
5. Add admin/developer triage route guarded by role/policy or recipient-email rule.
6. Add mailables/templates for submitted and resolved feedback.
7. Add config and `.env.example` entries for feedback and Resend.
8. Add tests for submit validation, persistence when email fails, admin authorization, status update, and optional resolved email.
9. Update `docs/user-manual/feedback.md` when `docs/user-manual/` exists.
10. Run required Laravel/frontend commands yourself, including migrations/tests/build/cache clears as needed.
11. Restart/probe sandbox if the app is running and print the public URL for the feedback widget/admin page.
12. Write `docs/larv/features/feedback/implementation-report.md`.

## Hard Blocks

- Do not create only a contact form outside the app shell.
- Do not send feedback by email without persisting it first.
- Do not fail the user's submission because Resend/webhook delivery failed.
- Do not hardcode `RESEND_API_KEY`, recipient emails, from addresses, or secrets.
- Do not expose the feedback admin page to all users.
- Do not ask the user to run Laravel, npm, migration, queue, build, cache, server restart, or sandbox commands manually.
- Do not announce completion without the feedback route/widget location, admin route, public URL, and implementation report path.
