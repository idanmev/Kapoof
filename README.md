# Kapoof 🪄✨

A magical creative assistant for children aged 5-8. Let your ideas come to life through games, stories, and drawings!

## 🚀 Setup Instructions

### 1. Gemini API Key
This app uses Google's Gemini Pro API for content generation.
1. Get an API key from [Google AI Studio](https://aistudio.google.com/).
2. Create a `.env` file in the root directory (this file is ignored by git).
3. Add your key to the `.env` file:
   ```env
   GEMINI_API_KEY=your_actual_key_here
   ```

### 2. Firebase Connection
The app uses Firebase for anonymous authentication and storing creations.
1. Create a new project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Anonymous Authentication**.
3. Enable **Cloud Firestore** and **Firebase Storage**.
4. Register your iOS and Android apps in the Firebase project settings.
5. Download and place the configuration files:
   - Android: Place `google-services.json` in `android/app/`.
   - iOS: Place `GoogleService-Info.plist` in `ios/Runner/`.

### 3. Firestore Index
To fetch creations for the current user ordered by date, you need a compound index.
- **Collection ID**: `creations`
- **Fields to index**:
  - `userId` (Ascending)
  - `createdAt` (Descending)
- **Query Scope**: Collection

You can also create this index by clicking the link printed in the debug console the first time you run the app and try to view the gallery.

### 4. Running the App
Make sure you have Flutter installed.

```bash
# Get dependencies
flutter pub get

# Run on iOS or Android
flutter run
```

## 🎨 Design System
The app follows a **Neobrutalist** design aesthetic:
- High contrast colors
- Thick black borders (4px - 8px)
- Hard shadows with no blur (Offset 4, 4 or 8, 8)
- Playful rounded corners (Radius 24 - 40)
- Bold typography (Lexend & Plus Jakarta Sans)

## 🧒 Kid-Friendly Features
- **Voice Parser**: A specialized AI interpreter that understands and celebrates child-like descriptions.
- **Magic Mirror**: Live preview of generated content using a loading shimmer and magical animations.
- **Celebratory UI**: Confetti, big emojis, and excited language throughout the experience.
- **Kid-Friendly Errors**: No technical jargon. Errors are explained with emojis and simple, reassuring words.
