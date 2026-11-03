#!/usr/bin/env bash
# test-run.sh — run a project's automated tests the way /smoke-check Phase 2
# does, under a timeout, and read the result with that phase's exit-code ladder
# for the engine: the command, the timeout, the exit code, the zero-tests
# marker, the counts, and the ladder row that matched.
#
# Replaces the hand-run test command, `timeout`, exit-code reading and "looks
# like success and is not" cases.
#
# OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/"). The
# `rule` row says which row of the ladder the exit code and output fall on, in
# plain words; PASS, FAIL, NOT ASSESSED and "PASS WITH WARNINGS" stay with
# /smoke-check, which also decides what an unmatched exit code means.
#
# Usage: bash .claude/scripts/test-run.sh <engine> [options]
#   <engine>            godot, unity, unreal or bevy (any case)
#   --cmd COMMAND       the test command to run, instead of project.yaml's
#                       commands.test or the engine's default
#   --exe PATH          the editor executable (default: the one commands.test
#                       names, for godot only when its name says godot, else
#                       engine.path, else godot / Unity on PATH); for unreal,
#                       the UE root; for bevy, cargo (default: the one
#                       commands.test names when its name says cargo, else
#                       cargo on PATH; engine.path is not read)
#   --platform P        unity only: editmode (default) or playmode
#   --timeout SECONDS   default 900; 1800 for unreal and bevy
#   --os windows|linux|macos
#                       unreal only: default is read from `uname -s`
#   --filter ROOT       unreal only: the automation test root (default: the
#                       .uproject's name); read one test name when unsure
#   --no-build          unreal only: skip the build that comes first
#   --tool T            force the timeout tool: timeout, gtimeout, perl or none (the
#                       tests use this to reach the perl and no-tool paths)
#   --log FILE          keep the runner's output here (default: a temp file); the
#                       import's or the build's output goes to FILE.pre
#   --dry-run           print what would run; run nothing
#   --root DIR          the project; defaults to the repo this script is in
#   -h, --help          this text
#
# The timeout is `timeout`, else `gtimeout`, else perl (the command in its own
# process group, which gets TERM at the timeout and KILL five seconds on, as
# coreutils timeout does), whichever exists first; the `timeout` row names it,
# or `none` when no timeout tool exists and the run is unbounded. An exit of
# 124 (timeout, gtimeout) or 142 (perl) is a timeout.
#
# Before the test run, per engine: godot checks addons/gdUnit4/bin/GdUnitCmdTool.gd,
# then runs the import (`--headless --path . --import`) with the editor
# executable, whether the test command is commands.test or the default; unity
# checks Packages/manifest.json names com.unity.test-framework and deletes the
# old results file; unreal builds the editor target first (it needs the UE root),
# and a build that fails or times out runs no test, because the tests would run
# against the last good binaries or not load at all; bevy checks Cargo.toml is
# in the root (`cargo test` compiles the crate, then runs it, in one command, so
# its timeout is Unreal's). A check that fails runs
# nothing and prints why. The import and the build each have a row saying what
# runs, or why it does not, and their output goes to its own log (pre_log), so
# nothing they print is read as the tests' output.
#
# Bevy reads libtest's output (`cargo test` with the default harness): one
# `running N tests` line and one `test result: ok|FAILED. P passed; F failed;
# I ignored; ...` line per test binary (the library, each tests/ target, the
# doctests), and `test <path> ... ok|FAILED|ignored` per test. A test failure
# and a compile error both exit 101: a `test result: FAILED` line is a test
# failure; with no `test result:` line at all, an `error[E...]` or `error:
# could not compile` line is a compile error (a doctest that does not compile
# prints its error[E...] inside a FAILED test, so the order matters). `cargo
# test` stops at the first test binary that fails, so the counts after a
# failure cover only the binaries that ran.
#
# Output: TSV, in this order (a row that cannot apply is left out).
#   engine      <Godot|Unity|Unreal|Bevy>
#   exe         <path|->  <commands.test|engine.path|path|--exe|->
#   command     <--cmd|commands.test|default>  <the command>
#   import      <command> | - <skipped: why>                godot, before the tests
#   build       <command> | - <skipped: why>                unreal, before the tests
#   timeout     <seconds>  <timeout|gtimeout|perl|none>
#   precheck    <what>  <present|absent>
#   import_exit, build_exit   <code>                        when it ran
#   import_timed_out, build_timed_out   <yes|no>            when it ran
#   ran         <yes|no>  <why not, or ->
#   exit        <code of the test command>
#   timed_out   <yes|no>
#   results_file  <path>  <present|absent>                  unity
#   zero_tests  <yes|no|unknown>  <the marker line, or ->   godot, unity, unreal, bevy
#                                                           (bevy: yes when every
#                                                           `running N tests` has N 0,
#                                                           unknown when there is none)
#   tests       total=<n> passed=<n> failed=<n>             unity (the <test-run> element),
#                                                           unreal (Result={...} lines);
#                                                           bevy: the same plus
#                                                           ignored=<n>, summed over the
#                                                           `test result:` lines, or
#                                                           `-  no "test result:" line`;
#                                                           godot: `-  not sourced`
#   failed      <a line naming a failing test>  (up to 10, then `failed_more <n>`)
#   evidence    <a line that backs the rule>
#   rule        <id>  <what that row of the ladder says>     `-` when no row fits
#   pre_log     <path>                                      when the import or build ran
#   log         <path>
# Rule ids: timeout, runner-unavailable, godot:no-gdunit4, godot:0, godot:0-zero,
# godot:101, godot:100, godot:105, godot:103, godot:104, godot:1, godot:1-no-import,
# unity:no-test-framework, unity:0, unity:zero-tests, unity:no-count,
# unity:no-results, unity:2, unity:1, unity:3, unity:4, unity:other,
# unreal:mac-unsourced, unreal:build-failed, unreal:result-fail,
# unreal:no-tests-matched, unreal:pass, unreal:other-nonzero,
# bevy:no-cargo-toml, bevy:test-fail, bevy:compile-failed, bevy:no-tests,
# bevy:no-count, bevy:pass, bevy:other-nonzero.
#
# Exit codes: 0 the helper finished (whatever the tests did: read the rows);
# 1 cannot read the root or write the log; 2 usage error; 3 unknown engine.
# It runs the project's own test command and writes under the project (Unity's
# results file, the engine's caches); it never prompts and never edits
# project.yaml.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk and sort.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "test-run: $1 (try --help)" >&2; exit 2; }
ENGINE_ARG=""; CMD_ARG=""; EXE_ARG=""; PLATFORM="editmode"; TIMEOUT=""; OS_ARG=""; FILTER=""
NOBUILD=0; LOG=""; DRY=0; ROOT_ARG=""; TOOL_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --dry-run) DRY=1; shift ;;
    --no-build) NOBUILD=1; shift ;;
    --cmd|--exe|--platform|--timeout|--os|--filter|--log|--root|--tool)
      [ $# -ge 2 ] || usage "$1 needs a value"
      case "$1" in
        --cmd) CMD_ARG="$2" ;; --exe) EXE_ARG="$2" ;; --platform) PLATFORM="$2" ;;
        --timeout) TIMEOUT="$2" ;; --os) OS_ARG="$2" ;; --filter) FILTER="$2" ;;
        --log) LOG="$2" ;; --root) ROOT_ARG="$2" ;; --tool) TOOL_ARG="$2" ;;
      esac
      shift 2 ;;
    -?*) usage "unknown argument: $1" ;;
    *) [ -z "$ENGINE_ARG" ] || usage "one engine only"; ENGINE_ARG="$1"; shift ;;
  esac
