# lost_and_found_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## User roles

Roles, accounts, reports, and claims are stored locally with
`shared_preferences`; no Firebase project or network connection is required.
Students can register with Gmail or another valid email. Preconfigured staff
emails are seeded with the Staff role on startup; the staff member creates
their password through **Create an account** on first use. Add or change
preconfigured addresses in `lib/auth_service.dart`. Admins can assign roles
to existing accounts from **Manage user roles**. Staff/admin accounts can
review reports and claims, while only admins can manage roles. Unauthorized
pages and protected operations show **Access denied**. There is no public
admin registration screen. This app does not verify email ownership and has
no backend, so preconfigured roles and accounts are local to each installation;
use trusted server-side authentication before relying on them across a campus.

Local data belongs to this browser or app installation and is not shared
between devices. This is a simple offline/demo setup, not tamper-proof
server-side authorization: someone with access to the device or browser storage
can alter local data. Use a trusted backend before relying on roles across a
campus or for sensitive operations.
