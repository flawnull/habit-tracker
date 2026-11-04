# Firebase setup (optional)

HabitTracker runs without Firebase. Habits and check-ins are always stored on device with SwiftData. Firebase only adds accounts: email sign-up, sign-in, password reset and a small user profile document.

If `GoogleService-Info.plist` is missing, the app starts in local demo mode and the login screen offers **Start tracking** instead of a sign-in form.

Setup takes about 10 minutes.

## 1. Create the project

1. Open the [Firebase console](https://console.firebase.google.com/) and click **Add project**.
2. Analytics is not needed. You can turn it off.

## 2. Register the iOS app

1. Add an **iOS** app.
2. Bundle ID: `com.habit-tracker`. If you change it, change `PRODUCT_BUNDLE_IDENTIFIER` in Xcode to match.
3. Download `GoogleService-Info.plist`.
4. Put it in the repo root, next to `AppDelegate.swift`. You don't need to add it to the Xcode project: the **Bundle Firebase config (optional)** build phase copies it into the app.

The file is listed in `.gitignore`. Keep it that way.

## 3. Enable sign-in

**Build → Authentication → Get started → Sign-in method → Email/Password → Enable.**

## 4. Create Firestore

1. **Build → Firestore Database → Create database.**
2. Pick a region close to your users.
3. Start in production mode, then deploy the rules in this repo:

```bash
npm install -g firebase-tools
firebase login
firebase init firestore   # point it at the existing firestore.rules
firebase deploy --only firestore:rules
```

Or paste the contents of [`firestore.rules`](firestore.rules) into **Firestore → Rules** and publish.

The rules let each signed-in user read and write only `users/{their uid}`. Everything else is denied.

## 5. Run

Clean build (<kbd>⇧</kbd><kbd>⌘</kbd><kbd>K</kbd>), then run (<kbd>⌘</kbd><kbd>R</kbd>). The build log prints `Firebase config bundled` when the plist was found.

Check it works:

1. Create an account from the login screen.
2. The user appears under **Authentication → Users**.
3. A document appears under **Firestore → users/{uid}** with `fullName`, `email` and `createdAt`.
4. Sign out from **Profile**, sign back in, and try **Forgot password**.

## Data model

| Location | Contents |
|---|---|
| Firebase Auth | Email, password hash, display name |
| `users/{uid}` | `uid`, `email`, `fullName`, `createdAt` |
| On device (SwiftData) | Habits, check-ins |

## Troubleshooting

| Symptom | Fix |
|---|---|
| Login screen says "Local demo build" | The plist was not found at build time. Check it sits in the repo root and is named exactly `GoogleService-Info.plist`. |
| Package resolution fails | **File → Packages → Reset Package Caches**, then build again. |
| `auth/operation-not-allowed` | Email/Password sign-in is not enabled in the console. |
| Firestore permission denied on sign-up | Deploy `firestore.rules`, or check the user is signed in before the write. |
| Sign-in works but the name shows "Habit builder" | The profile name is set after account creation. Pull to the Profile tab again, or sign out and in. |

## Before shipping

- Turn on [App Check](https://firebase.google.com/docs/app-check) for Auth and Firestore.
- Add email verification if you need it.
- Set up budget alerts in Google Cloud.
