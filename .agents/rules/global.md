---
trigger: always_on
---

# GLOBAL RULES

## 1. SYSTEM DISCIPLINE
- All outputs must be production-ready by default
- No placeholder logic in final implementations
- Avoid unnecessary complexity at all times
- Prefer explicit behavior over implicit assumptions

## 2. ARCHITECTURE INTEGRITY
- Maintain strict separation of concerns across all layers
- Do not mix UI, business logic, and AI logic in the same module
- Each module must have a single responsibility

## 3. CONSISTENCY RULE
- Use existing patterns before introducing new ones
- Do not create duplicate implementations of existing logic
- Maintain naming consistency across the system

## 4. SECURITY & TRUST
- Never expose sensitive user data in logs or UI
- Always assume financial data requires protection-first design
- Fail safely, not silently

## 5. QUALITY STANDARD
- If a solution is uncertain, prefer explicit error handling
- Do not guess critical financial logic
- Validate before execution in all system decisions