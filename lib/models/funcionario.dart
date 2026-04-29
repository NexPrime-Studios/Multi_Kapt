enum CargoAcesso {
  dono, // Proprietário da conta
  adm, // Administrador com altos poderes
  funcionario // Funcionário padrão
}

extension CargoAcessoExt on CargoAcesso {
  String get label {
    switch (this) {
      case CargoAcesso.dono:
        return 'Proprietário';
      case CargoAcesso.adm:
        return 'Sócio / Administrador';
      case CargoAcesso.funcionario:
        return 'Colaborador';
    }
  }
}

class PermissoesFuncionario {
  final bool podeVerMetricas;
  final bool podeGerenciarEquipe;
  final bool podeEditarProdutos;

  PermissoesFuncionario({
    this.podeVerMetricas = false,
    this.podeGerenciarEquipe = false,
    this.podeEditarProdutos = false,
  });

  factory PermissoesFuncionario.fromMap(Map<String, dynamic> map) {
    return PermissoesFuncionario(
      podeVerMetricas: map['pode_ver_metricas'] ?? false,
      podeGerenciarEquipe: map['pode_gerenciar_equipe'] ?? false,
      podeEditarProdutos: map['pode_editar_produtos'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pode_ver_metricas': podeVerMetricas,
      'pode_gerenciar_equipe': podeGerenciarEquipe,
      'pode_editar_produtos': podeEditarProdutos,
    };
  }
}

class Funcionario {
  final String id;
  final String nome;
  final String mercadoId;
  final String? email;
  final String codigoSenha;
  final CargoAcesso cargo;
  final bool ativo;
  final PermissoesFuncionario permissoes;

  Funcionario({
    required this.id,
    required this.mercadoId,
    this.email,
    required this.codigoSenha,
    required this.nome,
    required this.cargo,
    this.ativo = true,
    required this.permissoes,
  });

  factory Funcionario.fromMap(Map<String, dynamic> map, {String? docId}) {
    final permissoesRaw = map['permissoes'];
    final permissoesMap = (permissoesRaw is Map)
        ? Map<String, dynamic>.from(permissoesRaw)
        : <String, dynamic>{};

    return Funcionario(
      id: docId ?? map['id']?.toString() ?? '',
      mercadoId: map['mercado_id']?.toString() ?? '',
      email: map['email']?.toString(),
      codigoSenha: map['codigo_id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? 'Sem Nome',
      cargo: _parseCargo(map['funcao']),
      ativo: map['ativo'] ?? true,
      permissoes: PermissoesFuncionario.fromMap(permissoesMap),
    );
  }

  static CargoAcesso _parseCargo(dynamic value) {
    if (value == null) return CargoAcesso.funcionario;
    return CargoAcesso.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => CargoAcesso.funcionario,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mercado_id': mercadoId,
      'email': email?.toLowerCase().trim(),
      'codigo_id': codigoSenha.toUpperCase().trim(),
      'nome': nome,
      'funcao': cargo.name,
      'ativo': ativo,
      'permissoes': permissoes.toMap(),
    };
  }
}
