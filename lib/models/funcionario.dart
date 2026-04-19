enum CargoAcesso {
  dono,
  gerente,
  operador,
  coletor,
  entregador,
  coletorEntregador,
}

extension CargoAcessoExt on CargoAcesso {
  String get label {
    switch (this) {
      case CargoAcesso.dono:
        return 'Dono / Administrador';
      case CargoAcesso.gerente:
        return 'Gerente';
      case CargoAcesso.operador:
        return 'Operador de Caixa';
      case CargoAcesso.coletor:
        return 'Coletor';
      case CargoAcesso.entregador:
        return 'Entregador';
      case CargoAcesso.coletorEntregador:
        return 'Coletor e Entregador';
    }
  }

  // --- LOGICA DE PERMISSÕES ---

  /// Define quem pode acessar as métricas financeiras da loja
  bool get podeVerMetricas =>
      this == CargoAcesso.dono || this == CargoAcesso.gerente;

  /// Define quem pode gerenciar a lista de funcionários
  bool get podeGerenciarEquipe => this == CargoAcesso.dono;

  /// Define quem pode editar produtos e estoque
  bool get podeEditarProdutos =>
      this == CargoAcesso.dono ||
      this == CargoAcesso.gerente ||
      this == CargoAcesso.operador ||
      this == CargoAcesso.coletor;
}

class Funcionario {
  final String id;
  final String mercadoId;
  final String? email;
  final String codigoSenha;
  final String nome;
  final CargoAcesso cargo;
  final bool ativo;

  Funcionario({
    required this.id,
    required this.mercadoId,
    this.email,
    required this.codigoSenha,
    required this.nome,
    required this.cargo,
    this.ativo = true,
  });

  factory Funcionario.fromMap(Map<String, dynamic> map) {
    return Funcionario(
      id: map['id']?.toString() ?? '',
      mercadoId: map['mercado_id']?.toString() ?? '',
      email: map['email']?.toString(),
      codigoSenha: map['codigo_id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? 'Sem Nome',
      cargo: CargoAcesso.values.firstWhere(
        (e) => e.name == map['funcao'],
        orElse: () => CargoAcesso.operador,
      ),
      ativo: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mercado_id': mercadoId,
      'email': email?.toLowerCase().trim(),
      'codigo_id': codigoSenha.toUpperCase(),
      'nome': nome,
      'funcao': cargo.name,
      'ativo': ativo,
    };
  }
}
