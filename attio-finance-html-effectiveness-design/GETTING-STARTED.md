# Getting Started with Attio Finance HTML Effectiveness

Welcome! This guide will help you get up and running with the Attio Finance HTML Effectiveness design system.

## 🚀 Quick Start (2 minutes)

### 1. Open the Gallery

```bash
# Navigate to the project directory
cd <larv-plugin-root>/attio-finance-html-effectiveness-design

# Open index.html in your browser
open index.html  # macOS
# or
xdg-open index.html  # Linux
# or
start index.html  # Windows
```

Or simply **drag `index.html` into your browser**.

### 2. Browse Examples

- Browse the categorized gallery of 20 examples
- Click any card to view the full example
- Each example is fully interactive and self-contained

### 3. Check Design System

- Open **`05-design-system.html`** to see all Attio Finance design system components
- Reference this page for color palette, typography, and component styles

## 📚 What's Included

### Design System
- **`design-system.css`** - Complete CSS design system with all variables and components
- **`DESIGN-TOKENS.md`** - Reference for all CSS custom properties

### Examples (20 Total)
Organized in 7 categories:

1. **Exploration** (2) - Code and design exploration tools
2. **Code & Analysis** (4) - Reviews, documentation, design system
3. **Prototyping** (2) - Animation and interaction examples
4. **Communication** (4) - Reports, presentations, documentation
5. **Diagrams & Research** (4) - Visualizations and explainers
6. **Planning** (1) - Implementation plans
7. **Custom Editors** (3) - Interactive tools and dashboards

### Documentation
- **`README.md`** - Complete project overview
- **`DESIGN-TOKENS.md`** - Design token reference
- **`GETTING-STARTED.md`** - This file

## 🎨 Using the Design System

### Option 1: Reference Examples

Simply open any of the 20 examples and:
1. **Copy** the HTML structure you like
2. **Inspect** the CSS classes used
3. **Adapt** for your needs

### Option 2: Use in Your Own Project

Copy `design-system.css` to your project:

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="path/to/design-system.css">
</head>
<body>
  <!-- Your content -->
</body>
</html>
```

### Option 3: Import CSS Variables

Use any of the design tokens in your custom CSS:

```css
.my-component {
  background: var(--attio-finance-primary);
  padding: var(--space-24);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
}
```

## 🎯 Common Tasks

### Creating a Button

```html
<button class="btn btn-primary">Click me</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-success">Success</button>
<button class="btn btn-danger">Delete</button>
```

### Creating a Card

```html
<div class="card">
  <h3 class="card-title">Card Title</h3>
  <p class="card-description">Card description text goes here.</p>
</div>
```

### Using Colors

```css
/* Primary brand color */
color: var(--attio-finance-primary);

/* Accent green */
background: var(--attio-finance-accent);

/* Success state */
border-color: var(--attio-finance-success);

/* Neutral grays */
border: 1px solid var(--gray-300);
```

### Using Spacing

```html
<!-- Using predefined spacing classes -->
<div class="p-24 mb-16">
  Content with 24px padding and 16px bottom margin
</div>

<!-- Using CSS variables directly -->
<div style="padding: var(--space-24); margin-bottom: var(--space-16);">
  Content with consistent spacing
</div>
```

### Creating a Form

```html
<form>
  <div class="form-group">
    <label>Email Address</label>
    <input type="email" placeholder="you@example.com" required>
  </div>

  <div class="form-group">
    <label>Message</label>
    <textarea placeholder="Your message..." rows="4"></textarea>
  </div>

  <button type="submit" class="btn btn-primary">Send</button>
</form>
```

### Adding Alerts

```html
<div class="alert alert-success">✓ Operation completed successfully</div>
<div class="alert alert-warning">⚠ Please review before proceeding</div>
<div class="alert alert-danger">✗ An error occurred</div>
<div class="alert alert-info">ℹ Additional information</div>
```

## 🌈 Attio Finance Brand Colors

Use these colors consistently throughout your designs:

```css
/* Primary: Deep Blue (Trust, Finance) */
--attio-finance-primary: #1B5E7F
--attio-finance-primary-light: #2A7FA3

