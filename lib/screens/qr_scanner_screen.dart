import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final imagePicker = ImagePicker();
  bool processed = false;
  bool analyzingImage = false;
  String? statusMessage;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void process(String code) {
    if (processed) return;
    processed = true;
    final state = context.read<AppState>();
    final student = state.currentStudent;
    final prefix = 'presenca-qr:';
    final message = !code.startsWith(prefix)
        ? 'Este QR Code não pertence a uma chamada do Presença QR.'
        : student == null
        ? 'Não foi possível identificar o aluno conectado.'
        : state.registerAttendance(
            code.substring(prefix.length),
            studentId: student.id,
          );
    setState(() => statusMessage = message);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    if (controller.value.isRunning) controller.stop();
  }

  Future<void> _switchCamera() async {
    try {
      await controller.switchCamera();
    } on MobileScannerException catch (error) {
      _showMessage(_cameraError(error));
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await controller.toggleTorch();
    } on MobileScannerException catch (error) {
      _showMessage(_cameraError(error));
    }
  }

  Future<void> _scanImage() async {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      _showMessage(
        'A leitura por imagem não está disponível nesta plataforma. '
        'Use um celular compatível ou a câmera em HTTPS/localhost.',
      );
      return;
    }

    setState(() => analyzingImage = true);
    XFile? image;
    try {
      image = await imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final capture = await controller.analyzeImage(image.path);
      final value = capture?.barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .firstOrNull;
      if (value == null) {
        _showMessage('Nenhum QR Code foi encontrado na imagem selecionada.');
      } else {
        process(value);
      }
    } on UnsupportedError {
      _showMessage('A leitura de imagens não é suportada neste dispositivo.');
    } on MobileScannerBarcodeException catch (error) {
      _showMessage(
        error.message ?? 'Nenhum QR Code foi encontrado na imagem selecionada.',
      );
    } on PlatformException catch (error) {
      _showMessage(
        'Não foi possível abrir a imagem: ${error.message ?? error.code}',
      );
    } on MobileScannerException catch (error) {
      _showMessage('Não foi possível ler o QR Code: ${_cameraError(error)}');
    } finally {
      if (mounted) setState(() => analyzingImage = false);
    }
  }

  Future<void> _resumeScanning() async {
    setState(() {
      processed = false;
      statusMessage = null;
    });
    try {
      await controller.start();
    } on MobileScannerException catch (error) {
      _showMessage(_cameraError(error));
    }
  }

  String _cameraError(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => 'Permita o acesso à câmera nas configurações do navegador ou dispositivo.',
      MobileScannerErrorCode.unsupported => 'Nenhuma câmera compatível foi encontrada. Use a leitura por imagem ou teste em um dispositivo com câmera.',
      _ =>
        'Não foi possível iniciar a câmera: ${error.errorDetails?.message ?? error.errorCode.message}',
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => statusMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cameraHeight = (constraints.maxHeight * 0.58)
            .clamp(0.0, 480.0)
            .toDouble();
        return Column(
          children: [
            SizedBox(
              height: cameraHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (context, cameraConstraints) {
                      final frameSize = (cameraConstraints.maxWidth * 0.68)
                          .clamp(150.0, 280.0)
                          .clamp(0.0, cameraConstraints.maxHeight * 0.72)
                          .toDouble();
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: controller,
                            onDetect: (capture) {
                              for (final barcode in capture.barcodes) {
                                final value = barcode.rawValue;
                                if (value != null) {
                                  process(value);
                                  break;
                                }
                              }
                            },
                            onDetectError: (error, stackTrace) {
                              _showMessage(
                                'Erro durante a leitura do código: $error',
                              );
                            },
                            errorBuilder: (context, error) => _ScannerError(
                              message: _cameraError(error),
                              onRetry: _resumeScanning,
                            ),
                            placeholderBuilder: (context) => const ColoredBox(
                              color: Color(0xFF031C30),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                          ValueListenableBuilder<MobileScannerState>(
                            valueListenable: controller,
                            builder: (context, value, _) {
                              if (value.error != null || frameSize <= 0) {
                                return const SizedBox.shrink();
                              }
                              return IgnorePointer(
                                child: Center(
                                  child: Container(
                                    width: frameSize,
                                    height: frameSize,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.lightCyan,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ValueListenableBuilder<MobileScannerState>(
                              valueListenable: controller,
                              builder: (context, value, _) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: switch (value.torchState) {
                                      TorchState.on => 'Desligar lanterna',
                                      TorchState.off => 'Ligar lanterna',
                                      TorchState.auto => 'Lanterna automática',
                                      TorchState.unavailable =>
                                        'Lanterna indisponível',
                                    },
                                    onPressed:
                                        value.torchState ==
                                            TorchState.unavailable
                                        ? null
                                        : _toggleTorch,
                                    icon: Icon(
                                      value.torchState == TorchState.on
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    tooltip:
                                        value.availableCameras == null ||
                                            value.availableCameras! < 2
                                        ? 'Câmera alternativa indisponível'
                                        : 'Trocar câmera',
                                    onPressed:
                                        value.availableCameras != null &&
                                            value.availableCameras! > 1
                                        ? _switchCamera
                                        : null,
                                    icon: const Icon(
                                      Icons.cameraswitch_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusMessage == null)
                      const Text(
                        'Aponte a câmera para o QR Code da chamada ativa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.lightCyan.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.lightCyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                statusMessage!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: analyzingImage ? null : _scanImage,
                          icon: analyzingImage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.image_search_outlined),
                          label: const Text('LER POR IMAGEM'),
                        ),
                        if (processed)
                          FilledButton.icon(
                            onPressed: _resumeScanning,
                            icon: const Icon(Icons.refresh),
                            label: const Text('LER OUTRO'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF031C30),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 52,
                color: AppTheme.lightCyan,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('TENTAR NOVAMENTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
