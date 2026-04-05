# Frontend Security Setup

## What Changed

- API endpoint configuration moved to [lib/config/api_config.dart](/c:/Users/HP/AndroidStudioProjects/Trusted-Social-Network-Platform-frontend/lib/config/api_config.dart) with release-mode HTTPS enforcement.
- API logs in [lib/services/api_service.dart](/c:/Users/HP/AndroidStudioProjects/Trusted-Social-Network-Platform-frontend/lib/services/api_service.dart) are disabled by default and redact tokens/passwords when enabled.
- Android release signing no longer hardcodes credentials in [android/app/build.gradle](/c:/Users/HP/AndroidStudioProjects/Trusted-Social-Network-Platform-frontend/android/app/build.gradle).
- Cleartext traffic is disabled in release through [android/app/src/main/AndroidManifest.xml](/c:/Users/HP/AndroidStudioProjects/Trusted-Social-Network-Platform-frontend/android/app/src/main/AndroidManifest.xml) and only allowed in debug/profile manifests.
- Local auth/session cleanup now clears stale tokens when the backend returns `401`.

## Development

1. Default local emulator target is `10.0.2.2`.
2. You can override the local server from the in-app server dialog.
3. Optional local launch:

```bash
flutter run --dart-define=DEV_SERVER=10.0.2.2
```

## Production

1. Use HTTPS only.
2. Provide the API base URL at build time:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/Trusted-Social-Network-Platform/api/v1
```

3. Create `android/key.properties` from [android/key.properties.example](/c:/Users/HP/AndroidStudioProjects/Trusted-Social-Network-Platform-frontend/android/key.properties.example).
4. Keep `android/key.properties` and the keystore file out of version control.

## Optional Debug Logging

API logs stay off unless you explicitly enable them:

```bash
flutter run --dart-define=ENABLE_API_LOGS=true
```

Even then, token/password/OTP fields are redacted before printing.

## Manual Checks

1. Open the server config dialog and verify local HTTP works in debug.
2. Build/review release config and confirm only HTTPS URLs are accepted.
3. Delete or expire the token, then hit a protected endpoint and confirm local credentials are cleared.
4. Verify release signing uses `android/key.properties` instead of inline secrets.
