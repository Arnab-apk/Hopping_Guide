import pathlib, subprocess, sys, re, json

adb = r'D:\src\android-sdk\platform-tools\adb.exe'
def run(*args):
    return subprocess.check_output([adb, *args], text=True, encoding='utf-8', errors='replace')

display = run('shell', 'dumpsys', 'SurfaceFlinger')
if 'powerMode=Off' in display:
    raise SystemExit('Physical display is off; refusing an invalid visible-frame benchmark.')
run('shell', 'dumpsys', 'SurfaceFlinger', '--timestats', '-clear', '-enable')
try:
    run('shell', '; '.join(['input swipe 800 1500 350 900 1200',
                           'input swipe 350 900 800 1500 1200'] * 4))
    raw = run('shell', 'dumpsys', 'SurfaceFlinger', '--timestats', '-dump')
finally:
    run('shell', 'dumpsys', 'SurfaceFlinger', '--timestats', '-disable')
path = pathlib.Path(__file__).parent / (sys.argv[1] + '.txt')
if path.exists():
    from datetime import datetime
    path = path.with_stem(path.stem + '-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
path.write_text(raw, encoding='utf-8')
for block in re.split(r'(?=layerName =)', raw):
    if 'kolkatapuja' not in block and 'SurfaceView[]' not in block:
        continue
    summary = block.split('present2present histogram')[0]
    hist = re.search(r'present2present histogram is as below:\s*([^\n]+)', block)
    bins = [(int(ms), int(n)) for ms,n in re.findall(r'(\d+)ms=(\d+)', hist[1])] if hist else []
    print(summary)
    print(json.dumps({'intervals': sum(n for _, n in bins),
                      'intervals_22ms_or_more': sum(n for ms,n in bins if ms >= 22),
                      'intervals_50ms_or_more': sum(n for ms,n in bins if ms >= 50)}))
