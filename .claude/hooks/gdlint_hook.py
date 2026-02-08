"""Hook: run gdlint on .gd files after Edit/Write tool calls."""
import json
import subprocess
import sys

def main():
    try:
        data = json.load(sys.stdin)
        file_path = data.get("tool_input", {}).get("file_path", "")
    except (json.JSONDecodeError, AttributeError):
        sys.exit(0)

    if not file_path.endswith(".gd"):
        sys.exit(0)

    result = subprocess.run(
        [sys.executable, "-m", "gdtoolkit.linter", file_path],
        capture_output=True, text=True,
    )
    if result.stdout.strip():
        print(result.stdout.strip())
    if result.stderr.strip():
        print(result.stderr.strip(), file=sys.stderr)

    # Exit 2 = blocking error (Claude sees it as feedback)
    # Exit 0 = success
    sys.exit(2 if result.returncode != 0 else 0)

if __name__ == "__main__":
    main()
