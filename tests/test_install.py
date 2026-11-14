import json
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='agent-rules-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / 'repo'
        shutil.copytree(SOURCE, self.repo, ignore=shutil.ignore_patterns('.git', '__pycache__'))
        self.home = self.root / 'home'
        self.project = self.home / 'project'
        self.project.mkdir(parents=True)
        for tool in ('.claude', '.codex', '.gemini'):
            (self.home / tool).mkdir(parents=True)
        self.env = dict(os.environ, HOME=str(self.home), AGENT_RULES_ALL='1')
        self.env.pop('CODEX_HOME', None)

    def run_make(self, target, ok=True):
        result = subprocess.run(['make', target, f'DIR={self.project}'], cwd=self.repo,
                                env=self.env, capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    @property
    def artifact(self):
        return self.repo / 'generated' / 'AGENTS.md'

    def test_build_keeps_artifact_current(self):
        checked = self.artifact.read_bytes()
        self.run_make('build')
        self.assertEqual(checked, self.artifact.read_bytes())
        rules = self.artifact.read_text()
        self.assertLessEqual(len(rules.splitlines()), 200)
        self.assertNotIn('## Threads', rules)
        self.assertNotIn('## How to answer me', rules)
        self.assertIn('Verify, then assert.', rules)
        self.assertIn('## Git and worktrees', rules)
        self.assertIn('## Code and architecture', rules)
        self.assertIn('do not apply to chat replies', rules)
        (self.repo / 'rules/99-new.md').write_text('NEW RULE\n')
        self.run_make('build')
        self.assertIn('NEW RULE', self.artifact.read_text())

    def test_install_preserves_personal_and_reconciles_rules(self):
        agents = self.home / '.codex/AGENTS.md'
        original = ('Personal above.\n\n<!-- >>> agent-rules >>> -->\nold pointer\n'
                    '<!-- <<< agent-rules <<< -->\n\nPersonal below.\n')
        agents.write_text(original)
        config = self.home / '.codex/config.toml'
        config.write_text('model = "personal-model"\n')
        personal_link = self.home / '.claude/rules/personal.md'
        personal_link.parent.mkdir()
        outside = self.root / 'personal.md'
        outside.write_text('My own rule\n')
        personal_link.symlink_to(outside)
        collision = personal_link.parent / '18-verification.md'
        collision.symlink_to(outside)
        removed = personal_link.parent / '25-threads.md'
        removed.symlink_to(self.repo / 'rules/25-threads.md')
        for _ in range(2):
            self.run_make('install')
            self.assertTrue(agents.is_symlink())
            self.assertEqual(agents.resolve(), self.artifact)
            self.assertIn(str(self.artifact), config.read_text())
            self.assertIn('model = "personal-model"', config.read_text())
            self.assertEqual(personal_link.resolve(), outside)
            self.assertEqual(collision.resolve(), outside)
            self.assertFalse(removed.is_symlink())
            self.assertTrue((personal_link.parent / '40-git.md').exists())
            gemini = (self.home / '.gemini/GEMINI.md').read_text()
            self.assertIn('@' + str(self.artifact), gemini)
            personal = self.home / '.codex/agent-rules-personal.md'
            self.assertIn('Personal above.', personal.read_text())
            self.assertIn('Personal below.', personal.read_text())
            hook = subprocess.run([str(self.repo / 'hooks/codex-session-start.sh'),
                                   str(self.artifact)], env=self.env,
                                  capture_output=True, text=True, check=True)
            context = json.loads(hook.stdout)['hookSpecificOutput']['additionalContext']
            self.assertEqual(context.count('Personal above.'), 1)
            self.assertTrue(context.startswith(self.artifact.read_text()))
            self.assertIn('Personal below.', context)
            before = (config.read_bytes(), personal.read_bytes())
            self.run_make('install')
            self.assertEqual(before, (config.read_bytes(), personal.read_bytes()))
        self.assertTrue(any(p.read_text() == original for p in agents.parent.glob('AGENTS.md.bak-*')))
        self.run_make('uninstall')
        self.assertFalse(agents.is_symlink())
        self.assertIn('Personal above.', agents.read_text())
        self.assertIn('Personal below.', agents.read_text())
        self.assertEqual(personal_link.resolve(), outside)
        self.assertNotIn('# >>> agent-rules >>>', config.read_text())

    def test_project_install_and_status(self):
        self.run_make('install')
        self.run_make('project')
        agents = self.project / 'AGENTS.md'
        self.assertEqual(agents.resolve(), self.artifact)
        for directory in ('.claude/rules', '.agents/rules'):
            self.assertFalse((self.project / directory / '25-threads.md').exists())
            self.assertTrue((self.project / directory / '40-git.md').exists())
            writing = (self.project / directory / '10-writing.md').read_text()
            self.assertIn('do not apply to chat replies', writing)
        status = self.run_make('status').stdout
        self.assertIn(f'{self.artifact}: current', status)
        project_rules = next(line for line in status.splitlines() if '~/project/.claude/rules/' in line)
        self.assertIn('linked (5)', project_rules)

    def test_personal_collisions_are_untouched(self):
        agents = self.project / 'AGENTS.md'
        agents.symlink_to(self.repo / 'README.md')
        rule = self.project / '.claude/rules/40-git.md'
        rule.parent.mkdir(parents=True)
        rule.write_text('personal git rule\n')
        personal_repo_link = rule.parent / '60-code.md'
        personal_repo_link.symlink_to(self.repo / 'README.md')
        self.run_make('project')
        self.assertEqual(personal_repo_link.resolve(), self.repo / 'README.md')
        self.assertEqual(agents.resolve(), self.repo / 'README.md')
        self.assertEqual(rule.read_text(), 'personal git rule\n')
        self.run_make('uninstall')
        self.assertEqual(agents.resolve(), self.repo / 'README.md')
        self.assertEqual(rule.read_text(), 'personal git rule\n')

    def test_migration_preserves_missing_final_newline(self):
        agents = self.home / '.codex/AGENTS.md'
        original = ('Before.\n<!-- >>> agent-rules >>> -->\nold\n'
                    '<!-- <<< agent-rules <<< -->\nAfter without newline')
        agents.write_text(original)
        self.run_make('install')
        personal = self.home / '.codex/agent-rules-personal.md'
        self.assertEqual(personal.read_bytes(), b'Before.\nAfter without newline')
        self.run_make('uninstall')
        self.assertEqual(agents.read_bytes(), personal.read_bytes())
        self.run_make('install')
        self.assertEqual(agents.resolve(), self.artifact)

    def test_conflicting_personal_migration_refuses_without_changes(self):
        agents = self.home / '.codex/AGENTS.md'
        agents.write_text('Keep original\n')
        personal = self.home / '.codex/agent-rules-personal.md'
        personal.write_text('Keep existing personal file\n')
        result = self.run_make('install', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('personal migration conflicts', result.stderr)
        self.assertEqual(agents.read_text(), 'Keep original\n')
        self.assertEqual(personal.read_text(), 'Keep existing personal file\n')
        self.assertFalse((self.home / '.codex/config.toml').exists())

    def test_malformed_managed_block_refuses_without_changes(self):
        agents = self.home / '.codex/AGENTS.md'
        original = 'Keep original\n<!-- >>> agent-rules >>> -->\nmissing end\n'
        agents.write_text(original)
        result = self.run_make('install', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('malformed managed block', result.stderr)
        self.assertEqual(agents.read_text(), original)

    def test_hook_command_handles_repository_path_with_spaces(self):
        moved = self.root / 'repo with spaces'
        self.repo.rename(moved)
        self.repo = moved
        self.run_make('install')
        config = (self.home / '.codex/config.toml').read_text()
        command_line = next(line for line in config.splitlines() if line.startswith('command = '))
        # The TOML string uses JSON-compatible escaping.
        command = json.loads(command_line.partition(' = ')[2])
        result = subprocess.run(command, shell=True, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        context = json.loads(result.stdout)['hookSpecificOutput']['additionalContext']
        self.assertIn('## Verification', context)
        self.assertNotIn('## Threads', context)

    def test_hook_block_keeps_the_tables_codex_writes_into_it(self):
        # Codex records the trust of each hook in [hooks.state] tables, and it
        # writes them inside the managed block, after the hook tables.
        config = self.home / '.codex/config.toml'
        self.run_make('install')
        trust = ('\n[hooks.state]\n\n'
                 '[hooks.state."dialogue@mihaibojin:hooks/codex.json:session_start:0:0"]\n'
                 'trusted_hash = "sha256:00"\nenabled = true\n')
        end = '# <<< agent-rules <<<\n'
        config.write_text(config.read_text().replace(end, trust + end)
                          + '\n[sandbox_workspace_write]\nwritable_roots = ["/tmp"]\n')

        self.run_make('install')
        installed = config.read_text()
        self.assertEqual(installed.count('trusted_hash = "sha256:00"'), 1)
        self.assertEqual(installed.count('[[hooks.SessionStart]]'), 1)
        self.assertIn(str(self.artifact), installed)
        self.assertIn('writable_roots = ["/tmp"]', installed)

        backups = set(config.parent.glob('config.toml.bak-*'))
        self.run_make('install')
        self.assertEqual(config.read_text(), installed)
        self.assertEqual(set(config.parent.glob('config.toml.bak-*')), backups)

        self.run_make('uninstall')
        removed = config.read_text()
        self.assertEqual(removed.count('trusted_hash = "sha256:00"'), 1)
        self.assertNotIn('[[hooks.SessionStart]]', removed)
        self.assertIn('writable_roots = ["/tmp"]', removed)

    def test_migration_keeps_newline_before_unterminated_end_marker(self):
        agents = self.home / '.codex/AGENTS.md'
        agents.write_text('Before.\n<!-- >>> agent-rules >>> -->\nold\n<!-- <<< agent-rules <<< -->')
        self.run_make('install')
        self.assertEqual((self.home / '.codex/agent-rules-personal.md').read_bytes(), b'Before.\n')

    def test_global_personal_symlink_into_repo_is_untouched(self):
        agents = self.home / '.codex/AGENTS.md'
        agents.symlink_to(self.repo / 'README.md')
        result = self.run_make('install', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(agents.resolve(), self.repo / 'README.md')

    def test_failed_codex_link_preserves_original_personal_file(self):
        agents = self.home / '.codex/AGENTS.md'
        original = ('Before.\n<!-- >>> agent-rules >>> -->\nold pointer\n'
                    '<!-- <<< agent-rules <<< -->\nAfter.\n')
        agents.write_text(original)
        tools = self.root / 'bin'
        tools.mkdir()
        self.env['PATH'] = str(tools) + os.pathsep + self.env['PATH']
        failures = {
            'ln': '[ "$2" = ' + shlex.quote(str(self.artifact)) + ' ]',
            'cp': '[ "$1" = -Pp ] && [ "$2" = ' + shlex.quote(str(agents)) + ' ]',
            'mv': '[ "$1" = -f ] && [ "$3" = ' + shlex.quote(str(agents)) + ' ]',
        }
        for command, condition in failures.items():
            with self.subTest(command=command):
                wrapper = tools / command
                wrapper.write_text('#!/bin/sh\nif ' + condition + '; then exit 1; fi\n'
                                   + 'exec ' + shlex.quote(shutil.which(command)) + ' "$@"\n')
                wrapper.chmod(0o755)
                result = self.run_make('install', ok=False)
                wrapper.unlink()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(agents.read_text(), original)
                personal = self.home / '.codex/agent-rules-personal.md'
                self.assertEqual(personal.read_text(), 'Before.\nAfter.\n')

    def test_personal_pointer_defers_to_already_injected_context(self):
        self.run_make('build')
        self.assertIn('read it only if its full contents are absent from the current context',
                      self.artifact.read_text())

    def test_override_refuses_without_replacing_personal_instructions(self):
        override = self.home / '.codex/AGENTS.override.md'
        override.write_text('personal override\n')
        agents = self.home / '.codex/AGENTS.md'
        agents.write_text('personal instructions\n')
        self.assertNotEqual(self.run_make('install', ok=False).returncode, 0)
        self.assertIn('AGENTS.override.md suppresses', self.run_make('install', ok=False).stderr)
        self.assertEqual(agents.read_text(), 'personal instructions\n')
        self.assertEqual(override.read_text(), 'personal override\n')


if __name__ == '__main__':
    unittest.main()
