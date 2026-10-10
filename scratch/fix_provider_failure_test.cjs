const fs=require('fs');const p='app/test/custom_trail_builder_test.dart';let s=fs.readFileSync(p,'utf8');s=s.replace('CustomTrailPlannerDialog 3-step wizard workflow and optimization execution','CustomTrailPlannerDialog keeps the wizard open when street directions fail');s=s.replace('// Dialog should dismiss and trail should be active in service\n    expect(trailStartedCalled, isTrue);\n    expect(trailService.hasActiveTrail, isTrue);\n    expect(trailService.activeTrail!.totalStops, 2);\n    expect(find.text(\'Custom Trail Builder\'), findsNothing);',`// An unavailable provider must never claim that a navigable trail started.
    expect(trailStartedCalled, isFalse);
    expect(trailService.hasActiveTrail, isFalse);
    expect(find.text('Custom Trail Builder'), findsOneWidget);
    expect(find.text('Could not load the trail route. Check your connection and retry.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();`);fs.writeFileSync(p,s);
const dialog='app/lib/widgets/custom_trail_planner_dialog.dart';s=fs.readFileSync(dialog,'utf8').replace('final totalStops = trail.totalStops ?? selectedList.length;','final totalStops = trail.totalStops;');fs.writeFileSync(dialog,s);
