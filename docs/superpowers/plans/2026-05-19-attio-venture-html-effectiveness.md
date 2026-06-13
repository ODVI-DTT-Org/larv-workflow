# Attio Venture HTML Effectiveness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create attio-venture-html-effectiveness-design with 20 production-ready HTML templates using Attio Venture's brown/tan branding (#9B6632, #ECCDAE, #755637).

**Architecture:** Clone html-effectiveness repo, adapt to Attio design system, create attio-venture-html-effectiveness-design folder with Attio Venture colors and logo. Mirror Attio Finance structure exactly (20 templates across 8 categories) plus 3 CRM dashboards. All templates are self-contained with no build steps.

**Tech Stack:** HTML5, CSS3 (custom properties), Vanilla JavaScript, no external dependencies.

---

## File Structure

```
<larv-plugin-root>/attio-venture-html-effectiveness-design/
├── design-system.css           (Attio Venture color palette + components)
├── crm-shared.js               (Shared CRM utilities - modal, selection, filtering)
├── crm-shared-styles.css       (Shared CRM styling)
├── attio-venture-logo.png          (Brand asset - 225x225px)
├── index.html                  (Gallery with all 20 templates + 3 CRM)
├── 01-exploration-code-approaches.html
├── 02-exploration-visual-designs.html
├── 03-code-review-pr.html
├── 04-code-understanding.html
├── 05-design-system.html
├── 06-component-variants.html
├── 07-prototype-animation.html
├── 08-prototype-interaction.html
├── 09-slide-deck.html
├── 10-svg-illustrations.html
├── 11-status-report.html
├── 12-incident-report.html
├── 13-flowchart-diagram.html
├── 14-research-feature-explainer.html
├── 15-research-concept-explainer.html
├── 16-implementation-plan.html
├── 17-pr-writeup.html
├── 18-editor-triage-board.html
├── 19-editor-feature-flags.html
├── 20-editor-prompt-tuner.html
├── 21-credit-officer-crm.html
├── 22-sales-crm.html
└── 23-service-crm.html
```

---

## Task 1: Project Setup and Logo

**Files:**
- Create: `<larv-plugin-root>/attio-venture-html-effectiveness-design/`
- Create: `<larv-plugin-root>/attio-venture-html-effectiveness-design/attio-venture-logo.png`

- [ ] **Step 1: Create project directory**

```bash
mkdir -p <larv-plugin-root>/attio-venture-html-effectiveness-design
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
```

Expected: Directory created and ready for files.

- [ ] **Step 2: Copy Attio Venture logo**

```bash
cp /tmp/attio-venture-logo.png <larv-plugin-root>/attio-venture-html-effectiveness-design/attio-venture-logo.png
```

Expected: Logo file exists (270K, 1178x1178px).

- [ ] **Step 3: Initialize git tracking**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git init
git add attio-venture-logo.png
git commit -m "Initial: Add Attio Venture logo (1178x1178px, 270K)"
```

Expected: Project initialized with logo committed.

---

## Task 2: Create Attio Venture Design System CSS

**Files:**
- Create: `<larv-plugin-root>/attio-venture-html-effectiveness-design/design-system.css`

- [ ] **Step 1: Write design-system.css with Attio Venture colors**

Use the Attio Finance design-system.css as template, but replace all brand color variables with Attio Venture colors:
- `--oak-primary: #9B6632` (warm brown, replace Attio Finance gold)
- `--oak-accent: #ECCDAE` (light tan, replace Attio Finance secondary)
- `--oak-dark: #755637` (dark brown, replace Attio Finance dark)

Keep all component styles (buttons, cards, forms, tables, badges, alerts) identical to Attio Finance version but using Attio Venture CSS variables.

