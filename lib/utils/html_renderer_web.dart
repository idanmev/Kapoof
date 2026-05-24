import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildHtmlView(String htmlContent, String viewId) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id, {Object? params}) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.setAttribute('srcdoc', htmlContent);
      return iframe;
    },
  );
  return HtmlElementView(viewType: viewId);
}

void openHtmlInNewTab(String htmlContent) {
  final blob = web.Blob(
    [htmlContent.toJS].toJS,
    web.BlobPropertyBag(type: 'text/html'),
  );
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
}

void downloadBytes(List<int> bytes, String filename, String mimeType) {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.setAttribute('download', filename);
  anchor.click();
  web.URL.revokeObjectURL(url);
}

void printImage(List<int> pngBytes) {
  final base64Str = base64Encode(pngBytes);
  final html = '''
<!DOCTYPE html><html><head><title>Print</title>
<style>
  @media print { @page { margin: 1cm; } body { margin: 0; } }
  body { display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: white; }
  img { max-width: 100%; max-height: 100vh; }
</style>
</head><body><img src="data:image/png;base64,$base64Str" onload="window.print();" /></body></html>
''';
  final blob = web.Blob(
    [html.toJS].toJS,
    web.BlobPropertyBag(type: 'text/html'),
  );
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
}

void printHtml(String htmlContent) {
  final blob = web.Blob(
    [htmlContent.toJS].toJS,
    web.BlobPropertyBag(type: 'text/html'),
  );
  final url = web.URL.createObjectURL(blob);
  final printWindow = web.window.open(url, '_blank');
  if (printWindow == null) return;
  printWindow.addEventListener(
    'load',
    ((web.Event _) {
      printWindow.print();
    }).toJS,
  );
}
