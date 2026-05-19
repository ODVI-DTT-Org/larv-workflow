# HTML Effectiveness Design Systems

This workflow contains two complete design system implementations based on the [html-effectiveness](https://github.com/ThariqS/html-effectiveness) repository, adapted to the Attio design philosophy.

## Projects

### 1. PCNI HTML Effectiveness Design
**Location:** `pcni-html-effectiveness-design/`

Complete gallery with 23 self-contained HTML templates styled with PCNI's financial services branding:
- **Primary Color:** Gold (#FAA000)
- **Accent Color:** Deep Blue (#1B5E7F)
- **Ideal for:** Financial services, credit, lending, banking mockups

**Quick Start:**
```
cd pcni-html-effectiveness-design
python -m http.server 8000
# Open http://localhost:8000/setup.html
```

### 2. Oak Drive HTML Effectiveness Design
**Location:** `oak-drive-html-effectiveness-design/`

Parallel implementation with Oak Drive's venture/investment branding:
- **Primary Color:** Warm Brown (#9B6632)
- **Accent Color:** Light Tan (#ECCDAE)
- **Ideal for:** Venture capital, investment, growth-focused mockups

**Quick Start:**
```
cd oak-drive-html-effectiveness-design
python -m http.server 8000
# Open http://localhost:8000/setup.html
```

## Design Choice System

Both projects include a **Design System Chooser** that lets developers select between three design variants:

### 1. **Custom** (Purple)
- Base gradient: #667eea → #764ba2
- For custom branding projects

### 2. **PCNI** (Gold + Blue)
- Primary: #FAA000 (Gold)
- Accent: #1B5E7F (Deep Blue)
- Perfect for PCNI templates and financial mockups

### 3. **Oak Drive** (Brown + Tan)
- Primary: #9B6632 (Warm Brown)
- Accent: #ECCDAE (Light Tan)
- Perfect for Oak Drive templates and venture mockups

## Workflow

### First Visit
1. Navigate to `setup.html` in either project
2. Select your preferred design system (Custom, PCNI, or Oak Drive)
3. System automatically redirects to `index.html` with your choice
4. Choice is saved to browser localStorage

### Subsequent Visits
- Choice persists automatically
- Browse templates with your selected design system
- Use **"Change Design"** link in header to switch systems anytime

### Resetting Design Choice
- Click **"Change Design"** in the gallery header
- Or visit `setup.html?setup=true` to force design chooser

## File Structure

Each project contains:

```
project-folder/
├── setup.html                    # Design system chooser (entry point)
├── index.html                    # Template gallery
├── design-system.css             # Attio design system with brand colors
├── oak-drive-logo.png           # Brand asset (Oak Drive project only)
├── pcni-logo.png                # Brand asset (PCNI project only)
├── crm-shared.js                # Shared CRM utilities
├── crm-shared-styles.css        # Shared CRM component styles
│
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
│
├── 21-credit-officer-crm.html   # CRM Dashboard: Loan management
├── 22-sales-crm.html            # CRM Dashboard: Deal pipeline
└── 23-service-crm.html          # CRM Dashboard: Support tickets
```

## Design System Features

### Colors
- Complete brand color palette with primary, accent, and semantic colors
- CSS custom properties for easy theming and customization

### Components
- Buttons (primary, secondary, success, danger, small variants)
- Cards and panels with density options
- Forms (inputs, select, textarea) with focus states
- Tables with hover and striping
- Badges and labels (all semantic colors)
- Alerts and messages (success, warning, danger, info)
- Modals and dialogs
- Navigation and header structures

### Spacing
8px grid system (--space-2 through --space-64)

### Typography
- System font stack for maximum compatibility
- Monospace font for code samples
- Heading hierarchy (h1–h6)
- Code blocks with syntax highlighting

### Responsiveness
- Mobile-first design
- Breakpoint at 768px for tablet/mobile adjustments
- Flexible grid layouts (auto-fit, minmax)
- Touch-friendly component sizing

## Using the Templates

All templates are **self-contained** — no build steps, no dependencies:

1. Open any template HTML in a modern browser
2. Template automatically applies your selected design system
3. CSS is embedded or linked from single `design-system.css`
4. JavaScript is vanilla (no frameworks)

## Modifying Templates

To customize a template for your project:

1. Copy the template file
2. Edit the HTML content directly
3. Styling comes from `design-system.css` — override with inline `<style>` if needed
4. No build step required

## Development Server

For development with live reload capabilities:

```bash
# Simple Python server (no reload)
python -m http.server 8000

# Or with reload capability using Live.js
# Add to HTML: <script type="text/javascript" src="http://livereload.com/livereload.js"></script>

# Or with live-server npm package
npm install -g live-server
live-server
```

## Browser Support

All templates work in modern browsers (Chrome, Firefox, Safari, Edge):
- CSS Grid and Flexbox support required
- CSS Custom Properties support required
- JavaScript uses ES6+ features

## License

Licensed under Apache 2.0, adapted from [html-effectiveness](https://github.com/ThariqS/html-effectiveness) by Anthropic.

---

**Built for Oak Drive Ventures** — Combining Attio's design philosophy with brand-specific implementations.
