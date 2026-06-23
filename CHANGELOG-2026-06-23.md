# AutoLearn Changelog - June 23, 2026

This document summarizes all the major features, bug fixes, integration cleanups, and security remediations applied to the application today.

## 1. UI & Theme Enhancements
- **Admin Dashboard Redesign**: Restructured the Admin Dashboard layout to match a premium "AdminKit" design aesthetic. Implemented a Dark Sidebar alongside a Light Main Content area.
- **Theme Support**: Enabled comprehensive Light and Dark theme modes across the app. Fixed a compilation error in `app_theme.dart` regarding the `lightTheme` getter and block initialization logic to ensure seamless theme toggling.
- **Dashboard Charts**: Integrated the `fl_chart` library into the Admin Dashboard components and wired the Category Bar Chart to plot dynamic heights using the top 4 courses by enrollment.

## 2. System-Wide Integration & Mock Data Cleanup
- **Auth Flow**: Updated `AuthRepository.getCurrentUser()` to successfully fetch live user profiles via `getUserProfile(uid)` instead of resolving stub mock profiles.
- **Async State Resolution**: Refactored `home_page.dart` to await Future profile fetches in `initState()`, preventing UI crashes when loading the sidebar widget.
- **AI Chat Integrations**: Stripped out hardcoded `'mock_session'` fallbacks inside `chat_repository.dart`. If session generation fails, the system now safely throws an exception which the UI gracefully catches via Snackbars.
- **Data Hardcoding**: Verified that all mock data dependencies in Auth, Chat, and Analytics have been stripped and properly replaced with dynamic state maps connected to your endpoints.

## 3. Security Audit & Hardening
- **Critical Secret Removal**: Removed a plaintext, hardcoded OpenAI API key from `ai_tutor_engine.dart` (Note: ensure this key is revoked on the OpenAI dashboard).
- **Compile-Time Key Injection**: Upgraded the OpenAI logic to use `String.fromEnvironment('OPENAI_API_KEY')` for secure, compile-time key initialization.
- **Log Leakage Prevention**: Replaced over 20 insecure `print()` statements with `debugPrint()` across `AuthRepository`, `ChatRepository`, `CourseRepository`, `UserRepository`, `PaymentGatewayService`, and `main.dart` to prevent sensitive payloads from leaking to system logcats in production builds.
- **HTTPS Enforcement**: Added an automatic protocol-check in `api_client.dart` that intercepts HTTP traffic and rewrites it to HTTPS (except on localhost environments) to defend against MITM sniffing.

## 4. Internal SEO Optimization (Flutter Web)
- **Path URL Strategy (Clean URLs)**: Removed default Flutter hash routing (e.g., `/#/login`) by invoking `usePathUrlStrategy()` inside `main.dart`, yielding clean URLs like `/login`. Verified that `vercel.json` already natively rewrites traffic to support this.
- **Rich Meta Tags**: Completely overhauled `web/index.html` with robust meta tags, including SEO keyword descriptors, Open Graph data (`og:title`, `og:image`), and Twitter Cards, empowering rich link-previews across Discord, iMessage, and Twitter.
- **Dynamic Browser Titling**: Wrapped the primary application routes inside Flutter's native `Title` widgets, enabling the browser tab's text to dynamically update as users navigate between the Welcome, Login, Dashboard, and Admin screens.
