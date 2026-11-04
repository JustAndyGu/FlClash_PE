---
name: upstream-merge
description: Use when merging upstream chen08209/FlClash into this fork, or after a merge dropped, conflicted with, or silently reverted the fork's own changes, to restore the fork-specific code.
---

# Upstream Merge

## When To Use

After a `git merge` or `reset` from `chen08209/FlClash`, when the merge took upstream's side, conflicted, or silently left the fork's edits behind. Not for feature work.

## Ground Rules

- Upstream wins wherever the fork intentionally made no change. Restore only the items below, and keep each diff surgical.
- Read the current upstream file before editing. Upstream renames, splits, and moves code between releases; the paths here are hints, not contracts.
- `lib/l10n/l10n.dart` and `lib/l10n/intl/messages_all.dart` are generated. Edit them only to delete locales; never restructure them.
- Tray and app icon assets, and `README*`, are the maintainer's own work. Never regenerate or restore them.

## Always Restore

### 1. Drop es / fr / ko

Six files disappear: `arb/intl_{es,fr,ko}.arb` and `lib/l10n/intl/messages_{es,fr,ko}.dart`. A merge may leave them as **0-byte files** instead of deleting them; remove the files either way.

Five places must agree:

- `messages_all.dart`: the three imports, `_deferredLibraries` entries, `_findExact` cases.
- `l10n.dart`: the three `Locale.fromSubtags` in `supportedLocales`.
- `l10n_labels.dart`: the `LocaleL10n` switch arms.
- `.agents/skills/localization/SKILL.md`: the ARB file list.
- `test/l10n/localization_contract_test.dart`: the three imports and `lookups` entries.

Keep the `AppLocalizations.es/fr/ko` getters: they are ARB message keys (language names), not locale support.

### 2. Fork identity

- `lib/common/constant.dart`: `repository = 'JustAndyGu/FlClash_PE'`.
- `windows/packaging/exe/make_config.yaml`: `publisher_url`.
- Both must match `github.repository == 'JustAndyGu/FlClash_PE'` in `.github/workflows/build.yaml`.

### 3. Tray follows system brightness

- `getTrayIcon` takes `required Brightness brightness`.
- Name selection: stopped state on a non-macOS light shell uses `status_1_b`, every other state uses `status_<n>`. macOS stays a template icon.
- `AppTray.update` passes `read(systemBrightnessProvider)`.
- `TrayManager` listens to `systemBrightnessProvider` when `!system.isMacOS`.
- `test/common/tray_test.dart` passes `brightness` in every call.
- Resource names the code expects, supplied by the maintainer: `assets/images/tray/unix/status_1_b.png` plus the `2.0x/3.0x/4.0x` variants, and `assets/images/tray/windows/status_1_b.ico`.

### 4. Dashboard: edit anywhere, order on desktop

- The edit action shows whenever `!editing`, at any window size.
- Nothing forces `_editing = false` on resize.
- Inside `LayoutBuilder`: `column = editing || !layout.isDesktop`; editing renders the mobile card column with `DashboardDensity.mobile`, so the drag width equals the reading width.
- The desktop grid is a `ConsumerWidget` that reads `dashboardStateProvider.dashboardWidgets` and lays cards in saved order: fixed `(units, height, card)` per widget, a new row on height change or overflow, spare units handed to the last cell, tables/summaries last and only when present.
- `defaultDashboardWidgets` keeps `profiles` before `serviceStatus`.
- Drag start: upstream may already use an immediate `ReorderDragStartListener`; keep upstream's listener unless touch scrolling breaks.

### 5. Narrow CI

Apply the intent, not the exact lines: release only on `v*` tags; no `desktop` or `android` jobs; the build matrix is Windows and Linux only (amd64 + arm64); no Telegram, Homebrew, Fdroid, or changelog-verification steps; `upload.needs` lists only the surviving jobs; `pages.yaml` is manual-only. `release_template.md` lists only Windows and Linux and links this fork.

## Submodule: plugins/prism_ui

Upstream moved the sidebar out of `lib/ui/sidebar.dart` into this submodule.

- `.gitmodules` points at `https://github.com/JustAndyGu/prism_ui.git`.
- Edit inside the submodule, commit, push, then `git add plugins/prism_ui` in the parent.
- Never stage the submodule before its commit exists on the remote; a clone would break.
- IDEs check out `branch = main` when the submodule is opened, which hides a detached commit and makes the file look unmodified. Compare `git -C plugins/prism_ui rev-parse HEAD` with `git -C plugins/prism_ui ls-remote origin main`.
- Sidebar sizing: `_itemSize` 48, `_compactMargin` 4, `_compactWidth = _itemSize + _compactMargin * 2`. Tests expect a collapsed width of 56 and a row of `(54, 48)` where window controls are 78 wide.

## Verify

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test test/common/tray_test.dart test/widgets/sidebar_test.dart \
  test/pages/home_test.dart test/views/dashboard/edit_test.dart \
  test/l10n/localization_contract_test.dart
```

## Case By Case

Decide with the maintainer per merge, do not assume: version bump and release tag, whether an upstream refactor made a restored behavior redundant, whether a dropped CI job should return, and any icon asset change.
