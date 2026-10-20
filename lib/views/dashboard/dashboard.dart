import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'edit.dart';
import 'layout.dart';
import 'style.dart';
import 'widget_registry.dart';
import 'widgets/core_status_button.dart';
import 'widgets/widgets.dart';

// Narrower columns leave the service grid's cells too tight for a status, so
// the grid takes the memory card's column instead.
const _memoryColumnMin = 290.0;

const _maxColumnWidth = 440.0;

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key, this.platform});

  /// The host's platform when null.
  final SupportPlatform? platform;

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  var _editing = false;
  final _cardKeys = <DashboardWidget, GlobalKey>{};

  void _setEditing(bool editing) {
    setState(() => _editing = editing);
  }

  GlobalKey _cardKeyOf(DashboardWidget widget) =>
      _cardKeys.putIfAbsent(widget, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final platform = widget.platform ?? SupportPlatform.currentPlatform;
    final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
    final editing = _editing;
    final gap = cardSpacingOf(context, ref.watch(viewModeProvider));
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      backgroundColor: DashboardColors.of(context).page,
      title: editing
          ? appLocalizations.editDashboard
          : appLocalizations.dashboard,
      backAction: editing ? () => _setEditing(false) : null,
      actions: [if (!editing && coreLib == null) const CoreStatusButton()],
      confirmationAction: editing
          ? IconButtonData(
              glyph: AppGlyphs.check,
              tooltip: appLocalizations.done,
              onPressed: () => _setEditing(false),
            )
          : null,
      iconActions: [
        if (!editing)
          IconButtonData(
            glyph: AppGlyphs.edit,
            tooltip: appLocalizations.editDashboard,
            onPressed: () => _setEditing(true),
          ),
      ],
      // The providers learn a resize a frame late, too late for the cards.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.biggest / scale;
          final layout = DashboardDensity.of(room);
          // Editing always uses the card column, however wide the window is,
          // so the width a card is dragged at stays the one it is read at.
          final column = editing || !layout.isDesktop;
          return DashboardDensityScope(
            density: column ? DashboardDensity.mobile : layout,
            scale: scale,
            child: column
                ? _MobileDashboard(
                    platform: platform,
                    gap: gap,
                    editing: editing,
                    cardKeyOf: _cardKeyOf,
                    onDone: () => _setEditing(false),
                  )
                : _DesktopDashboard(
                    platform: platform,
                    columns: dashboardColumnsOf(room.width),
                    gap: gap,
                  ),
          );
        },
      ),
    );
  }
}

/// Four columns fill the window, the tables taking what the rows above them
/// leave. A window too short for the tables, and every two column one, gets
/// the summary cards instead, so no list scrolls inside a page that scrolls.
///
/// The rows follow the saved order, each card keeping the width its row gives
/// it, so a card moved in the editor moves here too. Cards of one height share
/// a row, and the two tables always close the page: they are what takes the
/// height the cards above them leave.
class _DesktopDashboard extends ConsumerWidget {
  const _DesktopDashboard({
    required this.platform,
    required this.columns,
    required this.gap,
  });

