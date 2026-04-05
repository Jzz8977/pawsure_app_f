# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# 安装依赖
flutter pub get

# 运行（选择目标设备）
flutter run

# 静态分析
flutter analyze

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/widget_test.dart

# 重新生成 i18n 本地化文件（修改 .arb 后必须执行）
flutter gen-l10n

# 代码生成（freezed / json_serializable / riverpod_generator）
dart run build_runner build --delete-conflicting-outputs

# 监听模式（开发期持续生成）
dart run build_runner watch --delete-conflicting-outputs
```

## Architecture Overview

### Tech Stack
- **State management**: Riverpod v3 — vanilla `Notifier`/`NotifierProvider` for core providers (no code-gen needed); `@riverpod` annotation for feature-level providers
- **Routing**: go_router v17 with `ShellRoute` for dual-role tab shells
- **Networking**: Dio + `TokenInterceptor` (auto-injects Bearer token on request; extracts token from response headers on login)
- **i18n**: Flutter's built-in `flutter gen-l10n` with ARB files; output class is `S`
- **Local storage**: `FlutterSecureStorage` for tokens/sensitive data; `SharedPreferences` for theme/locale preferences

### Dual-Role Routing
The app has two user roles that determine which shell the user lands in after login:

```
/welcome → /login-phone → login succeeds
    ├── UserRole.petOwner  → /home   (PetOwnerShell — 4 tabs: home/pets/chat/my)
    └── UserRole.provider  → /provider-home  (ProviderShell — 2 tabs: home/work-tab)
```

`_RouterNotifier` in `app_router.dart` bridges `userNotifierProvider` to GoRouter's `refreshListenable`, triggering redirect logic whenever auth state changes. All routes outside the shells use `context.push(path)`.

### Core Providers (no build_runner required)
| Provider | Location | Purpose |
|----------|----------|---------|
| `userNotifierProvider` | `shared/providers/user_provider.dart` | Auth state, `UserModel?`, `UserRole` |
| `themeNotifierProvider` | `core/theme/theme_provider.dart` | Light/Dark/System, persisted to SharedPreferences |
| `localeNotifierProvider` | `core/i18n/locale_provider.dart` | zh/en locale, persisted to SharedPreferences |
| `dioProvider` | `core/network/dio_client.dart` | Singleton Dio instance with `TokenInterceptor` attached |
| `secureStorageProvider` | `core/storage/secure_storage.dart` | Wrapper around FlutterSecureStorage |

### API Constants
All endpoints are in `lib/core/constants/api_constants.dart`, organized as static classes per domain:
- `AuthApi`, `OrderApi`, `PetApi`, `WalletApi`, `CheckinApi`, etc.
- Base URL: `https://www.jiaweiwei.top` (switch environments by editing `ApiConstants.baseUrl`)
- Four path prefixes: `/api/id` (general), `/api/lib` (dict/breeds/files), `/api/trade` (wallet/payment), `/api/order` (orders/checkin)
- `ApiConstants.loginPaths` drives token extraction in `TokenInterceptor.onResponse`

### Token Flow
1. Login response → `TokenInterceptor.onResponse` detects login path → reads `x-access-token` header → writes to `SecureStorage`
2. Subsequent requests → `TokenInterceptor.onRequest` reads token → injects `Authorization: Bearer <token>`
3. 401 response → clears all stored tokens

### i18n
- ARB template: `lib/core/i18n/l10n/app_zh.arb` (Chinese, add new keys here first)
- English translation: `lib/core/i18n/l10n/app_en.arb`
- Generated class `S` lives in `lib/core/i18n/l10n/app_localizations.dart`
- Import path: `package:pawsure_app/core/i18n/l10n/app_localizations.dart`
- Usage in widgets: `final s = S.of(context)!;`

### Adding a New Page
1. Create the page under `lib/features/<feature>/presentation/pages/`
2. Add a `GoRoute` entry in `lib/app/router/app_router.dart`
3. Import the page at the top of `app_router.dart`

### Adding a New API Call
Use the relevant class from `api_constants.dart` and the `dioProvider`:
```dart
final dio = ref.read(dioProvider);
final response = await dio.post(AuthApi.phoneLogin, data: {...});
```
