"""Owner testing budget: CLI must reject full Godot matrices before launching engines."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
RUNNERS = (
    "check-compatibility.py",
    "check-editor-lifecycle.py",
    "check-editor-play.py",
    "check-filtered-highlighting.py",
    "check-script-context.py",
)


class TwoEngineLimitTests(unittest.TestCase):
    def test_three_engines_are_rejected_before_running_or_creating_output(self):
        for runner in RUNNERS:
            with self.subTest(runner=runner), tempfile.TemporaryDirectory() as temp:
                output = Path(temp) / "not-created"
                command = [sys.executable, str(ROOT / "tools" / runner),
                           "--engine", "4.0.4=/not/a/godot",
                           "--engine", "4.4.1=/not/a/godot",
                           "--engine", "4.7=/not/a/godot",
                           "--output", str(output)]
                process = subprocess.run(command, capture_output=True, text=True, timeout=10)
                self.assertNotEqual(process.returncode, 0)
                self.assertIn("Maximum two Godot engines", process.stderr)
                self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