done
[ -n "$ENGINE_ARG" ] || usage "no engine given"
case "$(printf '%s' "$ENGINE_ARG" | tr 'A-Z' 'a-z')" in
  godot) ENGINE=godot; ENAME=Godot ;;
  unity) ENGINE=unity; ENAME=Unity ;;
  unreal) ENGINE=unreal; ENAME=Unreal ;;
  bevy) ENGINE=bevy; ENAME=Bevy ;;
  *) echo "test-run: '$ENGINE_ARG' is not an engine this knows (godot, unity, unreal, bevy)" >&2; exit 3 ;;
esac
case "$PLATFORM" in editmode|playmode) ;; *) usage "--platform is editmode or playmode" ;; esac
case "$OS_ARG" in ""|windows|linux|macos) ;; *) usage "--os is windows, linux or macos" ;; esac
# /smoke-check Phase 2's limits: `timeout 900` for a test run, `timeout 1800` for
# Unreal, whose editor build and start-up come before any test, and for Bevy,
# whose `cargo test` compiles the crate (Bevy too, on a fresh clone) first.
if [ -z "$TIMEOUT" ]; then case "$ENGINE" in unreal|bevy) TIMEOUT=1800 ;; *) TIMEOUT=900 ;; esac; fi
case "$TIMEOUT" in ''|*[!0-9]*) usage "--timeout is whole seconds" ;; esac
[ "$TIMEOUT" -gt 0 ] || usage "--timeout must be above 0"

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "test-run: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "test-run: cannot reach the repo root" >&2; exit 1; }
fi
[ -f "$HERE/yaml-get.awk" ] || { echo "test-run: $HERE/yaml-get.awk is missing" >&2; exit 1; }
yget() { [ -f project.yaml ] && YG_PATH="$1" awk -f "$HERE/yaml-get.awk" project.yaml; }

