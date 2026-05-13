import 'package:flutter/material.dart';
import 'license_service.dart';

class ActivationPage extends StatefulWidget {
  final Future<void> Function() onActivated;

  const ActivationPage({
    super.key,
    required this.onActivated,
  });

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController codeController = TextEditingController();
  final LicenseService licenseService = LicenseService();

  bool isLoading = false;
  bool isClick = false;
  String? errorMessage;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> activateApp() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final success = await licenseService.activate(codeController.text);

    if (!mounted) return;

    if (!success) {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid activation code.';
      });
      return;
    }

    await widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 54,
                color: Color(0xFFE5322D),
              ),
              const SizedBox(height: 18),
              const Text(
                'Activate A R S Studio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter your activation code to unlock the app for 100 days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: codeController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => activateApp(),
                obscureText: isClick? false : true,
                decoration: InputDecoration(
                  labelText: 'Activation Code',
                  hintText: 'Enter code',
                  suffixIcon: IconButton(
                      onPressed: (){
                        setState(() {
                          isClick = !isClick;
                        });
                      },
                      icon: Icon(isClick? Icons.visibility : Icons.visibility_off)
                  ),
                  prefixIcon: const Icon(Icons.key_rounded),
                  errorText: errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : activateApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5322D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Activate App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}