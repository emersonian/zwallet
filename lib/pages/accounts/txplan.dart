import 'dart:async';

import 'package:YWallet/main.dart';
import 'package:YWallet/pages/utils.dart';
import 'package:YWallet/settings.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:warp_api/data_fb_generated.dart';
import 'package:warp_api/warp_api.dart';

import '../../accounts.dart';
import '../../coin/coins.dart';
import '../../generated/intl/messages.dart';

class TxPlanPage extends StatefulWidget {
  final bool signOnly;
  final String plan;
  final String tab;
  TxPlanPage(this.plan, {required this.tab, this.signOnly = false});
  
  @override
  State<StatefulWidget> createState() => _TxPlanState();
}

class _TxPlanState extends State<TxPlanPage> with WithLoadingAnimation {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final txplan = TxPlanWidget.fromPlan(widget.plan, signOnly: widget.signOnly);
    return Scaffold(
        appBar: AppBar(
          title: Text(s.txPlan),
          actions: [
            IconButton(
              onPressed: () => exportRaw(context),
              icon: Icon(MdiIcons.snowflake),
            ),
            IconButton(
              onPressed: () => widget.signOnly ? sign(context) : send(context),
              icon: widget.signOnly ? FaIcon(FontAwesomeIcons.signature) : Icon(Icons.send),
            )
          ],
        ),
        body: wrapWithLoading(SingleChildScrollView(child: txplan)));
  }

  send(BuildContext context) {
      GoRouter.of(context).go('/${widget.tab}/submit_tx', extra: widget.plan);
  }

  exportRaw(BuildContext context) {
      GoRouter.of(context).go('/account/export_raw_tx', extra: widget.plan);
  }

  sign(BuildContext context) async {
    await load(() async {
      final txBin = await WarpApi.signOnly(aa.coin, aa.id, widget.plan);
      GoRouter.of(context).go('/more/cold/signed', extra: txBin);
    });
  }
}

class TxPlanWidget extends StatelessWidget {
  final String plan;
  final TxReport report;
  final bool signOnly;

  TxPlanWidget(this.plan, this.report, {required this.signOnly});

  factory TxPlanWidget.fromPlan(String plan, {bool signOnly = false}) {
    final report = WarpApi.transactionReport(aa.coin, plan);
    return TxPlanWidget(plan, report, signOnly: signOnly);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = Theme.of(context);
    final c = coins[aa.coin];
    final supportsUA = c.supportsUA;
    final rows = report.outputs!
        .map((e) => DataRow(cells: [
              DataCell(Text('...${trailing(e.address!, 12)}')),
              DataCell(Text('${poolToString(s, e.pool)}')),
              DataCell(Text('${amountToString2(e.amount)}')),
            ]))
        .toList();
    final invalidPrivacy = report.privacyLevel < settings.minPrivacyLevel;

    return Column(children: [
      Row(children: [
        Expanded(
            child: DataTable(
                headingRowHeight: 32,
                columnSpacing: 32,
                columns: [
                  DataColumn(label: Text(s.address)),
                  DataColumn(label: Text(s.pool)),
                  DataColumn(label: Expanded(child: Text(s.amount))),
                ],
                rows: rows))
      ]),
      Divider(
        height: 16,
        thickness: 2,
        color: t.primaryColor,
      ),
      ListTile(
          visualDensity: VisualDensity.compact,
          title: Text(s.transparentInput),
          trailing: Text(amountToString(report.transparent, MAX_PRECISION))),
      ListTile(
          visualDensity: VisualDensity.compact,
          title: Text(s.saplingInput),
          trailing: Text(amountToString(report.sapling, MAX_PRECISION))),
      if (supportsUA)
        ListTile(
            visualDensity: VisualDensity.compact,
            title: Text(s.orchardInput),
            trailing: Text(amountToString(report.orchard, MAX_PRECISION))),
      ListTile(
          visualDensity: VisualDensity.compact,
          title: Text(s.netSapling),
          trailing: Text(amountToString(report.netSapling, MAX_PRECISION))),
      if (supportsUA)
        ListTile(
            visualDensity: VisualDensity.compact,
            title: Text(s.netOrchard),
            trailing: Text(amountToString(report.netOrchard, MAX_PRECISION))),
      ListTile(
          visualDensity: VisualDensity.compact,
          title: Text(s.fee),
          trailing: Text(amountToString(report.fee, MAX_PRECISION))),
      privacyToString(context, report.privacyLevel)!,
      if (invalidPrivacy)
        Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(s.privacyLevelTooLow, style: t.textTheme.bodyLarge)),
    ]);
  }
}

String poolToString(S s, int pool) {
  switch (pool) {
    case 0:
      return s.transparent;
    case 1:
      return s.sapling;
  }
  return s.orchard;
}

Widget? privacyToString(BuildContext context, int privacyLevel) {
  final m = S
      .of(context)
      .privacy(getPrivacyLevel(context, privacyLevel).toUpperCase());
  switch (privacyLevel) {
    case 0:
      return getColoredButton(m, Colors.red);
    case 1:
      return getColoredButton(m, Colors.orange);
    case 2:
      return getColoredButton(m, Colors.yellow);
    case 3:
      return getColoredButton(m, Colors.green);
  }
  return null;
}

ElevatedButton getColoredButton(String text, Color color) {
  var foregroundColor =
      color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  return ElevatedButton(
      onPressed: null,
      child: Text(text),
      style: ElevatedButton.styleFrom(
          disabledBackgroundColor: color,
          disabledForegroundColor: foregroundColor));
}
