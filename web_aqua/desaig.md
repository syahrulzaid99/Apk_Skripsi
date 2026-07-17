# Design System: Aqua Stock — Twinkling Stardust

**Version:** 1.0  
**Last Updated:** 2026-07-17  
**Scope:** Entire web_aqua application (all EJS views)

---

## Design Philosophy

An elegant, premium interface inspired by the night sky — deep navy surfaces with twinkling gold accents. The aesthetic is refined and sophisticated, like starlight reflected on water. Every element earns its place through clarity and purpose.

**Core Principles:**
- **Elegance over decoration** — Subtle gold accents, never overwhelming
- **Clarity through contrast** — Deep navy backgrounds make content breathe
- **Consistency across themes** — Both light and dark modes maintain the same premium feel
- **Simplicity in typography** — Clean, readable text without visual noise

---

## 1. Color System

### Primary Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `--navy-900` | `#0a1929` | `#0a1929` | Deepest background, hero sections |
| `--navy-800` | `#0d2847` | `#0d2847` | Card backgrounds (dark mode), sidebar |
| `--navy-700` | `#1a3a5c` | `#1a3a5c` | Secondary surfaces, table headers |
| `--navy-600` | `#2d4a6e` | `#2d4a6e` | Hover states, borders |
| `--navy-500` | `#3d5a80` | `#3d5a80` | Muted text on dark backgrounds |

### Accent: Gold Sparkle

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `--gold-500` | `#d4af37` | `#f4d03f` | Primary accent, buttons, highlights |
| `--gold-400` | `#e6c35c` | `#f9e076` | Hover states, active elements |
| `--gold-300` | `#f4d03f` | `#fce98a` | Subtle accents, badges |
| `--gold-200` | `#fce98a` | `#fef3b5` | Very subtle highlights |

### Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `--success` | `#10b981` | `#34d399` | Success states, positive data |
| `--warning` | `#f59e0b` | `#fbbf24` | Warnings, pending states |
| `--danger` | `#ef4444` | `#f87171` | Errors, destructive actions |
| `--info` | `#06b6d4` | `#22d3ee` | Informational messages |

### Surface Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `--surface-primary` | `#ffffff` | `#1a1f2e` | Card backgrounds, main content |
| `--surface-secondary` | `#f8fafc` | `#242938` | Table headers, secondary cards |
| `--surface-tertiary` | `#f1f5f9` | `#2d3342` | Hover states, nested elements |

### Text Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `--text-primary` | `#0f172a` | `#f1f5f9` | Headings, primary content |
| `--text-secondary` | `#475569` | `#cbd5e1` | Body text, descriptions |
| `--text-muted` | `#94a3b8` | `#64748b` | Metadata, timestamps, disabled |
| `--text-accent` | `#d4af37` | `#f4d03f` | Gold accent text, highlights |

### Border Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `--border-default` | `#e2e8f0` | `#334155` | Default borders |
| `--border-subtle` | `rgba(226, 232, 240, 0.5)` | `rgba(51, 65, 85, 0.5)` | Subtle dividers |
| `--border-accent` | `#d4af37` | `#f4d03f` | Gold accent borders, focus rings |

---

## 2. Typography

### Font Stack

**Primary Font:** `Outfit` (Google Fonts)  
**Fallback:** `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`

```css
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap');

body {
    font-family: 'Outfit', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}
```

### Type Scale

| Element | Size | Weight | Line Height | Letter Spacing | Usage |
|---------|------|--------|-------------|----------------|-------|
| **H1** | `clamp(2.5rem, 5vw, 3.5rem)` | 800 | 1.1 | `-0.02em` | Page titles, hero headings |
| **H2** | `clamp(2rem, 4vw, 2.5rem)` | 700 | 1.2 | `-0.01em` | Section headings |
| **H3** | `1.5rem` | 700 | 1.3 | `0` | Card titles, modal headers |
| **H4** | `1.25rem` | 600 | 1.4 | `0` | Subsection headings |
| **H5** | `1.125rem` | 600 | 1.5 | `0` | Small headings |
| **H6** | `1rem` | 600 | 1.5 | `0` | Labels, metadata headings |
| **Body Large** | `1.125rem` | 400 | 1.6 | `0` | Lead paragraphs |
| **Body** | `1rem` | 400 | 1.6 | `0` | Default body text |
| **Body Small** | `0.875rem` | 400 | 1.5 | `0` | Secondary text, captions |
| **Caption** | `0.75rem` | 500 | 1.4 | `0.02em` | Timestamps, metadata |
| **Overline** | `0.75rem` | 700 | 1.4 | `0.1em` | Labels, uppercase text |

