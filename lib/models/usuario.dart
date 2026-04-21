import 'dart:convert';

class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final String cpf;
  final String endereco;
  final String estado;
  final String cidade;
  final double? latitude;
  final double? longitude;

  Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    this.telefone = '',
    this.endereco = '',
    this.cpf = '',
    this.estado = '',
    this.cidade = '',
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
      'endereco': endereco,
      'estado': estado,
      'cidade': cidade,
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
      endereco: map['endereco'] ?? '',
      estado: map['estado'] ?? '',
      cidade: map['cidade'] ?? '',
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
    String? endereco,
    String? estado,
    String? cidade,
    double? latitude,
    double? longitude,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      endereco: endereco ?? this.endereco,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
