import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const NavGateApp());
}

class NavGateApp extends StatelessWidget {
  const NavGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavGate Indoor',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AirportLocation {
  final String id;
  final String name;
  final double x;
  final double y;
  final String type;
  final IconData icon;

  const AirportLocation({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.type,
    required this.icon,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Offset _userPosition = const Offset(250, 300);
  Offset? _destinationPosition;
  String _currentLocationName = "Aguardando Calibração (Escaneie o Totem)";
  String? _destinationName;

  final Map<String, AirportLocation> _qrDatabase = {
    "QR_GATE_A1": const AirportLocation(id: "QR_GATE_A1", name: "Portão A1", x: 200.0, y: 150.0, type: "Portão", icon: Icons.flight_takeoff),
    "QR_GATE_A12": const AirportLocation(id: "QR_GATE_A12", name: "Portão A12", x: 650.0, y: 150.0, type: "Portão", icon: Icons.flight_takeoff),
    "QR_GATE_B1": const AirportLocation(id: "QR_GATE_B1", name: "Portão B1", x: 200.0, y: 650.0, type: "Portão", icon: Icons.flight_land),
    "QR_GATE_B12": const AirportLocation(id: "QR_GATE_B12", name: "Portão B12", x: 650.0, y: 650.0, type: "Portão", icon: Icons.flight_land),
    "QR_SHOP_DUTYFREE": const AirportLocation(id: "QR_SHOP_DUTYFREE", name: "Duty Free Central", x: 420.0, y: 400.0, type: "Loja", icon: Icons.shopping_bag),
    "QR_SHOP_VIP": const AirportLocation(id: "QR_SHOP_VIP", name: "Sala VIP Lounge", x: 800.0, y: 400.0, type: "Serviço", icon: Icons.local_bar),
    "QR_SHOP_FOOD": const AirportLocation(id: "QR_SHOP_FOOD", name: "Praça de Alimentação", x: 420.0, y: 850.0, type: "Alimentação", icon: Icons.restaurant),
  };

  void _updatePositionFromQR(String rawCode) {
    final locationData = _qrDatabase[rawCode];
    if (locationData != null) {
      setState(() {
        _userPosition = Offset(locationData.x, locationData.y);
        _currentLocationName = locationData.name;
      });
      _showToast('Calibrado com sucesso: $_currentLocationName', isError: false);
    } else {
      _showToast('QR Code não reconhecido no sistema.', isError: true);
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDestinationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Navegar pelo Grande Terminal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha um setor, portão ou lounge',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _qrDatabase.length,
                  itemBuilder: (context, index) {
                    final location = _qrDatabase.values.elementAt(index);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(location.icon, color: const Color(0xFF818CF8)),
                        ),
                        title: Text(location.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(location.type, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          setState(() {
                            _destinationPosition = Offset(location.x, location.y);
                            _destinationName = location.name;
                          });
                          Navigator.pop(context);
                          _showToast('Rota traçada para $_destinationName', isError: false);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(600),
            minScale: 0.2,
            maxScale: 4.0,
            child: SizedBox(
              width: 1400,
              height: 1500,
              child: CustomPaint(
                painter: AirportGiantIsometricPainter(
                  userPos: _userPosition,
                  destPos: _destinationPosition,
                  locations: _qrDatabase.values.toList(),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _currentLocationName.contains('Aguardando') ? Colors.amber : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_currentLocationName.contains('Aguardando') ? Colors.amber : const Color(0xFF10B981)).withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LOCALIZAÇÃO ATUAL',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentLocationName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: const Text('Escanear QR', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final scannedCode = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                        );
                        if (scannedCode != null && scannedCode is String) {
                          _updatePositionFromQR(scannedCode);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.storefront_rounded, size: 20),
                      label: Text(
                        _destinationName ?? 'Ver Lojas',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _showDestinationSelector,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AirportGiantIsometricPainter extends CustomPainter {
  final Offset userPos;
  final Offset? destPos;
  final List<AirportLocation> locations;

  AirportGiantIsometricPainter({
    required this.userPos,
    required this.destPos,
    required this.locations,
  });

  Offset _toIso(double x, double y) {
    const double isoAngle = math.pi / 6;
    double isoX = (x - y) * math.cos(isoAngle);
    double isoY = (x + y) * math.sin(isoAngle);
    return Offset(isoX + 600, isoY + 100);
  }

  void _drawIsoBlock(Canvas canvas, Rect rect, double height3D, String label) {
    final p1 = _toIso(rect.left, rect.top);
    final p2 = _toIso(rect.right, rect.top);
    final p3 = _toIso(rect.right, rect.bottom);
    final p4 = _toIso(rect.left, rect.bottom);

    final pathShadow = Path()
      ..moveTo(p1.dx + 15, p1.dy + height3D + 15)
      ..lineTo(p2.dx + 15, p2.dy + height3D + 15)
      ..lineTo(p3.dx + 15, p3.dy + height3D + 15)
      ..lineTo(p4.dx + 15, p4.dy + height3D + 15)
      ..close();
    canvas.drawPath(pathShadow, Paint()..color = Colors.black.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    final wallLeft = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p3.dx, p3.dy + height3D)
      ..lineTo(p4.dx, p4.dy + height3D)
      ..close();
    canvas.drawPath(wallLeft, Paint()..color = const Color(0xFF1E293B));

    final wallRight = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p3.dx, p3.dy + height3D)
      ..lineTo(p2.dx, p2.dy + height3D)
      ..close();
    canvas.drawPath(wallRight, Paint()..color = const Color(0xFF334155));

    final topPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final paintTop = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64748B), Color(0xFF475569)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawPath(topPath, paintTop);
    canvas.drawPath(
      topPath,
      Paint()
        ..color = const Color(0xFF94A3B8).withOpacity(0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p1.dx + 12, p1.dy + 10));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = const Color(0xFF090D16);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    for (double x = 0; x <= 1100; x += 100) {
      canvas.drawLine(_toIso(x, 0), _toIso(x, 1100), paintGrid);
    }
    for (double y = 0; y <= 1100; y += 100) {
      canvas.drawLine(_toIso(0, y), _toIso(1100, y), paintGrid);
    }

    _drawIsoBlock(canvas, const Rect.fromLTWH(80, 60, 320, 220), 24.0, '🛫 PÍER NORTE - PORTÕES A');
    _drawIsoBlock(canvas, const Rect.fromLTWH(430, 60, 320, 220), 24.0, '🛫 PÍER NORTE - PORTÕES B');
    _drawIsoBlock(canvas, const Rect.fromLTWH(80, 310, 320, 280), 28.0, '🛍️ DUTY FREE & SHOPPING');
    _drawIsoBlock(canvas, const Rect.fromLTWH(430, 310, 320, 280), 28.0, '🛋️ LOUNGE VIP & BUSINESS');
    _drawIsoBlock(canvas, const Rect.fromLTWH(80, 620, 320, 280), 24.0, '☕ PRAÇA DE ALIMENTAÇÃO');
    _drawIsoBlock(canvas, const Rect.fromLTWH(430, 620, 320, 280), 24.0, '🛄 ESTEIRAS DE BAGAGEM');
    _drawIsoBlock(canvas, const Rect.fromLTWH(780, 60, 220, 530), 20.0, '🏢 TERMINAL INTERNACIONAL');
    _drawIsoBlock(canvas, const Rect.fromLTWH(780, 620, 220, 280), 20.0, '🚪 ALFÂNDEGA & SEGURANÇA');

    for (var loc in locations) {
      final isoPt = _toIso(loc.x, loc.y);
      final paintPoi = Paint()..color = const Color(0xFFE2E8F0);
      final paintPoiOuter = Paint()..color = const Color(0xFF6366F1).withOpacity(0.5);

      canvas.drawCircle(isoPt, 8, paintPoiOuter);
      canvas.drawCircle(isoPt, 4, paintPoi);
    }

    if (destPos != null) {
      final userIso = _toIso(userPosition.dx, userPosition.dy);
      final destIso = _toIso(destPos!.dx, destPos!.dy);

      final paintRouteGlow = Paint()
        ..color = const Color(0xFFF43F5E).withOpacity(0.4)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final paintRoute = Paint()
        ..color = const Color(0xFFFB7185)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(userIso, destIso, paintRouteGlow);
      canvas.drawLine(userIso, destIso, paintRoute);

      final paintDestOuter = Paint()..color = const Color(0xFFF43F5E).withOpacity(0.3);
      final paintDestInner = Paint()..color = const Color(0xFFE11D48);
      canvas.drawCircle(destIso, 22, paintDestOuter);
      canvas.drawCircle(destIso, 9, paintDestInner);
    }

    final userIsoPt = _toIso(userPos.dx, userPos.dy);
    final paintUserGlow = Paint()..color = const Color(0xFF6366F1).withOpacity(0.45);
    final paintUserOuter = Paint()..color = const Color(0xFF818CF8);
    final paintUserInner = Paint()..color = Colors.white;

    canvas.drawCircle(userIsoPt, 24, paintUserGlow);
    canvas.drawCircle(userIsoPt, 12, paintUserOuter);
    canvas.drawCircle(userIsoPt, 5, paintUserInner);
  }

  Offset get userPosition => userPos;

  @override
  bool shouldRepaint(covariant AirportGiantIsometricPainter oldDelegate) {
    return oldDelegate.userPos != userPos ||
        oldDelegate.destPos != destPos ||
        oldDelegate.locations != locations;
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR do Totem', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }
}