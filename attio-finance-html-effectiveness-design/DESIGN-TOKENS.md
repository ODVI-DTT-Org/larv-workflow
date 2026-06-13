# Attio Finance Design Tokens Reference

Complete reference for all CSS variables and design tokens used throughout the system.

## Color Tokens

### Brand Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--attio-finance-primary` | #1B5E7F | Primary actions, headers, brand identity |
| `--attio-finance-primary-light` | #2A7FA3 | Hover states, light backgrounds |
| `--attio-finance-primary-lighter` | #4B9FC9 | Disabled states, subtle accents |
| `--attio-finance-accent` | #00A651 | Success, growth, positive actions |
| `--attio-finance-accent-light` | #2FBC6F | Hover states for accent |
| `--attio-finance-warning` | #F59E0B | Warnings, caution states |
| `--attio-finance-danger` | #EF4444 | Errors, destructive actions |
| `--attio-finance-success` | #10B981 | Confirmations, successful states |

### Neutral Scale (Gray)

| Token | Value | Usage |
|-------|-------|-------|
| `--white` | #FFFFFF | Backgrounds, cards |
| `--gray-50` | #F9FAFB | Light backgrounds, alternate rows |
| `--gray-100` | #F3F4F6 | Subtle backgrounds, disabled states |
| `--gray-200` | #E5E7EB | Light borders, dividers |
| `--gray-300` | #D1D5DB | Default borders |
| `--gray-400` | #9CA3AF | Secondary text, placeholders |
| `--gray-500` | #6B7280 | Secondary content, labels |
| `--gray-600` | #4B5563 | Tertiary text |
| `--gray-700` | #374151 | Primary text on light backgrounds |
| `--gray-800` | #1F2937 | Dark text |
| `--gray-900` | #111827 | Darkest text, headers |

## Typography Tokens

### Font Families

```css
--font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
             "Helvetica Neue", Arial, sans-serif;
--font-mono: "SF Mono", Monaco, "Cascadia Code", "Roboto Mono", Consolas, monospace;
```

### Font Sizes

| Size | Usage |
|------|-------|
| 13px | Code, metadata, helper text |
| 14px | Form labels, secondary content |
| 15px | Body text (default) |
| 16px | Card titles, emphasis |
| 18px | Subheadings |
| 24px | Section headings (h3) |
| 32px | Page headings (h2) |
| 40px | Main headings (h1) |

### Line Heights

- `1.3`: Headings (compact)
- `1.5`: Labels and metadata
- `1.6`: Body text (default)
- `1.7`: Long-form content

## Spacing Tokens (8px Grid)

All spacing uses multiples of 8px for consistency.

| Token | Value | Use Case |
|-------|-------|----------|
| `--space-2` | 2px | Micro-spacing, hairlines |
| `--space-4` | 4px | Tight spacing, small gaps |
| `--space-6` | 6px | Very small margins |
| `--space-8` | 8px | Small gaps, icon margins |
| `--space-12` | 12px | Standard padding, button padding |
| `--space-16` | 16px | Element spacing, form padding |
| `--space-20` | 20px | Medium spacing |
| `--space-24` | 24px | Card padding, section gaps |
| `--space-32` | 32px | Large gaps, container padding |
| `--space-40` | 40px | Extra large spacing |
| `--space-48` | 48px | Major section spacing |
| `--space-56` | 56px | Large section breaks |
| `--space-64` | 64px | Maximum spacing |

## Border & Radius Tokens

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | 4px | Small buttons, badges |
| `--radius-md` | 6px | Standard components |
| `--radius-lg` | 8px | Cards, large buttons |
| `--radius-xl` | 12px | Large cards, modals |
| `--radius-2xl` | 16px | Extra large components |

### Borders

| Token | Value | Usage |
|-------|-------|-------|
| `--border-light` | 1px solid var(--gray-200) | Subtle dividers |
| `--border-md` | 1px solid var(--gray-300) | Standard borders |

## Shadow Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | 0 1px 2px 0 rgba(0, 0, 0, 0.05) | Subtle elevation |
| `--shadow-md` | 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06) | Standard depth |
| `--shadow-lg` | 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05) | High elevation |

## Transition Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--transition-fast` | 150ms ease-out | Quick UI feedback |
| `--transition-base` | 200ms ease-out | Standard interactions |

## Component Presets

### Button States

```css
/* Primary Button */
.btn-primary {
  background: var(--attio-finance-primary);      /* #1B5E7F */
  color: white;
}

.btn-primary:hover {
  background: var(--attio-finance-primary-light); /* #2A7FA3 */
  box-shadow: var(--shadow-md);
}

/* Secondary Button */
.btn-secondary {
  background: var(--gray-100);
  color: var(--gray-900);
  border: var(--border-light);
}

.btn-secondary:hover {
  background: var(--gray-200);
}
```

### Card Styles

```css
.card {
  background: var(--white);
  border: var(--border-light);
  border-radius: var(--radius-lg);
  padding: var(--space-24);
  box-shadow: var(--shadow-sm);
}

.card:hover {
  border-color: var(--gray-300);
  box-shadow: var(--shadow-md);
}
```

### Form Inputs

```css
input, select, textarea {
  border: var(--border-light);
  border-radius: var(--radius-md);
  padding: var(--space-12);
  font-size: 14px;
}

input:focus, select:focus, textarea:focus {
  outline: none;
  border-color: var(--attio-finance-primary);
  box-shadow: 0 0 0 3px rgba(27, 94, 127, 0.1);
}
```

## Usage Examples

### Creating a New Card

```html
<div class="card">
  <h3 class="card-title">Card Title</h3>
  <p class="card-description">Card description text</p>
</div>
```

### Spacing Pattern

```html
<!-- Using spacing tokens -->
<div style="padding: var(--space-24); margin-bottom: var(--space-16);">
  Content with consistent spacing
</div>
```

### Color Usage in Custom CSS

```css
.custom-component {
  background: var(--attio-finance-primary);
  border: var(--border-light);
  color: var(--gray-900);
  padding: var(--space-16);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  transition: all var(--transition-base);
}

.custom-component:hover {
  border-color: var(--attio-finance-primary-light);
  box-shadow: var(--shadow-lg);
}
```

## Accessibility Considerations

- **Color Contrast**: All text meets WCAG AA standards (4.5:1 minimum)
- **Focus States**: All interactive elements have visible focus rings
- **Spacing**: Adequate spacing for touch targets (min 44x44px)
- **Typography**: Line heights and sizes optimized for readability

## Print Styles

Print styles automatically remove box-shadows and ensure:
- Clean, printer-friendly appearance
- Proper page breaks for multi-page content
- Readable text sizing and contrast

---

All tokens can be customized by modifying the `:root` section in `design-system.css`.
