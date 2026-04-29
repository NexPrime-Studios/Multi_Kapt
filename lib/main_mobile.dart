import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mercado_app/app_theme.dart';
import 'package:mercado_app/target/shared/pages/login_page.dart';
// Importe apenas os Providers necessários para o Mobile
import 'package:mercado_app/services/shared/user_provider.dart';
import 'package:mercado_app/services/cliente/carrinho_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
