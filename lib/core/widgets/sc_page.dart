import 'package:flutter/material.dart';

import 'app_chrome.dart';

/// Estructura común de pantalla: barra SafeCore, título, subtítulo y
/// contenido desplazable con "tirar para actualizar".
class ScPage extends StatelessWidget {
  const ScPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onRefresh,
    this.floatingActionButton,
    this.headerTrailing,
    this.showConnectivityBanner = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final Widget? headerTrailing;

  /// Para pantallas fuera de la navegación inferior (que ya lo muestra).
  final bool showConnectivityBanner;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (headerTrailing != null) headerTrailing!,
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
    return Scaffold(
      appBar: const ScAppBar(),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          showConnectivityBanner ? const ConnectivityBanner() : null,
      body: onRefresh == null
          ? list
          : RefreshIndicator(onRefresh: onRefresh!, child: list),
    );
  }
}

/// Separador vertical estándar entre tarjetas.
const kGap = SizedBox(height: 12);
