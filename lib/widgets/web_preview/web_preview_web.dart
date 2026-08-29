import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class WebPreviewWeb extends StatefulWidget {
  final String url;

  const WebPreviewWeb({super.key, required this.url});

  @override
  State<WebPreviewWeb> createState() => _WebPreviewWebState();
}

class _WebPreviewWebState extends State<WebPreviewWeb> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _registerFactory();
  }

  @override
  void didUpdateWidget(WebPreviewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _registerFactory();
    }
  }

  void _registerFactory() {
    _viewId =
        'preview-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.transform = 'scale(1)'
          ..style.transformOrigin = '0 0';

        // Disable zoom on iframe load
        iframe.onLoad.listen((_) {
          try {
            final iframeDoc = iframe.contentWindow?.document;
            if (iframeDoc != null) {
              // Add viewport meta tag to prevent zoom
              final viewport = iframeDoc.querySelector('meta[name="viewport"]');
              if (viewport == null) {
                final meta = iframeDoc.createElement('meta');
                meta.setAttribute('name', 'viewport');
                meta.setAttribute('content',
                    'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
                iframeDoc.head?.append(meta);
              } else {
                viewport.setAttribute('content',
                    'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
              }

              // Add CSS to prevent zoom
              final style = iframeDoc.createElement('style');
              style.text = '''
                * {
                  touch-action: pan-x pan-y;
                }
                html {
                  -ms-touch-action: pan-x pan-y;
                  -ms-content-zooming: none;
                }
              ''';
              iframeDoc.head?.append(style);
            }
          } catch (e) {
            // Cross-origin restrictions may prevent access
            // This is expected for security reasons
          }
        });

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: ValueKey(_viewId),
      viewType: _viewId,
    );
  }
}

class WebPreviewWithDownload extends StatelessWidget {
  final String url;
  final String zipUrl;

  const WebPreviewWithDownload({
    super.key,
    required this.url,
    required this.zipUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebPreviewWeb(url: url),
        Positioned(
          top: 16,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: () {
              web.window.open(zipUrl, '_blank');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.download),
            label: const Text(
              'Download',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
