# Splash Screen Progress

Yeh document app ke maujooda splash screen aur usse jude startup/navigation behavior ka summary hai.

## Jo implement hai

- App ka initial route splash screen hai.
- Splash screen par dashboard jaisa warm theme (`AppColors.background`), stylish chair icon ke saath **Funica** branding, aur primary burnt-orange circular loading indicator dikhte hain.
- Screen khulne ke baad teen seconds ka fixed delay hota hai.
- Delay ke baad Firebase initialized ho aur current user signed in ho, to splash `/home` par navigate karta hai.
- Signed-in user ke PIN/session state ko `go_router` redirect sambhalta hai. Locked user ko home ke bajaye PIN verification par bheja ja sakta hai.
- Firebase initialized na ho ya user signed in na ho, to splash `/onboarding` par navigate karta hai.
- Navigation se pehle widget mounted hai ya nahi, check kiya jata hai.

## Onboarding se connection

- Onboarding mein welcome screen aur teen feature slides hain.
- Welcome screen teen seconds baad agle slide par auto-advance karti hai, agar user ne swipe nahi kiya.
- Aakhri slide complete karne par `onboarding_seen` preference save hoti hai aur user `/lets-you-in` par jata hai.
- Onboarding seen preference read karne ka `StorageService.isOnboardingSeen()` method maujood hai.

## Abhi pending / limitations

- Splash screen `onboarding_seen` preference check nahi karti. Isliye currently har signed-out app launch onboarding par jata hai, chahe onboarding pehle complete hui ho.
- Splash fixed teen seconds rukta hai; Firebase auth/loading state ke saath koi explicit readiness synchronization nahi hai.
- Splash flow ke liye alag error/loading recovery UI nahi hai.
- Splash UI mein animation nahi, sirf static branding aur progress indicator hai.

## Startup flow

```text
App launch
  -> Firebase initialize (web, Android, iOS par)
  -> Splash screen (3 seconds)
      -> Signed in: /home -> router PIN/session guard apply karta hai
      -> Signed out: /onboarding
          -> onboarding complete: /lets-you-in
```

## Related files

- `lib/main.dart` — Firebase initialization aur app startup.
- `lib/core/router/app_router.dart` — initial route aur auth/PIN redirects.
- `lib/features/onboarding/views/splash_screen.dart` — splash UI aur teen-second navigation decision.
- `lib/features/onboarding/views/onboarding_screen.dart` — onboarding slides aur completion navigation.
- `lib/features/onboarding/viewmodels/onboarding_viewmodel.dart` — onboarding completion state coordination.
- `lib/core/services/storage_service.dart` — `onboarding_seen` preference read/write.
- `lib/core/constants/app_colors.dart` — splash background/text colors.
