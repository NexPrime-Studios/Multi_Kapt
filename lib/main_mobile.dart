import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mercado_app/app_theme.dart';
import 'package:mercado_app/target/shared/pages/login_page.dart';
import 'package:mercado_app/target/cliente/pages/main_navigation.dart';
import 'package:mercado_app/target/funcionario/pages/main_navigation_funcionario.dart';
// Importe apenas os Providers necessários para o Mobile
import 'package:mercado_app/services/shared/usuario_provider.dart';
import 'package:mercado_app/services/cliente/carrinho_service.dart';
import 'package:mercado_app/services/funcionario/funcionario_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => CarrinhoService()),
      ],
      child: const MercadoAppMobile(),
    ),
  );
}

class MercadoAppMobile extends StatelessWidget {
  const MercadoAppMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercado App',
      theme: AppTheme.lightTheme, // Usando seu arquivo de tema
      debugShowCheckedModeBanner: false,
      // Aqui você decide para onde o usuário vai
      home: const LoginPage(),
    );
  }
}