printf 'engine\t%s\n' "$ENAME"

# --- the editor executable ----------------------------------------------------
CFG_TEST=$(yget commands.test); ENGINE_PATH=$(yget engine.path)
# exe_ok P — an existing file, or a command found on PATH.
exe_ok() { [ -n "$1" ] && { [ -f "$1" ] || command -v "$1" >/dev/null 2>&1; }; }
EXE=""; EXE_SRC="-"
if [ -n "$EXE_ARG" ]; then
  EXE="$EXE_ARG"; EXE_SRC="--exe"
else
  # The executable commands.test names: its quoted path, else its first word.
  # For Godot it counts only when its file name says godot (godot, godot4,
  # Godot_v4.7-stable_win64.exe): a wrapper such as `bash run-tests.sh` is not
  # the editor, and the import would run it with the editor's flags.
  first=""
  if [ -n "$CFG_TEST" ]; then
    case "$CFG_TEST" in
      \"*) first=${CFG_TEST#\"}; first=${first%%\"*} ;;
      \'*) first=${CFG_TEST#\'}; first=${first%%\'*} ;;
      *) first=${CFG_TEST%% *} ;;
    esac
  fi
  # Bevy's likewise only when it says cargo: Bevy has no editor, the toolchain is cargo.
  if [ "$ENGINE" = godot ] || [ "$ENGINE" = bevy ]; then
    _base=${first##*/}; _base=$(printf '%s' "${_base##*\\}" | tr 'A-Z' 'a-z')
    case "$ENGINE:$_base" in godot:*godot*|bevy:*cargo*) ;; *) first="" ;; esac
  fi
  if [ "$ENGINE" != unreal ] && exe_ok "$first"; then EXE="$first"; EXE_SRC="commands.test"
  elif [ "$ENGINE" != bevy ] && [ -n "$ENGINE_PATH" ] && { [ "$ENGINE" = unreal ] && [ -d "$ENGINE_PATH" ] || { [ "$ENGINE" != unreal ] && exe_ok "$ENGINE_PATH"; }; }; then EXE="$ENGINE_PATH"; EXE_SRC="engine.path"
  elif [ "$ENGINE" = godot ] && exe_ok godot; then EXE="godot"; EXE_SRC="path"
  elif [ "$ENGINE" = unity ] && exe_ok Unity; then EXE="Unity"; EXE_SRC="path"
  elif [ "$ENGINE" = bevy ] && exe_ok cargo; then EXE="cargo"; EXE_SRC="path"
  fi
fi
printf 'exe\t%s\t%s\n' "${EXE:--}" "$EXE_SRC"

# --- timeout tool -------------------------------------------------------------
if [ -n "$TOOL_ARG" ]; then
  case "$TOOL_ARG" in timeout|gtimeout|perl|none) TOOL="$TOOL_ARG" ;; *) usage "--tool is timeout, gtimeout, perl or none" ;; esac
