Design Language: Institutional Minimalism with Subtle Depth

1. CORE DESIGN PHILOSOPHY

Trim is not “friendly finance.”
Trim is controlled power.

Every pixel must communicate:

Stability
Precision
Trust
Quiet sophistication

If something feels decorative → remove it.
If something doesn’t improve decision-making → it doesn’t belong.

2. DESIGN TOKENS (NON-NEGOTIABLE)
Color System
--color-bg-primary: #0F172A;        /* Deep slate (main background) */
--color-surface: #1E293B;           /* Elevated cards */
--color-surface-glass: rgba(30, 41, 59, 0.7);

--color-accent-primary: #22C55E;    /* Success / growth */
--color-accent-secondary: #3B82F6;  /* Informational */

--color-text-primary: #FFFFFF;
--color-text-secondary: rgba(255,255,255,0.7);
--color-border-glass: rgba(255,255,255,0.1);
Spacing System (8-Point Grid ONLY)
--space-1: 8px;
--space-2: 16px;
--space-3: 24px;
--space-4: 32px;

No 10px. No 14px. No “close enough.”
Everything snaps to 8. That’s what makes it feel engineered.

Geometry
--radius-sm: 6px;
--radius-md: 8px;

--border-thin: 1px;

Rounded, but not soft.
Modern, not playful.

3. LAYERED UI ARCHITECTURE
Layer 0 — Background
Flat
Static
#0F172A
No gradients unless extremely subtle
Layer 1 — Cards (Primary UI Containers)
Base Style:
background: rgba(30, 41, 59, 0.7);
backdrop-filter: blur(16px);
border: 1px solid rgba(255,255,255,0.1);
border-radius: 8px;
padding: 16px;
Shadow (Neumorphic Hybrid):
box-shadow:
  6px 6px 12px rgba(0,0,0,0.35),
  -2px -2px 6px rgba(255,255,255,0.03);

This creates:

Depth without heaviness
A “soft engineered” feel
Layer 2 — Data Visualization

This is where Trim wins or loses.

Radial Gauges (CRITICAL COMPONENT)

Structure:

Base Track: Dark inset
Progress Layer: Accent green with glow
Inner Circle: Slightly recessed (neumorphic inset)
/* Track */
stroke: rgba(255,255,255,0.08);

/* Progress */
stroke: #22C55E;
filter: drop-shadow(0 0 6px rgba(34,197,94,0.6));
Inner Dial (Inset Effect):
box-shadow:
  inset 4px 4px 8px rgba(0,0,0,0.5),
  inset -2px -2px 4px rgba(255,255,255,0.04);
Bar Charts (Asset Allocation)
Use #3B82F6 for secondary data
Use #22C55E for primary/highlight
Rounded ends
Tight spacing (8px grid)
Layer 3 — Navigation

Bottom tab bar:

Glassmorphic
Slightly elevated
Active state = green accent glow
.active {
  color: #22C55E;
  filter: drop-shadow(0 0 4px rgba(34,197,94,0.5));
}
4. TYPOGRAPHY SYSTEM
Font: Inter
Hierarchy:
/* Headers */
font-weight: 600;
letter-spacing: 0.02em;

/* Body */
font-weight: 400;

/* Data (Numbers) */
font-weight: 700;
Rules:
Numbers must dominate visually
Labels must never compete with data
Use spacing, not size, for hierarchy whenever possible
5. GLASSMORPHISM (STRICT USAGE RULES)

Allowed ONLY for:

Overlay cards (e.g. “Upcoming Bills”)
Navigation containers
Modals

Never use it everywhere.
If everything is glass → nothing is.

6. NEUMORPHISM (CONTROLLED TACTILITY)

Used ONLY for:

Buttons
Toggles
Press states
Press Interaction:
Scale: 0.98
Shadow becomes inset

This creates the feeling:

“I pressed something real.”

7. MOTION SYSTEM (NO ANIMATION FOR ENTERTAINMENT)
Allowed Motion:
Micro-interactions:
Scale: 1 → 0.98 (tap)
Duration: 120ms
Transitions:
Opacity fade
Duration: 200–300ms
Easing: ease-in-out
Data Changes:
Smooth number transitions
No bouncing
No flashy effects

This is finance. Not a game.

8. COMPONENT BREAKDOWN (FROM YOUR IMAGE)
Top Section
Logo + Profile
Minimal distraction
Tight spacing
Main Card — Portfolio Performance
Large radial dial
Central number (dominant)
Supporting % (secondary)
Side Metrics
Cash Flow
Debt Ratio

Small radial indicators
Same visual language → smaller scale

Upcoming Bills (Glass Card)
Frosted
Light border
Vertical list
Status indicator (dot)
Asset Allocation
Horizontal bars
Clean labeling
No clutter
Bottom Navigation
3–4 tabs max
Active = green
Inactive = muted