```css
/* Attio Venture HTML Effectiveness Design System */

:root {
  /* ── Attio Venture Brand Colors ───────────────── */
  --oak-primary: #9B6632;        /* Warm Brown - Primary */
  --oak-primary-light: #B07D47;  /* Lighter brown */
  --oak-primary-lighter: #C69765;/* Even lighter for hover */
  --oak-dark: #755637;           /* Dark Brown - Contrast */
  --oak-accent: #ECCDAE;         /* Light Tan - Accent */
  --oak-accent-light: #F5DCC5;   /* Lighter tan */
  --oak-warning: #F59E0B;        /* Amber - Caution */
  --oak-danger: #EF4444;         /* Red - Risk */
  --oak-success: #10B981;        /* Green - Confirmation */

  /* ── Attio-Inspired Neutrals ──────────────── */
  --white: #FFFFFF;
  --gray-50: #F9FAFB;
  --gray-100: #F3F4F6;
  --gray-200: #E5E7EB;
  --gray-300: #D1D5DB;
  --gray-400: #9CA3AF;
  --gray-500: #6B7280;
  --gray-600: #4B5563;
  --gray-700: #374151;
  --gray-800: #1F2937;
  --gray-900: #111827;

  /* ── Typography ───────────────────────────── */
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-mono: "SF Mono", Monaco, "Cascadia Code", "Roboto Mono", Consolas, monospace;

  /* ── Spacing (8px grid) ───────────────────── */
  --space-2: 2px;
  --space-4: 4px;
  --space-6: 6px;
  --space-8: 8px;
  --space-12: 12px;
  --space-16: 16px;
  --space-20: 20px;
  --space-24: 24px;
  --space-32: 32px;
  --space-40: 40px;
  --space-48: 48px;
  --space-56: 56px;
  --space-64: 64px;

  /* ── Borders & Radius ─────────────────────── */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-lg: 8px;
  --radius-xl: 12px;
  --radius-2xl: 16px;
  --border-light: 1px solid var(--gray-200);
  --border-md: 1px solid var(--gray-300);

  /* ── Shadows (subtle, Notion-like) ────────── */
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);

  /* ── Transitions ──────────────────────────── */
  --transition-fast: 150ms ease-out;
  --transition-base: 200ms ease-out;
}

/* ════════════════════════════════════════════════════ */
/* GLOBAL STYLES                                       */
/* ════════════════════════════════════════════════════ */

* { box-sizing: border-box; }

html {
  scroll-behavior: smooth;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body {
  margin: 0;
  padding: 0;
  background: var(--white);
  color: var(--gray-900);
  font-family: var(--font-sans);
  font-size: 15px;
  line-height: 1.6;
}

a {
  color: var(--oak-primary);
  text-decoration: none;
  transition: color var(--transition-fast);
}

a:hover {
  color: var(--oak-primary-light);
  text-decoration: underline;
}

/* ════════════════════════════════════════════════════ */
/* LAYOUT                                              */
/* ════════════════════════════════════════════════════ */

.container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--space-24);
}

@media (max-width: 768px) {
  .container {
    padding: 0 var(--space-16);
  }
}

.page {
  max-width: 980px;
  margin: 0 auto;
}

/* ════════════════════════════════════════════════════ */
/* HEADER & NAVIGATION                                 */
/* ════════════════════════════════════════════════════ */

.header {
  padding: var(--space-24) 0;
  border-bottom: var(--border-light);
  background: var(--gray-50);
  position: sticky;
  top: 0;
  z-index: 10;
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-24);
}

.logo {
  font-size: 18px;
  font-weight: 700;
  color: var(--oak-primary);
  display: flex;
  align-items: center;
  gap: var(--space-8);
}

.logo-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-md);
  overflow: hidden;
  background: var(--white);
}

.logo-icon img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.logo-icon svg {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

/* ════════════════════════════════════════════════════ */
/* TYPOGRAPHY                                          */
/* ════════════════════════════════════════════════════ */

h1, h2, h3, h4, h5, h6 {
  margin: 0;
  font-weight: 600;
  line-height: 1.3;
  color: var(--gray-900);
}

h1 {
  font-size: 40px;
  letter-spacing: -0.02em;
}

h2 {
  font-size: 32px;
  letter-spacing: -0.015em;
  margin-bottom: var(--space-8);
}

h3 {
  font-size: 24px;
  letter-spacing: -0.01em;
  margin-bottom: var(--space-6);
}

h4 {
  font-size: 18px;
  margin-bottom: var(--space-4);
}

p {
  margin: 0 0 var(--space-16);
  color: var(--gray-700);
}

code {
  font-family: var(--font-mono);
  font-size: 13px;
  background: var(--gray-100);
  padding: 2px 6px;
  border-radius: var(--radius-md);
  color: var(--gray-800);
}

/* ════════════════════════════════════════════════════ */
/* CARDS & PANELS                                      */
/* ════════════════════════════════════════════════════ */

.card {
  background: var(--white);
  border: var(--border-light);
  border-radius: var(--radius-lg);
  padding: var(--space-24);
  transition: all var(--transition-base);
  box-shadow: var(--shadow-sm);
}

.card:hover {
  border-color: var(--gray-300);
  box-shadow: var(--shadow-md);
}

.card-dense {
  padding: var(--space-16);
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--gray-900);
  margin-bottom: var(--space-8);
}

.card-description {
  font-size: 14px;
  color: var(--gray-600);
  line-height: 1.5;
}

/* ════════════════════════════════════════════════════ */
/* BUTTONS                                             */
/* ════════════════════════════════════════════════════ */

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-8);
  padding: var(--space-12) var(--space-20);
  font-size: 14px;
  font-weight: 600;
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all var(--transition-fast);
  font-family: var(--font-sans);
}

.btn-primary {
  background: var(--oak-primary);
  color: white;
}

.btn-primary:hover {
  background: var(--oak-primary-light);
  box-shadow: var(--shadow-md);
}

.btn-secondary {
  background: var(--gray-100);
  color: var(--gray-900);
  border: var(--border-light);
}

.btn-secondary:hover {
  background: var(--gray-200);
}

.btn-success {
  background: var(--oak-success);
  color: white;
}

.btn-success:hover {
  background: #059669;
}

.btn-danger {
  background: var(--oak-danger);
  color: white;
}

.btn-danger:hover {
  background: #DC2626;
}

.btn-small {
  padding: var(--space-8) var(--space-12);
  font-size: 13px;
}

/* ════════════════════════════════════════════════════ */
/* BADGES & LABELS                                     */
/* ════════════════════════════════════════════════════ */

.badge {
  display: inline-block;
  padding: var(--space-4) var(--space-12);
  font-size: 12px;
  font-weight: 600;
  border-radius: var(--radius-sm);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.badge-primary {
  background: var(--oak-primary);
  color: white;
}

.badge-success {
  background: var(--oak-success);
  color: white;
}

.badge-warning {
  background: var(--oak-warning);
  color: white;
}

.badge-danger {
  background: var(--oak-danger);
  color: white;
}

.badge-gray {
  background: var(--gray-200);
  color: var(--gray-700);
}

/* ════════════════════════════════════════════════════ */
/* TABLES                                              */
/* ════════════════════════════════════════════════════ */

.table-wrapper {
  overflow-x: auto;
  border: var(--border-light);
  border-radius: var(--radius-lg);
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

th {
  padding: var(--space-12) var(--space-16);
  background: var(--gray-50);
  border-bottom: var(--border-md);
  text-align: left;
  font-weight: 600;
  color: var(--gray-700);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

td {
  padding: var(--space-12) var(--space-16);
  border-bottom: var(--border-light);
  color: var(--gray-700);
}

tr:last-child td {
  border-bottom: none;
}

tr:hover {
  background: var(--gray-50);
}

/* ════════════════════════════════════════════════════ */
/* FORMS                                               */
/* ════════════════════════════════════════════════════ */

.form-group {
  margin-bottom: var(--space-20);
}

label {
  display: block;
  font-weight: 600;
  color: var(--gray-900);
  margin-bottom: var(--space-8);
  font-size: 14px;
}

input,
select,
textarea {
  width: 100%;
  padding: var(--space-12);
  border: var(--border-light);
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 14px;
  color: var(--gray-900);
  transition: border-color var(--transition-fast);
}

input:focus,
select:focus,
textarea:focus {
  outline: none;
  border-color: var(--oak-primary);
  box-shadow: 0 0 0 3px rgba(155, 102, 50, 0.1);
}

/* ════════════════════════════════════════════════════ */
/* ALERTS & MESSAGES                                   */
/* ════════════════════════════════════════════════════ */

.alert {
  padding: var(--space-16);
  border-radius: var(--radius-lg);
  border-left: 4px solid;
  margin-bottom: var(--space-16);
  font-size: 14px;
}

.alert-success {
  background: rgba(16, 185, 129, 0.1);
  border-color: var(--oak-success);
  color: #047857;
}

.alert-warning {
  background: rgba(245, 158, 11, 0.1);
  border-color: var(--oak-warning);
  color: #92400e;
}

.alert-danger {
  background: rgba(239, 68, 68, 0.1);
  border-color: var(--oak-danger);
  color: #7f1d1d;
}

.alert-info {
  background: rgba(155, 102, 50, 0.1);
  border-color: var(--oak-primary);
  color: var(--oak-primary);
}

/* ════════════════════════════════════════════════════ */
/* GRID & FLEX UTILITIES                               */
/* ════════════════════════════════════════════════════ */

.grid {
  display: grid;
  gap: var(--space-24);
}

.grid-2 {
  grid-template-columns: repeat(2, 1fr);
}

.grid-3 {
  grid-template-columns: repeat(3, 1fr);
}

@media (max-width: 768px) {
  .grid-2,
  .grid-3 {
    grid-template-columns: 1fr;
  }
}

.flex {
  display: flex;
  gap: var(--space-16);
}

.flex-between {
  justify-content: space-between;
  align-items: center;
}

/* ════════════════════════════════════════════════════ */
/* COLOR SWATCHES                                       */
/* ════════════════════════════════════════════════════ */

.swatch-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: var(--space-24);
  margin-bottom: var(--space-32);
}

.swatch {
  border-radius: var(--radius-lg);
  overflow: hidden;
  border: var(--border-light);
}

.swatch-color {
  width: 100%;
  height: 80px;
}

.swatch-info {
  padding: var(--space-12);
  background: var(--gray-50);
  border-top: var(--border-light);
}

.swatch-name {
  font-weight: 600;
  font-size: 13px;
  color: var(--gray-900);
  margin-bottom: var(--space-4);
}

.swatch-hex {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--gray-600);
}

/* ════════════════════════════════════════════════════ */
/* SPACING UTILITIES                                    */
/* ════════════════════════════════════════════════════ */

.mt-8 { margin-top: var(--space-8); }
.mt-16 { margin-top: var(--space-16); }
.mt-24 { margin-top: var(--space-24); }
.mt-32 { margin-top: var(--space-32); }

.mb-8 { margin-bottom: var(--space-8); }
.mb-16 { margin-bottom: var(--space-16); }
.mb-24 { margin-bottom: var(--space-24); }
.mb-32 { margin-bottom: var(--space-32); }

.p-16 { padding: var(--space-16); }
.p-24 { padding: var(--space-24); }
.p-32 { padding: var(--space-32); }

.text-muted { color: var(--gray-600); }
.text-sm { font-size: 13px; }
.text-center { text-align: center; }

/* ════════════════════════════════════════════════════ */
/* PRINT STYLES                                         */
/* ════════════════════════════════════════════════════ */

@media print {
  body {
    background: white;
  }
  .card {
    box-shadow: none;
    page-break-inside: avoid;
  }
}
```

