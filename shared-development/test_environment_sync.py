import unittest,tempfile,pathlib,subprocess,sys,json
SCRIPT=pathlib.Path(__file__).with_name('environment_sync.py')
class SyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.root=pathlib.Path(self.tmp.name)
        self.source=self.root/'source';self.home=self.root/'home'
        (self.source/'agents-skills/example').mkdir(parents=True)
        (self.source/'agents-skills/example/SKILL.md').write_text('version one')
        (self.source/'AGENTS.md').write_text('common instructions')
    def tearDown(self):self.tmp.cleanup()
    def run_sync(self,*flags):
        return subprocess.run([sys.executable,str(SCRIPT),'--source',str(self.source),'--home',str(self.home),*flags],capture_output=True,text=True)
    def test_installs_and_repeated_execution_is_noop(self):
        r=self.run_sync();self.assertEqual(r.returncode,0,r.stderr)
        dest=self.home/'.agents/skills/example/SKILL.md'
        self.assertEqual(dest.read_text(),'version one')
        stamp=dest.stat().st_mtime_ns
        r=self.run_sync();self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(dest.stat().st_mtime_ns,stamp)
    def test_conflict_refuses_whole_update_and_adopt_preserves_backup(self):
        self.assertEqual(self.run_sync().returncode,0)
        dest=self.home/'.agents/skills/example/SKILL.md';dest.write_text('user edit')
        (self.source/'agents-skills/example/SKILL.md').write_text('version two')
        (self.source/'AGENTS.md').write_text('new instructions')
        r=self.run_sync();self.assertEqual(r.returncode,2,r.stderr)
        self.assertEqual(dest.read_text(),'user edit')
        self.assertEqual((self.home/'.codex/AGENTS.md').read_text(),'common instructions')
        r=self.run_sync('--adopt');self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(dest.read_text(),'version two')
        backups=list((self.home/'.local/state/environment-sync/backups').rglob('SKILL.md'))
        self.assertTrue(any(p.read_text()=='user edit' for p in backups))
    def test_replaces_skill_symlink_without_modifying_target(self):
        external=self.root/'external';external.mkdir();(external/'SKILL.md').write_text('original')
        target=self.home/'.agents/skills/example';target.parent.mkdir(parents=True);target.symlink_to(external,target_is_directory=True)
        r=self.run_sync('--adopt');self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual((external/'SKILL.md').read_text(),'original')
        self.assertFalse(target.is_symlink())
        self.assertEqual((target/'SKILL.md').read_text(),'version one')
    def test_detects_lost_execution_permission(self):
        script=self.source/'agents-skills/example/run';script.write_text('#!/bin/sh\nexit 0\n');script.chmod(0o755)
        self.assertEqual(self.run_sync().returncode,0)
        installed=self.home/'.agents/skills/example/run';installed.chmod(0o644)
        self.assertEqual(self.run_sync('--check').returncode,2)
        self.assertEqual(self.run_sync('--adopt').returncode,0)
        self.assertTrue(installed.stat().st_mode & 0o111)
    def test_detects_internal_symlink_with_identical_contents(self):
        self.assertEqual(self.run_sync().returncode,0)
        external=self.root/'external-file';external.write_text('version one')
        installed=self.home/'.agents/skills/example/SKILL.md';installed.unlink();installed.symlink_to(external)
        self.assertEqual(self.run_sync('--check').returncode,2)
        self.assertEqual(external.read_text(),'version one')
    def test_missing_source_entry_is_reported_without_forgetting_state(self):
        self.assertEqual(self.run_sync().returncode,0)
        manifest=self.home/'.local/state/environment-sync/installed.json';before=manifest.read_bytes()
        (self.source/'AGENTS.md').unlink()
        for flags in [('--check',),(),('--adopt',)]:
            r=self.run_sync(*flags);self.assertEqual(r.returncode,2,r.stdout)
            self.assertEqual(manifest.read_bytes(),before)
            self.assertEqual((self.home/'.codex/AGENTS.md').read_text(),'common instructions')
    def test_partial_filesystem_failure_rolls_back_and_preserves_manifest(self):
        (self.source/'AGENTS.md').unlink()
        self.assertEqual(self.run_sync().returncode,0)
        manifest=self.home/'.local/state/environment-sync/installed.json';before=manifest.read_bytes()
        (self.source/'agents-skills/example/SKILL.md').write_text('version two')
        (self.source/'AGENTS.md').write_text('new instructions')
        (self.home/'.codex').write_text('existing file blocks destination directory')
        r=self.run_sync();self.assertEqual(r.returncode,1,r.stdout)
        self.assertEqual((self.home/'.agents/skills/example/SKILL.md').read_text(),'version one')
        self.assertEqual(manifest.read_bytes(),before)
        self.assertEqual((self.home/'.codex').read_text(),'existing file blocks destination directory')
        (self.home/'.codex').unlink()
        self.assertEqual(self.run_sync().returncode,0)
        self.assertEqual((self.home/'.agents/skills/example/SKILL.md').read_text(),'version two')
if __name__=='__main__':unittest.main()
