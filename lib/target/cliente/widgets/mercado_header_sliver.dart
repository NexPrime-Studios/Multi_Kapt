import 'package:flutter/material.dart';
import '../../../models/mercado.dart';

class MercadoHeaderSliver extends StatelessWidget {
  final Mercado mercado;

  const MercadoHeaderSliver({super.key, required this.mercado});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    final bool temCapa =
        mercado.capaUrl.isNotEmpty && mercado.capaUrl.startsWith('http');
    final bool temLogo =
        mercado.logoUrl.isNotEmpty && mercado.logoUrl.startsWith('http');

    return SliverMainAxisGroup(
      slivers: [
        // PARTE 1: CABEÇALHO COM TEXTOS MAIORES
        SliverAppBar(
          expandedHeight: 230, // Aumentado para acomodar fontes maiores
          pinned: true,
          elevation: 0,
          backgroundColor: cores.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                temCapa
                    ? Hero(
                        tag: 'capa-${mercado.id}',
                        child: Image.network(
                          mercado.capaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderCapa(cores),
                        ),
                      )
                    : _buildPlaceholderCapa(cores),

                // Gradiente reforçado para leitura
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black
                            .withOpacity(0.85) // Escurecido um pouco mais
                      ],
                    ),
                  ),
                ),

                // Conteúdo: Logo e Textos Ampliados
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildLogoHero(temLogo, cores),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mercado.nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 26, // Aumentado de 20 para 26
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Endereço Ampliado
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14,
                                    color: Colors.white), // Ícone maior
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    mercado.endereco,
                                    maxLines:
                                        2, // Permite 2 linhas se for muito longo
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13, // Aumentado de 10 para 13
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Telefone Ampliado
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 14,
                                    color: Colors.white), // Ícone maior
                                const SizedBox(width: 6),
                                Text(
                                  mercado.telefone,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13, // Aumentado de 10 para 13
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // PARTE 2: STATUS RÁPIDO (Mantido original)
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(Icons.star_rounded, "${mercado.estrelas}",
                    "Avaliação", Colors.amber),
                _statItem(Icons.timer_outlined, mercado.tempoEntrega, "Tempo",
                    cores.secondary),
                _statItem(
                    Icons.delivery_dining_outlined,
                    "R\$ ${mercado.taxaEntrega.toStringAsFixed(2)}",
                    "Taxa",
                    Colors.green),
              ],
            ),
          ),
        ),

        // PARTE 3: STATUS E PEDIDO MÍNIMO (Mantido original)
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      mercado.estaAberto ? "Aberto agora" : "Fechado",
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  "Mínimo: R\$ ${mercado.pedidoMinimo.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares permanecem iguais, apenas ajustei o raio do logo para equilibrar com o texto maior
  Widget _buildLogoHero(bool temLogo, ColorScheme cores) {
    return Hero(
      tag: 'logo-${mercado.id}',
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: 32, // Aumentado de 28 para 32
          backgroundColor: Colors.grey[200],
          backgroundImage: temLogo ? NetworkImage(mercado.logoUrl) : null,
          child: !temLogo
              ? Icon(Icons.store_rounded, color: cores.primary, size: 28)
              : null,
        ),
      ),
    );
  }

  Widget _buildPlaceholderCapa(ColorScheme cores) {
    return Container(
      color: cores.primary,
      child: Icon(Icons.storefront_rounded,
          size: 80, color: Colors.white.withOpacity(0.2)),
    );
  }

  Widget _statItem(IconData icone, String valor, String label, Color cor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: 4),
            Text(valor,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