- [ ] **Step 2: Verify design-system.css**

```bash
wc -l <larv-plugin-root>/attio-venture-html-effectiveness-design/design-system.css
grep -c "var(--oak" <larv-plugin-root>/attio-venture-html-effectiveness-design/design-system.css
```

Expected: ~600+ lines, 9+ Attio Venture color variables defined.

- [ ] **Step 3: Commit design system**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git add design-system.css
git commit -m "feat: create Attio Venture design system CSS with brown/tan color palette"
```

Expected: Design system committed with all Attio Venture branding.

---

## Task 3: Copy and Adapt 20 HTML Templates

**Files:**
- Copy: All 20 HTML templates from Attio Finance version
- Modify: Update headers, logo references, and color scheme

- [ ] **Step 1: Copy all 20 templates from Attio Finance**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
for i in {01..20}; do
  cp <larv-plugin-root>/attio-finance-html-effectiveness-design/$i-*.html ./
done
ls -1 *.html | head -20
```

Expected: All 20 HTML files copied (01-exploration through 20-editor-prompt-tuner).

- [ ] **Step 2: Update all template headers with Attio Venture branding**

For each template, replace header HTML with Attio Venture logo and styling. Use sed to replace Attio Finance with Attio Venture in all files:

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design

# Replace all Attio Finance references with Attio Venture
sed -i 's/People'"'"'s Credit Network Finance Co\. Inc\./Attio Venture Studio/g' *.html
sed -i 's/Attio Finance/Attio Venture/g' *.html

