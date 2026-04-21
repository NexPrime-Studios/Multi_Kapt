import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Usuario? _usuario;
  bool _isMobile = !kIsWeb;

  bool get isMobile => _isMobile;
  bool get isPC => !_isMobile;

  Usuario? get usuario => _usuario;
  bool get temPerfil => _usuario != null;

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
      final dados = await _authService
          .getUsuarioData(); // Usa o método atualizado do AuthService
      if (dados != null) {
        _usuario = dados;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil no Provider: $e");
    }
  }

  /// Salva os dados no Supabase e atualiza o estado local
  Future<void> salvarEAtualizarPerfil(Usuario usuarioEditado) async {
    try {
      // Chama o AuthService que agora aponta para a tabela 'usuarios'
      await _authService.salvarOuAtualizarPerfil(usuarioEditado);
      atualizarUsuario(usuarioEditado);
    } catch (e) {
      rethrow;
    }
  }

  void limparUsuario() {
    _usuario = null;
    notifyListeners();
  }
}
