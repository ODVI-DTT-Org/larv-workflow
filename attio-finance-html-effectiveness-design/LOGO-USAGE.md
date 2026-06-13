# Attio Finance Logo Usage Guide

## Logo File

**Filename**: `attio-finance-logo.png`
**Format**: PNG (transparent background)
**Size**: 225x225px
**Color**: Full color Attio Finance branding

## Implementation

### In HTML

The logo is automatically included in the header of all pages:

```html
<header class="header">
  <div class="container">
    <div class="logo">
      <img src="attio-finance-logo.png" alt="Attio Finance Logo" style="height: 48px; width: auto; border-radius: var(--radius-md);">
      <div>
        <div style="font-size: 14px; color: var(--gray-600);">Attio Finance Studio</div>
        <div style="font-weight: 700; color: var(--attio-finance-primary);">Finance Co. Inc.</div>
      </div>
    </div>
  </div>
</header>
```

### Sizing

The logo is displayed at:
- **Header**: 48px height (recommended)
- **Responsive**: Scales proportionally on mobile
- **Ratio**: Maintains aspect ratio automatically

### In CSS

```css
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
```

## Usage Across Templates

The Attio Finance logo appears on:

✓ **index.html** - Gallery index page
✓ **01-exploration-code-approaches.html** - Code exploration
✓ **02-exploration-visual-designs.html** - Design exploration
✓ **03-code-review-pr.html** - Code review interface
✓ **04-code-understanding.html** - Code documentation
✓ **05-design-system.html** - Design system reference
✓ **06-component-variants.html** - Component showcase
✓ **07-prototype-animation.html** - Animation prototype
✓ **08-prototype-interaction.html** - Interactive prototype
✓ **09-slide-deck.html** - Presentation slides
✓ **10-svg-illustrations.html** - Vector graphics
✓ **11-status-report.html** - Status reporting
✓ **12-incident-report.html** - Incident documentation
✓ **13-flowchart-diagram.html** - Process flows
✓ **14-research-feature-explainer.html** - Feature guides
✓ **15-research-concept-explainer.html** - Concept documentation
✓ **16-implementation-plan.html** - Project planning
✓ **17-pr-writeup.html** - Pull request documentation
✓ **18-editor-triage-board.html** - Issue management
✓ **19-editor-feature-flags.html** - Feature flags UI
✓ **20-editor-prompt-tuner.html** - AI prompt tool

## Customization

### Change Logo Size

Edit the HTML inline style:

```html
<img src="attio-finance-logo.png" alt="Attio Finance Logo" style="height: 64px; width: auto;">
```

### Change Border Radius

Modify the border-radius value:

```html
<img src="attio-finance-logo.png" alt="Attio Finance Logo" style="border-radius: 8px;">
```

Or use CSS variables:

```html
<img src="attio-finance-logo.png" alt="Attio Finance Logo" style="border-radius: var(--radius-xl);">
```

### Change Background

Modify the `.logo-icon` background:

```css
.logo-icon {
  background: var(--gray-50);  /* Instead of white */
}
```

## Brand Guidelines

- **Color**: Display full color logo
- **Minimum Size**: 32px height (for small displays)
- **Maximum Size**: 96px height (for large displays)
- **Spacing**: Maintain adequate spacing from other elements (var(--space-16) minimum)
- **Background**: Works on white, light gray, or transparent backgrounds
- **Never**: Don't rotate, skew, or distort the logo

## Accessibility

- **Alt Text**: "Attio Finance Logo" provides context for screen readers
- **Semantic**: Logo is part of the navigation header
- **Link**: Can be wrapped in an anchor tag to homepage:

```html
<a href="index.html" class="logo">
  <img src="attio-finance-logo.png" alt="Attio Finance Logo" ...>
  ...
</a>
```

## File Management

To use in your own project:

1. **Copy the file**:
   ```bash
   cp attio-finance-logo.png your-project/assets/
   ```

2. **Update the path**:
   ```html
   <img src="assets/attio-finance-logo.png" alt="Attio Finance Logo" ...>
   ```

3. **Or use a CDN/absolute path**:
   ```html
   <img src="https://your-domain.com/logo.png" alt="Attio Finance Logo" ...>
   ```

## Logo Variants

Currently available: **Full Color Logo**

For additional variants (monochrome, white, etc.), please contact Attio Finance branding team.

## Questions?

Refer to the main design system documentation:
- **README.md** - Project overview
- **GETTING-STARTED.md** - Quick reference
- **DESIGN-TOKENS.md** - Design tokens
