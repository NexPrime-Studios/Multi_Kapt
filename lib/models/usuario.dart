import 'dart:convert';

class Endereco {
  final String cep;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String complemento;

  Endereco({
    this.cep = '',
    this.rua = '',
    this.numero = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.complemento = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'complemento': complemento,
    };
  }

  factory Endereco.fromMap(Map<String, dynamic> map) {
    return Endereco(
      cep: map['cep'] ?? '',
      rua: map['rua'] ?? '',
      numero: map['numero'] ?? '',
      bairro: map['bairro'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      complemento: map['complemento'] ?? '',
    );
  }
}

// --- CLASSE USUARIO ---
class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final String cpf;
  final String dataNascimento;
  final String estado;
  final String cidade;
  final Endereco endereco;
  final double? latitude;
  final double? longitude;

  Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    this.telefone = '',
    this.cpf = '',
    this.dataNascimento = '',
    this.estado = '',
    this.cidade = '',
    required this.endereco,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
      'data_nascimento': dataNascimento,
      'estado': estado,
      'cidade': cidade,
      'endereco': endereco.toMap(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      cpf: map['cpf'] ?? '',
      dataNascimento: map['data_nascimento'] ?? '',
      estado: map['estado'] ?? '',
      cidade: map['cidade'] ?? '',
      endereco: Endereco.fromMap(
        map['endereco'] is String
            ? json.decode(map['endereco'])
            : (map['endereco'] ?? {}),
      ),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Usuario.fromJson(String source) =>
      Usuario.fromMap(json.decode(source) as Map<String, dynamic>);

  Usuario copyWith({
    String? uid,
    String? nome,
    String? email,
    String? telefone,
    String? cpf,
    String? dataNascimento,
    String? estado,
    String? cidade,
    Endereco? endereco,
    double? latitude,
    double? longitude,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
