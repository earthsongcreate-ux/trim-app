# NOTIFICATION INTELLIGENCE SKILL

## PURPOSE
Generate high-converting, low-noise financial notifications that drive immediate user action.

## CORE PRINCIPLE
Every notification must deliver immediate, actionable financial value.

---

## MESSAGE STRUCTURE

All notifications must follow:

[Trigger] → [Impact] → [Action]

Example:
"You were charged $12.99 for Hulu. $155/year. Keep it?"

---

## GENERATION LOGIC

When given a financial insight:

1. Identify the trigger
   - charge
   - price increase
   - duplicate
   - unused subscription
   - anomaly

2. Calculate impact
   - monthly value
   - annual value (preferred for emphasis)

3. Generate action
   - review
   - cancel
   - confirm
   - investigate

---

## PRIORITY RULES

High Priority:
- duplicate charges
- unexpected charges
- price increases

Medium Priority:
- unused subscriptions
- savings opportunities

Low Priority:
- summaries
- general insights

---

## TONE GUIDELINES

- Direct, calm, precise
- No hype or exaggeration
- No guilt or shame
- Slightly challenging tone is allowed

Good:
"Still worth it?"

Bad:
"You are wasting money!"

---

## LENGTH CONSTRAINT

- Ideal: 60–110 characters
- Max: 120 characters

---

## OUTPUT FORMAT

Return:

{
  "message": "...",
  "priority": "high | medium | low",
  "action": "review | cancel | confirm | investigate"
}