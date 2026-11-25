// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:lost_and_found_app/auth_service.dart';
import 'package:lost_and_found_app/lost_report.dart';
import 'package:lost_and_found_app/UserAccess.dart';

void main() {
  test(
    'Local signup defaults to student and only admin can assign roles',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      final admin = await AuthService.bootstrapAdmin(
        name: 'Initial Admin',
        email: 'admin@cadt.edu.kh',
        password: 'admin-pass-123',
      );
      expect(admin.role, UserRole.admin);
      await expectLater(
        AuthService.bootstrapAdmin(
          name: 'Second Admin',
          email: 'other-admin@cadt.edu.kh',
          password: 'another-pass-123',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        await AuthService.register(
          'Campus Student',
          'student@gmail.com',
          'student-pass-123',
        ),
        isNull,
      );
      final student = await AuthService.login(
        'student@gmail.com',
        'student-pass-123',
      );
      expect(student?.role, UserRole.student);
      await expectLater(
        AuthService.updateRole(student!.id, UserRole.staff),
        throwsA(isA<AccessDeniedException>()),
      );

      await AuthService.login('admin@cadt.edu.kh', 'admin-pass-123');
      await AuthService.updateRole(student.id, UserRole.staff);
      final users = await AuthService.allUsers();
      expect(
        users.singleWhere((user) => user.id == student.id).role,
        UserRole.staff,
      );
      await AuthService.signOut();
      final staff = await AuthService.login(
        'student@gmail.com',
        'student-pass-123',
      );
      expect(staff?.role, UserRole.staff);
    },
  );

  testWidgets('Admins can create staff accounts from role management', (
    WidgetTester tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    AuthService.setCurrentUserForTesting(
      const UserRecord(
        id: 'role-admin-uid',
        name: 'Admin',
        email: 'role-admin@example.com',
        passwordSalt: '',
        passwordHash: '',
        role: UserRole.admin,
      ),
    );
    addTearDown(() => AuthService.setCurrentUserForTesting(null));
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: RoleManagementPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add staff'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Staff Member');
    await tester.enterText(fields.at(1), 'admin@gmail.com');
    await tester.enterText(fields.at(2), 'staff-test-pass-123');
    await tester.enterText(fields.at(3), 'staff-test-pass-123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create staff account'));
    await tester.pumpAndSettle();

    expect(find.text('Staff account created.'), findsOneWidget);
    expect(find.text('admin@gmail.com'), findsOneWidget);
    final staff = (await AuthService.allUsers()).singleWhere(
      (user) => user.email == 'admin@gmail.com',
    );
    expect(staff.role, UserRole.staff);
    await AuthService.signOut();
    expect(
      (await AuthService.login('admin@gmail.com', 'staff-test-pass-123'))?.role,
      UserRole.staff,
    );
  });

  test(
    'Staff can review local reports and claims but cannot manage roles',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      AuthService.setCurrentUserForTesting(
        const UserRecord(
          id: 'staff-uid',
          name: 'Staff Member',
          email: 'staff@cadt.edu.kh',
          passwordSalt: '',
          passwordHash: '',
          role: UserRole.staff,
        ),
      );
      addTearDown(() => AuthService.setCurrentUserForTesting(null));

      final report = await LostReportRepository.add(
        title: 'Notebook',
        description: 'Blue notebook',
        category: 'Other',
        dateLost: DateTime(2026, 1, 1),
        location: 'Library',
      );
      final claim = await LostReportClaimRepository.submit(
        reportId: report.id,
        details: 'My initials are on the cover.',
      );
      expect(
        (await LostReportRepository.allForStaffReview()).single.id,
        report.id,
      );
      expect(
        (await LostReportClaimRepository.allForStaffReview()).single.id,
        claim.id,
      );

      await LostReportRepository.review(report.id, 'Resolved');
      await LostReportClaimRepository.review(claim.id, 'Approved');
      expect(
        (await LostReportRepository.allForStaffReview()).single.status,
        'Resolved',
      );
      expect(
        (await LostReportClaimRepository.allForStaffReview()).single.status,
        'Approved',
      );
      await expectLater(
        AuthService.updateRole('student-uid', UserRole.staff),
        throwsA(isA<AccessDeniedException>()),
      );
    },
  );

  testWidgets('Login UI renders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Campus Email'), findsOneWidget);
    expect(find.text('name@gmail.com'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Set up the first administrator'), findsNothing);
  });

  testWidgets('Registration UI opens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('Gmail address can register through the signup form', (
    WidgetTester tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Campus Student');
    await tester.enterText(fields.at(1), 'signup-flow-test@gmail.com');
    await tester.enterText(fields.at(2), 'student-pass-123');
    await tester.enterText(fields.at(3), 'student-pass-123');

    final createAccount = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.text('Account created! You can now log in.'), findsOneWidget);
    final student = await AuthService.login(
      'signup-flow-test@gmail.com',
      'student-pass-123',
    );
    expect(student?.role, UserRole.student);
  });

  testWidgets('Students are denied direct access to staff review', (
    WidgetTester tester,
  ) async {
    AuthService.setCurrentUserForTesting(
      const UserRecord(
        id: 'student-uid',
        name: 'Student',
        email: 'student@cadt.edu.kh',
        passwordSalt: '',
        passwordHash: '',
        role: UserRole.student,
      ),
    );
    addTearDown(() => AuthService.setCurrentUserForTesting(null));
    expect(UserRole.student.canReview, isFalse);
    expect(UserRole.student.canManageRoles, isFalse);
    expect(UserRole.staff.canReview, isTrue);
    expect(UserRole.staff.canManageRoles, isFalse);
    expect(UserRole.admin.canReview, isTrue);
    expect(UserRole.admin.canManageRoles, isTrue);

    await tester.pumpWidget(const MaterialApp(home: StaffReviewPage()));

    expect(find.text('Access denied'), findsNWidgets(2));
    await expectLater(
      LostReportRepository.allForStaffReview(),
      throwsA(isA<AccessDeniedException>()),
    );
    await expectLater(
      LostReportRepository.review('report-id', 'Resolved'),
      throwsA(isA<AccessDeniedException>()),
    );
    await expectLater(
      LostReportClaimRepository.allForStaffReview(),
      throwsA(isA<AccessDeniedException>()),
    );
    await expectLater(
      LostReportClaimRepository.review('claim-id', 'Approved'),
      throwsA(isA<AccessDeniedException>()),
    );
    await expectLater(
      AuthService.updateRole('user-id', UserRole.admin),
      throwsA(isA<AccessDeniedException>()),
    );
    await expectLater(
      AuthService.createStaff(
        'Staff Member',
        'staff@gmail.com',
        'test-pass-123',
      ),
      throwsA(isA<AccessDeniedException>()),
    );
    await expectLater(
      AuthService.allUsers(),
      throwsA(isA<AccessDeniedException>()),
    );

    await tester.pumpWidget(const MaterialApp(home: RoleManagementPage()));
    expect(find.text('Access denied'), findsNWidgets(2));
  });

  testWidgets('Students can search listings by title and description', (
    WidgetTester tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    const student = UserRecord(
      id: 'student-uid',
      name: 'Student',
      email: 'student@cadt.edu.kh',
      passwordSalt: '',
      passwordHash: '',
      role: UserRole.student,
    );
    AuthService.setCurrentUserForTesting(student);
    LostReportSession.signIn(student.email);
    addTearDown(() {
      AuthService.setCurrentUserForTesting(null);
      LostReportSession.signOut();
    });

    await LostReportRepository.add(
      title: 'Lost Wallet',
      description: 'Black leather wallet',
      category: 'Accessories',
      dateLost: DateTime(2026, 1, 1),
      location: 'Library',
    );
    await LostReportRepository.add(
      title: 'Key Ring',
      description: 'Has an engraved serial number',
      category: 'Keys & Fobs',
      dateLost: DateTime(2026, 1, 2),
      location: 'Cafeteria',
    );

    await tester.pumpWidget(const MaterialApp(home: BrowseItemsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Lost Wallet'), findsOneWidget);
    expect(find.text('Key Ring'), findsOneWidget);

    final search = find.byKey(const Key('listing-search'));
    await tester.enterText(search, 'wallet');
    await tester.pumpAndSettle();
    expect(find.text('Lost Wallet'), findsOneWidget);
    expect(find.text('Key Ring'), findsNothing);

    await tester.enterText(search, 'engraved serial');
    await tester.pumpAndSettle();
    expect(find.text('Lost Wallet'), findsNothing);
    expect(find.text('Key Ring'), findsOneWidget);

    await tester.enterText(search, 'missing item');
    await tester.pumpAndSettle();
    expect(find.text('No results found.'), findsOneWidget);
  });
}
