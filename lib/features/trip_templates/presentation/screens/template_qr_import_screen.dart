import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'trip_template_view_screen.dart';

class TemplateQrImportScreen extends StatefulWidget {
  const TemplateQrImportScreen({super.key});

  @override
  State<TemplateQrImportScreen> createState() => _TemplateQrImportScreenState();
}

class _TemplateQrImportScreenState extends State<TemplateQrImportScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentContext = context;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Trip Template QR')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: (ctrl) {
          controller = ctrl;
          ctrl.scannedDataStream.listen((scanData) {
            if (!_scanned) {
              _scanned = true;
              controller?.pauseCamera();
              if (!parentContext.mounted) return;
              Navigator.pushReplacement(
                parentContext,
                MaterialPageRoute(
                  builder: (_) =>
                      TripTemplateViewScreen(templateId: scanData.code ?? ''),
                ),
              );
            }
          });
        },
      ),
    );
  }
}
