# TRIM CORE SYSTEM SKILL
Version: 1.0

## PURPOSE
This skill defines the full system architecture, feature set, and technology stack for the Trim mobile application.

Trim is an AI-powered financial optimization platform focused on:
- Subscription discovery
- Bill negotiation
- Behavioral finance coaching
- Freelancer financial management

The system must operate with high trust, precision, and scalability.

---

## SYSTEM ARCHITECTURE

The project is divided into 4 primary domains:

1. MOBILE CLIENTS
- iOS (Swift, SwiftUI)
- Android (Kotlin, Jetpack Compose)

2. BACKEND SYSTEM
- API Layer
- AI/ML Models
- Business Logic Services

3. DOCUMENTATION LAYER
- Architecture specs
- API definitions
- UI/UX system

4. SHARED ASSETS
- Icons
- Fonts
- Visual assets

---

## DIRECTORY STRUCTURE (ENFORCED)

/ios → Native iOS app  
/android → Native Android app  

/backend  
    /api → API routes + controllers  
    /models → AI/ML logic  
    /services → Business logic + integrations  
    /tests → Backend testing  

/docs  
    /architecture → system diagrams  
    /api_specs → endpoint definitions  
    /ui_ux → design system  

/assets → shared resources  

---

## CORE FEATURES

1. Automated Subscription Discovery
- Detect recurring payments
- Categorize subscriptions
- Flag unused services

2. Bill Negotiation
- AI-assisted negotiation flows
- Cost reduction recommendations
- Provider interaction logic

3. Behavioral Finance Coaching
- Spending pattern analysis
- Personalized nudges
- Habit optimization loops

4. Freelancer Mode
- Income volatility handling
- Tax estimation + withholding
- Cash flow smoothing

---

## TECHNOLOGY STACK

Frontend:
- iOS: Swift + SwiftUI
- Android: Kotlin + Jetpack Compose

Backend:
- Python (FastAPI or Django)

AI/ML:
- TensorFlow or PyTorch

Database:
- PostgreSQL or MongoDB

Cloud:
- AWS / GCP / Azure

Integrations:
- Plaid → financial data aggregation
- Firebase → notifications

---

## SYSTEM INTENT

All generated code, features, and architecture decisions must:

- Follow modular backend design
- Keep AI logic isolated in /models
- Keep business logic in /services
- Maintain strict separation of concerns
- Be scalable and production-ready

No shortcuts. No mixed responsibilities.

---

## OUTPUT EXPECTATION

When invoked, this skill must:

- Generate code aligned to this structure
- Respect directory boundaries
- Use correct technologies per platform
- Maintain consistency across iOS, Android, and backend

This skill acts as the **source of truth** for the Trim system.