# Update header gradient background for Attio Venture aesthetic
sed -i 's/background: linear-gradient(135deg, #FFFBF0 0%, #FFFEF9 100%)/background: linear-gradient(135deg, #FFF9F3 0%, #FBF6F1 100%)/g' *.html

# Verify changes
grep -l "Attio Venture" *.html | wc -l
```

Expected: All 20 files updated with Attio Venture references.

- [ ] **Step 3: Commit template copies**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git add 01-*.html 02-*.html 03-*.html 04-*.html 05-*.html 06-*.html 07-*.html 08-*.html 09-*.html 10-*.html 11-*.html 12-*.html 13-*.html 14-*.html 15-*.html 16-*.html 17-*.html 18-*.html 19-*.html 20-*.html
git commit -m "feat: copy and adapt 20 HTML templates with Attio Venture branding"
```

Expected: All 20 templates committed.

---

## Task 4: Copy and Adapt CRM Shared Files

**Files:**
- Copy: `crm-shared.js` and `crm-shared-styles.css` from Attio Finance
- No modifications needed (generic utilities)

- [ ] **Step 1: Copy CRM shared files**

```bash
cp <larv-plugin-root>/attio-finance-html-effectiveness-design/crm-shared.js <larv-plugin-root>/attio-venture-html-effectiveness-design/
cp <larv-plugin-root>/attio-finance-html-effectiveness-design/crm-shared-styles.css <larv-plugin-root>/attio-venture-html-effectiveness-design/
```

