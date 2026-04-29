import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/usuario.dart';
import 'user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _authService = UserService();
  Usuario? _usuario;
  bool _isMobile = !kIsWeb;
  String _cidadeLocal = "";
  String _estadoLocal = "";

  bool get isMobile => _isMobile;
  bool get isPC => !_isMobile;
  Usuario? get usuario => _usuario;
  bool get temPerfil => _usuario != null;

  String get cidade => _usuario?.cidade ?? _cidadeLocal;
  String get estado => _usuario?.estado ?? _estadoLocal;
  bool get temLocalizacao => cidade.isNotEmpty;

  Future<void> inicializar() async {
    await carregarPerfil();
    if (!temLocalizacao) {
      final prefs = await SharedPreferences.getInstance();
      _cidadeLocal = prefs.getString('cidade_local') ?? "";
      _estadoLocal = prefs.getString('estado_local') ?? "";
      notifyListeners();
    }
  }

  Future<void> definirLocalizacaoLocal(String cidade, String estado) async {
    _cidadeLocal = cidade;
    _estadoLocal = estado;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cidade_local', cidade);
    await prefs.setString('estado_local', estado);

    notifyListeners();
  }

  void configurarPlataforma({required bool paraMobile}) {
    _isMobile = paraMobile;
    notifyListeners();
  }

  /// Atualiza o estado local do usuário e notifica a interface
  void atualizarUsuario(Usuario novoUsuario) {
    _usuario = novoUsuario;
    notifyListeners();
  }

  /// Busca os dados do perfil no banco de dados e sincroniza com o Provider
  Future<void> carregarPerfil() async {
    try {
      final dados = await _authService.getUsuarioData();
      if (dados != null) {
        _usuario = dados;
        _cidadeLocal = dados.cidade;
        _estadoLocal = dados.estado;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil no Provider: $e");
    }
  }

  Future<void> salvarEAtualizarPerfil(Usuario usuarioEditado) async {
    try {
      await _authService.salvarOuAtualizarPerfil(usuarioEditado);
      atualizarUsuario(usuarioEditado);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> limparUsuario() async {
    _usuario = null;
    _cidadeLocal = "";
    _estadoLocal = "";

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cidade_local');
    await prefs.remove('estado_local');

    notifyListeners();
  }
}