### Typography Rules

1. **Never use pure black** (`#000000`) — always use `--text-primary` or `--navy-900`
2. **Never use pure white** (`#ffffff`) for text on dark backgrounds — use `--text-primary` in dark mode
3. **Uppercase labels** should have `letter-spacing: 0.1em` for elegance
4. **Numbers in tables** should use `font-weight: 600` for emphasis
5. **Code/monospace** — Use `JetBrains Mono` or `Fira Code` for code blocks and SKU values

---

## 3. Spacing System

### Base Unit: 4px

All spacing uses multiples of 4px for mathematical consistency.

| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `0.25rem` (4px) | Micro spacing, icon gaps |
| `--space-2` | `0.5rem` (8px) | Small gaps, inline elements |
| `--space-3` | `0.75rem` (12px) | Compact spacing |
| `--space-4` | `1rem` (16px) | Default spacing, padding |
| `--space-5` | `1.25rem` (20px) | Medium spacing |
| `--space-6` | `1.5rem` (24px) | Card padding, section gaps |
| `--space-8` | `2rem` (32px) | Large spacing, section dividers |
| `--space-10` | `2.5rem` (40px) | Extra large spacing |
| `--space-12` | `3rem` (48px) | Section padding |
| `--space-16` | `4rem` (64px) | Hero sections, major dividers |

### Component Spacing

**Cards:**
- Internal padding: `var(--space-6)` (24px)
- Card-to-card gap: `var(--space-6)` (24px)
- Section-to-section gap: `var(--space-12)` (48px)

**Tables:**
- Cell padding: `var(--space-4) var(--space-3)` (16px vertical, 12px horizontal)
- Header padding: `var(--space-3) var(--space-3)` (12px)

**Buttons:**
- Padding: `var(--space-3) var(--space-6)` (12px vertical, 24px horizontal)
- Icon gap: `var(--space-2)` (8px)

---

## 4. Component Specifications

### 4.1 Cards

**Base Card:**
```css
.card {
    background: var(--surface-primary);
    border-radius: 16px;
    border: 1px solid var(--border-subtle);
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    overflow: hidden;
}

.card:hover {
    transform: translateY(-4px);
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    border-color: var(--gold-300);
}
```

**Stat Card (Dashboard):**
- Gradient accent bar on left or top
- Icon container: 64x64px, rounded 16px, gradient background
- Value: `clamp(2rem, 4vw, 3rem)`, weight 700
- Label: uppercase, weight 600, size 0.875rem, letter-spacing 0.05em

**Elegant Card (Orders, Shipments):**
- Header with subtle gradient: `linear-gradient(135deg, var(--navy-700) 0%, var(--navy-800) 100%)`
- Gold accent on key data (order codes, totals)
- Status badges with gradient backgrounds

### 4.2 Buttons

**Primary Button:**
```css
.btn-primary {
    background: linear-gradient(135deg, var(--gold-500) 0%, var(--gold-400) 100%);
    color: var(--navy-900);
    border: none;
    border-radius: 12px;
    padding: var(--space-3) var(--space-6);
    font-weight: 600;
    box-shadow: 0 4px 6px -1px rgba(212, 175, 55, 0.3);
    transition: all 0.3s ease;
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(212, 175, 55, 0.4);
    background: linear-gradient(135deg, var(--gold-400) 0%, var(--gold-300) 100%);
}
```

**Secondary Button:**
```css
.btn-secondary {
    background: transparent;
    color: var(--text-primary);
    border: 2px solid var(--border-default);
    border-radius: 12px;
    padding: var(--space-3) var(--space-6);
    font-weight: 600;
    transition: all 0.3s ease;
}

.btn-secondary:hover {
    border-color: var(--gold-500);
    color: var(--gold-500);
    background: rgba(212, 175, 55, 0.05);
}
```

**Danger Button:**
```css
.btn-danger {
    background: linear-gradient(135deg, var(--danger) 0%, #dc2626 100%);
    color: white;
    border: none;
    border-radius: 12px;
    box-shadow: 0 4px 6px -1px rgba(239, 68, 68, 0.3);
}
```

**Icon Button:**
- Size: 40x40px (default), 48x48px (large)
- Border-radius: 50%
- Icon size: 1.25rem
- Hover: subtle background shift, no glow

### 4.3 Tables

