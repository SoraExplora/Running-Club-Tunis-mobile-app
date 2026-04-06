 Running Club Tunis – Inclusive Mobile Application 

#MaraTechEsprit2026

A modern, inclusive, and role-based mobile application designed for **Running Club Tunis**, built to enhance community engagement, event management, and accessibility for all users — including people with special needs.

---

📌 Project Overview

**Running Club Tunis Platform** is a web/mobile application developed to digitalize and centralize the activities of the *Running Club Tunis* association.  
The solution respects inclusivity, accessibility, and clean governance while offering a modern user experience adapted to each user’s needs.

The platform supports:
- Multiple user roles with controlled permissions
- Inclusive UI adaptations (color blindness & contrast sensitivity)
- Event and program management
- Public content access for non-members
- Centralized administration with strict role hierarchy

---

 About the Association

**Running Club Tunis** is a community-driven association that promotes:
- Healthy lifestyle through running
- Inclusivity and solidarity
- Participation in marathons and sports events
- Collective progress and mutual support
- 

This platform reflects the association’s identity by showcasing real moments from past marathons, its values, and its mission — while offering members a structured digital environment.

---

 ♿ Accessibility & Inclusivity

Inclusivity is a **core pillar** of this project:

🎨 4 Color-Blind Friendly UI Modes
Custom color palettes adapted to different types of color vision deficiency.

🌗 Dark Mode / Light Mode
Optimized for users with contrast sensitivity and visual fatigue.

🔍 Adjustable UI Scale
Users can resize buttons and interface components to improve readability and ease of interaction for people with visual impairments.

🧭 Guided Onboarding Tutorial
A step-by-step tutorial is displayed on first login to help new users understand how to navigate and use the application confidently.

🧠 AI Accessibility Assistant
An intelligent assistant that:

Converts the UI into speech for visually impaired users

Allows users to navigate and interact with the app using voice commands, enabling hands-free usage for people with motor disabilities

✨ Adaptive UX
The interface dynamically adjusts to each user’s preferences to ensure comfort, clarity, and autonomy.

---

## 👥 User Roles & Permissions

| Role | Capabilities |
|-----|-------------|
| **Admin** | Full control, user role management, hierarchy definition, bans and promote users |
| **Coach** | Add & view training programs |
| **Group Admin (Meneur d’allure)** | Create and manage one running group, add members |
| **Member** | Register for events, manage profile, access features |
| **Guest** | Access public content (blog, association presentation) |

All actions are controlled through a **clean and respectful permission system**.

---

 🚀 Main Features

- Public homepage presenting the association’s identity
- Blog posts accessible without authentication
- Event viewing & registration
- Role-based dashboards
- Personal profile creation & update
- Program management by coaches
- Group creation & management by group admins
- Secure and centralized administration
- Inclusive UI & adaptive themes

---

 🛠️ Technologies Used

- **Frontend:** Flutter  
- **Backend:** Firebase (Authentication, Firestore, Storage)  
- **UI/UX:** Adaptive design, accessibility-first approach  
- **State Management:** Flutter-native / Firebase integration  
- **Authentication:** Role-based Firebase Auth  

---

 ⚙️ Installation & Setup

### Prerequisites
- Flutter SDK installed
- Firebase project configured
- Android Studio / VS Code
- Emulator or physical device

### Steps

```bash
# Clone the repository
git clone https://github.com/orroo/EspritMaratech2026-DreamTeam.git

# Navigate to the project
cd running-club-tunis

# Install dependencies
flutter pub get

# Run the application
flutter run