Expected: Both files copied.

- [ ] **Step 2: Verify files copied correctly**

```bash
ls -lh <larv-plugin-root>/attio-venture-html-effectiveness-design/crm-shared.*
wc -l <larv-plugin-root>/attio-venture-html-effectiveness-design/crm-shared.js
```

Expected: Files exist and intact.

- [ ] **Step 3: Commit CRM shared files**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git add crm-shared.js crm-shared-styles.css
git commit -m "feat: add shared CRM utilities and styles"
```

Expected: Files committed.

---

## Task 5: Create and Adapt 3 CRM Dashboards

**Files:**
- Copy: 21-credit-officer-crm.html, 22-sales-crm.html, 23-service-crm.html from Attio Finance
- Modify: Update branding, logo references, organization names

- [ ] **Step 1: Copy 3 CRM dashboards**

```bash
cp <larv-plugin-root>/attio-finance-html-effectiveness-design/21-credit-officer-crm.html <larv-plugin-root>/attio-venture-html-effectiveness-design/
cp <larv-plugin-root>/attio-finance-html-effectiveness-design/22-sales-crm.html <larv-plugin-root>/attio-venture-html-effectiveness-design/
cp <larv-plugin-root>/attio-finance-html-effectiveness-design/23-service-crm.html <larv-plugin-root>/attio-venture-html-effectiveness-design/
```

Expected: All 3 CRM files copied.

- [ ] **Step 2: Update CRM dashboards with Attio Venture branding**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design

# Replace Attio Finance with Attio Venture in all CRM files
sed -i 's/People'"'"'s Credit Network/Attio Venture/g' 21-*.html 22-*.html 23-*.html
sed -i 's/Finance Co\. Inc\./Ventures/g' 21-*.html 22-*.html 23-*.html

# Verify changes
grep "Attio Venture" 21-*.html 22-*.html 23-*.html | head -3
```

Expected: All 3 CRM dashboards updated with Attio Venture branding.

