# POS KIOSK UI/UX REDESIGN GUIDE

## Goal
Redesign the current POS KIOSK application into a modern, premium, fast, and touch-friendly kiosk experience while KEEPING the EXISTING BRAND COLORS.

This is ONLY a UI/UX redesign.
DO NOT rewrite business logic unless necessary for layout responsiveness.
DO NOT change APIs, backend logic, routing, database, or state management unless required for UI consistency.

---

# CORE DESIGN DIRECTION

The kiosk should feel:

- Modern
- Minimal
- Premium
- Fast
- Clean
- Responsive
- Large-touch optimized
- Easy to use from a distance
- Similar quality to:
  - McDonald's Self Ordering Kiosk
  - Toast POS
  - Square Kiosk
  - Shopify POS
  - Clover POS
  - Apple-inspired minimal interfaces

The redesign should prioritize:
- clarity
- spacing
- accessibility
- large tap targets
- visual hierarchy
- consistent alignment
- smooth navigation

---

# KEEP EXISTING BRANDING

IMPORTANT:
- KEEP the current primary colors and branding identity
- Improve saturation balance, contrast, shadows, and layering
- Modernize the UI without changing the company identity

Allowed:
- Better shades
- Better typography
- Better spacing
- Better cards
- Better elevation
- Better gradients
- Better glassmorphism (light use only)
- Better animations

Avoid:
- Overdesigned neon UI
- Heavy gradients everywhere
- Too many borders
- Tiny buttons
- Cramped layouts
- Excessive text
- Material 2 outdated layouts

---

# GLOBAL UI RULES

## Layout Rules

- Use an 8px spacing system
- Maintain consistent paddings
- Avoid RenderFlex overflow issues
- Avoid nested scrolling
- Use responsive scaling for:
  - 1080p
  - 1366x768
  - 1920x1080
  - tablet kiosk sizes

Preferred layout:
- Sidebar + Content
OR
- Header + Grid Layout

---

# RESPONSIVENESS

The app MUST fully support:
- Flutter Windows
- Landscape kiosk displays
- Touch screen interactions
- Large screen scaling

Avoid:
- hardcoded widths
- negative constraints
- fixed height containers
- overflowing rows

Prefer:
- Expanded
- Flexible
- LayoutBuilder
- MediaQuery
- Wrap
- GridView
- Adaptive breakpoints

---

# TOUCH-FIRST UX

All kiosk interactions should be optimized for touch.

Minimum touch target:
- 48x48 minimum
- Prefer 56-72 height buttons

Buttons should:
- feel large
- have rounded corners
- have hover + pressed states
- have smooth animations

---

# TYPOGRAPHY

Use modern typography hierarchy.

Recommended:
- Inter
- SF Pro
- Poppins

Hierarchy:
- Large bold page titles
- Medium section headers
- Minimal supporting text

Avoid:
- small unreadable text
- excessive font weights
- inconsistent sizing

---

# MODERN COMPONENT STYLE

## Cards
Use:
- rounded corners (16-24 radius)
- soft shadows
- layered surfaces
- subtle borders

## Buttons
Use:
- pill or rounded rectangle buttons
- filled primary CTA
- outlined secondary actions

## Inputs
Use:
- filled modern inputs
- larger height
- soft borders
- focus glow

## Dialogs
Modern centered modals with:
- blur background
- smooth fade animation
- strong CTA buttons

---

# SCREEN REDESIGN REQUIREMENTS

Update ALL screens with modern UI patterns.

This includes:
- Login
- Dashboard
- Product Catalog
- Cart
- Checkout
- Payment
- Order Summary
- Receipt
- Transaction History
- Settings
- Admin Panels
- Employee Screens
- Kitchen Queue
- Order Status
- Customer Queue
- Error Screens
- Empty States
- Loading States

Every screen should feel visually connected.

---

# KIOSK-SPECIFIC IMPROVEMENTS

## Home Screen
Create:
- large category cards
- promotional banners
- featured products
- clean search area

## Product Browsing
Use:
- modern product cards
- large product images
- floating cart summary
- sticky category navigation

## Cart Experience
Should feel:
- clean
- easy to edit
- visually organized

Use:
- quantity steppers
- modern pricing summary
- large checkout CTA

## Payment Screen
Design should feel:
- secure
- premium
- simple

Use:
- large payment options
- animated selection states
- modern QR/payment cards

---

# ANIMATIONS

Use subtle animations only.

Preferred:
- fade transitions
- scale animations
- slide transitions
- smooth hover effects

Avoid:
- flashy transitions
- unnecessary motion
- laggy animations

Animations should improve perceived responsiveness.

---

# DESIGN CONSISTENCY

Ensure:
- consistent border radius
- consistent shadows
- consistent spacing
- consistent typography
- consistent iconography

Use one unified design system across all screens.

---

# DARK/LIGHT MODE

If possible:
- support both dark and light mode
- keep branding consistent

Dark mode should:
- use layered dark surfaces
- avoid pure black
- maintain readable contrast

---

# PERFORMANCE REQUIREMENTS

The redesign MUST remain performant.

Avoid:
- excessive widget rebuilds
- deep widget trees
- unnecessary opacity widgets
- laggy blur effects

Optimize for kiosk hardware.

---

# CLEAN ARCHITECTURE EXPECTATIONS

Refactor UI code for:
- reusable widgets
- reusable cards
- reusable buttons
- reusable spacing constants
- reusable typography styles
- reusable theme extensions

Suggested structure:

lib/
 ├── core/
 ├── theme/
 ├── widgets/
 ├── features/
 ├── shared/
 └── kiosk/

---

# MODERN KIOSK INSPIRATION

Use inspiration from:

- McDonald's Self-Service Kiosk
- Toast POS
- Square POS
- Clover Kiosk
- Shopify POS
- Apple Store self-service UI
- Samsung kiosk interfaces
- Modern airport self-check-in kiosks

Visual style references:
- large image cards
- floating surfaces
- soft shadows
- premium spacing
- minimal text
- strong visual hierarchy
- tablet-first design

---

# UI PRIORITIES

Priority order:
1. Clean Layout
2. Touch Accessibility
3. Responsiveness
4. Visual Hierarchy
5. Consistency
6. Performance
7. Animations

---

# IMPORTANT IMPLEMENTATION RULES

- DO NOT break existing functionality
- DO NOT remove existing flows
- DO NOT change backend behavior
- DO NOT remove business logic
- ONLY modernize and improve the UI/UX

If existing layout causes UI issues:
- refactor layout safely
- preserve functionality
- preserve navigation

---

# FINAL EXPECTATION

The final UI should feel like a professional commercial kiosk product used in:
- fast food chains
- modern cafés
- restaurants
- self-service stores
- retail checkout systems

The application should look polished, production-ready, modern, responsive, and premium while maintaining the existing branding colors.