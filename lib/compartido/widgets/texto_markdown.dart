import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../nucleo/tema/colores_app.dart';

/// Muestra las respuestas de la IA (Markdown) con la tipografía de la app.
class TextoMarkdown extends StatelessWidget {
  const TextoMarkdown(this.texto, {super.key, this.color = ColoresApp.textoTitulo});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 14.5, height: 1.5, color: color);
    return MarkdownBody(
      data: texto,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: base,
        strong: base.copyWith(fontWeight: FontWeight.w700),
        em: base.copyWith(fontStyle: FontStyle.italic),
        listBullet: base,
        h1: base.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
        h2: base.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        h3: base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
        blockSpacing: 10,
        listIndent: 20,
        code: base.copyWith(fontFamily: 'monospace', fontSize: 13, backgroundColor: ColoresApp.fondoSuave),
        tableHead: base.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        tableBody: base.copyWith(fontSize: 13),
        tableBorder: TableBorder.all(color: ColoresApp.borde),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ColoresApp.borde)),
        ),
      ),
    );
  }
}
