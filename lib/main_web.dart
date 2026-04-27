import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mercado_app/app_theme.dart';
import 'package:mercado_app/target/lojista/login/tela_selecao_mercado.dart';
// Importe apenas os Providers necessários para o Lojista
import 'package:mercado_app/services/shared/usuario_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
      ],
      child: const MercadoAppWeb(),
    ),
  );
}

class MercadoAppWeb extends StatelessWidget {
  const MercadoAppWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel Lojista',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // O fluxo de login da Web pode ser diferente do mobile
      home: const TelaSelecaoMercado(),
    );
  }
}