elif command -v timeout >/dev/null 2>&1; then TOOL=timeout
elif command -v gtimeout >/dev/null 2>&1; then TOOL=gtimeout
elif command -v perl >/dev/null 2>&1; then TOOL=perl
else TOOL=none; fi
# The perl fallback does what coreutils timeout does: the command runs in a
# process group of its own, and at the timeout the whole group gets TERM, then
# KILL five seconds on, so an editor that a compound command started (cd x &&
# godot ...) ends with it. It exits 142 (128 + SIGALRM's 14) on a timeout,
# else with the command's own code.
PERL_TIMEOUT='
  my $t = shift @ARGV;
  my $pid = fork;
  defined $pid or die "test-run: fork failed: $!\n";
  if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; }
  setpgrp($pid, $pid);
  my $timed = 0;
  $SIG{ALRM} = sub { if ($timed++) { kill "KILL", -$pid } else { kill "TERM", -$pid; alarm 5 } };
  for my $s (qw(INT TERM HUP)) { $SIG{$s} = sub { kill $_[0], -$pid } }
  alarm $t;
  my $st = 0;
  while (1) {
    my $w = waitpid($pid, 0);
    if ($w == $pid) { $st = $?; last }
    last if $w == -1;
  }
  alarm 0;
  if ($timed) {
    for (1 .. 50) { last unless kill 0, -$pid; select(undef, undef, undef, 0.1) }
    kill "KILL", -$pid if kill 0, -$pid;
    exit 142;
  }
  exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
'
# run_timed SECONDS COMMAND — COMMAND under the timeout tool, output on stdout and stderr.
run_timed() {
  case "$TOOL" in
    timeout|gtimeout) "$TOOL" "$1" bash -c "$2" ;;
    perl) perl -e "$PERL_TIMEOUT" "$1" bash -c "$2" ;;
    *) bash -c "$2" ;;
  esac
}
# is_timeout CODE — whether CODE is the tool's timeout exit: 124 from timeout and
# gtimeout, 142 (128 + SIGALRM's 14) from the perl alarm.
is_timeout() {
  case "$TOOL" in
    timeout|gtimeout) [ "$1" = 124 ] ;;
    perl) [ "$1" = 142 ] ;;
    *) return 1 ;;
  esac
}

# --- the commands -------------------------------------------------------------
ABS=$(pwd -W 2>/dev/null || pwd)
RESULTS=""; BUILD=""; CMD=""; CMD_SRC="default"; PRE_FAIL=""; PRE_ID=""; PRE_WHY=""
case "$ENGINE" in
  godot)
    CMD="\"${EXE:-godot}\" --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode 2>&1"
    ;;
  unity)
    if [ "$PLATFORM" = playmode ]; then P=PlayMode; RESULTS=test-results/playmode.xml; else P=EditMode; RESULTS=test-results/editmode.xml; fi
    CMD="\"${EXE:-Unity}\" -batchmode -runTests -projectPath . -testPlatform $P -testResults $RESULTS"
    ;;
  unreal)
    if [ -n "$OS_ARG" ]; then OSN=$OS_ARG
    else case "$(uname -s)" in Linux) OSN=linux ;; Darwin) OSN=macos ;; *) OSN=windows ;; esac; fi
    PROJ=""
    for u in ./*.uproject; do [ -f "$u" ] && { PROJ=${u#./}; PROJ=${PROJ%.uproject}; break; }; done
    [ -n "$FILTER" ] || FILTER="$PROJ"
    case "$OSN" in
      windows)
        BUILD="\"$EXE/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe\" ${PROJ}Editor Win64 Development -Project=\"$ABS/$PROJ.uproject\" 2>&1"
        CMD="\"$EXE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe\" \"$ABS/$PROJ.uproject\" -ExecCmds=\"Automation RunTests $FILTER.; Quit\" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1" ;;
      linux)
        BUILD="\"$EXE/Engine/Build/BatchFiles/Linux/Build.sh\" ${PROJ}Editor Linux Development -Project=\"$ABS/$PROJ.uproject\" 2>&1"
        CMD="\"$EXE/Engine/Binaries/Linux/UnrealEditor\" \"$ABS/$PROJ.uproject\" -ExecCmds=\"Automation RunTests $FILTER.; Quit\" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1" ;;
      macos)
        BUILD="\"$EXE/Engine/Build/BatchFiles/Mac/Build.sh\" ${PROJ}Editor Mac Development -Project=\"$ABS/$PROJ.uproject\" 2>&1"
        CMD="" ;;
    esac
    ;;
  bevy)
    CMD="\"${EXE:-cargo}\" test"
    ;;
esac
# commands.test and --cmd win over the default. Unreal keeps the build first.
if [ -n "$CMD_ARG" ]; then CMD="$CMD_ARG"; CMD_SRC="--cmd"
elif [ -n "$CFG_TEST" ]; then CMD="$CFG_TEST"; CMD_SRC="commands.test"; fi
# A Unity results file named in the command is the one to read and to delete first.
if [ "$ENGINE" = unity ] && [ "$CMD_SRC" != default ]; then
  # -E: BSD sed has no \| in a basic regex.
  named=$(printf '%s\n' "$CMD" | sed -n -E 's/.*-testResults[ =]*("[^"]*"|[^ ]*).*/\1/p' | head -1)
  named=${named#\"}; named=${named%\"}
  [ -n "$named" ] && RESULTS="$named"
fi
# The step before the tests: Godot's import, Unreal's build.
PRE_NAME=""; PRE_CMD=""; PRE_WHY=""
case "$ENGINE" in
  godot)
    PRE_NAME=import
    if [ -n "$EXE" ]; then PRE_CMD="\"$EXE\" --headless --path . --import"
    else PRE_WHY="skipped: no Godot executable (--exe, commands.test, engine.path, PATH)"; fi ;;
  unreal)
    PRE_NAME=build
    if [ "$NOBUILD" = 1 ]; then PRE_WHY="skipped: --no-build"
    elif [ -z "$EXE" ]; then PRE_WHY="skipped: no UE root (--exe or engine.path)"
    else PRE_CMD="$BUILD"; fi ;;
