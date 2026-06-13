# Attio Finance HTML Effectiveness Design System

A comprehensive gallery of **production-ready HTML examples** adapted to **Attio Finance Studio's** branding combined with **Attio's modern design philosophy**.

## Overview

This project merges:
- **html-effectiveness**: A gallery of standalone HTML examples by Anthropic (code reviews, design systems, prototypes, etc.)
- **Attio's design system**: Notion-like aesthetic with clean, modular, minimal components
- **Attio Finance branding**: Financial services color palette, typography, and visual identity

All examples are **self-contained** (no build steps, no dependencies), require only a **modern browser**, and demonstrate contemporary HTML/CSS/JavaScript patterns suitable for financial services applications.

## Quick Start

1. **Open the gallery**: Open `index.html` in any modern web browser
2. **Browse examples**: Click any example card to view the full template
3. **No installation needed**: Everything runs in-browser

## Design System

### Color Palette

**Primary Brand Colors:**
- `--attio-finance-primary`: #1B5E7F (Deep Blue - Trust, Finance)
- `--attio-finance-primary-light`: #2A7FA3
- `--attio-finance-accent`: #00A651 (Green - Growth, Success)
- `--attio-finance-warning`: #F59E0B (Amber - Caution)
- `--attio-finance-danger`: #EF4444 (Red - Risk)
- `--attio-finance-success`: #10B981 (Green - Confirmation)

**Neutral Palette (Attio-inspired):**
- Gray scale from `--gray-50` (light) to `--gray-900` (dark)
- Clean, minimal aesthetic consistent with Notion/Attio

### Typography

- **Sans-serif**: System font stack (SF Pro Display, Segoe UI, Roboto, etc.)
- **Monospace**: SF Mono, Monaco, Menlo for code and technical content
- Carefully tuned scale for readability and hierarchy

### Components

All design system CSS is in `design-system.css` with:
- **Buttons**: Primary, secondary, success, danger variants
- **Cards & Panels**: Modular content containers with hover effects
- **Tables**: Dense, readable data presentation
- **Forms**: Clear input fields with focus states
- **Badges & Labels**: Status indicators and tags
- **Alerts**: Success, warning, danger, info states
- **Spacing & Grid**: 8px base unit with utility classes
- **Shadows**: Subtle, professional elevation effects

## Examples Gallery

### 🔍 Exploration (2 examples)
- **01-exploration-code-approaches**: Compare technical implementations side-by-side
- **02-exploration-visual-designs**: Explore design variations and iterations

### 💻 Code & Analysis (4 examples)
- **03-code-review-pr**: Collaborative pull request review with inline feedback
- **04-code-understanding**: Visual code documentation with interactive browser
- **05-design-system**: Attio Finance design system reference (colors, typography, components)
- **06-component-variants**: Interactive component showcase in different states

### 🚀 Prototyping (2 examples)
- **07-prototype-animation**: Smooth transitions and motion design
- **08-prototype-interaction**: Interactive dashboard with real-time updates

### 📢 Communication (4 examples)
- **09-slide-deck**: Business presentation template
- **11-status-report**: Weekly progress report with KPIs
- **12-incident-report**: Structured incident documentation
- **17-pr-writeup**: Comprehensive pull request documentation

### 📊 Diagrams & Research (4 examples)
- **10-svg-illustrations**: Custom vector graphics and illustrations
- **13-flowchart-diagram**: Process flow visualization
- **14-research-feature-explainer**: Feature deep-dive documentation
- **15-research-concept-explainer**: Educational concept guides

### 📋 Planning & Implementation (1 example)
- **16-implementation-plan**: Project roadmap with phases and milestones

### ✏️ Custom Editors & Tools (3 examples)
- **18-editor-triage-board**: Drag-and-drop issue management interface
- **19-editor-feature-flags**: Feature flag management dashboard
- **20-editor-prompt-tuner**: AI prompt optimization tool

## Project Structure

```
attio-finance-html-effectiveness-design/
├── index.html                 # Main gallery page
├── design-system.css          # Complete design system (all variables & components)
├── 01-exploration-code-approaches.html
├── 02-exploration-visual-designs.html
├── 03-code-review-pr.html
├── 04-code-understanding.html
├── 05-design-system.html      # Design system reference page
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
├── README.md                   # This file
├── source/                     # Original html-effectiveness repository
└── adapt-templates.py         # Batch adaptation script (reference)
```

## Using the Design System

### Linking CSS

Every HTML file includes the design system:

```html
<link rel="stylesheet" href="design-system.css">
```

### CSS Variables

Use CSS variables for consistent theming:

```css
/* Primary colors */
background: var(--attio-finance-primary);
color: var(--attio-finance-accent);

/* Neutrals */
border: 1px solid var(--gray-300);

/* Spacing (8px grid) */
padding: var(--space-24);
margin-bottom: var(--space-16);

/* Components */
border-radius: var(--radius-lg);
box-shadow: var(--shadow-md);
```

### HTML Components

```html
<!-- Card -->
<div class="card">
  <h3 class="card-title">Title</h3>
  <p class="card-description">Description</p>
</div>

<!-- Button -->
<button class="btn btn-primary">Primary Action</button>
<button class="btn btn-secondary">Secondary</button>

<!-- Badge -->
<span class="badge badge-success">Approved</span>

<!-- Alert -->
<div class="alert alert-info">Information message</div>

<!-- Form Group -->
<div class="form-group">
  <label>Field Label</label>
  <input type="text" placeholder="Enter value">
</div>
```

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (iOS Safari, Chrome Mobile)

All examples use modern CSS and JavaScript; no transpilation or polyfills needed.

## Customization

### Changing Colors

Edit CSS variables in `design-system.css`:

```css
:root {
  --attio-finance-primary: #1B5E7F;        /* Change to your brand color */
  --attio-finance-accent: #00A651;
}
```

### Modifying Typography

Update font families in `:root`:

```css
--font-sans: "Your Font", system-ui, sans-serif;
--font-mono: "Your Mono Font", monospace;
```

### Adding New Components

Add new component classes to `design-system.css`:

```css
.your-component {
  padding: var(--space-16);
  background: var(--white);
  border-radius: var(--radius-lg);
  /* ... */
}
```

## Financial Services Context

All example content has been adapted for financial services use cases:
- Credit scoring and loan applications
- Account management and dashboards
- Payment processing workflows
- Compliance and documentation
- Customer onboarding flows
- Regulatory reporting

## Content Attribution

- **Original Project**: [html-effectiveness](https://github.com/ThariqS/html-effectiveness) by Anthropic
- **Design System Adaptation**: Attio's Notion-like design philosophy
- **Branding**: Attio Finance Studio

## License

Apache License 2.0 (same as original html-effectiveness project)

## Notes

- All product names, fictional data, and scenarios in examples are for illustration only
- This is a design system and component reference, not production code
- Examples demonstrate patterns and best practices for HTML/CSS/JavaScript
- Each file is self-contained and can be used independently

## Getting Started with Development

1. **View Gallery**: Open `index.html` in browser
2. **Reference Design System**: Open `05-design-system.html` for component showcase
3. **Copy Components**: Reference any `.html` file to understand patterns
4. **Customize**: Modify CSS variables for your specific needs
5. **Extend**: Add new components following established patterns

---

**Built with** ❤️ **for Attio Finance Studio**
