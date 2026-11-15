# Authentication Progress

Yeh document app ke maujooda authentication code ka status batata hai. Isme sirf repository mein maujood implementation ko complete maana gaya hai; UI mein dikhne wale, lekin abhi wired nahi kiye gaye options ko alag mark kiya gaya hai.

## Overview

- **Framework:** Flutter
- **State management:** Riverpod (`AuthViewModel`)
- **Navigation:** `go_router`
- **Authentication/profile backend:** Firebase Authentication aur Cloud Firestore
- **Local security:** `flutter_secure_storage`, `shared_preferences`, `local_auth`

## Jo kaam ho chuka hai

### Email/password sign-up

- Name, email aur password ke fields aur form validation maujood hain.
- Email Firebase Authentication ke saath account create hota hai; input email trim hota hai.
- Firebase Auth display name update hota hai.
- Firestore ke `users/{uid}` document mein UID, name, email aur creation timestamp save hote hain.
- Success par user profile completion screen par jata hai.
- Firebase Auth/Firestore errors ko user-readable messages mein dikhaya jata hai.

### Email/password login

- Email format aur non-empty password validate hote hain.
- Firebase Authentication se sign-in hota hai.
- Sign-in ke baad `users/{uid}` profile missing ho to basic profile create hoti hai.
- Login success par app home ke bajaye PIN verification screen kholta hai.
- Loading state aur common Firebase errors ke messages maujood hain.

### Forgot password

- Email validation ke baad Firebase Auth password-reset email bhejta hai.
- Loading state aur success/error feedback diya jata hai.

### Profile completion

- Signup se name/email prefill kiye ja sakte hain; maujooda Firebase profile bhi load hoti hai.
- Name, nickname, date of birth, phone number aur gender edit kiye ja sakte hain.
- Profile Firestore ke `users/{uid}` document mein merge hoti hai aur Firebase display name update hota hai.
- Profile save hone ke baad naya account PIN setup par jata hai.
- Profile photo ke liye camera/gallery picker UI hai; current save flow photo upload ya photo URL persist nahi karta.

### PIN setup aur verification

- Naye user ko chaar-digit PIN do baar enter karke confirm karna hota hai.
- PIN mismatch par error milta hai; PIN sahi tarah save hone par session unlock hota hai.
- Existing signed-in user ke liye PIN keypad verification hai.
- PIN input par haptic feedback aur incorrect PIN par retry message diya jata hai.
- PIN bhoolne par sign-out karke dobara login karne ka option hai.

### Session aur protected navigation

- Router Firebase sign-in state ke mutabiq auth, setup aur protected routes par redirect karta hai.
- Signed-in, locked user ko PIN verification se guzarna padta hai.
- PIN create karne ke baad user home par jata hai.
- App detached hone par in-memory PIN session lock ki jati hai.

### Fingerprint implementation

- `local_auth` use karke device support, enrolled biometrics aur biometric verification check karne wala bottom sheet maujood hai.
- Fingerprint preference ko `SharedPreferences` aur Firestore mein save karne ka code hai.
- Fingerprint setup screen par Continue aur Skip actions hain.

## Abhi pending / incomplete

- Google, Apple aur Facebook buttons UI mein hain, lekin sign-in actions TODO hain.
- Phone OTP flow abhi implemented nahi hai; OTP screen file maujooda auth views mein nahi hai.
- Fingerprint setup screen aur bottom sheet maujood hain, lekin router mein fingerprint route nahi hai aur current signup/PIN flow unhe open nahi karta.
- PIN screen se biometric unlock ka flow wired nahi hai. Isliye biometric UI ko complete sign-in/unlock feature na samjhein.

## Implementation notes

- `Firebase.initializeApp` web, Android aur iOS par hota hai. Kisi aur platform par Firebase initialization/configuration check karni hogi.
- Sign-up, login, reset email aur profile save ke liye Firebase project setup, Email/Password provider enablement aur sahi Firestore security rules zaroori hain.
- PIN local secure storage mein save karne ki koshish hoti hai; fallback `SharedPreferences` hai. Firestore bhi PIN ko `users/{uid}` document mein seedha `pin` field ke roop mein rakhta hai. Production se pehle is remote PIN storage ko secure design se badalna chahiye aur Firestore rules ko review karna chahiye.
- PIN storage mein local/Firestore fallback failures kuch paths par ignore hote hain; cross-device PIN recovery ki reliability setup aur permissions par depend kar sakti hai.

## Main implementation files

- `lib/features/auth/repositories/auth_repository.dart` — Firebase Auth aur basic Firestore user profile.
- `lib/features/auth/viewmodels/auth_viewmodel.dart` — loading/error state aur auth operations.
- `lib/features/auth/views/login_screen.dart` — login UI.
- `lib/features/auth/views/signup_screen.dart` — signup UI.
- `lib/features/auth/views/forgot_password_screen.dart` — password reset UI.
- `lib/features/auth/views/fill_profile_screen.dart` — profile completion.
- `lib/features/auth/views/create_pin_screen.dart` — PIN setup/confirmation.
- `lib/features/auth/views/enter_pin_screen.dart` — PIN verification.
- `lib/features/auth/views/fingerprint_screen.dart` — fingerprint setup UI.
- `lib/features/auth/widgets/fingerprint_bottom_sheet.dart` — native biometric prompt.
- `lib/core/services/pin_storage.dart` — PIN aur fingerprint preference persistence.
- `lib/core/services/pin_session.dart` — in-memory unlocked session state.
- `lib/core/router/app_router.dart` — auth/setup routes aur access redirects.
