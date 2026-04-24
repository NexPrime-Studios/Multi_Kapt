import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerManualPage extends StatefulWidget {
  const ScannerManualPage({super.key});

  @override
  State<ScannerManualPage> createState() => _ScannerManualPageState();
}

class _ScannerManualPageState extends State<ScannerManualPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  late AudioPlayer _audioPlayer;
  final TextEditingController _manualController = TextEditingController();
  bool _codigoDetectado = false;
  bool _flashLigado = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _prepararAudio();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _prepararAudio() async {
    try {
      // ReleaseMode.stop ajuda a evitar conflitos de estado em sons curtos
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
      // 1. Para a câmera primeiro para liberar processamento
      await controller.stop();

      // 2. Feedback
      _tocarBip();
      HapticFeedback.heavyImpact();

      // 3. Pequeno delay para garantir que o áudio iniciou e o hardware respirou
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        Navigator.pop(context, codigo);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, codigo);
    }
  }

  void _tocarBip() async {
    try {
      // resume() é mais seguro que play() se a fonte já foi definida no initState
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint("Erro ao tocar bip: $e");
      // Fallback nativo caso o audioplayers falhe
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    // Ordem de limpeza para evitar "AudioPlayer has been disposed"
    _animationController.dispose();
    _manualController.dispose();

    // Para e descarta o player imediatamente
    _audioPlayer.stop();
    _audioPlayer.dispose();

    controller.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
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
          _buildVisualOverlay(size),
          _buildInterfaceCamada(),
        ],
      ),
    );
  }

  Widget _buildInterfaceCamada() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: _flashLigado
                        ? Colors.yellow.withOpacity(0.8)
                        : Colors.black54,
                  ),
                  icon: Icon(
                    _flashLigado ? Icons.flash_on : Icons.flash_off,
                    color: _flashLigado ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _flashLigado = !_flashLigado);
                    controller.toggleTorch();
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.red,
                    decoration: InputDecoration(
                      hintText: "Digitar código manualmente...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.isNotEmpty) _processarSaida(val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  backgroundColor: Colors.red,
                  onPressed: () {
                    if (_manualController.text.isNotEmpty) {
                      _processarSaida(_manualController.text);
                    }
                  },
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
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
            child: CustomPaint(painter: ScannerOverlayManualPainter()),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Container(
              height: 2,
              width: scanW - 40,
              decoration: BoxDecoration(
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayManualPainter extends CustomPainter {
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
