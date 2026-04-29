import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mercado_app/services/shared/mercado_shared_provider.dart';
import 'package:mercado_app/target/lojista/login/tela_selecao_mercado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';

// Importações dos serviços e modelos
import 'package:mercado_app/services/cliente/carrinho_service.dart';
import 'package:mercado_app/target/cliente/pages/main_navigation.dart';
import 'package:mercado_app/target/shared/pages/login_page.dart';
import 'package:mercado_app/target/funcionario/pages/tela_selecao_modo.dart';

import 'package:mercado_app/services/shared/user_provider.dart';
import 'package:mercado_app/services/funcionario/funcionario_provider.dart';

import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "chaves.env");

  // 1. INICIALIZAÇÃO DO SUPABASE
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  final usuarioProvider = UserProvider();
  await usuarioProvider.inicializar();

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
        ChangeNotifierProvider.value(value: usuarioProvider),
        ChangeNotifierProvider(create: (_) => MercadoSharedProvider()),
        ChangeNotifierProxyProvider<MercadoSharedProvider, FuncionarioProvider>(
          create: (context) => FuncionarioProvider(
            isFuncionario: ehFuncionarioPersistido,
            mercadoId: mercadoIdPersistido,
            funcionarioId: funcionarioIdPersistido,
            mercadoSharedProvider:
                Provider.of<MercadoSharedProvider>(context, listen: false),
          ),
          update: (context, mercadoShared, funcionario) =>
              funcionario!..mercadoSharedProvider = mercadoShared,
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
      home: const UpdateChecker(child: PlatformSelector()),
    );
  }
}

class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    // Só verifica se for Android e não for Web
    if (!kIsWeb && Platform.isAndroid) {
      _verificarAtualizacao();
    }
  }

  Future<void> _verificarAtualizacao() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Opção 1: performImmediateUpdate (Trava o app até atualizar)
        // Opção 2: showUpdateDialog (Aviso nativo do Google)
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint("Play Store Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final funcProv = context.watch<FuncionarioProvider>();
    final usuarioProv = context.read<UserProvider>();

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
