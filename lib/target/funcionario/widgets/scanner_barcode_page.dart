import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerBarcodePage extends StatefulWidget {
  const ScannerBarcodePage({super.key});

  @override
  State<ScannerBarcodePage> createState() => _ScannerBarcodePageState();
}

class _ScannerBarcodePageState extends State<ScannerBarcodePage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _codigoDetectado = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _prepararAudio(); // Prepara o áudio imediatamente

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  // Configuração robusta de áudio
  Future<void> _prepararAudio() async {
    try {
      // Define a origem do áudio antecipadamente para evitar delay no primeiro bip
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
      // Força o volume no máximo para o player
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Erro ao preparar áudio: $e");
    }
  }

  void _tocarBip() async {
    try {
      // PlayerMode.lowLatency é essencial para scanners
      await _audioPlayer.resume();
      // Reinicia o som para o início para o próximo bip
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      // Se falhar o áudio, pelo menos ouvimos o clique do sistema
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _animationController.dispose();
    _audioPlayer.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_codigoDetectado) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _codigoDetectado = true;

                  // FEEDBACKS
                  _tocarBip();
                  HapticFeedback
                      .heavyImpact(); // Vibração mais forte para confirmar

                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          _buildVisualOverlay(size),
        ],
      ),
    );
  }

  Widget _buildVisualOverlay(Size size) {
    final double scanW = size.width * 0.6;
    final double scanH = 140;
    return Stack(
      children: [
        ColorFiltered(
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut)),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: scanH,
                  width: scanW,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SizedBox(
            height: scanH,
            width: scanW,
            child: CustomPaint(painter: ScannerOverlayPainter()),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Container(
              height: 2,
              width: scanW - 40,
              decoration: BoxDecoration(color: Colors.red, boxShadow: [
                BoxShadow(
                    color: Colors.red.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2)
              ]),
            ),
          ),
        ),
        Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
                child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context))))),
      ],
    );
  }
}

// O ScannerOverlayPainter permanece o mesmo que enviamos antes...
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path();
    const double corner = 25;
    path.moveTo(0, corner);
    path.lineTo(0, 0);
    path.lineTo(corner, 0);
    path.moveTo(size.width - corner, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, corner);
    path.moveTo(size.width, size.height - corner);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - corner, size.height);
    path.moveTo(corner, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - corner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
