# VoteWala

**Your Voice. Your Choice. / మీ అభిప్రాయం. మీ ఎంపిక.**

Andhra Pradesh political opinion polls: daily polls for all 175 assembly (MLA) and
25 parliament (MP) constituencies. Built with Flutter from a single codebase for:

- **Android** app
- **iOS** app
- **Website** (desktop: side navigation rail, wide layouts)
- **Mobile website** (same web build, phone layout with bottom navigation; installable as a PWA)

## Screens

| Screen | File |
| --- | --- |
| Welcome / language choice (తెలుగు / English) | `lib/screens/welcome_screen.dart` |
| Sign in (Google, mobile OTP) | `lib/screens/login_screen.dart` |
| Home (hero, MLA/MP polls, quick actions, featured polls) | `lib/screens/home_screen.dart` |
| MLA / MP constituencies (All / By District, search, district filter) | `lib/screens/constituency_list_screen.dart` |
| Constituency poll (vote, candidates, results, about) | `lib/screens/constituency_detail_screen.dart` |
| Candidate details | `lib/screens/candidate_detail_screen.dart` |
| Live poll results | `lib/screens/live_results_screen.dart` |
| AP map (district choropleth, tap a district) | `lib/screens/ap_map_screen.dart` |
| Results (date, stats, district-wise) | `lib/screens/results_screen.dart` |
| Profile, participation, saved candidates, settings | `lib/screens/profile_screen.dart`, `lib/screens/info_screens.dart` |
| Search, live polls, candidates directory | `lib/screens/browse_screens.dart` |

The whole UI is bilingual; switch with the EN / తెలుగు toggle on Home or in Profile → Language.

## Run

```bash
flutter pub get
flutter run -d chrome        # website / mobile website
flutter run -d android       # Android device or emulator
flutter run -d ios           # iOS simulator/device (macOS + Xcode)
```

## Build for release

```bash
flutter build web --release          # output: build/web  (host on any static host)
flutter build appbundle --release    # Play Store (.aab)
flutter build apk --release          # sideload APK
flutter build ipa --release          # App Store (macOS + Xcode, signing required)
```

## Data and backend status

- `lib/data/ap_data.dart` holds the real constituency list: 175 assembly constituencies
  (official numbering, English + Telugu names, 13 districts) and 25 parliament constituencies
  with their 7 assembly segments each.
- **Poll counts and candidate profiles are sample data** generated in
  `lib/data/poll_repository.dart` (placeholder names "Candidate 1…5"). Replace
  `PollRepository` with API calls and load candidate data from ECI affidavits.
- **Auth is a demo** (`lib/services/auth_service.dart`): Google sign-in returns a demo user and
  any 6-digit OTP is accepted. Implement `AuthService` with Firebase Auth (Google + phone) for
  production.
- Votes, language, saved candidates and settings are stored on-device with `shared_preferences`.

## Tests

```bash
flutter analyze
flutter test
```
