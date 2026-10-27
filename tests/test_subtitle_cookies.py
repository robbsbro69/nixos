"""Offline opt-in tests: python3 -m unittest discover -s tests -v."""
import ast
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SOURCE=Path(__file__).resolve().parents[1]/'config/quickshell/assets/subs.py'

def functions():
    tree=ast.parse(SOURCE.read_text())
    definitions=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ('cookie_setting','cookie_args','base_args')]
    scope={'os':os}
    exec(compile(ast.Module(body=definitions,type_ignores=[]),str(SOURCE),'exec'),scope)
    return scope

class CookieOptIn(unittest.TestCase):
    def test_default_does_not_discover_or_read_profiles(self):
        scope=functions();scope['COOKIE_PROFILE']=''
        with patch('glob.glob',side_effect=AssertionError('must not discover profiles')), patch('builtins.open',side_effect=AssertionError('must not read cookies')):
            self.assertEqual(scope['base_args'](),['yt-dlp','--no-warnings'])

    def test_only_selected_profile_is_passed(self):
        scope=functions()
        with tempfile.TemporaryDirectory(prefix='selected profile ') as tmp:
            profile=Path(tmp)/'profile';profile.mkdir();(profile/'cookies.sqlite').touch()
            other=Path(tmp)/'other';other.mkdir();(other/'cookies.sqlite').touch()
            scope['COOKIE_PROFILE']=str(profile)
            self.assertEqual(scope['cookie_args'](),['--cookies-from-browser','firefox:'+str(profile)])

    def test_empty_missing_and_explicit_settings(self):
        scope=functions()
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ,HOME=tmp):
            self.assertEqual(scope['cookie_setting'](),'')
            setting=Path(tmp)/'.config/quickshell/subs-cookie-profile';setting.parent.mkdir(parents=True)
            setting.write_text(' \n');self.assertEqual(scope['cookie_setting'](),'')
            setting.write_text('/chosen/profile\n');self.assertEqual(scope['cookie_setting'](),'/chosen/profile')

    def test_invalid_profile_does_not_fall_back_to_discovery(self):
        scope=functions()
        for profile in ('relative/profile','/nonexistent/profile'):
            scope['COOKIE_PROFILE']=profile
            with self.assertRaises(ValueError):scope['cookie_args']()

if __name__=='__main__':unittest.main()
