// models/horario_mercado.dart
class DiaFuncionamento {
  final bool aberto;
  final String abertura; // Ex: "08:00"
  final String fechamento; // Ex: "22:00"

  DiaFuncionamento({
    required this.aberto,
    this.abertura = "00:00",
    this.fechamento = "00:00",
  });

  Map<String, dynamic> toMap() {
    return {'aberto': aberto, 'abertura': abertura, 'fechamento': fechamento};
  }

  factory DiaFuncionamento.fromMap(Map<String, dynamic> map) {
    return DiaFuncionamento(
      aberto: map['aberto'] ?? false,
      abertura: map['abertura'] ?? "00:00",
      fechamento: map['fechamento'] ?? "00:00",
    );
  }
}
