---
trigger: always_on
---

# BACKEND RULES

## 1. ARCHITECTURE STRUCTURE
- Controllers must remain thin (routing only)
- Business logic must live in services layer only
- Data access must be isolated from business logic

## 2. API DESIGN
- APIs must be deterministic and predictable
- Avoid coupling endpoints to UI requirements
- Version all external-facing APIs

## 3. DATA HANDLING
- Never trust external input without validation
- Normalize data at ingestion layer
- Maintain single source of truth for financial records

## 4. INTEGRATIONS
- External services must be wrapped in abstraction layers
- No direct third-party calls inside core business logic
- Fail gracefully when external systems are unavailable

## 5. SCALABILITY RULE
- Write stateless services where possible
- Avoid synchronous blocking operations in critical flows