const fs=require('fs');
function endCall(s,start){let depth=0,q=null;for(let i=s.indexOf('(',start);i<s.length;i++){const c=s[i];if(q){if(c==='\\'){i++;continue;}if(c===q)q=null;continue;}if(c==='"'||c==="'"){q=c;continue;}if(c==='(')depth++;if(c===')'&&--depth===0)return i+1;}throw Error('unclosed');}
function edit(p,fn){fs.writeFileSync(p,fn(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
function flexText(s,needle){const at=s.indexOf(needle);if(at<0)throw needle;const a=s.lastIndexOf('Text(',at),b=endCall(s,a);return s.slice(0,a)+'Flexible(child: '+s.slice(a,b)+')'+s.slice(b);}
function wrapRow(s,needle){const at=s.indexOf(needle);if(at<0)throw needle;const a=s.lastIndexOf('Row(',at),b=endCall(s,a);let body=s.slice(a,b).replace(/^Row\(/,'Wrap(\n spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,').replace(/mainAxisSize: MainAxisSize\.\w+,/g,'').replace(/mainAxisAlignment: MainAxisAlignment\.\w+,/g,'').replace('const Spacer(),','');return s.slice(0,a)+body+s.slice(b);}
edit('app/lib/screens/squad_chat_screen.dart',s=>{
s=wrapRow(s,"'Puja Bot");
s=flexText(s,"'$timeStr");
s=s.replace('height: 38,', 'height: 48 + (MediaQuery.textScalerOf(context).scale(12) - 12),');
s=s.replace('icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),', 'icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20),');
s=s.replace('onPressed: () => _sendMessage(),','onPressed: _isSending ? null : () => _sendMessage(),');
s=s.replace('widget.squadName,\n              style:', 'widget.squadName,\n              maxLines: 1, overflow: TextOverflow.ellipsis,\n              style:');
s=s.replace('icon: const Icon(Icons.close, color: Colors.white),','icon: const Icon(Icons.close, color: Colors.white),\n                tooltip: \'Close photo\',');
return s;});
edit('app/lib/screens/route_chat_screen.dart',s=>wrapRow(s,'OutlinedButton.icon(\n                      onPressed: () => CustomTrailPlannerDialog.show'));
edit('app/lib/widgets/app_tutorial_dialog.dart',s=>wrapRow(s,"'Tutorial"));
edit('app/lib/widgets/custom_trail_planner_dialog.dart',s=>wrapRow(s,"'Custom Trail Builder'").replace('icon: const Icon(Icons.close_rounded),','icon: const Icon(Icons.close_rounded),\n            tooltip: \'Close trail builder\','));
edit('app/lib/widgets/user_profile_sheet.dart',s=>{
 s=flexText(s,'userName,'); s=flexText(s,"'Add Phone (Squad Calling)'"); s=flexText(s,"'Pujo Parikrama Stats'");
 const a=s.indexOf('                  GestureDetector(',s.indexOf('// Display Name')),b=endCall(s,a);
 s=s.slice(0,a)+`                  IconButton(
                    tooltip: 'Edit display name',
                    onPressed: authUser == null ? null : () => _editDisplayName(context, authUser),
                    icon: const Icon(Icons.edit_rounded, size: 20, color: PujaColors.festivalGold),
                  )`+s.slice(b);
 return s;
});
edit('app/lib/widgets/pandal_detail_sheet.dart',s=>{
 s=wrapRow(s,'// Zone Tag'); s=wrapRow(s,'if (pandal.area != null && pandal.area!.isNotEmpty)');
 s=flexText(s,"'Visited & Hopped! (Tap to unmark)'");
 s=flexText(s,"'Get Turn-by-Turn Directions'");
 s=wrapRow(s,"_buildGenderPill('Female'");
 s=s.replace('width: double.infinity,\n                      height: 46,','width: double.infinity,\n                      constraints: const BoxConstraints(minHeight: 52),\n                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),');
 s=s.replace('width: 34,\n            height: 34,','width: 48,\n            height: 48,');
 return s;
});
// Allow notices to wrap and remain readable; expose them to assistive technology.
edit('app/lib/screens/map_screen.dart',s=>{
const a=s.indexOf('  void _showStatusPill('),b=s.indexOf('  @override',a);let part=s.slice(a,b);
part=part.replace('2400','5000').replace('maxLines: 1,','maxLines: 4,').replace('fontSize: 12.5,','fontSize: 14,');
part=part.replace('child: Text(\n                            message,','child: Semantics(liveRegion: true, child: Text(\n                            message,');
part=part.replace('                            ),\n                          ),\n                        ),\n                      ],','                            ),\n                          )),\n                        ),\n                      ],');
part=part.replace('_statusOverlayTimer = Timer(duration,', '_statusOverlayTimer = Timer(MediaQuery.accessibleNavigationOf(context) ? const Duration(seconds: 10) : duration,');
return s.slice(0,a)+part+s.slice(b);
});
