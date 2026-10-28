import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:takeone/app.dart';
import 'package:takeone/data/app_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates a project, records a take, and shows its history', (
    tester,
  ) async {
    Future<void> waitForElapsedTime(Duration duration) async {
      final steps = duration.inMilliseconds ~/ 100;
      for (var step = 0; step < steps; step++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
    }

    Future<void> removeTestProject() async {
      final projects = await LocalStore.instance.getProjects();
      for (final project in projects.where(
        (project) => project.name == 'Integration Test Production',
      )) {
        await LocalStore.instance.deleteProject(project.id);
      }
    }

    await removeTestProject();
    addTearDown(removeTestProject);
    await tester.pumpWidget(const TakeOneApp());
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('New project'), findsOneWidget);
    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Project name *'),
      'Integration Test Production',
    );
    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();

    expect(find.text('Integration Test Production'), findsOneWidget);
    await tester.tap(find.text('Integration Test Production'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<bool>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alphabet'));
    await tester.pumpAndSettle();
    var project = (await LocalStore.instance.getProjects()).singleWhere(
      (item) => item.name == 'Integration Test Production',
    );
    expect(project.shot, 'A');

    await tester.tap(find.text('Slate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open full-screen slate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(find.text('Change Scene'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('CLAP'), findsOneWidget);
    await tester.tap(find.text('CLAP'));
    await waitForElapsedTime(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bad take'));
    await tester.pumpAndSettle();

    expect(find.text('Bad take'), findsNothing);
    project = (await LocalStore.instance.getProjects()).singleWhere(
      (item) => item.name == 'Integration Test Production',
    );
    var takes = await LocalStore.instance.getTakes(project.id);
    expect(takes, hasLength(1));
    expect(takes.single.rating, TakeRating.bad);
    expect(project.take, 2);

    await tester.tap(find.text('CLAP'));
    await waitForElapsedTime(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moving on'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next shot'));
    await tester.pumpAndSettle();
    project = (await LocalStore.instance.getProjects()).singleWhere(
      (item) => item.name == 'Integration Test Production',
    );
    expect(project.shot, 'B');

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Takes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SC 1  /  SH A  /  TK 01'), findsOneWidget);
    takes = await LocalStore.instance.getTakes(project.id);
    expect(takes, hasLength(2));
    expect(find.text('BAD'), findsOneWidget);
    expect(find.text('MOVED ON'), findsOneWidget);
  });
}
