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
First, use **Set up the first administrator** on a trusted device. After that,
public registration always creates student accounts. Staff/admin accounts can
review reports and claims, while only admins can change roles. Unauthorized
pages and protected operations show **Access denied**.

Local data belongs to this browser or app installation and is not shared
between devices. This is a simple offline/demo setup, not tamper-proof
server-side authorization: someone with access to the device or browser storage
can alter local data. Use a trusted backend before relying on roles across a
campus or for sensitive operations.
