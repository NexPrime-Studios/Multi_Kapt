import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerDesktopWidget extends StatefulWidget {
  final Function(String) onCodeFound;

  const ScannerDesktopWidget({super.key, required this.onCodeFound});

  @override
  State<ScannerDesktopWidget> createState() => _ScannerDesktopWidgetState();
}

class _ScannerDesktopWidgetState extends State<ScannerDesktopWidget> {
  MobileScannerController? controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      autoStart: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && controller != null) {
        if (!controller!.value.isRunning) {
          try {
            await controller!.start();
          } catch (e) {
            debugPrint('Erro ao iniciar MobileScanner: $e');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    if (controller != null) {
      await controller!.stop();
      await controller!.dispose();
      controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Indicador de Scanner Ativo (Agora fora da câmera) ---
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                "SCANNER ATIVO",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),

        // --- Container da Câmera ---
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // 1. O Scanner de Vídeo
                    MobileScanner(
                      controller: controller,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error) {
                        return _buildErrorWidget(error.errorCode);
                      },
                      // ... dentro do widget MobileScanner ...
                      onDetect: (capture) {
                        if (capture.barcodes.isNotEmpty) {
                          final barcode = capture.barcodes.first;
                          if (barcode.rawValue != null) {
                            final String code = barcode.rawValue!;

                            // 1. Executa a função que você passou via parâmetro
                            widget.onCodeFound(code);

                            // 2. Feedback visual imediato na tela
                            ScaffoldMessenger.of(context)
                                .hideCurrentSnackBar(); // Remove o anterior se houver
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Código lido: $code'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                    ),

                    // 2. Barra Vermelha Central (Simulando Laser)
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(MobileScannerErrorCode code) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            _getErrorMessage(code),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(MobileScannerErrorCode code) {
    switch (code) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Permissão da câmera negada.';
      case MobileScannerErrorCode.unsupported:
        return 'Hardware não suportado.';
      default:
        return 'Erro ao acessar câmera.';
    }
  }
}
