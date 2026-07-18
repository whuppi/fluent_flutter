.PHONY: check hooks lint-shell analyze analyze-floor platforms format test test-example clean

# ═══════════════════════════════════════════════════════════════════
# SDK resolution
#
# Uses fvm by default. Contributors without fvm can override:
# make check DART=dart FLUTTER=flutter
# fluent_flutter is a Flutter package — the suite runs on flutter_test
# (host VM, no device, no browser). example/ is its own Flutter app
# package, resolved / analyzed from its OWN root (analyze_core gives it
# a `flutter analyze` pass; the journeys drive its real UI).
# ═══════════════════════════════════════════════════════════════════

DART    ?= fvm dart
FLUTTER ?= fvm flutter
TEST_RESULTS_DIR ?= test-results
TIMEOUT := $(if $(CI),--timeout=30x,)
VERBOSE := $(if $(CI),--verbose,)

# ═══════════════════════════════════════════════════════════════════
# § 1 — Gate
# ═══════════════════════════════════════════════════════════════════
#
# make check    Full local gate before handing work over.

check: lint-shell analyze analyze-floor test test-example

# make hooks    Activate the repo's git hooks (commit-msg, pre-commit).
#               Run once after cloning — they stay dormant otherwise.
#               Idempotent. The hooks live at the repo root
#               (.githooks/), stamped from the shared whuppi set.
hooks:
	@git config core.hooksPath .githooks
	@echo "✓ git hooks active (core.hooksPath → .githooks)"

# make lint-shell  Shell portability gate: shellcheck + a bash-version scan
#                  over the repo's shell scripts. Shared gate
#                  tool/lint_shell.sh (canonical in whuppi/ci, stamped).
lint-shell:
	@bash tool/lint_shell.sh


# make platforms  BLOCKED pre-release, deliberately not in `check`: pana
#                 snapshots the GIT REPO, and the fluent_bundle path dep lives
#                 in a sibling repo whose required version is not yet
#                 published. Activates when the family deps go hosted — the
#                 release checklist flips it into `check`.
platforms:
	@echo "platforms gate is BLOCKED pre-release for fluent_flutter:"
	@echo "  pana snapshots the git repo; ../fluent_bundle (a sibling repo whose"
	@echo "  required version is not yet published) can never resolve in it."
	@echo "  Activates at release when the family deps go hosted — see the"
	@echo "  family release checklist (fluent_bundle/docs/UPDATING.md §6)."
	@exit 2

# ═══════════════════════════════════════════════════════════════════
# § 2 — Analyze
# ═══════════════════════════════════════════════════════════════════
#
# make analyze  Resolve, format, analyze at --fatal-infos. Resolve runs
#               FIRST because `dart format` reads the resolved language
#               version — an unresolved tree formats differently.
#               Locally format fixes in place; under CI a diff fails.
#               analyze_core gives example/ its own `flutter analyze`
#               pass from its own root.

analyze:
	@echo "=== Flutter: pub get ==="
	@$(FLUTTER) pub get
	@echo "=== Dart: format ==="
	@if [ -n "$$CI" ]; then \
	  $(DART) format --set-exit-if-changed lib test; \
	else \
	  $(DART) format lib test; \
	fi
	@echo "=== analyze (shared core) ==="
	@DART="$(DART)" FLUTTER="$(FLUTTER)" ANALYZE_DIRS="lib test" bash tool/analyze_core.sh

# make analyze-floor  Resolve to the OLDEST in-range dependencies and
#                     analyze the shipped code (lib). The wide lower
#                     bounds are only honest if the code analyzes against
#                     them, not just the newest a fresh resolve picks.
#                     Tests are excluded on purpose — a consumer sees
#                     lib, never your tests. Snapshots and restores the
#                     lock so a local run leaves the tree clean.
analyze-floor:
	@$(FLUTTER) pub get >/dev/null
	@cp pubspec.lock pubspec.lock.floorbak; \
	$(FLUTTER) pub downgrade >/dev/null && $(DART) analyze --fatal-infos lib; rc=$$?; \
	mv pubspec.lock.floorbak pubspec.lock; \
	$(FLUTTER) pub get >/dev/null 2>&1 || true; \
	exit $$rc

# make format   Format in place (analyze also formats; this is the
#               standalone entry).
format:
	@$(DART) format lib test

# ═══════════════════════════════════════════════════════════════════
# § 3 — Test
# ═══════════════════════════════════════════════════════════════════
#
# make test     The full flutter_test suite (host VM) — loader, delegate,
#               controller, markup, hot reload.

test:
	@echo "=== Flutter test suite (host VM) ==="
	@mkdir -p $(TEST_RESULTS_DIR)
	@$(FLUTTER) test $(VERBOSE) $(TIMEOUT) --file-reporter json:$(TEST_RESULTS_DIR)/vm.json

# make test-example  The demo's journeys — the exact UI a user sees driven
#                    end to end through the real asset loader, bundled FTL,
#                    delegates, and IntlBackend: locale switching, CLDR
#                    plurals, markup taps, the fallback chain.
test-example:
	@echo "=== Example: journeys (host VM, the demo UI end to end) ==="
	@mkdir -p $(TEST_RESULTS_DIR)
	cd example && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) test/journeys --file-reporter json:../$(TEST_RESULTS_DIR)/example.json

# ═══════════════════════════════════════════════════════════════════
# § 4 — Clean
# ═══════════════════════════════════════════════════════════════════

clean:
	@$(FLUTTER) clean >/dev/null 2>&1 || true
	@rm -rf $(TEST_RESULTS_DIR)
	@echo "✓ clean"
