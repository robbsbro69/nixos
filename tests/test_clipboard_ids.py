"""Offline QML behavior tests. Run: python3 -m unittest discover -s tests -v (requires Node.js)."""
import json
from pathlib import Path
import subprocess
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / 'config/quickshell/components/ClipboardPanel.qml').read_text()

def block(marker):
    start = SOURCE.index('{', SOURCE.index(marker)); end = start + 1; depth = 1
    while depth:
        depth += (SOURCE[end] == '{') - (SOURCE[end] == '}'); end += 1
    return SOURCE[start + 1:end - 1]

def node(script):
    return json.loads(subprocess.check_output(['node', '-e', script], text=True))

class ClipboardIds(unittest.TestCase):
    def parse(self, raw):
        return node('const clipDumpFile={text:()=>'+json.dumps(raw)+'}; const clipPanel={}; const thumbDecoder={};(()=>{'+block('id: parseTimer')+'})(); console.log(JSON.stringify({entries:clipPanel.clipAllEntries,thumbDecoder}))')

    def test_ids_and_thumbnails_survive_history_reordering(self):
        a=self.parse('11\tother\n10\tselected\n9\t[[ binary image ]]\n')
        b=self.parse('12\tnew\n11\tother\n10\tselected\n9\t[[ binary image ]]\n')
        self.assertEqual(a['entries'][1],b['entries'][2])
        self.assertEqual(a['entries'][2]['thumbPath'],b['entries'][3]['thumbPath'])
        self.assertIn('cliphist decode 9',a['thumbDecoder']['command'][2])
        self.assertNotIn('cliphist list',a['thumbDecoder']['command'][2])

    def test_selection_uses_original_id(self):
        argv=node('const entry={id:"10"};const pasteProcess={};const root={};(()=>{'+block('function pasteClipEntry(')+'})();console.log(JSON.stringify(pasteProcess.command))')
        stub='cliphist() { if [ "$1" = list ]; then printf "12\\tnew\\n11\\tother\\n10\\tselected\\n"; else [ "$2" = 10 ] && printf "selected\\n\\n"; fi; }; wl-copy() { cat; }; '
        result=subprocess.run([*argv[:4],stub+argv[4],*argv[5:]],capture_output=True,check=True)
        self.assertEqual(result.stdout,b'selected\n\n')

    def test_invalid_ids_are_rejected(self):
        self.assertEqual(self.parse('bad\ttext\nno tab\n')['entries'],[])
        result=node('const entry={id:"10; echo wrong"};const pasteProcess={};const root={};(()=>{'+block('function pasteClipEntry(')+'})();console.log(JSON.stringify(pasteProcess))')
        self.assertEqual(result,{})

if __name__=='__main__': unittest.main()
