🌴 CEYLON – Smart Tourism & Business Travel App

A Flutter + Firebase project with AI recommendations, localization, and business tools.

✨ Features
🔐 Authentication & Onboarding

Email/Password login & signup

Google Sign-In

Auto-login routing

Role-based Home (Tourist / Business)

Editable profile with Firestore sync

🗺️ Travel Tools for Tourists

Itinerary Builder (create, edit, save trips)

Nearby Attractions (OpenStreetMap)

Place details → Get directions via Google Maps

Favorites / Bookmarks ❤️

Share trips via device share sheet

🛎️ Notifications & AI

Push Notifications (Firebase Cloud Messaging)

AI-powered attraction recommendations (Gemini API – free tier)

💼 Business Features

Dashboard to manage business info

Publish & promote events

Respond to reviews

Analytics charts & feedback collection

Trusted badges for verified tours / homestays

🌐 Localization

Multi-language toggle (English 🇺🇸🇬🇧🇦🇺, Hindi 🇮🇳, Dhivehi 🇲🇻, Russian 🇷🇺, German 🇩🇪, French 🇫🇷, Dutch 🇳🇱)

Auto-detect language preference from Firestore after login

📂 Project Structure
apps/
 ├── ceylon/                # Main tourism app (Flutter + Firebase)

ceylon/ – full tourism platform with traveler + business modules

🚀 Getting Started
1. Clone the repo
git clone https://github.com/<your-username>/<repo>.git
cd <repo>

2. Setup CEYLON App
cd apps/ceylon
flutter pub get
flutter run


Make sure your google-services.json and firebase_options.dart are configured.

3. Setup Portfolio
cd apps/pasindu_portfolio
flutter pub get
flutter run -d chrome

Build for web:

flutter build web

☁️ Deployment
CEYLON App

📊 Tech Stack

Frontend: Flutter (Material 3, responsive UI)

Backend: Firebase (Auth, Firestore, Storage, FCM)

AI: Gemini API (Recommendations)

Maps: OpenStreetMap + Google Maps Deep Link

Hosting: Firebase Hosting / GitHub Pages

📸 Screenshots

<img width="250" height="500" alt="tourist home 1" src="https://github.com/user-attachments/assets/ce755563-da56-43a5-8131-104c53040f06" />

<img width="250" height="500" alt="tourist  home 2" src="https://github.com/user-attachments/assets/d1cf4531-ed65-4ac1-a4c1-a4d2d0bae58e" />


📅 Project Roadmap

✅ Authentication & Onboarding

✅ Itinerary Builder

✅ Map integration + Google Maps directions

✅ Reviews & Ratings

✅ Push Notifications

✅ Business Dashboard

🚧 AI Recommendations & Analytics

🚧 Final Polish (Dark Mode, Accessibility, Offline caching)

🚧 Store submission

👨‍💻 Author - Pasindu Jayakodi

MIT License © 2025 Pasindu Jayakodi
