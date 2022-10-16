import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:screenshot/screenshot.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: RofoodApp(),
    ),
  );
}

class RofoodApp extends StatefulWidget {
  const RofoodApp({Key? key}) : super(key: key);

  @override
  State<RofoodApp> createState() => _RofoodAppState();
}

class _RofoodAppState extends State<RofoodApp> {
  late WebViewController controller;
  ScreenshotController screenCtrl = ScreenshotController();
  Uint8List? img;
  String url = '';
  String html = '';

  Future<bool?> _bindingPrinter() async {
    final bool? result = await SunmiPrinter.bindingPrinter();
    return result;
  }

  @override
  void initState() {
    super.initState();
    _bindingPrinter();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WebView(
        initialUrl: 'https://pos.rofood.co',
        zoomEnabled: false,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController ctrl) {
          controller = ctrl;
        },
        onPageFinished: (url) async {
          if (url.contains('/print/')) {
            setState(() {
              this.url = url;
            });
            if (url.contains('/print/')) {
              html = await controller.runJavascriptReturningResult(
                  "encodeURIComponent(document.documentElement.outerHTML)");
              html = Uri.decodeComponent(html);
              html = html.substring(1, html.length - 1);
              html = html.replaceFirst(RegExp(r'</style>'), '<!--');
              html = html.replaceFirst(
                  RegExp(r'<h1 class="name_rep">مطعم المطاعم </h1>'),
                  '--></style><body><h1 class="name_rep">مطعم المطاعم </h1>');
              img = await WebcontentConverter.contentToImage(content: html);

              await SunmiPrinter.initPrinter();

              Uint8List byte = img!;
              await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
              await SunmiPrinter.startTransactionPrint(true);
              await SunmiPrinter.printImage(byte);
              await SunmiPrinter.lineWrap(1);
              await SunmiPrinter.exitTransactionPrint(true);
              await SunmiPrinter.cut();
              // });
              // screenCtrl.capture().then((value) {
              //   setState(() {
              //     img = value;
              //   });
              // });
              // showDialog(
              //     context: context, builder: (context) => Dialog());
            }
          }
        },
      ),
    );
  }
}
