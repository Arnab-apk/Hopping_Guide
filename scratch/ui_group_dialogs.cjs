const fs=require('fs');const p='app/lib/screens/group_screen.dart';let s=fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n');
const a=s.indexOf('  void _createGroup('),b=s.indexOf('  void _handleMenu(',a);
s="import '../widgets/group_setup_dialog.dart';\n"+s.slice(0,a)+`  Future<void> _createGroup(BuildContext context, SquadService squadService) async {
    final created = await showDialog<bool>(context: context,
      builder: (_) => GroupSetupDialog(service: squadService));
    if (created == true && context.mounted) {
      showAppSnackBar(context, SnackBar(content: Text('Group created. Invite code: ${squadService.squadCode}')));
    }
  }

  Future<void> _joinGroup(BuildContext context, SquadService squadService) async {
    final joined = await showDialog<bool>(context: context,
      builder: (_) => GroupSetupDialog(service: squadService, join: true));
    if (joined == true && context.mounted) {
      showAppSnackBar(context, const SnackBar(content: Text('You joined the group.')));
    }
  }

`+s.slice(b);fs.writeFileSync(p,s);
