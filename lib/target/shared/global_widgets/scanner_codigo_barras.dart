import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerCodigoDeBarrasPage extends StatefulWidget {
  const ScannerCodigoDeBarrasPage({super.key});

  @override
  State<ScannerCodigoDeBarrasPage> createState() =>
      _ScannerCodigoDeBarrasPageState();
}

class _ScannerCodigoDeBarrasPageState extends State<ScannerCodigoDeBarrasPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  late AudioPlayer _audioPlayer;
  bool _codigoDetectado = false;
  bool _flashLigado = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _prepararAudio();

    // Força a orientação para "em pé" ao iniciar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _prepararAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint("Erro ao preparar áudio: $e");
    }
  }

  void _processarSaida(String codigo) async {
    if (_codigoDetectado || !mounted) return;

    setState(() {
      _codigoDetectado = true;
    });

    try {
      await controller.stop();
      _tocarBip();
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(
            context, codigo); // Retorna o código para a página anterior
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, codigo);
    }
  }

  void _tocarBip() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    controller.dispose();

    // Mantém em pé ao sair também (padrão do app)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scanArea = size.width * 0.7; // Área de scan quadrada

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_codigoDetectado) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _processarSaida(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay Escuro com o buraco central
          _buildVisualOverlay(size, scanArea),

          // Controles de UI (Fechar e Flash)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  "Escanear Código",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                CircleAvatar(
                  backgroundColor:
                      _flashLigado ? Colors.yellow : Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _flashLigado ? Icons.flash_on : Icons.flash_off,
                      color: _flashLigado ? Colors.black : Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _flashLigado = !_flashLigado);
                      controller.toggleTorch();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Texto Informativo inferior
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Icon(Icons.qr_code_scanner, color: Colors.red, size: 40),
                SizedBox(height: 10),
                Text(
                  "Posicione o código de barras no centro",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualOverlay(Size size, double scanArea) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: scanArea,
                  width: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Moldura branca (Corners)
        Center(
          child: SizedBox(
            height: scanArea,
            width: scanArea,
            child: CustomPaint(painter: ScannerOverlayPainter()),
          ),
        ),
        // Linha de scan animada
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                  0,
                  (scanArea / 2 - 10) *
                      _animationController.value *
                      (_animationController.status == AnimationStatus.forward
                          ? 1
                          : -1)),
              child: Container(
                height: 2,
                width: scanArea - 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    const double corner = 30;

    // Top Left
    path.moveTo(0, corner);
    path.lineTo(0, 0);
    path.lineTo(corner, 0);

    // Top Right
    path.moveTo(size.width - corner, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, corner);

    // Bottom Right
    path.moveTo(size.width, size.height - corner);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - corner, size.height);

    // Bottom Left
    path.moveTo(corner, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - corner);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