esac
[ -n "$CMD" ] && printf 'command\t%s\t%s\n' "$CMD_SRC" "$CMD"
if [ -n "$PRE_CMD" ]; then printf '%s\t%s\n' "$PRE_NAME" "$PRE_CMD"
elif [ -n "$PRE_NAME" ]; then printf '%s\t-\t%s\n' "$PRE_NAME" "$PRE_WHY"; fi
printf 'timeout\t%s\t%s\n' "$TIMEOUT" "$TOOL"

# --- prechecks ----------------------------------------------------------------
ran_no() { printf 'ran\tno\t%s\n' "$2"; printf 'rule\t%s\t%s\n' "$1" "$3"; exit 0; }
case "$ENGINE" in
  godot)
    if [ -f addons/gdUnit4/bin/GdUnitCmdTool.gd ]; then printf 'precheck\taddons/gdUnit4/bin/GdUnitCmdTool.gd\tpresent\n'
    else
      printf 'precheck\taddons/gdUnit4/bin/GdUnitCmdTool.gd\tabsent\n'
      ran_no godot:no-gdunit4 "gdUnit4 is not installed at addons/gdUnit4/" "gdUnit4 not installed, so no runner was started"
    fi ;;
  unity)
    if [ -f Packages/manifest.json ] && grep -q 'com.unity.test-framework' Packages/manifest.json; then printf 'precheck\tcom.unity.test-framework\tpresent\n'
    else
      printf 'precheck\tcom.unity.test-framework\tabsent\n'
      ran_no unity:no-test-framework "Unity Test Framework is not in Packages/manifest.json" "the Unity Test Framework is not installed; the editor would hang, so it was not started"
    fi ;;
  unreal)
    if [ "$OSN" = macos ] && [ -z "$CMD_ARG" ] && [ -z "$CFG_TEST" ]; then
      printf 'precheck\tmacos test command\tabsent\n'
      ran_no unreal:mac-unsourced "no sourced Unreal test command on macOS and no commands.test" "no sourced Unreal test command on macOS: set commands.test"
    fi ;;
  bevy)
    if [ -f Cargo.toml ]; then printf 'precheck\tCargo.toml\tpresent\n'
    else
      printf 'precheck\tCargo.toml\tabsent\n'
      ran_no bevy:no-cargo-toml "no Cargo.toml in the root" "no Cargo.toml in the root, so cargo has no crate to test here"
    fi ;;
esac
if [ -z "$EXE" ] && [ "$CMD_SRC" = default ]; then
  if [ "$ENGINE" = bevy ]; then
    ran_no runner-unavailable "cargo is not on PATH (--exe, commands.test, PATH)" "cargo was not found, so the tests could not be run here"
  fi
  ran_no runner-unavailable "no editor executable (commands.test, engine.path, PATH)" "the engine executable was not found, so the tests could not be run here"
