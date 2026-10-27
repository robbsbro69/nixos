"""Offline concurrent helper tests: python3 -m unittest discover -s tests -v."""
import ast
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

SCRIPT=Path(__file__).resolve().parents[1]/'config/quickshell/assets/subs.py'
FAKE=r'''
import json,os,pathlib,sys,time
args=sys.argv[1:]
if '--help' in args: print('stub');sys.exit()
if any(x.startswith('ytsearch') for x in args):
    title=args[-1].split(':',1)[1];print(title+'\t60\t'+title);sys.exit()
if '-J' in args:
    tracks={} if os.environ['TEST_MODE']=='fallback' else {'en':[{'ext':'json3'}]}
    print(json.dumps({'subtitles':tracks}));sys.exit()
if '-o' in args:
    vid=args[-1].split('v=')[-1];target=pathlib.Path(args[args.index('-o')+1].replace('%(ext)s','en.json3'))
    root=pathlib.Path(os.environ['TEST_ROOT']);(root/(vid+'.ready')).touch()
    deadline=time.monotonic()+5
    while len(list(root.glob('*.ready')))<2:
        if time.monotonic()>deadline:sys.exit(2)
        time.sleep(.01)
    target.write_text(json.dumps({'events':[{'tStartMs':0,'segs':[{'utf8':vid}]}]}))
    (root/(vid+'.dir')).write_text(str(target.parent))
'''

class SubtitleDownloads(unittest.TestCase):
    def test_overlapping_workers_keep_their_own_files_in_both_branches(self):
        for mode in ('fallback','tracks'):
            with self.subTest(mode=mode),tempfile.TemporaryDirectory() as tmp:
                root=Path(tmp);bin=root/'bin';bin.mkdir();stub=bin/'yt-dlp'
                stub.write_text('#!'+sys.executable+'\n'+FAKE);stub.chmod(0o700)
                env=dict(os.environ,HOME=tmp,PATH=str(bin)+':'+os.environ['PATH'],TEST_MODE=mode,TEST_ROOT=tmp)
                jobs=[subprocess.Popen([sys.executable,str(SCRIPT),v,v,'channel','60','https://youtube.com/watch?v='+v],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE) for v in ('aaaaaaaaaaa','bbbbbbbbbbb')]
                try:
                    for job,vid in zip(jobs,('aaaaaaaaaaa','bbbbbbbbbbb')):
                        output,error=job.communicate(timeout=10)
                        self.assertEqual(job.returncode,0,error)
                        result=json.loads(output);self.assertTrue(result['ok'],result)
                        self.assertEqual(result['lines'],[[0,vid]])
                    dirs=[Path((root/(v+'.dir')).read_text()) for v in ('aaaaaaaaaaa','bbbbbbbbbbb')]
                    self.assertNotEqual(*dirs)
                    self.assertTrue(all(not p.exists() for p in dirs))
                    for cache in (root/'.cache/quickshell/subs').glob('*.json'):json.loads(cache.read_text())
                finally:
                    for job in jobs:
                        if job.poll() is None:job.kill();job.communicate()

    def test_cache_replacement_is_atomic_and_failure_keeps_original(self):
        tree=ast.parse(SCRIPT.read_text());save=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='save')
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)/'cache.json';dest.write_text('{"old":true}')
            scope={'os':os,'json':json,'tempfile':tempfile,'time':time,'CACHE':tmp,'cf':str(dest),'out':lambda r:None}
            exec(compile(ast.Module(body=[save],type_ignores=[]),str(SCRIPT),'exec'),scope)
            with patch('os.replace',side_effect=OSError('simulated failure')):
                with self.assertRaises(OSError):scope['save']({'ok':True})
            self.assertEqual(json.loads(dest.read_text()),{'old':True})
            self.assertEqual(list(Path(tmp).glob('*.tmp')),[])
            scope['save']({'ok':True});self.assertTrue(json.loads(dest.read_text())['ok'])

if __name__=='__main__':unittest.main()
