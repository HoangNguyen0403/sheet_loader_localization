import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 26),
              margin: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: const Text(
                'Choose language',
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            buildSwitchListTileMenuItem(
                context: context,
                title: 'عربي',
                subtitle: 'عربي',
                locale:
                    context.supportedLocales[1] //BuildContext extension method
                ),
            buildDivider(),
            buildSwitchListTileMenuItem(
                context: context,
                title: 'English',
                subtitle: 'English',
                locale: EasyLocalization.of(context)?.supportedLocales[0]),
            buildDivider(),
            buildSwitchListTileMenuItem(
                context: context,
                title: 'German',
                subtitle: 'German',
                locale: EasyLocalization.of(context)?.supportedLocales[2]),
            buildDivider(),
            buildSwitchListTileMenuItem(
                context: context,
                title: 'Русский',
                subtitle: 'Русский',
                locale: EasyLocalization.of(context)?.supportedLocales[3]),
            buildDivider(),
            buildSwitchListTileMenuItem(
                context: context,
                title: 'Vietnamese',
                subtitle: 'Vietnamese',
                locale: EasyLocalization.of(context)?.supportedLocales[4]),
            buildDivider(),
          ],
        ),
      ),
    );
  }

  Container buildDivider() => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        child: const Divider(
          color: Colors.grey,
        ),
      );

  Container buildSwitchListTileMenuItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    Locale? locale,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 5,
      ),
      child: ListTile(
          dense: true,
          // isThreeLine: true,
          title: Text(
            title,
          ),
          subtitle: Text(
            subtitle,
          ),
          onTap: () async {
            context.setLocale(
                locale ?? const Locale("en")); //BuildContext extension method
            Navigator.pop(context);
          }),
    );
  }
}
