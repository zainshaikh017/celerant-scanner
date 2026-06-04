import 'package:flutter/foundation.dart';
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
          onPageFinished: (url) async {
            isPageLoaded = true;
            print("Page Loaded ✅");
            // await injectResponsiveCss();
            await injectResponsiveCss();
            await disableClicks();
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
    // form.submit();
    form.submit();

setTimeout(function() {
   console.log("submitted");
}, 1000);
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

  Future<void> injectResponsiveCss() async {
    const css = r'''
/* Hide menu */
ul#main-nav {
  display: none !important;
}

/* Style Details table */
fieldset.table.styledetails {
  width: 100% !important;
  max-width: 100% !important;
  display: block !important;
  overflow-x: auto !important;
  overflow-y: hidden !important;
  -webkit-overflow-scrolling: touch !important;
}

/* Keep desktop width */
fieldset.table.styledetails table.itemReport {
  width: 775px !important;
  min-width: 775px !important;
  max-width: none !important;
}

/* Column layout */
fieldset.table.styledetails tr.title {
  display: inline-block !important;
  float: left !important;
}

fieldset.table.styledetails table.itemReport tr.title th {
  color: #000000 !important;
  padding: 5.5px !important;
  display: block !important;
  height: 31px !important;
  white-space: nowrap !important;
}

fieldset.table.styledetails tr.record {
  display: flex !important;
  flex-direction: column !important;
  float: left !important;
}

fieldset.table.styledetails tr.record th {
  background-color: #ffffff !important;
  color: #000000 !important;
  padding: 5px !important;
  text-align: center !important;
  border: 1px solid #414042 !important;
  height: 31px !important;
  white-space: nowrap !important;
}

fieldset.table.styledetails table.itemReport tr.record td {
  display: block !important;
  height: 31px !important;
  white-space: nowrap !important;
}

fieldset.table.styledetails tr.total {
  display: inline-block !important;
  float: left !important;
}

fieldset.table.styledetails table.itemReport tr.total td {
  display: block !important;
  height: 31px !important;
  white-space: nowrap !important;
}

/* Mobile Fix */
@media screen and (max-width: 768px) {

  body {
    overflow-x: auto !important;
  }

  fieldset.table.styledetails {
    overflow-x: auto !important;
    overflow-y: hidden !important;
  }

  fieldset.table.styledetails table.itemReport {
    width: 775px !important;
    min-width: 775px !important;
  }

  fieldset.table.styledetails th,
  fieldset.table.styledetails td {
    font-size: 12px !important;
    white-space: nowrap !important;
  }
}
''';

    final js =
        """
  (function() {
    var style = document.createElement('style');
    style.innerHTML = `$css`;
    document.head.appendChild(style);
  })();
  """;

    await controller.runJavaScript(js);
  }

  Future<void> disableClicks() async {
    const js = '''
(function() {

  // Disable all links
  document.querySelectorAll('a').forEach(function(el) {
    el.style.pointerEvents = 'none';
  });

  // Disable buttons except form submit
  document.querySelectorAll('button').forEach(function(el) {
    el.disabled = true;
  });

  // Disable menu clicks
  document.querySelectorAll('li').forEach(function(el) {
    el.style.pointerEvents = 'none';
  });

  // Disable onclick
  document.querySelectorAll('*').forEach(function(el) {
    el.onclick = null;
  });

})();
''';

    await controller.runJavaScript(js);
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
          if (kDebugMode)
            IconButton(
              onPressed: () async {
                if (!isPageLoaded) {
                  print("Page not ready ❌");
                  return;
                }

                String testBarcode =
                    "AH7860-102"; // 👈 yahan apni test value daalo

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