**Base Table:**
```css
.table {
    border-collapse: separate;
    border-spacing: 0;
    width: 100%;
}

.table thead th {
    background: var(--surface-secondary);
    color: var(--text-muted);
    font-weight: 700;
    text-transform: uppercase;
    font-size: 0.75rem;
    letter-spacing: 0.05em;
    padding: var(--space-3) var(--space-3);
    border-bottom: 2px solid var(--border-default);
}

.table tbody tr {
    transition: background 0.2s ease;
}

.table tbody tr:hover {
    background: var(--surface-tertiary);
}

.table td {
    padding: var(--space-4) var(--space-3);
    border-bottom: 1px solid var(--border-subtle);
    color: var(--text-primary);
}
```

**Special Cells:**
- **Code/SKU:** `background: var(--surface-secondary); padding: 4px 10px; border-radius: 6px; font-weight: 700;`
- **Currency:** `font-weight: 700; color: var(--gold-500);`
- **Status badges:** See Badges section

### 4.4 Badges

**Pill Badge:**
```css
.badge {
    padding: 0.5em 1.2em;
    border-radius: 50rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    font-size: 0.75rem;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
}
```

**Status Variants:**
```css
.badge-success {
    background: linear-gradient(135deg, var(--success) 0%, #059669 100%);
    color: white;
}

.badge-warning {
    background: linear-gradient(135deg, var(--warning) 0%, #d97706 100%);
    color: white;
}

.badge-danger {
    background: linear-gradient(135deg, var(--danger) 0%, #dc2626 100%);
    color: white;
}

.badge-info {
    background: linear-gradient(135deg, var(--info) 0%, #0891b2 100%);
    color: white;
}

.badge-gold {
    background: linear-gradient(135deg, var(--gold-500) 0%, var(--gold-400) 100%);
    color: var(--navy-900);
}
```

### 4.5 Form Inputs

**Base Input:**
```css
.form-control {
    background: var(--surface-primary);
    border: 2px solid var(--border-default);
    border-radius: 12px;
    padding: var(--space-3) var(--space-4);
    color: var(--text-primary);
    font-size: 1rem;
    transition: all 0.3s ease;
}

.form-control:focus {
    border-color: var(--gold-500);
    box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.1);
    outline: none;
}

.form-control::placeholder {
    color: var(--text-muted);
}
```

**Label:**
```css
.form-label {
    display: block;
    font-weight: 600;
    font-size: 0.875rem;
    color: var(--text-primary);
    margin-bottom: var(--space-2);
}
```

**Error State:**
```css
.form-control.is-invalid {
    border-color: var(--danger);
}

.invalid-feedback {
    color: var(--danger);
    font-size: 0.875rem;
    margin-top: var(--space-1);
}
```

### 4.6 Navigation (Sidebar)

**Sidebar Background:**
```css
.sidebar {
    background: linear-gradient(180deg, var(--navy-800) 0%, var(--navy-900) 100%);
}
```

**Sidebar Links:**
```css
.sidebar .nav-link {
    color: rgba(255, 255, 255, 0.7);
    padding: var(--space-3) var(--space-4);
    border-radius: 8px;
    transition: all 0.2s ease;
    margin: var(--space-1) var(--space-2);
}

.sidebar .nav-link:hover {
    background: rgba(212, 175, 55, 0.1);
    color: var(--gold-300);
}

.sidebar .nav-link.active {
    background: linear-gradient(135deg, var(--gold-500) 0%, var(--gold-400) 100%);
    color: var(--navy-900);
    font-weight: 600;
}
```

### 4.7 Topbar

```css
.topbar {
    background: var(--surface-primary);
    border-bottom: 1px solid var(--border-subtle);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.topbar .nav-link {
    color: var(--text-secondary);
    transition: color 0.2s ease;
}

.topbar .nav-link:hover {
    color: var(--gold-500);
}
```

### 4.8 Modals

```css
.modal-content {
    background: var(--surface-primary);
    border-radius: 20px;
    border: 1px solid var(--border-subtle);
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
}

.modal-header {
    border-bottom: 1px solid var(--border-default);
    padding: var(--space-6);
}

.modal-title {
    font-weight: 700;
    color: var(--text-primary);
}

.modal-footer {
    border-top: 1px solid var(--border-default);
    padding: var(--space-4) var(--space-6);
}
```

### 4.9 Alerts

