// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/usuario.dart'; // - Alterado de cliente.dart para usuario.dart

class UserService {
  final _supabase = Supabase.instance.client;

  // --- GETTERS ---

  /// Retorna o usuário autenticado atual
  User? get currentUser => _supabase.auth.currentUser;

  /// Retorna apenas o ID (UID) do usuário atual
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Stream que escuta mudanças no estado da autenticação (login/logout)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- MÉTODOS DE AUTENTICAÇÃO ---

  /// Realiza login com e-mail e senha
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Cria uma nova conta de usuário
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Encerra a sessão do usuário
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Envia e-mail para recuperação/redefinição de senha
  Future<void> recoverPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  // --- MÉTODOS DE BANCO DE DADOS (PERFIL USUÁRIO) ---

  /// Busca os dados completos na tabela 'usuarios' usando o UID atual
  Future<Usuario?> getUsuarioData() async {
    // - Renomeado para seguir o padrão
    final id = currentUserId;
    if (id == null) return null;

    final data = await _supabase
        .from('usuarios') // - Alterado de 'clientes' para 'usuarios'
        .select()
        .eq('uid', id)
        .maybeSingle();

    return data != null ? Usuario.fromMap(data) : null; //
  }

  /// Verifica se já existe um registro para o e-mail na tabela 'usuarios'
  Future<bool> verificarEmailExistente(String email) async {
    try {
      final response = await _supabase
          .from('usuarios') // Consulta na tabela 'usuarios'
          .select('email')
          .eq('email', email.trim()) // Filtra pelo e-mail
          .maybeSingle();

      return response != null; // Retorna true se encontrar o e-mail
    } catch (e) {
      debugPrint("Erro ao verificar e-mail: $e");
      return false;
    }
  }

  /// Salva ou atualiza os dados na tabela 'usuarios'
  Future<void> salvarOuAtualizarPerfil(Usuario usuario) async {
    //
    try {
      // 1. Atualiza metadados no Auth do Supabase (opcional, mas bom para manter sincronizado)
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': usuario.nome,
            'phone': usuario.telefone,
          },
        ),
      );

      // 2. Faz o upsert na tabela 'usuarios'.
      await _supabase.from('usuarios').upsert(usuario.toMap());
    } catch (e) {
      debugPrint("Erro ao salvar perfil no AuthService: $e");
      rethrow;
    }
  }
}
