import 'package:YWallet/accounts.dart';
import 'package:YWallet/settings.pb.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:gap/gap.dart';
import 'package:k_chart/extension/map_ext.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appsettings.dart';
import 'generated/intl/messages.dart';

class ThemeEditorTab extends StatefulWidget {
  final AppSettings appSettings;
  ThemeEditorTab(this.appSettings);

  @override
  State<StatefulWidget> createState() => _ThemeEditorState();
}

class _ThemeEditorState extends State<ThemeEditorTab>
    with AutomaticKeepAliveClientMixin {
  final formKey = GlobalKey<FormBuilderState>();
  late String _name = widget.appSettings.palette.name;
  late bool _dark = widget.appSettings.palette.dark;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = S.of(context);
    final schemes = FlexScheme.values.toList();
    return FormBuilder(
        key: formKey,
        child: Column(children: [
          FormBuilderSwitch(name: 'dark', title: Text(s.dark),
          initialValue: _dark, onChanged: (v) => setState(() => setDark(v!)),),
          Gap(16),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: schemes.map((s) {
                final cs = FlexColorScheme.light(scheme: s).colorScheme!;
                return ElevatedButton(
                    onPressed: () => setState(() => pick(s.name)),
                    child: Text(s.name),
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: cs.primary));
              }).toList())
        ]));
  }

  pick(String name) {
    _name = name;
    Future(update);
  }

  setDark(bool v) {
    _dark = v;
    Future(update);
  }

  update() async {
    final cp = ColorPalette(name: _name, dark: _dark);
    widget.appSettings.palette = cp;
    appSettings.palette = cp;
    aaSequence.settingsSeqno += 1;
  }

  bool get wantKeepAlive => true;
}