```css
.alert {
    border-radius: 12px;
    padding: var(--space-4);
    border: none;
}

.alert-info {
    background: rgba(6, 182, 212, 0.1);
    color: var(--info);
    border-left: 4px solid var(--info);
}

.alert-success {
    background: rgba(16, 185, 129, 0.1);
    color: var(--success);
    border-left: 4px solid var(--success);
}

.alert-warning {
    background: rgba(245, 158, 11, 0.1);
    color: var(--warning);
    border-left: 4px solid var(--warning);
}

.alert-danger {
    background: rgba(239, 68, 68, 0.1);
    color: var(--danger);
    border-left: 4px solid var(--danger);
}
```

---

## 5. Layout System

### Container Widths

| Breakpoint | Max Width | Padding |
|------------|-----------|---------|
| Mobile (< 768px) | 100% | `var(--space-4)` (16px) |
| Tablet (768px - 1024px) | 100% | `var(--space-6)` (24px) |
| Desktop (> 1024px) | 1400px | `var(--space-8)` (32px) |

### Grid System

Use Bootstrap 4 grid (already integrated) with these customizations:

**Stat Cards (Dashboard):**
```css
.stats-grid {
    display: grid;
    grid-template-columns: repeat(12, 1fr);
    gap: var(--space-6);
    grid-auto-flow: dense;
}

.stat-card.col-span-4 {
    grid-column: span 4;
}

.stat-card.col-span-6 {
    grid-column: span 6;
}

.stat-card.col-span-12 {
    grid-column: span 12;
}
```

**Responsive:**
- Mobile: All cards span 12 columns (stacked)
- Tablet: Cards span 6 columns (2 per row)
- Desktop: Cards span 4 columns (3 per row)

### Page Structure

1. **Hero Section** (optional, for dashboards)
   - Padding: `var(--space-16) 0` (64px top/bottom)
   - Title: H1 with gold accent
   - Subtitle: Body large, muted color

2. **Content Sections**
   - Section gap: `var(--space-12)` (48px)
   - Card gap: `var(--space-6)` (24px)

3. **Footer**
   - Padding: `var(--space-6) 0` (24px)
   - Border-top: 1px solid `var(--border-subtle)`

---

## 6. Motion & Animation

### Entrance Animations

**Staggered Fade-In:**
```javascript
const elements = document.querySelectorAll('.stat-card, .card');
elements.forEach((el, index) => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    
    setTimeout(() => {
        el.style.transition = 'all 0.6s cubic-bezier(0.4, 0, 0.2, 1)';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
    }, index * 100);
});
```

### Hover Effects

**Cards:**
```css
.card {
    transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1),
                box-shadow 0.3s cubic-bezier(0.4, 0, 0.2, 1),
                border-color 0.3s ease;
}

.card:hover {
    transform: translateY(-4px);
    border-color: var(--gold-300);
}
```

**Buttons:**
```css
.btn {
    transition: all 0.3s ease;
}

.btn:hover {
    transform: translateY(-2px);
}

.btn:active {
    transform: translateY(0);
}
```

### Timing Functions

- **Standard:** `cubic-bezier(0.4, 0, 0.2, 1)` — Material Design standard
- **Decelerate:** `cubic-bezier(0, 0, 0.2, 1)` — Entrance animations
- **Accelerate:** `cubic-bezier(0.4, 0, 1, 1)` — Exit animations
- **Spring:** `cubic-bezier(0.34, 1.56, 0.64, 1)` — Bouncy interactions

### Duration Guidelines

| Interaction | Duration |
|-------------|----------|
| Micro (icon hover) | 150ms |
| Small (button hover) | 200ms |
| Medium (card hover) | 300ms |
| Large (page transition) | 500ms |
| Entrance (stagger) | 600ms per element |

---

## 7. Responsive Design

### Breakpoints

| Name | Width | Columns | Gutter |
|------|-------|---------|--------|
| xs | < 576px | 12 | 16px |
| sm | ≥ 576px | 12 | 16px |
| md | ≥ 768px | 12 | 24px |
| lg | ≥ 992px | 12 | 24px |
| xl | ≥ 1200px | 12 | 32px |

### Mobile-First Rules

1. **Single column on mobile** — All grids collapse to 1 column below 768px
2. **Full-width buttons** — Buttons span 100% width on mobile
3. **Reduced padding** — Section padding reduces to `var(--space-8)` on mobile
4. **Touch targets** — Minimum 44x44px for all interactive elements
5. **No horizontal scroll** — `overflow-x: hidden` on body

### Typography Scaling

```css
h1 {
    font-size: clamp(2rem, 5vw, 3.5rem);
}

h2 {
    font-size: clamp(1.75rem, 4vw, 2.5rem);
}

h3 {
    font-size: clamp(1.25rem, 3vw, 1.5rem);
}
```

