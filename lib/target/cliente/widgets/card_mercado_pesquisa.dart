import 'package:flutter/material.dart';
import '../../../models/mercado.dart';
import '../pages/mercado_page_cliente.dart';

class CardMercadoPesquisa extends StatelessWidget {
  final Mercado mercado;

  const CardMercadoPesquisa({super.key, required this.mercado});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MercadoPaginaCliente(mercado: mercado)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Imagem de Capa ou Fundo Padrão
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cores.primary.withOpacity(0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    image: mercado.capaUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(mercado.capaUrl),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: mercado.capaUrl.isEmpty
                      ? Icon(Icons.storefront, size: 50, color: cores.primary)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4)
                              ],
                            ),
                          ),
                        ),
                ),

                // Badge de Status (Aberto/Fechado)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: mercado.estaAberto
                          ? cores.secondary
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      mercado.estaAberto ? "● ABERTO" : "FECHADO",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Logo do Mercado
                Positioned(
                  bottom: -15,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: mercado.logoUrl.isNotEmpty
                          ? NetworkImage(mercado.logoUrl)
                          : null,
                      child: mercado.logoUrl.isEmpty
                          ? Icon(Icons.store, color: cores.primary)
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Informações do Mercado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mercado.nome,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "${mercado.estrelas}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        mercado.tempoEntrega,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.delivery_dining,
                          size: 16, color: cores.secondary),
                      const SizedBox(width: 4),
                      Text(
                        mercado.taxaEntrega == 0
                            ? "Grátis"
                            : "R\$ ${mercado.taxaEntrega.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: mercado.taxaEntrega == 0
                              ? cores.secondary
                              : Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
