# mood_nakshatra_tracker

# Mood × Nakshatra Tracker 🌙

A beautiful Flutter web app to track your daily moods and explore how they correlate with the Moon's current Nakshatra (lunar mansion in Vedic astrology).

Log your mood each day, see the current transit Nakshatra, and visualize patterns over weeks, months, and years.

**Live Demo** (coming soon): []()  

## Features

- **Profile Setup** – Enter your name, gender, birth details, and location (for future natal chart features).
- **Daily Mood Logging** – 
  - Real-time current Moon Nakshatra with transit period (fetched via Vedic panchang API).
  - Choose from four moods: 😠 Angry, 😢 Sad, 😊 Happy, 💪 Productive.
  - Optional notes.
- **Insightful Charts** – Bar charts showing mood distribution across different Nakshatras (weekly, monthly, yearly views).
- **Settings & Backup** – 
  - Manual backup: Download all your data as a JSON file.
  - Restore: Upload a previous backup.
  - (Perfect for saving to Google Drive manually on web; auto Google Drive backup coming on Android/iOS)

## Screenshots

*(will be updated shortly)*
Profile Screen
Mood Logging
Charts
Settings Backup



## Tech Stack

- **Flutter** (single codebase – web first, Android/iOS ready)
- **Riverpod** – State management
- **Hive** – Lightweight local NoSQL database (works perfectly on web)
- **fl_chart** – Beautiful, customizable charts
- **file_picker** – Backup/restore on web
- Vedic panchang data via ProKerala API (Lahiri ayanamsa)

## Getting Started (Development)

### Prerequisites

- Flutter SDK (≥3.0.0)
- Git

### Setup

```bash
# Clone the repo
git clone https://github.com/0reenu0/mood_nakshatra_tracker.git
cd mood_nakshatra_tracker

# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome
```


Build for Production (Web)
```bash
flutter build web --release
```
The output will be in /build/web – ready to deploy!

Deploy to GitHub Pages in minutes:

# Install flutter_gh_pages (one-time)

```bash
dart pub global activate flutter_gh_pages
# Deploy
flutter_gh_pages deploy
```

Or use Firebase Hosting, Netlify, or Vercel by dragging the build/web folder.

Future Plans:

Android & iOS release with native look
Auto Google Drive backup/restore (using google_sign_in + googleapis)
Natal Moon Nakshatra comparison
Mood trends notifications
Dark mode toggle
Shareable insights