fi
if [ "$DRY" = 1 ]; then printf 'ran\tno\tdry run\n'; exit 0; fi

# --- run ----------------------------------------------------------------------
if [ -z "$LOG" ]; then
  LOG=$(mktemp "${TMPDIR:-/tmp}/test-run-XXXXXX" 2>/dev/null) || { echo "test-run: cannot create a log file" >&2; exit 1; }
fi
: > "$LOG" 2>/dev/null || { echo "test-run: cannot write the log $LOG" >&2; exit 1; }
[ "$ENGINE" = unity ] && [ -n "$RESULTS" ] && rm -f "$RESULTS"
PRE_LOG=""; PRE_CODE=""; PRE_TIMED=no
if [ -n "$PRE_CMD" ]; then
  PRE_LOG="$LOG.pre"
  : > "$PRE_LOG" 2>/dev/null || { echo "test-run: cannot write the log $PRE_LOG" >&2; exit 1; }
  run_timed "$TIMEOUT" "$PRE_CMD" > "$PRE_LOG" 2>&1
  PRE_CODE=$?
  is_timeout "$PRE_CODE" && PRE_TIMED=yes
  printf '%s_exit\t%s\n' "$PRE_NAME" "$PRE_CODE"
  printf '%s_timed_out\t%s\n' "$PRE_NAME" "$PRE_TIMED"
fi
# A build that did not finish cleanly runs no test (/smoke-check: a failed build
# is a failure): the editor would load the last good binaries, or none.
if [ "$PRE_NAME" = build ] && [ -n "$PRE_CMD" ] && [ "$PRE_CODE" != 0 ]; then
  if [ "$PRE_TIMED" = yes ]; then
    printf 'ran\tno\tthe editor build timed out after %ss\n' "$TIMEOUT"
    printf 'rule\ttimeout\tthe build did not complete: timed out after %ss, so nothing was verified\n' "$TIMEOUT"
  else
    printf 'ran\tno\tthe editor build failed (exit %s)\n' "$PRE_CODE"
    printf 'rule\tunreal:build-failed\tthe editor build failed, so no test ran\n'
  fi
  printf 'pre_log\t%s\n' "$PRE_LOG"
  exit 0
fi
run_timed "$TIMEOUT" "$CMD" > "$LOG" 2>&1
CODE=$?
printf 'ran\tyes\t-\n'
printf 'exit\t%s\n' "$CODE"
TIMED=no
is_timeout "$CODE" && TIMED=yes
printf 'timed_out\t%s\n' "$TIMED"

