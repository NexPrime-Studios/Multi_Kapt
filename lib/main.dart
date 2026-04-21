import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mercado_app/target/lojista/login/tela_selecao_mercado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importações dos serviços e modelos
import 'package:mercado_app/services/carrinho_service.dart';
import 'package:mercado_app/target/cliente/pages/main_navigation.dart';
import 'package:mercado_app/target/shared/pages/login_page.dart';
import 'package:mercado_app/target/funcionario/pages/selecao_modo_page.dart';

import 'package:mercado_app/services/usuario_provider.dart';
import 'package:mercado_app/services/lojista_provider.dart';
import 'package:mercado_app/services/funcionario_provider.dart';

import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAÇÃO DO SUPABASE
  await Supabase.initialize(
    url: 'https://porhtwwbqpljzwukxotu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvcmh0d3dicXBsanp3dWt4b3R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NjMyOTIsImV4cCI6MjA5MjEzOTI5Mn0.BE5ZID-JSqqyp4xv2CEIgSb4ZyuiubuhzaU1J4SoDng',
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
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
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
      title: 'Multi Kapt',
      theme: AppTheme.lightTheme,
      home: const PlatformSelector(),
    );
  }
}

// lib/main.dart

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final funcProv = context.watch<FuncionarioProvider>();
    final usuarioProv = context.read<UsuarioProvider>();

    // 1. Identifica se é Web/Desktop (PC)
    final bool ehPC =
        kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    // 2. Notifica o Provider sobre a plataforma atual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      usuarioProv.configurarPlataforma(paraMobile: !ehPC);
    });

    if (ehPC) {
      return const AuthWrapperLojista();
    }

    if (funcProv.isFuncionario || funcProv.mostrarSelecao) {
      return const SelecaoModoPage();
    }

    // 3. Se não for funcionário, segue como cliente (Mobile)
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
              body: Center(
                  child: CircularProgressIndicator(color: Colors.lightBlue)));
        }

        if (snapshot.data == null || snapshot.data?.session == null) {
          return const LoginPage();
        }

        return const TelaSelecaoMercado();
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
        return LoginPage(
          aoPular: () {
            setState(() => _ignorarLogin = true);
          },
        );
      },
    );
  }
}
