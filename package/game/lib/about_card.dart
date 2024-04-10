import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutCard extends StatelessWidget {
  final String version;
  final List<Widget> others;

  const AboutCard({
    super.key,
    required this.version,
    this.others = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('${UI.findUp.tr} v$version'),
            trailing: ElevatedButton.icon(
              onPressed: () =>
                  launchUrlString('https://github.com/whimsy-ai/find_up'),
              icon: FaIcon(FontAwesomeIcons.github),
              label: Text('Github'),
            ),
          ),
          Divider(),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.googlePlay),
            trailing: Icon(Icons.link),
            title: Text(UI.android.tr),
            subtitle: Text('Google Play'),
            onTap: () => launchUrlString(
                'https://play.google.com/store/apps/details?id=whimsy_ai.find_up'),
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.steam),
            trailing: Icon(Icons.link),
            title: Text('Steam'),
            subtitle: Text(UI.supportSteamWorkshop.tr),
            onTap: () =>
                launchUrlString('https://store.steampowered.com/app/2550370/'),
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.microsoft),
            trailing: Icon(Icons.link),
            title: Text(UI.msStore.tr),
            onTap: () {
              launchUrlString(
                  'https://www.microsoft.com/store/productid/9N99R98Z0QR3?ocid=pdpshare');
            },
          ),
          ...others,
          Divider(),
          ListTile(
            title: Text(UI.contactMe.tr),
            trailing: Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: FaIcon(Icons.discord_rounded),
                  label: Text('Discord'),
                  onPressed: () =>
                      launchUrlString('https://discord.gg/cy6QTzSpJw'),
                ),
                ElevatedButton.icon(
                  icon: FaIcon(FontAwesomeIcons.github),
                  label: Text('Github'),
                  onPressed: () => launchUrlString('https://github.com/gzlock'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