# --- read ---------------------------------------------------------------------
# first_line PATTERN — the first output line matching the extended regex, or empty.
first_line() { grep -E -m 1 "$1" "$LOG" 2>/dev/null | head -1 | tr -d '\r'; }
# list_failed PATTERN FILE — up to 10 matching lines as `failed` rows, then the
# overflow (Phase 2: "names of any failing tests (up to 10; if more, note the count)").
list_failed() {
  n=$(grep -E -c "$1" "$2" 2>/dev/null); n=${n:-0}
  grep -E "$1" "$2" 2>/dev/null | head -10 | tr -d '\r' | while IFS= read -r l; do printf 'failed\t%s\n' "$(printf '%s' "$l" | sed 's/^[[:blank:]]*//')"; done
  [ "$n" -gt 10 ] && printf 'failed_more\t%s\n' "$((n - 10))"
  return 0
}
RULE_ID="-"; RULE_TXT="no row of the ladder fits"
set_rule() { RULE_ID="$1"; RULE_TXT="$2"; }
case "$ENGINE" in
  godot)
    marker=$(first_line 'No test cases found')
    if [ -n "$marker" ]; then printf 'zero_tests\tyes\t%s\n' "$marker"; else printf 'zero_tests\tno\t-\n'; fi
    printf 'tests\t-\tnot sourced: the gdUnit4 summary format is not documented here\n'
    case "$CODE" in
      0) if [ -n "$marker" ]; then set_rule godot:0-zero "exit 0 over zero tests: the runner found no test cases"
         else set_rule godot:0 "exit 0: every test passed"; fi ;;
      101) set_rule godot:101 "every test passed, but a test leaked nodes (orphans)"
           e=$(first_line '[Oo]rphan'); [ -n "$e" ] && printf 'evidence\t%s\n' "$e" ;;
      100) set_rule godot:100 "a test failed" ;;
      105) set_rule godot:105 "a test script does not parse" ;;
      103) set_rule godot:103 "gdUnit4 refused to run headless (--ignoreHeadlessMode missing)" ;;
      104) set_rule godot:104 "Godot is older than 4.3" ;;
      # The ladder reads exit 1 by whether the import ran first: usually it was
      # skipped (the runner needs the class cache it builds); after it, exit 1
      # is Godot's own error.
      1) if [ "$PRE_CODE" = 0 ]; then
           set_rule godot:1 "Godot's own error: GdUnitCmdTool.gd did not load after the import, so no test ran"
         else
           if [ -z "$PRE_CMD" ]; then why="skipped: no Godot executable"
           elif [ "$PRE_TIMED" = yes ]; then why="timed out"
           else why="exit $PRE_CODE"; fi
           set_rule godot:1-no-import "GdUnitCmdTool.gd did not load, so no test ran, and the import did not complete first ($why)"
         fi
         e=$(first_line 'Failed to load script'); [ -n "$e" ] && printf 'evidence\t%s\n' "$e" ;;
      126|127) set_rule runner-unavailable "the editor did not start (command not found or not executable)" ;;
    esac ;;
  unity)
    if [ -f "$RESULTS" ]; then
      printf 'results_file\t%s\tpresent\n' "$RESULTS"
      run_el=$(grep -E -m 1 '<test-run' "$RESULTS" | tr -d '\r')
      attr() { printf '%s\n' "$run_el" | sed -n "s/.*[ <]$1=\"\\([0-9]*\\)\".*/\\1/p" | head -1; }
      total=$(attr testcasecount); passed=$(attr passed); failed=$(attr failed)
      printf 'tests\ttotal=%s passed=%s failed=%s\n' "${total:--}" "${passed:--}" "${failed:--}"
      if [ -z "$total" ]; then printf 'zero_tests\tunknown\tno testcasecount on a <test-run> element\n'
      elif [ "$total" = 0 ]; then printf 'zero_tests\tyes\ttestcasecount="0"\n'; else printf 'zero_tests\tno\t-\n'; fi
      list_failed '<test-case[^>]*result="Failed"' "$RESULTS"
    else
      printf 'results_file\t%s\tabsent\n' "$RESULTS"; total=""
    fi
    case "$CODE" in
      0) if [ ! -f "$RESULTS" ]; then set_rule unity:no-results "exit 0 but no results file was written"
         elif [ -z "$total" ]; then set_rule unity:no-count "exit 0, but the results file has no <test-run> testcasecount, so no test was counted"
         elif [ "$total" = 0 ]; then set_rule unity:zero-tests "testcasecount is 0: no test was compiled or run"
         else set_rule unity:0 "exit 0: every test passed"; fi ;;
      2) set_rule unity:2 "a test failed" ;;
      1) set_rule unity:1 "the project did not compile (see the editor log for error CS lines)" ;;
      3) set_rule unity:3 "the run itself failed" ;;
      4) set_rule unity:4 "an unknown -testPlatform" ;;
      126|127) set_rule runner-unavailable "the editor did not start (command not found or not executable)" ;;
      *) set_rule unity:other "any other non-zero exit" ;;
    esac ;;
  unreal)
    nok=$(grep -E -c 'Result=\{Success\}' "$LOG"); nfail=$(grep -E -c 'Result=\{Fail\}' "$LOG")
    nok=${nok:-0}; nfail=${nfail:-0}
    printf 'tests\ttotal=%s passed=%s failed=%s\n' "$((nok + nfail))" "$nok" "$nfail"
    marker=$(first_line 'No automation tests matched')
    if [ -n "$marker" ]; then printf 'zero_tests\tyes\t%s\n' "$marker"; else printf 'zero_tests\tno\t-\n'; fi
    list_failed 'Result=\{Fail\}' "$LOG"
    if [ "$nfail" -gt 0 ]; then set_rule unreal:result-fail "Result={Fail} on a line of the output"
    elif [ -n "$marker" ]; then set_rule unreal:no-tests-matched "No automation tests matched (a failing test and a run that matched nothing both exit 255)"
    elif [ "$CODE" = 126 ] || [ "$CODE" = 127 ]; then set_rule runner-unavailable "the editor did not start (command not found or not executable)"
    elif [ "$CODE" = 0 ] && [ "$nok" -gt 0 ]; then set_rule unreal:pass "exit 0 with Result={Success} lines"
    elif [ "$CODE" != 0 ]; then set_rule unreal:other-nonzero "a non-zero exit with no Result={Fail} line and no 'no tests matched': no test ran"
    fi ;;
  bevy)
    # One `running N tests` and (when it finishes) one `test result:` line per binary.
    nrun=$(grep -E -c '^running [0-9]+ tests?' "$LOG"); nrun=${nrun:-0}
    nnz=$(grep -E '^running [0-9]+ tests?' "$LOG" | grep -E -v -c '^running 0 tests'); nnz=${nnz:-0}
    # shellcheck disable=SC2046
    set -- $(awk '{ sub(/\r$/, "") }
      /^test result: / { n++; for (i = 4; i <= NF; i++) {
        if ($i ~ /^passed;?$/) p += $(i - 1); else if ($i ~ /^failed;?$/) f += $(i - 1); else if ($i ~ /^ignored;?$/) g += $(i - 1) } }
      END { print n + 0, p + 0, f + 0, g + 0 }' "$LOG")
    nres=$1; np=$2; nf=$3; ni=$4
    if [ "$nres" -gt 0 ]; then printf 'tests\ttotal=%s passed=%s failed=%s ignored=%s\n' "$((np + nf + ni))" "$np" "$nf" "$ni"
    else printf 'tests\t-\tno "test result:" line in the output\n'; fi
    if [ "$nrun" -eq 0 ]; then printf 'zero_tests\tunknown\tno "running N tests" line in the output\n'
    elif [ "$nnz" -eq 0 ]; then printf 'zero_tests\tyes\t%s (all %s test binaries)\n' "$(first_line '^running 0 tests')" "$nrun"
    else printf 'zero_tests\tno\t-\n'; fi
    list_failed '^test .* \.\.\. FAILED' "$LOG"
    tfail=$(first_line '^test result: FAILED')
    comp=$(first_line '^error: could not compile|^error\[E[0-9]+\]')
    # A test failure first: a doctest that does not compile prints error[E...]
    # inside a FAILED test, after `test result:` lines exist.
    if [ "$CODE" = 126 ] || [ "$CODE" = 127 ]; then set_rule runner-unavailable "cargo did not start (command not found or not executable)"
    elif [ -n "$tfail" ]; then set_rule bevy:test-fail "a test failed: a 'test result: FAILED' line"; printf 'evidence\t%s\n' "$tfail"
    elif [ "$nres" -eq 0 ] && [ -n "$comp" ]; then set_rule bevy:compile-failed "the crate or a test target did not compile, so no test ran"; printf 'evidence\t%s\n' "$comp"
    elif [ "$CODE" = 0 ] && [ "$nres" -eq 0 ]; then set_rule bevy:no-count "exit 0, but no 'test result:' line, so no test was counted"
    elif [ "$CODE" = 0 ] && [ "$nnz" -eq 0 ]; then set_rule bevy:no-tests "exit 0 over zero tests: every 'running N tests' line says 0"
    elif [ "$CODE" = 0 ] && [ "$np" -eq 0 ]; then set_rule bevy:no-tests "exit 0, but no test ran: every test was ignored"
    elif [ "$CODE" = 0 ]; then set_rule bevy:pass "exit 0 with 'test result: ok' lines: every test that ran passed"
    else set_rule bevy:other-nonzero "a non-zero exit with no 'test result: FAILED' line and no compile error: a test binary crashed or cargo stopped before the tests"
      e=$(first_line '^error'); [ -n "$e" ] && printf 'evidence\t%s\n' "$e"
    fi ;;
esac
if [ "$TIMED" = yes ]; then set_rule timeout "the run did not complete: timed out after ${TIMEOUT}s, so nothing was verified"; fi
printf 'rule\t%s\t%s\n' "$RULE_ID" "$RULE_TXT"
[ -n "$PRE_LOG" ] && printf 'pre_log\t%s\n' "$PRE_LOG"
printf 'log\t%s\n' "$LOG"
exit 0
