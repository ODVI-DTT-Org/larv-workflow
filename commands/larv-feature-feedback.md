---
name: larv-feature-feedback
description: Add an in-app feedback feature to the current Laravel app using bundled feedback references and Resend email delivery.
---

Argument: optional focus such as `widget`, `admin`, `screenshots`, or `resend`.

Invoke the `larv-feature-feedback` skill.

## Contract

- Add a real in-app feedback feature, not only documentation or a mockup.
- Reference these local implementations first:
  - `examples/rfp/app/Domain/Feedback/Actions/SubmitFeedback.php`
  - `examples/rfp/app/Livewire/Feedback/FeedbackWidget.php`
  - `examples/rfp/app/Livewire/Feedback/FeedbackAdmin.php`
  - `examples/rfp/resources/views/livewire/feedback/feedback-widget.blade.php`
  - `examples/rfp/resources/views/livewire/feedback/feedback-admin.blade.php`
  - `examples/rfp/config/feedback.php`
  - `examples/rfp/config/mail.php`
  - `examples/imu/backend-imu/src/routes/feedback.ts`
  - `examples/imu/frontend-web-imu/src/components/feedback/FeedbackWidget.vue`
- Use Resend API for email delivery in Laravel: `MAIL_MAILER=resend`, `RESEND_API_KEY`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME`, and recipient config such as `FEEDBACK_RECIPIENT_EMAIL`.
- Feedback submission must persist even if email/webhook delivery fails.
- Capture user, type, title, description, optional severity, notify-user flag, URL/route/user-agent/viewport context, and optional screenshot/attachment where feasible.
- Add admin triage for status updates: `open`, `in_progress`, `done`, `wont_fix`.
- Run required Laravel/frontend commands, restart/probe the sandbox if needed, and show the public URL.

## Required Artifacts

- `docs/larv/features/feedback/design.md`
- `docs/larv/features/feedback/implementation-report.md`
- `docs/user-manual/feedback.md` when `docs/user-manual/` exists.
