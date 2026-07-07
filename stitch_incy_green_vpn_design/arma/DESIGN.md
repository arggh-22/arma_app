---
name: Arma
colors:
  surface: '#15121b'
  surface-dim: '#15121b'
  surface-bright: '#3b3742'
  surface-container-lowest: '#0f0d15'
  surface-container-low: '#1d1a23'
  surface-container: '#211e27'
  surface-container-high: '#2c2832'
  surface-container-highest: '#37333d'
  on-surface: '#e7e0ed'
  on-surface-variant: '#cbc3d7'
  inverse-surface: '#e7e0ed'
  inverse-on-surface: '#322f39'
  outline: '#958ea0'
  outline-variant: '#494454'
  surface-tint: '#d0bcff'
  primary: '#d0bcff'
  on-primary: '#3c0091'
  primary-container: '#a078ff'
  on-primary-container: '#340080'
  inverse-primary: '#6d3bd7'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#ffb869'
  on-tertiary: '#482900'
  tertiary-container: '#ca801e'
  on-tertiary-container: '#3f2300'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#d0bcff'
  on-primary-fixed: '#23005c'
  on-primary-fixed-variant: '#5516be'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#ffdcbb'
  tertiary-fixed-dim: '#ffb869'
  on-tertiary-fixed: '#2c1700'
  on-tertiary-fixed-variant: '#673d00'
  background: '#15121b'
  on-background: '#e7e0ed'
  surface-variant: '#37333d'
typography:
  headline-xl:
    fontFamily: Montserrat
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 20px
  gutter: 16px
  nav-float-bottom: 32px
---

## Brand & Style

The design system for this product centers on high-performance security with a futuristic, cyber-noir aesthetic. It targets a tech-literate audience that values both privacy and cutting-edge aesthetics. The brand personality is protective, swift, and sophisticated.

The visual style is **Glassmorphism**, characterized by translucent, frosted surfaces that appear to float over deep, obsidian voids. Subtle light leaks and peripheral glows evoke a sense of digital energy and "active protection." The interface should feel like a high-tech command center—premium, immersive, and highly responsive.

## Colors

The palette is anchored by **Electric Indigo**, a vibrant primary accent that signals activity and encryption. This is contrasted against **Obsidian Black** and **Deep Navy** backgrounds to ensure maximum depth and visual comfort in low-light environments.

- **Primary:** #8B5CF6 (Electric Indigo) for high-priority actions and active states.
- **Secondary:** #06B6D4 (Cyber Cyan) for data visualizations and secondary status indicators.
- **Background:** #020617 (Obsidian) for the root application canvas.
- **Surface:** #0F172A (Deep Navy) for cards and containers, used with varying opacities for glass effects.
- **Glow:** #C084FC is used for subtle drop shadows and "active" light-source effects behind primary elements.

## Typography

This design system utilizes a dual-font strategy. **Montserrat** is used for headlines to provide a bold, geometric, and authoritative presence. **Inter** is used for all body text, data readouts, and labels to ensure maximum legibility at small sizes and within technical overlays.

Headlines should use tight tracking to maintain a compact, "armored" feel. Labels should use uppercase styling with increased letter spacing to differentiate metadata from body content.

## Layout & Spacing

The layout follows a fluid-first approach with a 12-column grid for desktop and a 4-column grid for mobile. Navigation is handled via a **Floating Bottom Bar**, which must maintain a safe-area margin of 32px from the bottom of the screen to enhance the "hovering" effect.

Spacing is based on a 4px baseline. Components like cards and input fields should use a consistent 16px or 24px internal padding to maintain a spacious, premium feel amidst the dark background.

## Elevation & Depth

Depth is conveyed through **Glassmorphism** and luminosity rather than traditional grey-scale shadows. 

1.  **Backdrop Blur:** All elevated surfaces (Cards, Floating Nav, Modals) must utilize a `blur(12px)` background filter.
2.  **Translucency:** Surfaces use a hex color with 60-80% opacity.
3.  **Inner Glow / Border:** Use a 1px solid border at 10-20% white opacity on the top and left edges to simulate light hitting a glass edge.
4.  **Shadows:** Shadows are colored, using low-opacity Electric Indigo (#8B5CF6) to create a subtle ambient glow beneath active elements, making them appear to emit light.

## Shapes

The shape language is modern and approachable. Root containers and cards use a 16px (`rounded-lg`) radius. The primary action buttons use a 24px (`rounded-xl`) radius to create a softer, more inviting touch target that contrasts against the technical, sharp grid. Floating elements, like the navigation bar, use a fully pill-shaped profile for a sleek, aerodynamic look.

## Components

### Floating Navigation Bar
The centerpiece of the UI. A pill-shaped bar that floats 32px from the bottom. It features a `Backdrop Filter: blur(20px)` and a 1px border (#FFFFFF10). Active icons should use the Electric Indigo glow effect.

### Primary Buttons
Large, high-contrast buttons with a background gradient from #8B5CF6 to #7C3AED. They should have a subtle outer glow of the same color to indicate they are "charged" and ready for interaction.

### Connection Cards
Glassmorphic containers with #FFFFFF05 (5% white) background. They display server locations and connection status. Status indicators (Connected/Disconnected) should use glowing pulses—Cyan for active, and a muted slate for inactive.

### Inputs & Toggles
Inputs are dark with a 1px Electric Indigo border only when focused. Toggles use the Primary color for the "On" state, featuring a soft glow that spills slightly onto the surrounding surface.

### Chips & Tags
Small, semi-transparent capsules used for latency (ping) or server load. Use color coding: Green for low latency, Purple for optimized, and Cyan for new locations.