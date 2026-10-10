const fs=require('fs');const p='app/test/squad_collaborative_hopping_test.dart';let s=fs.readFileSync(p,'utf8');s=s.replace('// 6. Verify Live Hopping Banner activates',`expect(find.text('Your trail is ready'), findsOneWidget);
        await tester.tap(find.text('Later'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 6. Verify Live Hopping Banner activates`);fs.writeFileSync(p,s);
