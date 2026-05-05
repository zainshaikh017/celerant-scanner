import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CelerantWebView extends StatefulWidget {
  const CelerantWebView({super.key});

  @override
  State<CelerantWebView> createState() => _CelerantWebViewState();
}

class _CelerantWebViewState extends State<CelerantWebView> {
  late final WebViewController controller;

  // ✅ Correct IDs
  final String fieldId = "upc";
  final String formId = "checkSizeForm";
  bool isPageLoaded = false;
  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            isPageLoaded = true;
            print("Page Loaded ✅");
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          "https://topsandbottoms.celerantwebservices.com/web_admin/style/checksize.cfm",
        ),
      );
  }

  Future<void> autoFillAndSubmit(String scannedValue) async {
    String safeValue = scannedValue.replaceAll('"', '\\"');

    final jsCode =
        '''
(function() {
  var input = document.getElementById("$fieldId");
  if (!input) {
    console.log("Field not found ❌ (maybe login page)");
    return;
  }

  input.value = "$safeValue";
  input.dispatchEvent(new Event('input', { bubbles: true }));
  input.dispatchEvent(new Event('change', { bubbles: true }));

  var form = document.getElementById("$formId");
  if (form) {
    form.submit();
  }
})();
''';

    await controller.runJavaScript(jsCode);
  }

  /// Scanner Screen Open
  Future<void> openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (result != null && result is String) {
      if (!isPageLoaded) {
        print("Page not ready ❌");
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await autoFillAndSubmit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Celerant Panel"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: openScanner,
            icon: const Icon(Icons.camera_alt),
          ),
          IconButton(
            onPressed: () async {
              if (!isPageLoaded) {
                print("Page not ready ❌");
                return;
              }

              String testBarcode = "G7407CK"; // 👈 yahan apni test value daalo

              await Future.delayed(const Duration(milliseconds: 300));
              await autoFillAndSubmit(testBarcode);
            },
            icon: const Icon(Icons.bug_report), // better icon for testing
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}

/// Barcode Scanner Screen
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;

          final barcode = capture.barcodes.first.rawValue;

          if (barcode != null && barcode.isNotEmpty) {
            scanned = true;
            Navigator.pop(context, barcode);
          }
        },
      ),
    );
  }
}