/* Accent: Green (Growth, Success) */
--attio-finance-accent: #00A651

/* Status Colors */
--attio-finance-warning: #F59E0B  (Caution)
--attio-finance-danger: #EF4444   (Error)
--attio-finance-success: #10B981  (Confirmation)
```

## 📱 Responsive Design

All components are mobile-friendly. The design system includes:
- **Flexible grid layouts** (`--grid-2`, `--grid-3`)
- **Responsive typography** (uses `clamp()` for scaling)
- **Touch-friendly sizes** (min 44x44px for interactive elements)
- **Mobile-optimized** media queries

```html
<!-- Responsive grid: 2 columns on desktop, 1 on mobile -->
<div class="grid-2">
  <div class="card">Item 1</div>
  <div class="card">Item 2</div>
</div>
```

## ♿ Accessibility

The design system is built with accessibility in mind:
- **Color Contrast**: Meets WCAG AA standards
- **Focus States**: All interactive elements have visible focus rings
- **Keyboard Navigation**: Full keyboard support
- **Screen Readers**: Semantic HTML structure
- **Motion**: Respects `prefers-reduced-motion`

## 🔧 Customization

### Change Brand Colors

Edit `design-system.css`:

```css
:root {
  --attio-finance-primary: #YOUR-COLOR-HERE;
  --attio-finance-accent: #YOUR-COLOR-HERE;
  /* ... other colors ... */
}
```

### Change Fonts

```css
:root {
  --font-sans: "Your Font Name", system-ui, sans-serif;
  --font-mono: "Your Mono Font", monospace;
}
```

### Add New Components

Add to `design-system.css`:

```css
.my-custom-component {
  padding: var(--space-16);
  background: var(--white);
  border: var(--border-light);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
}
```

## 🚨 Browser Support

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

All modern CSS features are supported. No polyfills or transpilation needed.

## 📖 Next Steps

1. **Explore Examples**: Open each example to understand different patterns
2. **Copy Components**: Start using components in your projects
3. **Customize**: Modify colors and fonts for your specific needs
4. **Build**: Create new pages using the design system foundation

## 📚 Additional Resources

- **`README.md`** - Complete project overview and features
- **`DESIGN-TOKENS.md`** - Comprehensive token reference
- **`05-design-system.html`** - Interactive component showcase
- **`source/`** - Original html-effectiveness repository

## 💬 Tips

- **Components are self-contained**: Copy-paste any HTML example into your project
- **No build step needed**: Just link `design-system.css` and you're ready
- **CSS variables are powerful**: Change tokens for instant theme updates
- **Examples are templates**: Use them as starting points for your designs

## 🎓 Learning Path

### Beginner
1. Open `index.html` and browse
2. Click on 05-design-system.html to see components
3. Copy simple components into a test file

### Intermediate
1. Create a new HTML file linking `design-system.css`
2. Build a multi-page dashboard using card components
3. Customize colors for your brand

### Advanced
1. Create custom components extending the design system
2. Build a complete application using the patterns
3. Contribute improvements back to the project

## ❓ FAQ

**Q: Do I need a build tool?**
A: No! Everything runs directly in the browser.

**Q: Can I customize the design system?**
A: Yes! Edit `design-system.css` to customize colors, fonts, and spacing.

**Q: Can I use this for production?**
A: Yes! The examples demonstrate production-ready patterns.

**Q: How do I add new components?**
A: Add new CSS classes to `design-system.css` following the established patterns.

**Q: Is this mobile-friendly?**
A: Yes! All components are responsive and touch-friendly.

---

**Ready to build?** Start with `index.html` and explore! 🚀
