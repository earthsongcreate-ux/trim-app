# Veloran OS UI Standards (Financial App)

## 🎨 Color Palette
- Background: #0F172A (Deep Slate)
- Card Surfaces: #1E293B (70% opacity)
- Accents: #22C55E (Neon Green), #3B82F6 (Action Blue)

## ✨ Effects
- Glassmorphism: backdrop-blur: 16px; border: 1px solid rgba(255,255,255,0.1);
- Neumorphism: Use inset shadows for gauges to create "carved" depth.
- Shadows: Soft dual-tone shadows (Dark: bottom-right, Faint Light: top-left).

## 📐 Geometry & Grid
- Corner Radius: 8px (Cards), 4px (Buttons).
- Grid: Strict 8-point system.
- Typography: Inter (Sans-serif), Medium weight for headers.

## 📊 Component Logic
- Radial Dials: Glowing neon progress track over a recessed inset track.
- Cards: High-density layout with 16px internal padding.

🗂️ Card Architecture
Cards are the primary data containers. They must follow a "Physical Glass" logic to maintain depth across the app.

Layering: Never stack cards directly on the base background without a subtle 2px offset or a change in surface opacity to indicate hierarchy.

Internal Scoping: For complex cards (like "Upcoming Bills"), use a 1px horizontal separator with rgba(255,255,255,0.05) to divide line items without breaking the glass surface.

Micro-Interactions: Cards should exhibit a subtle "lift" effect on hover/focus—increase the backdrop-blur from 16px to 20px and slightly brighten the border opacity.

📱 Menu & Navigation System
The navigation must feel like an integrated part of the hardware, not an overlay.

Bottom Tab Bar: * Surface: Use the same Glassmorphic standard (70% opacity, 16px blur) as the cards.

Active State: The active icon must use a Neon Green (#22C55E) glow. Incorporate a small, 2px thick horizontal bar above the active icon to anchor the user's focus.

Geometry: The tab bar should have a top-left and top-right corner radius of 12px to "cradle" the app content.

Contextual Menus (Modals):

Any slide-up menu or drawer must use a higher Z-index surface with a darker overlay (backdrop-filter: brightness(0.5)) on the content beneath it to maintain the financial app's focus on security and clarity.

Iconography: Use "Linear" (outlined) icons with a 1.5px stroke weight. When an icon is active, transition it to a "Solid" fill with the Green accent.

# Trim – Financial Command App

---

## 🎯 Design Philosophy

Trim is not a dashboard.  
It is a **financial command center**.

Design must communicate:
- Clarity over complexity  
- Control over chaos  
- Trust over decoration  

Every element must answer:
> “Does this make the user feel more in control of their money?”

---

## 🎨 Color System

### Core Surfaces
- **Background:** `#0F172A` (Deep Slate)
- **Card Surface:** `#1E293B` @ 70% opacity
- **Glass Border:** `rgba(255,255,255,0.1)`

### Semantic Colors
- **Success (Money In / Growth):** `#22C55E` (Neon Green)
- **Action (Navigation / Interaction):** `#3B82F6` (Action Blue)
- **Warning (Attention Needed):** `#F59E0B` (Amber)
- **Danger (Loss / Risk):** `#EF4444` (Red)

### Rules
- Green is **earned**, not decorative  
- Blue is **neutral**, not emotional  
- Red must be **rare but unmistakable**

---

## ✨ Visual Effects System

### Glassmorphism (Primary Surface Language)
- `backdrop-blur: 16px`
- `border: 1px solid rgba(255,255,255,0.1)`
- Background opacity must never exceed 70%

### Depth Model ("Physical Glass")
- Cards float above background
- Modals sit above cards
- Background is infinite and static

### Shadows (Dual-Layer)
- **Primary Shadow:** bottom-right (dark)
- **Secondary Glow:** top-left (subtle blue/white)

### Neumorphism (Selective Use Only)
- Use **inset shadows** for:
  - radial dials
  - input fields
- Never apply to full cards

---

## 📐 Geometry & Layout

### Grid System
- Strict **8-point spacing system**
- Internal card padding: **16px**

### Corner Radius
- Cards: `8px`
- Buttons/Inputs: `4px`
- Navigation Bar (top only): `12px`

### Typography
- Font: **Inter**
- Headers: Medium (500)
- Body: Regular (400)
- Use high contrast for all financial values

---

## 📊 Core Component Logic

### 1. Financial Truth Layer (Top Priority Component)

**Net Position Card**
- Large central number (primary focus)
- Sub-label:
  - `+$2,350 this week` OR `$1,120 this month`
- Subtle glow based on state:
  - Green → positive trend
  - Neutral → stable
  - Dim/Red → negative trend

> This is the emotional anchor of the app.

---

### 2. Radial Dials (Use Sparingly)

Used only for:
- Savings goals
- Debt payoff progress
- Budget completion

Style:
- Neon progress arc
- Recessed inset track
- Soft glow on active values

---

### 3. Data Visualization

- Bars > Dials for comparisons
- Numbers > Charts for clarity
- Avoid clutter at all costs

---

## 🗂️ Card Architecture

Cards are **modular control panels**, not containers.

### Rules

#### Layering
- Never place cards flat on the background  
- Use:
  - 2px vertical offset OR  
  - opacity variation  

#### Internal Structure
- Use separators:
  - `1px rgba(255,255,255,0.05)`
- Maintain visual continuity (no harsh breaks)

#### Density
- High-density, but never cramped  
- Prioritize scan-ability over aesthetics  

---

## ⚡ Micro-Interactions

### Card Behavior
- Default: soft float
- Hover/Focus:
  - increase blur: `16px → 20px`
  - slightly brighten border
- Tap:
  - **subtle press-in before transition**

### Feedback Principle
Every action must feel:
> “Instant, intentional, controlled”

---

## 📱 Navigation System

Navigation must feel like **hardware**, not UI.

### Bottom Tab Bar

#### Surface
- Glassmorphic (same as cards)
- 70% opacity + 16px blur

#### Active State
- Neon Green icon glow (`#22C55E`)
- Add **2px indicator bar above icon**

#### Geometry
- Top-left & top-right radius: `12px`

---

### Navigation Motion

- Tabs should **slide**, not snap  
- Background remains fixed  
- Only content layers transition  

> Feels like rotating within a system—not switching screens.

---

## 🪟 Modals & Overlays

### Behavior
- Always higher Z-index than cards
- Must dim background:
  - `backdrop-filter: brightness(0.5)`

### Purpose
- Focus
- Security
- Decision-making clarity

---

## 🔲 Iconography

- Style: **Linear (Outlined)**
- Stroke: `1.5px`
- Active:
  - transitions to **Solid fill**
  - adopts **Green accent**

---

## 🚫 Anti-Patterns (Do NOT Do)

- Overuse glassmorphism (causes fatigue)
- Too many radial dials (becomes gimmicky)
- Weak color meaning (destroys trust)
- Over-animated transitions (feels unstable)

---

## 🧠 Final Principle

Users are not opening Trim to explore.

They are opening it to answer one question:

> “Am I okay?”

Your UI must answer that…
**in under 3 seconds.**