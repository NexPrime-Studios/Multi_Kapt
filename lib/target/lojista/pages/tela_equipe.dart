import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/funcionario.dart';
import '../../../services/lojista_provider.dart';
import '../widgets/cadastro_funcionario_widget.dart';

class TelaEquipeLojista extends StatefulWidget {
  final String mercadoId;
  const TelaEquipeLojista({super.key, required this.mercadoId});

  @override
  State<TelaEquipeLojista> createState() => _TelaEquipeLojistaState();
}

class _TelaEquipeLojistaState extends State<TelaEquipeLojista> {
  void _abrirFormulario({Funcionario? funcionario}) {
    showDialog(
      context: context,
      builder: (_) => DialogCadastroFuncionario(
        mercadoId: widget.mercadoId,
        funcionarioParaEditar: funcionario,
      ),
    );
  }

  // Função auxiliar para definir cores baseadas no CargoAcesso (Enum)
  Color _getCorCargo(CargoAcesso cargo) {
    switch (cargo) {
      case CargoAcesso.dono:
        return Colors.redAccent;
      case CargoAcesso.gerente:
        return Colors.indigo;
      case CargoAcesso.operador:
        return Colors.teal;
      case CargoAcesso.coletor:
        return Colors.orange;
      case CargoAcesso.entregador:
        return Colors.blue;
      case CargoAcesso.coletorEntregador:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final lojistaProvider = context.watch<LojistaProvider>();
    final equipe = lojistaProvider.equipe;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Gestão de Equipe",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text("NOVO INTEGRANTE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cores.primary,
                minimumSize: const Size(180, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: lojistaProvider.estaCarregando
          ? const Center(child: CircularProgressIndicator())
          : equipe.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 230, // Ajustado para os novos cargos
                  ),
                  itemCount: equipe.length,
                  itemBuilder: (context, index) {
                    final f = equipe[index];
                    return _buildCardFuncionarioGrid(
                        context, f, cores, lojistaProvider);
                  },
                ),
    );
  }

  Widget _buildCardFuncionarioGrid(BuildContext context, Funcionario f,
      ColorScheme cores, LojistaProvider provider) {
    // Agora acessamos diretamente o enum 'cargo' do modelo Funcionario
    final corCargo = _getCorCargo(f.cargo);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      f.ativo ? corCargo.withOpacity(0.1) : Colors.grey[200],
                  child: Icon(Icons.person,
                      size: 28, color: f.ativo ? corCargo : Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  f.nome,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),

                // Badge do Cargo usando o label da Extension
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        f.ativo ? corCargo.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: f.ativo
                            ? corCargo.withOpacity(0.3)
                            : Colors.grey[300]!),
                  ),
                  child: Text(
                    f.cargo.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 8,
                        color: f.ativo ? corCargo : Colors.grey[600],
                        fontWeight: FontWeight.bold),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    "CÓD: ${f.codigoSenha}",
                    style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey),
                  ),
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(f.ativo ? "Disponível" : "Inativo",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: f.ativo ? Colors.green : Colors.grey)),
                    SizedBox(
                      height: 24,
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: f.ativo,
                          activeThumbColor: Colors.green,
                          onChanged: (val) =>
                              provider.alternarStatusFuncionario(f.id, val),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Colors.grey, size: 18),
              onPressed: () => _abrirFormulario(funcionario: f),
              tooltip: "Configurar",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Sua equipe aparecerá aqui.",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Cadastre os membros da equipe para operar o mercado.",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
