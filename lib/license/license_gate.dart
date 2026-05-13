import 'package:flutter/material.dart';
import '../pages/generator_home_page.dart';
import 'activation_screen.dart';
import 'expired_screen.dart';
import 'license_service.dart';

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});

  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  final LicenseService licenseService = LicenseService();

  LicenseStatus? status;

  @override
  void initState() {
    super.initState();
    loadLicenseStatus();
  }

  Future<void> loadLicenseStatus() async {
    final result = await licenseService.checkLicenseStatus();

    if (!mounted) return;

    setState(() {
      status = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (status!) {
      case LicenseStatus.notActivated:
        return ActivationPage(
          onActivated: loadLicenseStatus,
        );

      case LicenseStatus.active:
        return const GeneratorHomePage();

      case LicenseStatus.expired:
        return const LicenseExpiredPage();
    }
  }
}