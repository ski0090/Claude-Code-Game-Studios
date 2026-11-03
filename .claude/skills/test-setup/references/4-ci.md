# /test-setup — Phase 4: Create CI/CD Workflow

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Create CI/CD Workflow

**In this file:**

- Godot 4
- Unity
- Unreal Engine
- Bevy

### Godot 4

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run GdUnit4 Tests
    runs-on: ubuntu-latest
    # The action publishes its results as a check run. A new repository's
    # token is read-only, and without checks: write the job fails even when
    # every test passes. If you protect main, require the `Run GdUnit4 Tests` job
    # check, not `test-results`: that check run concludes success even when a
    # test fails.
    permissions:
      contents: read
      checks: write

    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      # godot-version must be a full release such as 4.7.2 (`godot --version`
      # shows it); VERSION.md's "4.7" is not one. version: installed runs the
      # gdUnit4 committed in addons/ -- without it the action deletes that
      # copy and installs the latest release, which may not match your tests.
      - name: Run GdUnit4 Tests
        uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: '[FULL GODOT VERSION, e.g. 4.7.2]'
          version: 'installed'
          paths: |
            tests/unit
            tests/integration
          report-name: test-results

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: reports/
```

### Unity

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run Unity Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      - name: Run Edit Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: editmode
          artifactsPath: test-results/editmode

      - name: Run Play Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: playmode
          artifactsPath: test-results/playmode

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: test-results/
```

Note: Unity CI requires a `UNITY_LICENSE` secret. Add to GitHub repository
secrets before the first CI run.

### Unreal Engine

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run UE Automation Tests
    runs-on: [self-hosted, windows]  # UE requires a local runner with the editor installed

    # The quoted "{0}" in each `shell:` below: the Windows runner passes bash
    # its script path unquoted, so with plain `shell: bash` every step fails
    # ("No such file or directory") when the runner's folder has a space.
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      # Binaries/ is gitignored, so a fresh checkout has no compiled game
      # module: without this step the editor stops with "The game module could
      # not be found" before running any test. UnrealBuildTool.exe, not
      # Build.bat -- from bash, Build.bat fails on an engine path with spaces.
      - name: Build Editor Target
        run: |
          "$UE_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" [ProjectName]Editor Win64 Development \
            -Project="${{ github.workspace }}/[ProjectName].uproject"
        shell: bash --noprofile --norc -eo pipefail "{0}"

      # -stdout -FullStdOutLogOutput: without them the editor prints nothing
      # here, and the results are only in Saved/Logs/.
      - name: Run Automation Tests
        run: |
          "$UE_ROOT/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "${{ github.workspace }}/[ProjectName].uproject" \
            -nullrhi -nosound \
            -ExecCmds="Automation RunTests [ProjectName].; Quit" \
            -unattended -stdout -FullStdOutLogOutput
        shell: bash --noprofile --norc -eo pipefail "{0}"

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-logs
          path: Saved/Logs/
```

Note: UE CI requires a self-hosted Windows runner with Unreal Editor installed.
The `windows` label keeps the job off any Linux self-hosted runner the
repository also has. Set the `UE_ROOT` environment variable on the runner to the engine folder
(e.g. `C:/Program Files/Epic Games/UE_5.8`). `[ProjectName]Editor` is the
editor target in `Source/[ProjectName]Editor.Target.cs`. `actions/checkout@v7`
and `actions/upload-artifact@v7` run on Node.js 24, which needs Actions Runner
2.327.1 or newer: update the self-hosted runner before the first run
(https://github.com/actions/checkout/blob/v7.0.1/README.md).

### Bevy

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run cargo test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      # Bevy's Ubuntu build dependencies, from docs/linux_dependencies.md in
      # the bevy crate (the second pair is needed while the default wayland
      # feature is on). Without them the build stops in a -sys crate.
      - name: Install Bevy's Linux dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y g++ pkg-config libx11-dev libasound2-dev libudev-dev libxkbcommon-x11-0
          sudo apt-get install -y libwayland-dev libxkbcommon-dev

      # Bevy sets a minimum Rust version (rust-version in its Cargo.toml):
      # bring the runner's toolchain up to date before building.
      - name: Update Rust
        run: rustup update stable && rustup default stable

      # Compiles the crate (and Bevy) first, then runs every test target.
      # --no-fail-fast: a failing binary does not hide the ones after it.
      - name: Run tests
        run: cargo test --no-fail-fast
```

Note: the packages are the Ubuntu line of `docs/linux_dependencies.md` in the
`bevy` 0.20.1 crate. Bevy 0.20.1 sets `rust-version = "1.97.1"`. A cold build
compiles Bevy itself, so the first run takes many minutes. This workflow has
not been run on GitHub here: confirm the first run goes green.

---