  final SupportPlatform platform;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final compact = density.isCompact;
    final scale = DashboardDensityScope.scaleOf(context);
    final base = EdgeInsetsDirectional.fromSTEB(
      16,
      MediaQuery.paddingOf(context).top,
      24,
      24 + MediaQuery.paddingOf(context).bottom,
    );
    final topHeight = (compact ? 176 : 208) * scale;
    final controlHeight = (compact ? 56 : 64) * scale;
    final middleHeight = (compact ? 152 : 176) * scale;
    final tablesHeight = connectionsTableMinHeight(density, scale);
    final summaryHeight = (compact ? 112 : 120) * scale;
    final saved = ref.watch(
      dashboardStateProvider.select((state) => state.dashboardWidgets),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final room =
            constraints.maxWidth - base.horizontal - gap * (columns - 1);
        final column = math.min(room / columns, _maxColumnWidth * scale);
        final inset = (room - column * columns) / 2;
        final padding = base.copyWith(
          start: base.start + inset,
          end: base.end + inset,
        );
        double span(int units) => column * units + gap * (units - 1);
        // A row always spans the whole grid, so a short one hands what it has
        // left to its last card instead of leaving a hole.
        Widget row(List<(int, Widget)> cells) {
          final used = cells.fold(0, (sum, cell) => sum + cell.$1);
          final spare = columns - used;
          final last = cells.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              for (var index = 0; index < cells.length; index++)
                SizedBox(
                  width: span(cells[index].$1 + (index == last ? spare : 0)),
                  child: RepaintBoundary(child: cells[index].$2),
                ),
            ],
          );
        }

        final wideMiddle = column >= _memoryColumnMin * scale;
        final ordered = <(int, double, Widget)>[];
        final tables = <DashboardWidget>[];
        var listedMemory = false;
        for (final widget in saved) {
          if (!widget.platforms.contains(platform)) {
            continue;
          }
          switch (widget) {
            case DashboardWidget.currentOutbound:
              ordered.add((2, topHeight, const CurrentOutboundCard()));
            case DashboardWidget.networkSpeed:
              ordered.add((2, topHeight, _SpeedPair(gap: gap)));
            case DashboardWidget.outboundMode:
              ordered.add((2, controlHeight, const OutboundModeBar()));
            case DashboardWidget.vpnButton:
              ordered.add((2, controlHeight, const VpnTile()));
            case DashboardWidget.networkTakeover:
              ordered.add((2, controlHeight, _TakeoverPair(gap: gap)));
            case DashboardWidget.intranetIp:
              ordered.add((1, middleHeight, const IntranetIpCard()));
            case DashboardWidget.profiles:
              ordered.add((1, middleHeight, const ProfilesCard()));
            case DashboardWidget.serviceStatus:
              final units = wideMiddle ? 1 : 2;
              ordered.add((units, middleHeight, const ServiceStatusCard()));
            case DashboardWidget.memoryInfo:
              listedMemory = true;
              if (wideMiddle) {
                ordered.add((1, middleHeight, const MemoryInfo()));
              }
            case DashboardWidget.proxyGroups:
            case DashboardWidget.connectionStats:
              tables.add(widget);
          }
        }
        // The memory card was never among the phone's defaults, yet the grid
        // has always carried it, so it stays whether or not it is listed.
        if (wideMiddle && !listedMemory) {
          ordered.add((1, middleHeight, const MemoryInfo()));
        }

        final cards = <Widget>[];
        var cardsHeight = 0.0;
        var line = <(int, Widget)>[];
        var used = 0;
        var lineHeight = 0.0;
        for (final (units, height, card) in ordered) {
          // A card keeps its own height, so a height change ends a row as
          // surely as a full one does.
          final full = used + units > columns;
          if (line.isNotEmpty && (full || height != lineHeight)) {
            cards.add(SizedBox(height: lineHeight, child: row(line)));
            cardsHeight += lineHeight + gap;
            line = [];
            used = 0;
          }
          line.add((units, card));
          used += units;
          lineHeight = height;
        }
        if (line.isNotEmpty) {
          cards.add(SizedBox(height: lineHeight, child: row(line)));
          cardsHeight += lineHeight + gap;
        }
        final rowsHeight = padding.vertical + cardsHeight;

        final hasStats = tables.contains(DashboardWidget.connectionStats);
        final hasGroups = tables.contains(DashboardWidget.proxyGroups);
        Widget summaries() {
          final cells = <(int, Widget)>[];
          if (hasStats) {
            final units = hasGroups ? columns ~/ 2 : columns;
            cells.add((units, const ConnectionStatsCard()));
          }
          if (hasGroups) {
            final units = hasStats ? columns - columns ~/ 2 : columns;
            cells.add((units, const ProxyGroupsSummaryCard()));
          }
          return row(cells);
        }

        Widget tablesRow() => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            if (hasStats)
              const Expanded(
                flex: 3,
                child: RepaintBoundary(child: ConnectionsTableCard()),
              ),
            if (hasGroups)
              const Expanded(
                flex: 2,
                child: RepaintBoundary(child: ProxyGroupsCard()),
              ),
          ],
        );

        final hasTables = hasStats || hasGroups;
        final tablesFit =
            hasTables &&
            columns != 2 &&
            constraints.maxHeight >= rowsHeight + tablesHeight;
        final summaryFit =
            hasTables &&
            columns != 2 &&
            constraints.maxHeight >= rowsHeight + summaryHeight;
        // A filling bottom row is Expanded, so the page must be pinned to the
        // viewport height whenever one is added.
        final fills = tablesFit || summaryFit;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: fills ? constraints.maxHeight : null,
            child: Padding(
              padding: padding,
              child: Column(
                spacing: gap,
                children: [
                  ...cards,
                  if (tablesFit)
                    Expanded(child: tablesRow())
                  else if (summaryFit)
                    Expanded(child: summaries())
                  else if (hasTables)
                    SizedBox(height: summaryHeight, child: summaries()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeedPair extends StatelessWidget {
  const _SpeedPair({required this.gap});

  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: const [
        Expanded(
          child: RepaintBoundary(
            child: SpeedCard(direction: TrafficDirection.upload),
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            child: SpeedCard(direction: TrafficDirection.download),
          ),
        ),
      ],
    );
  }
}

class _TakeoverPair extends StatelessWidget {
  const _TakeoverPair({required this.gap});

  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: const [
        Expanded(
          child: RepaintBoundary(
            child: NetworkTakeoverTile(TakeoverSwitch.systemProxy),
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            child: NetworkTakeoverTile(TakeoverSwitch.tun),
          ),
        ),
      ],
    );
  }
}

class _MobileDashboard extends ConsumerWidget {
  const _MobileDashboard({
    required this.platform,
    required this.gap,
    required this.editing,
    required this.cardKeyOf,
    required this.onDone,
  });

  final SupportPlatform platform;
  final double gap;
  final bool editing;
  final GlobalKey Function(DashboardWidget widget) cardKeyOf;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      dashboardStateProvider.select((state) => state.dashboardWidgets),
    );
    final top = MediaQuery.paddingOf(context).top + 4;
    final bottom = 16 + BottomInsetScope.of(context);
    return CustomScrollView(
      // A viewport per card lays them all out and holds the scroll end still.
      scrollCacheExtent: editing
          ? ScrollCacheExtent.viewport(DashboardWidget.values.length.toDouble())
          : null,
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final side = dashboardMobileSideOf(constraints.crossAxisExtent);
            final widgets = [
              for (final widget in saved)
                if (widget.platforms.contains(platform)) widget,
            ];
            if (editing) {
              return DashboardEditor(
                platform: platform,
                widgets: widgets,
                cardKeyOf: cardKeyOf,
                padding: EdgeInsets.fromLTRB(side, top, side, bottom),
                gap: gap,
                onDone: onDone,
              );
            }
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(side, top, side, bottom),
              // A lazy list estimates the cards it has not laid out from the
              // ones it has; cards this uneven move the scroll end as it goes.
              sliver: SliverToBoxAdapter(
                child: Column(
                  spacing: gap,
                  children: [
                    for (final widget in widgets)
                      RepaintBoundary(
                        key: cardKeyOf(widget),
                        child: widget.card,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
