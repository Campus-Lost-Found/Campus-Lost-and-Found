// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lost_and_found_app/auth_service.dart';
import 'package:lost_and_found_app/lost_report.dart';
import 'package:lost_and_found_app/UserAccess.dart';

void main() {
  testWidgets('Login UI renders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Campus Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
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
  });

  testWidgets('Students are denied direct access to staff review', (
    WidgetTester tester,
  ) async {
    AuthService.setCurrentUserForTesting(
      const UserRecord(
        id: 'student-uid',
        name: 'Student',
        email: 'student@cadt.edu.kh',
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
      AuthService.allUsers(),
      throwsA(isA<AccessDeniedException>()),
    );

    await tester.pumpWidget(const MaterialApp(home: RoleManagementPage()));
    expect(find.text('Access denied'), findsNWidgets(2));
  });
}
