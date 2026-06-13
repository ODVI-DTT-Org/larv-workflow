---
name: larv-hyperframes
description: "Use when creating a HyperFrames promo video for a Laravel or larv-managed app, especially when the app needs discovery, theme direction, app screenshots, role/workflow documentation, claim confirmation, or delegated rendering with hyperframes-codex."
---

# larv-hyperframes

## Overview

Use this skill to turn a Laravel app into a reliable short promo video workflow. The core rule is brief first, render second: inspect the app, generate concise product/workflow/theme documentation, gather or propose visual references, ask the user to confirm inferred claims, then use `hyperframes-codex` to create the actual video only after approval.

This skill is for internal business apps where the video must explain the use case, roles, process phases, and outcomes without inventing unsupported features.

## Invocation Modes

### Discovery mode

Use this when the user asks for a promo but the app does not already have a clear manual, product brief, or role workflow.

Generate the planning files and stop for approval. Include a theme recommendation and screenshot plan. Do not create or render the HyperFrames project unless the user explicitly says the brief is approved.

### Execution mode

Use this when the user has already approved a generated promo brief or explicitly asks to execute the approved brief.

Read the approved brief, then use `hyperframes-codex` for project creation, validation, rendering, and final MP4 reporting.

## Discovery Workflow

1. Identify the source app.
   - Use the current directory if it is a Laravel app.
   - If the user provides a path, inspect that path.
   - Prefer existing `docs/larv/`, `docs/user-manual/`, `README.md`, `DOCS.md`, routes, models, migrations, policies, seeders, tests, Filament resources, Livewire components, Blade views, enums, exports, PDFs, and permission/role definitions.

2. Extract only defensible facts.
   - Product name and app entry points.
   - Core business problem and use case.
   - Roles/personas and what each one actually does.
   - Workflow phases, statuses, approvals, signatures, reports, exports, and records.
   - Important entities such as cycles, requests, applications, queues, evaluations, documents, or tickets.
   - Visual surfaces that can inspire the promo: dashboards, admin resources, tables, forms, status badges, timeline steps, PDF/export screens.

3. Gather visual source material.
   - Ask whether the user has a preferred theme, brand reference, existing video, website, screenshot set, or design direction.
   - If no preference is provided, generate 2-3 concise theme candidates and recommend one default based on the app domain.
   - Look for existing app screenshots, mockups, design docs, brand files, logos, favicon assets, public images, and UI components.
   - If the app can be run locally and credentials/seed data are available, capture representative screenshots of key screens using Playwright or the repo's existing browser-test tooling.
   - Store screenshots under `docs/larv/hyperframes/screenshots/` or, when working outside the source app, under the sibling promo-brief package's `screenshots/` folder.
   - Do not block discovery solely because screenshots cannot be captured. Document the blocker and describe which screenshots should be captured later.
   - Use screenshots as reference material or contained UI mockups in the video; do not make the promo a slideshow of raw screenshots.

4. Separate facts from inference.
   - Treat code/docs as confirmed evidence.
   - Put unclear claims into "Claims That Need User Confirmation."
   - Do not claim notifications, external integrations, automation, HRIS/payroll sync, AI features, email/SMS reminders, analytics, approvals, signatures, exports, or audit trails unless verified.

5. Generate these files.
   - `docs/larv/hyperframes/product-brief.md`
   - `docs/larv/hyperframes/workflow-summary.md`
   - `docs/larv/hyperframes/visual-theme.md`
   - `docs/larv/hyperframes/promo-brief.md`

6. Stop for user review.
   - Summarize the files created.
   - Mention any screenshots captured or screenshots still needed.
   - Ask the user to review `promo-brief.md`.
   - Mention the execution prompt already included at the bottom of the promo brief.

## Required File Contents

### product-brief.md

Include:
- source app path
- product name
- framework and main entry points
- brief purpose
- core message
- business problem solved
- target audience
- confirmed capabilities
- inferred claims requiring confirmation

### workflow-summary.md

Include:
- roles/personas
- high-level workflow phases
- key screens/resources/routes
- main records/entities
- status lifecycle, if detected
- outputs such as reports, PDFs, exports, signatures, dashboards, or closed records
- a short "manual-lite" explanation of how the app is used by each role

### visual-theme.md

Include:
- user-provided theme or reference, if any
- available brand assets and screenshot paths
- screenshot capture status: captured, unavailable, or needs credentials/setup
- 2-3 theme candidates when the user did not specify a direction
- recommended theme with rationale tied to the app audience and workflow
- color, typography, motion, layout, and UI-motif guidance
- screenshot usage guidance: which screens should appear, how they should be cropped/framed, and which should only inspire recreated UI
- constraints to avoid clutter, overlap, unsupported imagery, stock-photo usage, and illegible text

### promo-brief.md

Include:
- working title
- source app summary
- promo purpose
- core message
- opening problem statement
- target audience
- main roles
- workflow phases for the video
- product logic to mention lightly
- visual direction, linked to `visual-theme.md`
- screenshot/reference asset plan
- suggested 30-second storyboard
- alternate short voiceover
- claims that need user confirmation
- recommended execution prompt

## Required Execution Prompt

Add this section at the bottom of every generated `promo-brief.md`, customized with the actual paths, app name, output project name, and any approved details:

```text
Use $larv-hyperframes to execute the approved promo brief.

Use $hyperframes-codex to create a 30-second 1920x1080 promo video for <APP_NAME> using <PROMO_BRIEF_PATH> as the creative brief and <SOURCE_APP_PATH> as the source app.

Also read <VISUAL_THEME_PATH> and use any approved screenshots or reference assets in <SCREENSHOT_OR_ASSET_PATHS>. If no theme was approved, use the recommended theme from the visual theme file.

Create a new HyperFrames project named <OUTPUT_PROJECT_NAME> beside the existing promo projects unless I specify another output directory.

The video should introduce <APP_NAME> as a Digital Transformation Team app. It should show the use case, main roles, and workflow phases without becoming a full user manual.

Use the approved visual theme with dashboard-inspired visuals, role lanes, timeline states, product cards, status badges, and a clear final record/export/result moment where supported by the app. Screenshots may be used as cropped, framed product evidence or recreated as simplified UI scenes, but should not become raw full-screen slides.

Do not use stock photos. Do not include unsupported claims. Validate the project, render to output.mp4, and report the final file path.
```

## Execution Workflow

When executing an approved brief:

1. Read `promo-brief.md` and any linked `product-brief.md` or `workflow-summary.md`.
2. Read `visual-theme.md` and inspect any referenced screenshots/assets.
3. Use `hyperframes-codex`.
4. Create or reuse the target HyperFrames project.
5. Keep the video short and legible, usually 30 seconds at 1920x1080.
6. Build visuals from app concepts: dashboards, lanes, timelines, cards, statuses, forms, records, signatures, exports, or reports.
7. Use screenshots selectively as product evidence, cropped UI anchors, or reference for recreated visuals.
8. Avoid dense training/manual screens.
9. Validate before rendering.
10. Render `output.mp4`.
11. Report source files, validation result, final video path, duration, resolution, screenshot/assets used, and any claims intentionally omitted.

## Quality Bar

- The promo must be accurate before it is attractive.
- The first screen should make the product/use case clear.
- The story should explain problem, product, roles, process, reliable outcome, and DTT identity.
- Theme direction should be explicit before render starts; if the user gives none, state the chosen default.
- Screenshots should improve product specificity without creating overlap, illegible text, or slideshow pacing.
- Any uncertainty belongs in the confirmation list, not the video.
- Do not skip validation or final render checks before reporting completion.
