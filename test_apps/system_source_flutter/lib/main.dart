import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:time_machine2/time_machine2.dart';

/// A minimal app that hosts the integration tests in integration_test/. When
/// run on its own, it shows what DateTimeZoneProviders.system reports.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimeMachine.initialize({'rootBundle': rootBundle});
  runApp(SystemSourceApp(summary: await describeSystemSource()));
}

Future<String> describeSystemSource() async {
  try {
    var provider = await DateTimeZoneProviders.system;
    var zone = await provider.getSystemDefault();
    return '${provider.versionId}\n'
        '${provider.ids.length} zones\n'
        'System default: ${zone.id}';
  } catch (error) {
    return 'SystemDateTimeZoneSource failed: $error';
  }
}

class SystemSourceApp extends StatelessWidget {
  const SystemSourceApp({super.key, required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SystemDateTimeZoneSource',
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(summary),
            ),
          ),
        ),
      );
}
