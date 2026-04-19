import 'dart:convert';

class Cliente {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final String endereco;
  final String estado;
  final String cidade;
  final double? latitude;
  final double? longitude;

  Cliente({
    required this.uid,
    required this.nome,
    required this.email,
    this.telefone = '',
    this.endereco = '',
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
      'endereco': endereco,
      'estado': estado,
      'cidade': cidade,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      estado: map['estado'] ?? '',
      cidade: map['cidade'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Cliente.fromJson(String source) =>
      Cliente.fromMap(json.decode(source) as Map<String, dynamic>);

  Cliente copyWith({
    String? uid,
    String? nome,
    String? email,
    String? telefone,
    String? endereco,
    String? estado,
    String? cidade,
    double? latitude,
    double? longitude,
  }) {
    return Cliente(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