- [ ] **Step 3: Commit CRM dashboards**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git add 21-*.html 22-*.html 23-*.html
git commit -m "feat: add 3 CRM dashboards with Attio Venture branding"
```

Expected: CRM dashboards committed.

---

## Task 6: Create Gallery Index

**Files:**
- Create: `<larv-plugin-root>/attio-venture-html-effectiveness-design/index.html`

- [ ] **Step 1: Create index.html from Attio Finance template**

Copy the Attio Finance index.html and update it with Attio Venture branding and logo.

```html
<!-- Attio Venture HTML Effectiveness Design — Adapted to Attio Design System -->
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Attio Venture HTML Effectiveness — Design Examples</title>
  <link rel="stylesheet" href="design-system.css">
  <style>
    .header {
      padding: var(--space-32) 0;
      border-bottom: var(--border-light);
      background: linear-gradient(135deg, #FFF9F3 0%, #FBF6F1 100%);
    }

    .hero {
      max-width: 900px;
      margin: var(--space-64) auto;
      padding: 0 var(--space-24);
      text-align: center;
    }

    .hero h1 {
      font-size: 48px;
      color: var(--oak-primary);
      margin-bottom: var(--space-16);
    }

    .hero p {
      font-size: 18px;
      color: var(--gray-600);
      max-width: 600px;
      margin: 0 auto var(--space-32);
      line-height: 1.7;
    }

    .badge-hero {
      display: inline-block;
      background: var(--oak-primary);
      color: white;
      padding: var(--space-8) var(--space-16);
      border-radius: var(--radius-xl);
      font-size: 13px;
      font-weight: 600;
      margin-bottom: var(--space-24);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .examples-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: var(--space-32);
      max-width: 1200px;
      margin: var(--space-64) auto;
      padding: 0 var(--space-24);
    }

    .example-card {
      background: var(--white);
      border: var(--border-light);
      border-radius: var(--radius-lg);
      padding: var(--space-24);
      transition: all var(--transition-base);
      display: flex;
      flex-direction: column;
      text-decoration: none;
      color: inherit;
    }

    .example-card:hover {
      border-color: var(--oak-primary);
      box-shadow: var(--shadow-lg);
      transform: translateY(-2px);
    }

    .example-icon {
      width: 48px;
      height: 48px;
      background: var(--gray-100);
      border-radius: var(--radius-md);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      margin-bottom: var(--space-16);
    }

    .example-title {
      font-size: 18px;
      font-weight: 600;
      color: var(--gray-900);
      margin-bottom: var(--space-8);
    }

    .example-description {
      font-size: 14px;
      color: var(--gray-600);
      line-height: 1.6;
      flex-grow: 1;
      margin-bottom: var(--space-16);
    }

    .example-meta {
      font-size: 12px;
      color: var(--gray-500);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .category {
      max-width: 1200px;
      margin: var(--space-64) auto;
      padding: 0 var(--space-24);
    }

    .category-title {
      font-size: 24px;
      font-weight: 600;
      color: var(--oak-primary);
      margin-bottom: var(--space-24);
      padding-bottom: var(--space-16);
      border-bottom: 2px solid var(--oak-primary);
    }

    .category-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: var(--space-24);
      margin-bottom: var(--space-48);
    }

    footer {
      background: var(--gray-50);
      border-top: var(--border-light);
      padding: var(--space-40) var(--space-24);
      margin-top: var(--space-64);
      text-align: center;
      color: var(--gray-600);
      font-size: 14px;
    }

    footer a {
      color: var(--oak-primary);
    }

    .divider {
      width: 100%;
      height: 1px;
      background: var(--gray-200);
      margin: var(--space-32) 0;
    }
  </style>
</head>
<body>
  <!-- Header -->
  <header class="header">
    <div class="container">
      <div class="logo">
        <img src="attio-venture-logo.png" alt="Attio Venture Logo" style="height: 48px; width: auto; border-radius: var(--radius-md);">
        <div>
          <div style="font-size: 14px; color: var(--gray-600);">Attio Venture</div>
          <div style="font-weight: 700; color: var(--oak-primary);">Ventures</div>
        </div>
      </div>
    </div>
  </header>

  <!-- Hero Section -->
  <div class="hero">
    <div class="badge-hero">✨ Design System Examples</div>
    <h1>The unreasonable effectiveness of HTML</h1>
    <p>A comprehensive gallery of production-ready HTML examples adapted to Attio Venture's design system. Each example is self-contained, requires no build steps, and demonstrates modern UI patterns.</p>
  </div>

  <!-- Exploration Category -->
  <div class="category">
    <h2 class="category-title">🔍 Exploration</h2>
    <div class="category-grid">
      <a href="01-exploration-code-approaches.html" class="example-card">
        <div class="example-icon">💻</div>
        <div class="example-title">Code Approaches</div>
        <div class="example-description">Compare different technical implementations with side-by-side analysis.</div>
        <div class="example-meta">Interactive Comparison</div>
      </a>
      <a href="02-exploration-visual-designs.html" class="example-card">
        <div class="example-icon">🎨</div>
        <div class="example-title">Visual Designs</div>
        <div class="example-description">Explore design variations and layout approaches.</div>
        <div class="example-meta">Design Variants</div>
      </a>
    </div>
  </div>

  <!-- Code Category -->
  <div class="category">
    <h2 class="category-title">💻 Code & Analysis</h2>
    <div class="category-grid">
      <a href="03-code-review-pr.html" class="example-card">
        <div class="example-icon">👀</div>
        <div class="example-title">Code Review (PR)</div>
        <div class="example-description">Collaborative pull request review with inline comments.</div>
        <div class="example-meta">Development Workflow</div>
      </a>
      <a href="04-code-understanding.html" class="example-card">
        <div class="example-icon">📚</div>
        <div class="example-title">Code Understanding</div>
        <div class="example-description">Visual documentation with interactive source code browser.</div>
        <div class="example-meta">Documentation</div>
      </a>
      <a href="05-design-system.html" class="example-card">
        <div class="example-icon">🎯</div>
        <div class="example-title">Design System</div>
        <div class="example-description">Design system reference with components and tokens.</div>
        <div class="example-meta">Brand Guidelines</div>
      </a>
      <a href="06-component-variants.html" class="example-card">
        <div class="example-icon">🧩</div>
        <div class="example-title">Component Variants</div>
        <div class="example-description">Interactive showcase of UI components in different states.</div>
        <div class="example-meta">Component Library</div>
      </a>
    </div>
  </div>

  <!-- Prototyping Category -->
  <div class="category">
    <h2 class="category-title">🚀 Prototyping</h2>
    <div class="category-grid">
      <a href="07-prototype-animation.html" class="example-card">
        <div class="example-icon">✨</div>
        <div class="example-title">Animation Prototype</div>
        <div class="example-description">Smooth transitions and animations for user flows.</div>
        <div class="example-meta">Motion Design</div>
      </a>
      <a href="08-prototype-interaction.html" class="example-card">
        <div class="example-icon">🎮</div>
        <div class="example-title">Interaction Prototype</div>
        <div class="example-description">Interactive dashboard with real-time metrics and filtering.</div>
        <div class="example-meta">User Interaction</div>
      </a>
    </div>
  </div>

  <!-- Communication Category -->
  <div class="category">
    <h2 class="category-title">📢 Communication</h2>
    <div class="category-grid">
      <a href="09-slide-deck.html" class="example-card">
        <div class="example-icon">📊</div>
        <div class="example-title">Slide Deck</div>
        <div class="example-description">Presentation template for business reviews and strategy.</div>
        <div class="example-meta">Presentation</div>
      </a>
      <a href="11-status-report.html" class="example-card">
        <div class="example-icon">📈</div>
        <div class="example-title">Status Report</div>
        <div class="example-description">Weekly progress report with KPIs and metrics.</div>
        <div class="example-meta">Reporting</div>
      </a>
      <a href="12-incident-report.html" class="example-card">
        <div class="example-icon">⚠️</div>
        <div class="example-title">Incident Report</div>
        <div class="example-description">Structured documentation with timeline and remediation.</div>
        <div class="example-meta">Crisis Management</div>
      </a>
      <a href="17-pr-writeup.html" class="example-card">
        <div class="example-icon">📝</div>
        <div class="example-title">PR Writeup</div>
        <div class="example-description">Comprehensive pull request documentation.</div>
        <div class="example-meta">Development Docs</div>
      </a>
    </div>
  </div>

  <!-- Diagrams & Research Category -->
  <div class="category">
    <h2 class="category-title">📊 Diagrams & Research</h2>
    <div class="category-grid">
      <a href="10-svg-illustrations.html" class="example-card">
        <div class="example-icon">🎨</div>
        <div class="example-title">SVG Illustrations</div>
        <div class="example-description">Custom vector graphics and illustrations.</div>
        <div class="example-meta">Visual Assets</div>
      </a>
      <a href="13-flowchart-diagram.html" class="example-card">
        <div class="example-icon">🔀</div>
        <div class="example-title">Flowchart Diagram</div>
        <div class="example-description">Process flow visualization.</div>
        <div class="example-meta">Process Mapping</div>
      </a>
      <a href="14-research-feature-explainer.html" class="example-card">
        <div class="example-icon">💡</div>
        <div class="example-title">Feature Explainer</div>
        <div class="example-description">In-depth feature documentation with use cases.</div>
        <div class="example-meta">Product Research</div>
      </a>
      <a href="15-research-concept-explainer.html" class="example-card">
        <div class="example-icon">🧠</div>
        <div class="example-title">Concept Explainer</div>
        <div class="example-description">Educational guide on complex concepts.</div>
        <div class="example-meta">Thought Leadership</div>
      </a>
    </div>
  </div>

  <!-- Planning Category -->
  <div class="category">
    <h2 class="category-title">📋 Planning & Implementation</h2>
    <div class="category-grid">
      <a href="16-implementation-plan.html" class="example-card">
        <div class="example-icon">🗓️</div>
        <div class="example-title">Implementation Plan</div>
        <div class="example-description">Detailed project roadmap with phases and milestones.</div>
        <div class="example-meta">Project Management</div>
      </a>
    </div>
  </div>

  <!-- CRM Category -->
  <div class="category">
    <h2 class="category-title">💼 CRM & Business Applications</h2>
    <div class="category-grid">
      <a href="21-credit-officer-crm.html" class="example-card">
        <div class="example-icon">🏦</div>
        <div class="example-title">Credit Officer Dashboard</div>
        <div class="example-description">Loan management with credit scoring and risk assessment.</div>
        <div class="example-meta">Financial Services</div>
      </a>
      <a href="22-sales-crm.html" class="example-card">
        <div class="example-icon">📊</div>
        <div class="example-title">Sales Pipeline</div>
        <div class="example-description">Deal management with kanban pipeline and forecasting.</div>
        <div class="example-meta">Sales Management</div>
      </a>
      <a href="23-service-crm.html" class="example-card">
        <div class="example-icon">🎧</div>
        <div class="example-title">Customer Support Portal</div>
        <div class="example-description">Support ticket queue with SLA tracking.</div>
        <div class="example-meta">Customer Service</div>
      </a>
    </div>
  </div>

  <!-- Custom Editors Category -->
  <div class="category">
    <h2 class="category-title">✏️ Custom Editors & Tools</h2>
    <div class="category-grid">
      <a href="18-editor-triage-board.html" class="example-card">
        <div class="example-icon">📋</div>
        <div class="example-title">Triage Board</div>
        <div class="example-description">Drag-and-drop interface for managing issues.</div>
        <div class="example-meta">Workflow Tool</div>
      </a>
      <a href="19-editor-feature-flags.html" class="example-card">
        <div class="example-icon">🚩</div>
        <div class="example-title">Feature Flags</div>
        <div class="example-description">Visual feature flag management dashboard.</div>
        <div class="example-meta">DevOps Tool</div>
      </a>
      <a href="20-editor-prompt-tuner.html" class="example-card">
        <div class="example-icon">🎚️</div>
        <div class="example-title">Prompt Tuner</div>
        <div class="example-description">Interactive AI prompt optimizer.</div>
        <div class="example-meta">AI Tool</div>
      </a>
    </div>
  </div>

  <!-- Footer -->
  <footer>
    <p><strong>Attio Venture HTML Effectiveness</strong> — Adapted from <a href="https://github.com/ThariqS/html-effectiveness">html-effectiveness</a></p>
    <p>Combining Attio's design philosophy with Attio Venture's brand. All examples are self-contained, require no build steps, and demonstrate modern HTML/CSS/JS patterns.</p>
    <p style="margin-top: var(--space-24); font-size: 12px; color: var(--gray-500);">Licensed under Apache 2.0 · Built for Attio Venture Studio</p>
  </footer>
</body>
</html>
```

- [ ] **Step 2: Save index.html**

```bash
cat > <larv-plugin-root>/attio-venture-html-effectiveness-design/index.html << 'EOF'
[paste full HTML from step 1 above]
EOF
```

Expected: index.html created with all 23 template links.

- [ ] **Step 3: Verify index.html**

```bash
grep -c "href=" <larv-plugin-root>/attio-venture-html-effectiveness-design/index.html
```

Expected: 23 links found (20 templates + 3 CRM dashboards).

- [ ] **Step 4: Commit index**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git add index.html
git commit -m "feat: create gallery index with all 23 templates"
```

Expected: Gallery committed.

---

## Task 7: Verify All Files and Test

**Files:**
- Verify: All 23 HTML files, CSS, JS, logo

- [ ] **Step 1: Verify complete project structure**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
ls -1 *.html *.css *.js *.png 2>/dev/null | sort
echo "---"
echo "Total files:"
ls -1 *.html *.css *.js *.png 2>/dev/null | wc -l
```

Expected: 28 files (23 HTML + design-system.css + crm-shared.js + crm-shared-styles.css + attio-venture-logo.png).

- [ ] **Step 2: Verify all HTML files have correct header structure**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
for file in *.html; do
  if ! grep -q "attio-venture-logo.png" "$file"; then
    echo "WARNING: $file missing logo reference"
  fi
done
echo "Logo check complete"
```

Expected: No warnings (all files reference attio-venture-logo.png).

- [ ] **Step 3: Verify design-system.css is referenced**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
grep -l "design-system.css" *.html | wc -l
```

Expected: 23 files reference design-system.css.

- [ ] **Step 4: Test index.html opens in browser (manual)**

Open `<larv-plugin-root>/attio-venture-html-effectiveness-design/index.html` in a web browser and verify:
- Attio Venture logo displays
- All 23 template cards visible
- Links to all templates work
- Design colors are brown/tan (#9B6632, #ECCDAE, #755637)

Expected: Gallery loads correctly with Attio Venture branding.

- [ ] **Step 5: Test one template (manual)**

Click on one template (e.g., "Credit Officer Dashboard") and verify:
- Page loads without errors
- Attio Venture logo in header
- Brown/tan color scheme applied
- Tables, buttons, modals work

Expected: Template functions correctly.

- [ ] **Step 6: Final commit**

```bash
cd <larv-plugin-root>/attio-venture-html-effectiveness-design
git status
git log --oneline | head -10
```

Expected: All files committed, project complete.

---

## Summary

**Total Implementation Time:** ~2-3 hours

**Deliverables:**
- ✅ attio-venture-html-effectiveness-design folder with complete gallery
- ✅ 23 production-ready HTML templates
- ✅ Attio Venture design system with brown/tan colors
- ✅ Full CRM system (3 dashboards)
- ✅ Gallery index linking all templates
- ✅ Zero dependencies, no build steps required

**Ready for:** Developers on Attio Venture team to use as design template reference and starting point for new projects.
