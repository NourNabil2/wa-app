# Fastway Mobile App 🚀

A full-featured Flutter e-commerce app supporting authenticated and guest checkout, order tracking, loyalty points, and Telr payment integration.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.x |
| State Management | flutter_bloc / Cubit |
| Networking | Dio + PrettyDioLogger |
| DI | get_it |
| Localization | easy_localization (AR / EN) |
| Local Storage | shared_preferences |
| Navigation | Named routes via AppRouter |
| Payment | Telr (WebView) |
| Architecture | Clean Architecture (Data / Domain / Presentation) |

---

## Project Structure

```
lib/
├── core/
│   ├── api/              # Dio client, base service, endpoints, interceptors
│   ├── di/               # get_it injection container
│   ├── errors/           # Failures, exceptions, result handler
│   ├── routes/           # AppRouter, route names
│   ├── service/          # AppInitializer, SessionService
│   ├── theme/            # Colors, AppTheme (light/dark)
│   └── widgets/          # Shared UI widgets
│
└── features/
    ├── auth/             # Login, OTP, register
    ├── cart/             # Cart management
    ├── checkout/         # Checkout flow, guest + auth, Telr payment
    ├── home/             # Home screen, banners, categories
    ├── orders/           # Order list, details, tracking
    ├── points/           # Loyalty points & rewards
    ├── product_details/  # Product page
    ├── profile/          # Profile, addresses, settings
    ├── search/           # Product search
    ├── settings/         # Theme & language (SettingsCubit)
    └── user_data/        # UserCubit, UserRepository, AuthGuard
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`
- Android Studio / Xcode
- A running instance of the Fastway backend API

### 1. Clone the repo

```bash
git clone https://github.com/your-org/fastway-mobile.git
cd fastway-mobile
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the API base URL

Open `lib/core/api/model/endpoints.dart` and set:

```dart
static const String baseUrl = 'https://your-domain.com/api/v1';
```

### 4. Add translation files

Ensure these exist:

```
assets/
└── translations/
    ├── ar.json
    └── en.json
```

Register in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/translations/
```

### 5. Run the app

```bash
# Debug on connected device
flutter run

# Specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

---

## Guest Mode

The app supports guest checkout without requiring registration.

- A UUID session ID is generated on first launch and persisted in `SharedPreferences` under `session_id`.
- Every API request sends `X-Session-ID: <uuid>` automatically via `DioApiService`.
- When the user logs in, the same UUID is sent alongside the Bearer token so the server merges the guest cart.
- On logout, the UUID is cleared and a new one is generated for the next guest session.

---

## Environment Flavors

| Flavor | Base URL | Notes |
|---|---|---|
| `dev` | `https://fastway.atwdemo.com/api/v1` | Logging enabled |
| `prod` | `https://your-domain.com/api/v1` | PrettyDioLogger disabled |

To run a specific flavor:

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

---

## Building a Release APK (Android)

### 1. Create a keystore (first time only)

```bash
keytool -genkey -v \
  -keystore android/app/fastway-release.jks \
  -alias fastway \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### 2. Configure signing in `android/app/build.gradle`

```groovy
android {
    signingConfigs {
        release {
            storeFile     file('fastway-release.jks')
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias      'fastway'
            keyPassword   System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 3. Build

```bash
# Fat APK (all ABIs — for direct install / sideload)
flutter build apk --release

# Split APKs per ABI (smaller file size — recommended for Play Store)
flutter build apk --release --split-per-abi

# App Bundle (required for Google Play)
flutter build appbundle --release
```

Output locations:

```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

---

## Building a Release IPA (iOS)

```bash
# Build runner archive
flutter build ipa --release

# Output
build/ios/archive/Runner.xcarchive
build/ios/ipa/
```

Then open Xcode Organizer → Distribute App → App Store Connect.

---

## Building for Web

### 1. Enable web support (one time)

```bash
flutter config --enable-web
```

### 2. Build

```bash
flutter build web --release
```

Output: `build/web/`

### 3. Optimize (optional but recommended)

```bash
# Use CanvasKit renderer for better text/font rendering
flutter build web --release --web-renderer canvaskit

# Use HTML renderer for smaller initial bundle
flutter build web --release --web-renderer html
```

### 4. Deploy to Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and init (first time)
firebase login
firebase init hosting
# Set public directory to: build/web

# Deploy
firebase deploy --only hosting
```

### 5. Deploy to Nginx / Apache

Copy `build/web/` contents to your web server root:

```bash
scp -r build/web/* user@your-server:/var/www/html/fastway/
```

Add this to your Nginx config to support Flutter's client-side routing:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### 6. Deploy to GitHub Pages

```bash
# Build with correct base href
flutter build web --release --base-href /fastway-mobile/

# Copy to gh-pages branch
cp -r build/web/* docs/

git add docs/
git commit -m "chore: deploy web build"
git push origin main
```

Then in GitHub → Settings → Pages → Source: `main` branch, `/docs` folder.

---

## Running Tests

```bash
# Unit & widget tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Integration tests
flutter test integration_test/
```

---

## Code Generation

```bash
# Re-run build_runner (for injectable, json_serializable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## Localization

Translation files are in `assets/translations/`.

```json
{
  "checkout": {
    "title": "إتمام الطلب",
    "guest": {
      "fullAddress": "العنوان الكامل",
      "phone": "رقم الجوال",
      "city": "المدينة",
      "district": "الحي (اختياري)",
      "save": "حفظ العنوان",
      "saved": "تم حفظ العنوان ✓",
      "fieldRequired": "هذا الحقل مطلوب"
    }
  }
}
```

To add a new language:

1. Create `assets/translations/fr.json`
2. Add `Locale('fr')` to `supportedLocales` in `main.dart` and `EasyLocalization`
3. Add `Locale('fr')` to `SettingsCubit` language options

---

## Common Issues

| Issue | Fix |
|---|---|
| `401 Unauthorized` on `/profile/addresses` for guests | `loadCheckout()` now skips the address fetch when `UserRepository().currentUser == null` |
| `type '_Map' is not subtype of 'List'` on orders | `getOrders()` now reads `res['data']['orders']` not `res['data']` |
| Guest address form not showing cities | Pass `state.cities` to `_GuestAddressForm(cities: state.cities)` |
| Theme/language not updating `MaterialApp` | Call both `SettingsCubit.setTheme/setLanguage()` AND `context.setLocale()` |
| `Routes.addAddress` crashes for guests | Router now falls back to `sl<AddressesCubit>()` when argument is null |

---

## Contributing

1. Create a branch: `git checkout -b feature/your-feature`
2. Commit with clear messages: `git commit -m "feat: add guest address form"`
3. Open a PR against `main`

Commit prefix convention: `feat:` `fix:` `chore:` `refactor:` `docs:`

---

## License

Private — All rights reserved © Fastway 2026# wa-app
# wa-app
