import 'package:flutter/material.dart';

class MenuEscolhaCadastro extends StatelessWidget {
  final VoidCallback onNovoProduto;
  final VoidCallback onEditarProduto;
  final VoidCallback onScanCodigo;

  const MenuEscolhaCadastro({
    super.key,
    required this.onNovoProduto,
    required this.onEditarProduto,
    required this.onScanCodigo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header do Menu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          const Text(
            "Gestão de Catálogo",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Como deseja gerenciar seus produtos?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // --- OPÇÃO PRINCIPAL: SCANNER ---
          _CardOpcao(
            titulo: "Ler Código de Barras",
            subtitulo: "Ação rápida via câmera",
            icon: Icons.qr_code_scanner,
            color: Colors.blue, // Destaque em azul para a ação principal
            onTap: onScanCodigo,
          ),

          const SizedBox(height: 24),

          // --- DIVISOR COM TEXTO ---
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "OU MANUALMENTE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 24),

          // --- OPÇÕES MANUAIS ---
          _CardOpcao(
            titulo: "Novo Produto",
            subtitulo: "Cadastrar um item do zero",
            icon: Icons.add_box_rounded,
            color: Colors.green,
            onTap: onNovoProduto,
          ),
          const SizedBox(height: 16),
          _CardOpcao(
            titulo: "Editar Existente",
            subtitulo: "Buscar e alterar um item",
            icon: Icons.edit_document,
            color: Colors.orange,
            onTap: onEditarProduto,
          ),
        ],
      ),
    );
  }
}

class _CardOpcao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardOpcao({
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
