import 'package:flutter/material.dart';
import '../../../../models/funcionario.dart';

class CardMercadoVinculo extends StatelessWidget {
  final String nomeMercado;
  final CargoAcesso cargo;
  final VoidCallback? onTap;

  const CardMercadoVinculo({
    super.key,
    required this.nomeMercado,
    required this.cargo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cores.outlineVariant.withOpacity(0.5)),
      ),
      // O ClipRRect garante que o painel de fundo não escape das bordas arredondadas
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // 1. Painel de Fundo (Decorativo)
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: cores.primary.withOpacity(0.05),
                ),
              ),

              // 2. Conteúdo Principal
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Ícone de Perfil do Mercado
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: cores.primaryContainer,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: cores.onPrimaryContainer,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Textos (Nome e Cargo)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeMercado,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cores.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCorCargo(cores).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cargo.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getCorCargo(cores),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ícone de Ação
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: cores.primary.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função auxiliar para dar cores diferentes dependendo do cargo
  Color _getCorCargo(ColorScheme cores) {
    switch (cargo) {
      case CargoAcesso.dono:
        return Colors.amber.shade800;
      case CargoAcesso.gerente:
        return cores.primary;
      default:
        return cores.secondary;
    }
  }
}
