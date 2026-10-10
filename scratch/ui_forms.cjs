const fs=require('fs');
function edit(p,fn){fs.writeFileSync(p,fn(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('app/lib/widgets/search_enhanced.dart',s=>s.replace("import '../widgets/app_notice.dart';\n",'').replace('library;','library;\n\nimport \'app_notice.dart\';'));
edit('app/lib/screens/squad_settings_screen.dart',s=>{
const a=s.indexOf('  void _editSquadName'),b=s.indexOf('  void _configureAlertDistance',a);
return "import '../widgets/app_text_edit_dialog.dart';\n"+s.slice(0,a)+`  void _editSquadName(BuildContext context, SquadService squadService) {
    showDialog(context: context, builder: (_) => AppTextEditDialog(
      title: 'Edit Group Name', label: 'Group name', initialValue: squadService.squadName ?? 'My Group',
      hint: 'e.g. Bagbazar Pandal Crawlers', onSave: squadService.updateSquadName));
  }

  void _editMeetupPoint(BuildContext context, SquadService squadService) {
    showDialog(context: context, builder: (_) => AppTextEditDialog(
      title: 'Designated Meet-up Point', label: 'Landmark or gate', initialValue: squadService.meetupPointName,
      hint: 'e.g. Under Gariahat Flyover clock', onSave: (name) => squadService.setMeetupPoint(name)));
  }

`+s.slice(b);});
edit('app/lib/widgets/user_profile_sheet.dart',s=>{
const a=s.indexOf('  void _editDisplayName'),b=s.indexOf('  void _chooseGoogleAvatar',a);
return "import 'app_text_edit_dialog.dart';\n"+s.slice(0,a)+`  void _editDisplayName(BuildContext context, AppUser user) {
    showDialog(context: context, builder: (_) => AppTextEditDialog(
      title: 'Edit Display Name', label: 'Your name', initialValue: user.displayName ?? '',
      onSave: (name) => AuthService.instance.updateProfile(displayName: name)));
  }

  void _editPhoneNumber(BuildContext context, AppUser user) {
    showDialog(context: context, builder: (_) => AppTextEditDialog(
      title: 'Group Phone Number', label: 'Phone number', initialValue: user.phoneNumber ?? '',
      hint: '+91 98765 43210', keyboardType: TextInputType.phone, allowEmpty: true, maxLength: 24,
      description: 'Visible to your group companions for calling during Pujo hopping.',
      validator: (value) {
        if (value.isEmpty) return null;
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.length >= 7 && digits.length <= 15 && RegExp(r'^[+0-9 ()-]+$').hasMatch(value)
            ? null : 'Enter a valid phone number with country code.';
      },
      onSave: (phone) => AuthService.instance.updateProfile(phoneNumber: phone)));
  }

`+s.slice(b);});
edit('app/lib/main.dart',s=>"import 'widgets/app_notice.dart';\n"+s.replace('ScaffoldMessenger.of(ctx).showSnackBar(', 'showAppSnackBar(ctx, '));
