---
name: Lumina High-End Tech
colors:
  surface: '#f9f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f9f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f5'
  surface-container: '#eeeef0'
  surface-container-high: '#e8e8ea'
  surface-container-highest: '#e2e2e4'
  on-surface: '#1a1c1d'
  on-surface-variant: '#414753'
  inverse-surface: '#2f3132'
  inverse-on-surface: '#f0f0f2'
  outline: '#727784'
  outline-variant: '#c1c6d5'
  surface-tint: '#005cba'
  primary: '#004e9f'
  on-primary: '#ffffff'
  primary-container: '#0066cc'
  on-primary-container: '#dfe8ff'
  inverse-primary: '#aac7ff'
  secondary: '#5f5e60'
  on-secondary: '#ffffff'
  secondary-container: '#e2dfe1'
  on-secondary-container: '#636264'
  tertiary: '#883700'
  on-tertiary: '#ffffff'
  tertiary-container: '#af4900'
  on-tertiary-container: '#ffe3d6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#00458e'
  secondary-fixed: '#e4e2e4'
  secondary-fixed-dim: '#c8c6c8'
  on-secondary-fixed: '#1b1b1d'
  on-secondary-fixed-variant: '#474649'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb692'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#793000'
  background: '#f9f9fb'
  on-background: '#1a1c1d'
  surface-variant: '#e2e2e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 56px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 19px
    fontWeight: '400'
    lineHeight: '1.5'
  body-md:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: '1.5'
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  gutter: 24px
  margin-mobile: 20px
  margin-desktop: 40px
  max-width: 1200px
---

## Brand & Style

The design system is rooted in the "Premium Tech" aesthetic—a philosophy that prioritizes clarity, whitespace, and a meticulous attention to detail. It is designed to evoke a sense of calm, reliability, and sophistication, targeting a discerning audience that values quality over ornamentation.

The style is a refined **Minimalism** with a focus on **Tonal Layering**. It leverages high-quality imagery as a core structural element rather than a secondary decoration. The interface is characterized by expansive white space, precise typography, and a "physical" presence achieved through large-radius curves and soft, ambient shadows. It avoids visual clutter, ensuring that the product or content remains the hero of the experience.

## Colors

The palette is strictly curated to maintain a high-end, neutral environment. 

- **Backgrounds:** Use pure `#FFFFFF` for primary surfaces and `#F5F5F7` for secondary sections or container backgrounds to create subtle structural differentiation.
- **Typography:** The primary text color is `#1D1D1F`, a deep charcoal that provides high contrast without the harshness of pure black. Secondary text uses `#86868B` for metadata and descriptions.
- **Accents:** The Blue accent (`#0066CC`) is used sparingly and purposefully for interactive elements, links, and primary calls to action. It should never overwhelm the layout.

## Typography

The design system utilizes **Inter** for its neutral, highly legible, and systematic qualities, closely mimicking the proportions of SF Pro. 

- **Weight Contrast:** High contrast between bold headers and regular body text is essential. Use `600` or `700` weight for headlines to establish clear hierarchy.
- **Scale:** Large display sizes are intended for product hero sections with negative letter-spacing to maintain a tight, editorial look.
- **Readability:** Body text is set at a comfortable `17px` or `19px` to ensure accessibility and a premium feel.

## Layout & Spacing

This design system uses a **Fixed-Fluid Hybrid Grid**. Content is centered within a `1200px` max-width container for desktop, while fluidly adapting to margins on smaller screens.

- **Rhythm:** An 8px linear scale governs all spacing.
- **Margins:** Generous padding is a hallmark of this system. Vertical section spacing should typically range from `80px` to `120px` to allow content to "breathe."
- **Grid:** A 12-column grid is used for desktop. On mobile, this collapses to a single column with `20px` side margins.
- **Card Spacing:** Use `24px` or `32px` internal padding for cards to maintain a spacious, uncluttered interior.

## Elevation & Depth

Depth is achieved through **Tonal Layers** and **Ambient Shadows** rather than traditional heavy dropshadows.

- **The Surface System:** The base layer is white. Secondary surfaces (cards or sections) use the `#F5F5F7` neutral tone.
- **Shadows:** Use extremely soft, high-diffusion shadows for elevated cards. A typical shadow should have a large blur (`40px`+) and very low opacity (`0.04` to `0.08`) with a slight Y-offset.
- **Interactivity:** On hover, cards may subtly lift by increasing the shadow spread or slightly scaling up (1.02x) to provide tactile feedback.

## Shapes

The shape language is defined by **large, friendly radii** that soften the technical nature of the content. 

- **Standard Elements:** Buttons and small input fields use a `12px` (0.75rem) radius.
- **Containers & Cards:** Use a `20px` to `24px` (1.25rem - 1.5rem) radius for primary cards and image containers.
- **Continuous Curves:** Where possible, use "squircle" or smooth cornering logic to ensure transitions between straight lines and curves feel organic and high-end.

## Components

### Buttons
- **Primary:** Filled with `#0066CC`, white text, `12px` roundedness. No gradient.
- **Secondary:** Light gray background (`#F5F5F7`) with primary blue or black text.
- **Tertiary:** Text-only with an icon suffix (e.g., `>`), using the primary blue color.

### Cards
- Cards are the primary layout vehicle. They should have a `20px` corner radius, white background, and a very subtle ambient shadow. 
- Ensure images within cards are clipped to the same radius and bleed to the edges where appropriate.

### Input Fields
- Subtle `#F5F5F7` background with no border in its default state. 
- On focus, a thin `2px` blue outline or a high-contrast border is applied.

### Chips/Badges
- Small, uppercase labels with increased letter spacing. Used for "New" or "Pre-order" status, typically using a subtle gray or light blue background.

### Lists
- Clean, borderless rows with ample vertical padding. Separated by a `1px` stroke in `#E5E5E7` (a slightly darker version of the neutral background).