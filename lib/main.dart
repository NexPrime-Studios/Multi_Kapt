import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importações dos serviços e modelos
import 'package:mercado_app/services/carrinho_service.dart';
import 'package:mercado_app/target/lojista/login/login_lojista_page.dart';
import 'package:mercado_app/target/lojista/pages/tela_homepage_lojista.dart';
import 'package:mercado_app/target/cliente/pages/main_navigation.dart';
import 'package:mercado_app/target/cliente/pages/login_page_cliente.dart';
import 'package:mercado_app/target/funcionario/pages/selecao_modo_page.dart';

import 'package:mercado_app/services/cliente_provider.dart';
import 'package:mercado_app/services/lojista_provider.dart';
import 'package:mercado_app/services/funcionario_provider.dart';

import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAÇÃO DO SUPABASE
  await Supabase.initialize(
    url: 'https://lqgloatgwbmlftsmbkew.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZ2xvYXRnd2JtbGZ0c21ia2V3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2OTQxMjMsImV4cCI6MjA5MTI3MDEyM30.oG8HpOJ6cwVd3ZW4O3oNHoS7PwabyLWC9nEe2Recevw',
  );

  // 2. VERIFICAÇÃO LOCAL INSTANTÂNEA (Persistência do Funcionário)
  final prefs = await SharedPreferences.getInstance();
  final bool ehFuncionarioPersistido = prefs.getBool('is_funcionario') ?? false;
  final String? mercadoIdPersistido = prefs.getString('mercado_vinculado_id');
  final String? funcionarioIdPersistido = prefs.getString('funcionario_id');

  WakelockPlus.enable();
  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarrinhoService()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => LojistaProvider()),
        ChangeNotifierProvider(
          create: (_) => FuncionarioProvider(
            isFuncionario: ehFuncionarioPersistido,
            mercadoId: mercadoIdPersistido,
            funcionarioId: funcionarioIdPersistido,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mercado Multi',
      theme: AppTheme.lightTheme,
      home: const PlatformSelector(),
    );
  }
}

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final funcProv = context.watch<FuncionarioProvider>();

    // 1. Se for Web/Desktop, mantém o Lojista
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return const AuthWrapperLojista();
    }

    if (funcProv.isFuncionario || funcProv.mostrarSelecao) {
      return const SelecaoModoPage();
    }

    // 3. Se não for funcionário, segue como cliente
    return const AuthWrapperCliente();
  }
}

class AuthWrapperLojista extends StatelessWidget {
  const AuthWrapperLojista({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const HomePageLojista();
        }

        return const LoginLojistaPage();
      },
    );
  }
}

class AuthWrapperCliente extends StatefulWidget {
  const AuthWrapperCliente({super.key});

  @override
  State<AuthWrapperCliente> createState() => _AuthWrapperClienteState();
}

class _AuthWrapperClienteState extends State<AuthWrapperCliente> {
  bool _ignorarLogin = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // Se estiver logado OU o utilizador escolheu ignorar, vai para a navegação do cliente
        if (session != null || _ignorarLogin) {
          return const MainNavigationCliente();
        }

        // Caso contrário, mostra a tela de login inicial do cliente
        return LoginPageCliente(
          aoPular: () {
            setState(() => _ignorarLogin = true);
          },
        );
      },
    );
  }
}
