# Funica

Furniture aur home decor ke liye ek dark-theme e-commerce mobile app, Flutter mein bana hua. Architecture **MVVM** hai, state management **Riverpod**, aur backend **Firebase**.

## Features

- **Auth:** Email/password, Google sign-in, phone OTP, forgot password, PIN aur fingerprint
- **Home:** Special offers banner, 8 categories, most popular products
- **Categories:** Sofa, Chair, Table, Kitchen, Lamp, Cupboard, Vase
- **Product detail:** Image carousel, color swatches, quantity, reviews
- **Search:** Recent searches, sort and filter (category, price, rating)
- **Wishlist aur Cart**
- **Checkout:** Address, shipping type, promo code, payment methods, PIN confirm
- **Orders:** Active/Completed, order tracking, leave a review, e-receipt
- **E-Wallet:** Balance, top up, transaction history
- **Profile:** Edit profile, addresses, cards, security, language, dark mode, invite friends
- **Help Center:** FAQ aur customer service chat
- **Push notifications** (FCM)

## Tech Stack

| Cheez | Use |
|---|---|
| Framework | Flutter (Dart) |
| Architecture | MVVM (View, ViewModel, Repository) |
| State management | flutter_riverpod |
| Navigation | go_router |
| Backend | Firebase Auth, Firestore, Storage, Messaging, Cloud Functions |
| Networking | dio |
| UI packages | google_fonts, flutter_svg, cached_network_image, pinput, flutter_rating_bar, smooth_page_indicator |

## Architecture (MVVM)

```
View  ->  ViewModel  ->  Repository  ->  Firebase / API
(UI)      (state+logic)   (data access)
```

- **View:** sirf UI, `ref.watch` se ViewModel ka state dekhta hai
- **ViewModel:** Riverpod `Notifier`, state aur business logic
- **Repository:** abstract class + implementation, data source se baat karta hai
- **Model:** plain Dart classes

## Folder Structure

```
funica/
├── assets/
│   ├── images/
│   ├── icons/
│   └── illustrations/
└── lib/
    ├── main.dart
    ├── core/
    │   ├── theme/          # app_colors, app_theme
    │   ├── router/         # app_router
    │   ├── constants/
    │   ├── network/        # api_client
    │   ├── services/       # storage_service
    │   └── utils/
    ├── shared/
    │   ├── widgets/        # primary_button, app_text_field, product_card...
    │   └── models/         # product, user, order, address
    └── features/
        ├── onboarding/
        ├── auth/
        ├── home/
        ├── notifications/
        ├── wishlist/
        ├── search/
        ├── product/
        ├── cart/
        ├── checkout/
        ├── orders/
        ├── wallet/
        ├── profile/
        └── help/
```

Har feature ke andar:

```
features/auth/
├── views/            # screens, views/widgets mein chhote widgets
├── viewmodels/       # auth_viewmodel.dart
├── models/
└── repositories/     # auth_repository.dart
```

## Getting Started

### Requirements

- Flutter SDK (stable) aur `flutter doctor` clean
- Android Studio (emulator) ya real device
- VS Code with Flutter aur Dart extensions
- Node.js (Firebase CLI ke liye)
- Ek Firebase project

### Setup

```powershell
# 1. Project scaffold (agar abhi nahi banaya)
Set-ExecutionPolicy -Scope Process Bypass
.\create_funica_mvvm.ps1

# 2. Project mein jao
cd funica

# 3. Dependencies
flutter pub get
```

### Firebase Setup

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Firebase console mein enable karo:

1. Authentication: Email/Password, Google, Phone
2. Firestore Database
3. Storage
4. Cloud Messaging

Android pe Google Sign-In ke liye SHA-1 key console mein add karo:

```powershell
cd android
./gradlew signingReport
```

`main.dart` mein Firebase initialize hona chahiye:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Run

```powershell
flutter run
```

## Firestore Collections

| Collection | Kaam |
|---|---|
| `users/{uid}` | profile data, FCM token |
| `users/{uid}/addresses` | saved addresses |
| `users/{uid}/wishlist` | wishlist items |
| `users/{uid}/cart` | cart items |
| `products/{id}` | product data |
| `products/{id}/reviews` | reviews |
| `categories`, `offers`, `promos` | catalog data |
| `orders/{id}` | orders |
| `orders/{id}/tracking` | tracking timeline |
| `wallets/{uid}`, `transactions` | wallet aur history |
| `notifications` | in-app notifications |
| `chats/{uid}/messages` | support chat |
| `faqs` | help center |

## Security Notes

- Firestore aur Storage rules production se pehle zaroor lagao, test mode mat chhodo.
- Wallet balance, payment verification aur stock update sirf Cloud Functions se karo, client se nahi.
- Full card number kabhi store mat karo, sirf brand aur last4.
- PIN ko hash karke `flutter_secure_storage` mein rakho.
- `google-services.json` aur `GoogleService-Info.plist` public repo mein push karne se pehle check kar lo, aur keystore (`key.properties`) kabhi commit mat karo.

## Roadmap

| Week | Kaam |
|---|---|
| 1 | Setup, UI foundation, Firebase, Firestore design |
| 2 | Auth, Home, Products |
| 3 | Search/Filter, Wishlist, Cart |
| 4-5 | Checkout, Orders, Tracking |
| 5-6 | Wallet, Profile, Settings |
| 7 | Help, Chat, Notifications |
| 8 | Security rules, Testing, Polish |
| 9 | Release |

## Build

```powershell
# Android APK
flutter build apk --release

# Play Store ke liye
flutter build appbundle --release
```

## Testing

```powershell
flutter test
```

## Contributing

1. Branch banao: `git checkout -b feature/your-feature`
2. Changes commit karo: `git commit -m "Add your feature"`
3. Push karo aur Pull Request kholo

## License

Personal learning project. Design reference: Funica UI kit.