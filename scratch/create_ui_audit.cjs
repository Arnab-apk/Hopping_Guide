const fs=require('fs');
let s=fs.readFileSync('app/test/launch_layout_test.dart','utf8').replace(/\r\n/g,'\n');
s=s.replace("void main() {",`import 'package:kolkata_puja/screens/squad_settings_screen.dart';
import 'package:kolkata_puja/screens/squad_chat_screen.dart';
import 'package:kolkata_puja/screens/route_chat_screen.dart';
import 'package:kolkata_puja/screens/group_video_call_screen.dart';
import 'package:kolkata_puja/screens/pandal_detail_screen.dart';
import 'package:kolkata_puja/widgets/user_profile_sheet.dart';
import 'package:kolkata_puja/widgets/app_tutorial_dialog.dart';
import 'package:kolkata_puja/widgets/custom_trail_planner_dialog.dart';
import 'package:kolkata_puja/repositories/local_pandal_repository.dart';
import 'route_chat_screen_test.dart' show FakeChatService;

void main() {`);
const a=s.indexOf('  final screens ='),b=s.indexOf('  for (final dark',a);
s=s.slice(0,a)+`  final screens = <String, Widget Function()>{
    'settings': () => const SquadSettingsScreen(),
    'squad_chat': () => const SquadChatScreen(squadId: 'ui-audit', squadName: 'Friends exploring Kolkata together'),
    'assistant': () => RouteChatScreen(chatService: FakeChatService()),
    'video_lobby': () => const GroupVideoCallScreen(squadId: 'ui-audit', squadName: 'Friends exploring Kolkata together'),
    'profile': () => const Scaffold(body: UserProfileSheet()),
    'tutorial': () => const Scaffold(body: AppTutorialDialog()),
    'planner': () => const Scaffold(body: CustomTrailPlannerDialog(pandals: [])),
    'detail': () => FutureBuilder(future: LocalAssetPandalRepository().all(), builder: (context, snapshot) =>
      snapshot.hasData ? PandalDetailScreen(pandal: snapshot.data!.first) : const SizedBox()),
  };
  final displays = <String, ({Size size, double scale})>{
    'phone': (size: const Size(390, 844), scale: 1),
    'compact_large': (size: const Size(320, 640), scale: 2),
    'landscape_large': (size: const Size(844, 390), scale: 1.5),
  };
`+s.slice(b);
const x=s.indexOf("          if (screen.key == 'map'"),y=s.indexOf("          if (const bool.fromEnvironment",x);s=s.slice(0,x)+s.slice(y);
s=s.replace("build/launch-audit/visuals", "build/ui-audit/visuals");
for(const p of ['screens/group_screen.dart','screens/helplines_screen.dart','screens/map_screen.dart','screens/pandal_list_screen.dart','screens/routes_screen.dart','screens/welcome_screen.dart'])s=s.replace(`import 'package:kolkata_puja/${p}';\n`,'');
s=s.replace("import 'package:flutter_map/flutter_map.dart';\n",'');
fs.writeFileSync('app/test/ui_deep_audit_test.dart',s);