---

## 8. Accessibility

### Color Contrast

- **Normal text:** Minimum 4.5:1 contrast ratio
- **Large text (18px+):** Minimum 3:1 contrast ratio
- **Interactive elements:** Minimum 3:1 contrast ratio

### Focus States

All interactive elements must have visible focus states:

```css
:focus-visible {
    outline: 2px solid var(--gold-500);
    outline-offset: 2px;
}
```

### Keyboard Navigation

- All interactive elements must be keyboard accessible
- Focus order must follow visual order
- Skip links for main content areas

### Screen Readers

- Use semantic HTML (`<button>`, `<nav>`, `<main>`, `<section>`)
- Provide `aria-label` for icon-only buttons
- Use `aria-live` for dynamic content updates

---

## 9. Anti-Patterns (Banned)

### Visual

- **No pure black** (`#000000`) — always use `--navy-900` or `--text-primary`
- **No pure white** (`#ffffff`) for text — use `--text-primary`
- **No neon glows** — subtle shadows only
- **No oversaturated colors** — keep accents elegant
- **No rainbow gradients** — navy + gold only
- **No emojis** in UI (use Font Awesome icons)

### Typography

- **No Inter font** — use Outfit
- **No generic serif fonts** (Times New Roman, Georgia)
- **No excessive font weights** — stick to 400, 500, 600, 700, 800
- **No justified text** — always left-aligned

### Layout

- **No overlapping elements** — clean spatial separation
- **No centered hero sections** — use left-aligned or asymmetric layouts
- **No 3 equal columns for features** — use asymmetric grids
- **No horizontal scroll** — always responsive

### Code

- **No inline styles** — use CSS classes
- **No duplicate CSS** — extract to shared styles
- **No !important** — except for theme overrides in base.ejs
- **No magic numbers** — use CSS variables

---

## 10. Implementation Checklist

When creating or updating a page, verify:

- [ ] Uses CSS variables from `base.ejs` for theme compatibility
- [ ] Typography follows the type scale
- [ ] Spacing uses the spacing system
- [ ] Components match specifications
- [ ] Responsive at 375px, 768px, 1024px, 1440px
- [ ] Dark mode tested
- [ ] Keyboard accessible
- [ ] No banned patterns
- [ ] Entrance animations implemented
- [ ] Hover effects present

---

## 11. Migration Guide

### For Existing Pages

**SB Admin 2 Style (users.ejs, products.ejs, etc.):**

1. Add `<style>` block with component specifications
2. Replace `.card` with custom card styles
3. Replace `.btn` with custom button styles
4. Replace `.table` with custom table styles
5. Test in both light and dark modes

**Modern Aesthetic Style (orders.ejs, shipments.ejs):**

1. Update color values to use CSS variables
2. Replace Inter font with Outfit
3. Update border-radius to 12px/16px
4. Add gold accent to key elements
5. Test in both light and dark modes

### CSS Variable Mapping

```css
/* Old (SB Admin 2) */
border-left-primary → border-left: 4px solid var(--gold-500)
text-primary → color: var(--text-primary)
bg-light → background: var(--surface-secondary)

/* Old (Modern Aesthetic) */
.aesthetic-card → .card (with new styles)
.pill-badge → .badge (with new styles)
.aesthetic-table → .table (with new styles)
```

---

## 12. Resources

### Icons

- **Library:** Font Awesome 6.5.2
- **CDN:** `https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css`
- **Usage:** `<i class="fas fa-icon-name"></i>`

### Alerts

- **Library:** SweetAlert2
- **CDN:** `https://cdn.jsdelivr.net/npm/sweetalert2@11`
- **Usage:** See existing pages for examples

### Images

- **Placeholder:** `https://picsum.photos/seed/{keyword}/1920/1080`
- **Avatars:** `https://ui-avatars.com/api/?name={username}`
- **Filters:** Apply `grayscale`, `mix-blend-luminosity`, `opacity-90` for elegance

---

## 13. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07-17 | Initial design system — Twinkling Stardust theme |

---

## 14. Support

For questions or updates to this design system:
- Review existing implementations in [admin/dashboard.ejs](src/views/admin/dashboard.ejs)
- Check [base.ejs](src/views/layouts/base.ejs) for CSS variable definitions
- Consult the [API documentation](API.md) for backend integration

---

**Remember:** Elegance is achieved through restraint. Every gold accent should feel intentional, every navy surface should feel purposeful. The twinkling stardust aesthetic is about creating a sense of wonder without overwhelming the user.
