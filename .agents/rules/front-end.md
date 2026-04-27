---
trigger: always_on
---

# FRONTEND RULES

## 1. DESIGN SYSTEM ENFORCEMENT
- Use only defined design tokens (colors, spacing, radius)
- Maintain strict 8-point grid spacing system
- Corner radius limited to 6px–8px only

## 2. VISUAL HIERARCHY
- Data must always dominate labels
- Typography must reflect hierarchy, not decoration
- Avoid visual clutter under all conditions

## 3. INTERACTION DESIGN
- All interactions must have a functional purpose
- Micro-interactions must be subtle and fast (≤200ms)
- No animation without meaning or feedback

## 4. COMPONENT BEHAVIOR
- Components must be reusable and stateless where possible
- Avoid embedding business logic in UI components
- UI must only consume processed data, never raw logic

## 5. GLASS / NEUMORPHISM USAGE
- Glassmorphism allowed only for overlays, modals, navigation
- Neumorphism allowed only for interactive states (buttons, toggles)
- Never combine both styles in the same component layer