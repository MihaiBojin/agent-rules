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

    def artifact(self, profile):
        return self.repo / 'generated' / ('AGENTS.md' if profile == 'full' else 'AGENTS-limited.md')

    def test_build_keeps_both_artifacts_current(self):
        checked = {p: self.artifact(p).read_bytes() if self.artifact(p).exists() else None
                   for p in ('full', 'limited')}
        result = self.run_make('build')
        for profile in checked:
            self.assertEqual(checked[profile], self.artifact(profile).read_bytes())
        full = self.artifact('full').read_text()
        limited = self.artifact('limited').read_text()
        self.assertLessEqual(len(full.splitlines()), 200)
        self.assertIn((self.repo / 'rules/25-threads.md').read_text().strip(), full)
        self.assertNotIn('## Threads', limited)
        self.assertNotIn('## How to answer me', limited)
        self.assertIn('Verify, then assert.', limited)
        self.assertIn('## Git and worktrees', limited)
        self.assertIn('## Code and architecture', limited)
        self.assertIn('do not apply to chat replies', limited)
        (self.repo / 'rules/99-unlisted.md').write_text('UNLISTED RULE\n')
        self.run_make('build')
        self.assertNotIn('UNLISTED RULE', self.artifact('full').read_text())

    def test_profile_switches_preserve_personal_and_reconcile_rules(self):
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
        for profile, target in [('full', 'install'), ('limited', 'install-limited'),
                                ('full', 'install'), ('limited', 'install-limited')]:
            self.run_make(target)
            self.assertTrue(agents.is_symlink())
            self.assertEqual(agents.resolve(), self.artifact(profile))
            self.assertIn(str(self.artifact(profile)), config.read_text())
            self.assertIn('model = "personal-model"', config.read_text())
            self.assertEqual(personal_link.resolve(), outside)
            self.assertEqual(collision.resolve(), outside)
            for excluded in ('20-answering.md', '25-threads.md', '31-conversation-scope.md'):
                self.assertEqual((personal_link.parent / excluded).exists(), profile == 'full')
            gemini = (self.home / '.gemini/GEMINI.md').read_text()
            self.assertIn('@' + str(self.artifact(profile)), gemini)
            personal = self.home / '.codex/agent-rules-personal.md'
            self.assertIn('Personal above.', personal.read_text())
            self.assertIn('Personal below.', personal.read_text())
            hook = subprocess.run([str(self.repo / 'hooks/codex-session-start.sh'),
                                   str(self.artifact(profile))], env=self.env,
                                  capture_output=True, text=True, check=True)
            context = json.loads(hook.stdout)['hookSpecificOutput']['additionalContext']
            self.assertEqual(context.count('Personal above.'), 1)
            self.assertTrue(context.startswith(self.artifact(profile).read_text()))
            self.assertIn('Personal below.', context)
            self.assertEqual('## Threads' in context, profile == 'full')
            before = (config.read_bytes(), personal.read_bytes())
            self.run_make(target)
            self.assertEqual(before, (config.read_bytes(), personal.read_bytes()))
        self.assertTrue(any(p.read_text() == original for p in agents.parent.glob('AGENTS.md.bak-*')))
        self.run_make('uninstall')
        self.assertFalse(agents.is_symlink())
        self.assertIn('Personal above.', agents.read_text())
        self.assertIn('Personal below.', agents.read_text())
        self.assertEqual(personal_link.resolve(), outside)
        self.assertNotIn('# >>> agent-rules >>>', config.read_text())

    def test_project_switch_and_mixed_scope_status(self):
        self.run_make('install')
        self.run_make('project')
        self.run_make('project-limited')
        agents = self.project / 'AGENTS.md'
        self.assertEqual(agents.resolve(), self.artifact('limited'))
        for directory in ('.claude/rules', '.agents/rules'):
            self.assertFalse((self.project / directory / '25-threads.md').exists())
            self.assertTrue((self.project / directory / '40-git.md').exists())
            writing = (self.project / directory / '10-writing.md').read_text()
            self.assertIn('do not apply to chat replies', writing)
        status = self.run_make('status').stdout
        self.assertIn('global: full', status)
        self.assertIn('project: limited', status)
        project_rules = next(line for line in status.splitlines() if '~/project/.claude/rules/' in line)
        self.assertIn('linked (5)', project_rules)
        self.assertIn('WARNING: mixed profiles', status)
        self.run_make('project')
        self.assertEqual(agents.resolve(), self.artifact('full'))
        self.assertNotIn('WARNING: mixed profiles', self.run_make('status').stdout)

    def test_personal_collisions_are_untouched(self):
        agents = self.project / 'AGENTS.md'
        agents.symlink_to(self.repo / 'README.md')
        rule = self.project / '.claude/rules/40-git.md'
        rule.parent.mkdir(parents=True)
        rule.write_text('personal git rule\n')
        personal_repo_link = rule.parent / '60-code.md'
        personal_repo_link.symlink_to(self.repo / 'README.md')
        self.run_make('project-limited')
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
        self.run_make('install-limited')
        personal = self.home / '.codex/agent-rules-personal.md'
        self.assertEqual(personal.read_bytes(), b'Before.\nAfter without newline')
        self.run_make('uninstall')
        self.assertEqual(agents.read_bytes(), personal.read_bytes())
        self.run_make('install')
        self.assertEqual(agents.resolve(), self.artifact('full'))

    def test_conflicting_personal_migration_refuses_without_changes(self):
        agents = self.home / '.codex/AGENTS.md'
        agents.write_text('Keep original\n')
        personal = self.home / '.codex/agent-rules-personal.md'
        personal.write_text('Keep existing personal file\n')
        result = self.run_make('install-limited', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('personal migration conflicts', result.stderr)
        self.assertEqual(agents.read_text(), 'Keep original\n')
        self.assertEqual(personal.read_text(), 'Keep existing personal file\n')
        self.assertFalse((self.home / '.codex/config.toml').exists())

    def test_malformed_managed_block_refuses_without_changes(self):
        agents = self.home / '.codex/AGENTS.md'
        original = 'Keep original\n<!-- >>> agent-rules >>> -->\nmissing end\n'
        agents.write_text(original)
        result = self.run_make('install-limited', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('malformed managed block', result.stderr)
        self.assertEqual(agents.read_text(), original)

    def test_hook_command_handles_repository_path_with_spaces(self):
        moved = self.root / 'repo with spaces'
        self.repo.rename(moved)
        self.repo = moved
        self.run_make('install-limited')
        config = (self.home / '.codex/config.toml').read_text()
        command_line = next(line for line in config.splitlines() if line.startswith('command = '))
        # The TOML string uses JSON-compatible escaping.
        command = json.loads(command_line.partition(' = ')[2])
        result = subprocess.run(command, shell=True, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        context = json.loads(result.stdout)['hookSpecificOutput']['additionalContext']
        self.assertIn('## Verification', context)
        self.assertNotIn('## Threads', context)

    def test_migration_keeps_newline_before_unterminated_end_marker(self):
        agents = self.home / '.codex/AGENTS.md'
        agents.write_text('Before.\n<!-- >>> agent-rules >>> -->\nold\n<!-- <<< agent-rules <<< -->')
        self.run_make('install-limited')
        self.assertEqual((self.home / '.codex/agent-rules-personal.md').read_bytes(), b'Before.\n')

    def test_status_detects_legacy_global_full_without_profile_file(self):
        self.run_make('install')
        (self.home / '.config/agent-rules/profile').unlink()
        self.run_make('project-limited')
        status = self.run_make('status').stdout
        self.assertIn('global: full', status)
        self.assertIn('WARNING: mixed profiles', status)

    def test_missing_source_fails_without_replacing_artifact(self):
        original = self.artifact('full').read_bytes()
        (self.repo / 'rules/40-git.md').unlink()
        result = self.run_make('build', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.artifact('full').read_bytes(), original)

    def test_global_personal_symlink_into_repo_is_untouched(self):
        agents = self.home / '.codex/AGENTS.md'
        agents.symlink_to(self.repo / 'README.md')
        result = self.run_make('install-limited', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(agents.resolve(), self.repo / 'README.md')

    def test_problem_reporting_is_full_only(self):
        self.run_make('build')
        paragraph = ('Tell me about a problem as soon as you find it: bugs you introduced, gaps you left, places where my own instructions\n'
                     'were wrong. Say it where it belongs, in the same voice as everything else, never bundled with other caveats.')
        self.assertEqual(self.artifact('full').read_text().count(paragraph), 1)
        self.assertNotIn(paragraph, self.artifact('limited').read_text())

    def test_failed_codex_link_preserves_original_personal_file(self):
        agents = self.home / '.codex/AGENTS.md'
        original = ('Before.\n<!-- >>> agent-rules >>> -->\nold pointer\n'
                    '<!-- <<< agent-rules <<< -->\nAfter.\n')
        agents.write_text(original)
        tools = self.root / 'bin'
        tools.mkdir()
        self.env['PATH'] = str(tools) + os.pathsep + self.env['PATH']
        failures = {
            'ln': '[ "$2" = ' + shlex.quote(str(self.artifact('limited'))) + ' ]',
            'cp': '[ "$1" = -Pp ] && [ "$2" = ' + shlex.quote(str(agents)) + ' ]',
            'mv': '[ "$1" = -f ] && [ "$3" = ' + shlex.quote(str(agents)) + ' ]',
        }
        for command, condition in failures.items():
            with self.subTest(command=command):
                wrapper = tools / command
                wrapper.write_text('#!/bin/sh\nif ' + condition + '; then exit 1; fi\n'
                                   + 'exec ' + shlex.quote(shutil.which(command)) + ' "$@"\n')
                wrapper.chmod(0o755)
                result = self.run_make('install-limited', ok=False)
                wrapper.unlink()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(agents.read_text(), original)
                personal = self.home / '.codex/agent-rules-personal.md'
                self.assertEqual(personal.read_text(), 'Before.\nAfter.\n')
                self.assertFalse((self.home / '.config/agent-rules/profile').exists())

    def test_personal_pointer_defers_to_already_injected_context(self):
        self.run_make('build')
        for profile in ('full', 'limited'):
            self.assertIn('read it only if its full contents are absent from the current context',
                          self.artifact(profile).read_text())

    def test_override_refuses_without_replacing_personal_instructions(self):
        override = self.home / '.codex/AGENTS.override.md'
        override.write_text('personal override\n')
        agents = self.home / '.codex/AGENTS.md'
        agents.write_text('personal instructions\n')
        self.assertNotEqual(self.run_make('install-limited', ok=False).returncode, 0)
        self.assertIn('AGENTS.override.md suppresses', self.run_make('install-limited', ok=False).stderr)
        self.assertEqual(agents.read_text(), 'personal instructions\n')
        self.assertEqual(override.read_text(), 'personal override\n')


if __name__ == '__main__':
    unittest.main()
