import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const IndoorNavApp());
}

class IndoorNavApp extends StatelessWidget {
  const IndoorNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aeroporto Indoor Nav',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------------------------------------------------------------------
// TELA PRINCIPAL DO MAPA
// ---------------------------------------------------------------------------
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Posição atual simulada do usuário (X, Y na planta)
  Offset _userPosition = const Offset(100, 100);

  // Destino selecionado para rota
  Offset? _destinationPosition;
  String _currentLocationName = "Desconhecido (Escaneie um QR Code)";
  String? _destinationName;

  // Banco de dados expandido de QR Codes e locais do aeroporto
  final Map<String, Map<String, dynamic>> _qrDatabase = {
    "QR_GATE_A1": {"name": "Portão A1", "x": 100.0, "y": 100.0, "type": "gate", "icon": Icons.flight_takeoff},
    "QR_GATE_A12": {"name": "Portão A12", "x": 350.0, "y": 200.0, "type": "gate", "icon": Icons.flight_takeoff},
    "QR_GATE_B12": {"name": "Portão B12", "x": 450.0, "y": 150.0, "type": "gate", "icon": Icons.flight_takeoff},
    "QR_RESTROOM_A": {"name": "Banheiro Setor A", "x": 200.0, "y": 300.0, "type": "restroom", "icon": Icons.wc},
    "QR_RESTROOM_B": {"name": "Banheiro Setor B", "x": 400.0, "y": 500.0, "type": "restroom", "icon": Icons.wc},
    "QR_ELEVATOR_1": {"name": "Elevador Central", "x": 180.0, "y": 200.0, "type": "elevator", "icon": Icons.elevator},
    "QR_FOOD": {"name": "Praça de Alimentação", "x": 250.0, "y": 450.0, "type": "food", "icon": Icons.restaurant},
  };

  void _updatePositionFromQR(String rawCode) {
    final locationData = _qrDatabase[rawCode];
    if (locationData != null) {
      setState(() {
        _userPosition = Offset(locationData['x'], locationData['y']);
        _currentLocationName = locationData['name'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Posição calibrada: $_currentLocationName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code não reconhecido no sistema!')),
      );
    }
  }

  // Abre um painel inferior (BottomSheet) para escolher qualquer destino
  void _showDestinationSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecione o Destino',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: _qrDatabase.entries.map((entry) {
                    final data = entry.value;
                    return ListTile(
                      leading: Icon(data['icon'] ?? Icons.place, color: Colors.indigo),
                      title: Text(data['name']),
                      subtitle: Text('Tipo: ${data['type']}'),
                      onTap: () {
                        setState(() {
                          _destinationPosition = Offset(data['x'], data['y']);
                          _destinationName = data['name'];
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rota definida para: $_destinationName')),
                        );
                      },
                    );
                  }).toList(),
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
      appBar: AppBar(
        title: Text('Local: $_currentLocationName'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // MAPA INTERATIVO (Zoom e Pan)
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 4.0,
            child: SizedBox(
              width: 600,
              height: 800,
              child: CustomPaint(
                painter: AirportMapPainter(
                  userPos: _userPosition,
                  destPos: _destinationPosition,
                  locations: _qrDatabase.values.toList(),
                ),
              ),
            ),
          ),

          // PAINEL DE CONTROLE FLUTUANTE
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear QR'),
                    onPressed: () async {
                      final scannedCode = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                      if (scannedCode != null && scannedCode is String) {
                        _updatePositionFromQR(scannedCode);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.directions),
                    label: Text(_destinationName ?? 'Escolher Destino'),
                    onPressed: _showDestinationSelector,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DESENHISTA DA PLANTA BAIXA E ROTAS (CustomPainter)
// ---------------------------------------------------------------------------
class AirportMapPainter extends CustomPainter {
  final Offset userPos;
  final Offset? destPos;
  final List<Map<String, dynamic>> locations;

  AirportMapPainter({
    required this.userPos,
    required this.destPos,
    required this.locations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = Colors.grey.shade200;
    final paintWall = Paint()
      ..color = Colors.blueGrey.shade800
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // 1. Desenha o fundo da planta
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);
    canvas.drawRect(Rect.fromLTWH(50, 50, 500, 700), paintWall);
    canvas.drawLine(const Offset(50, 300), const Offset(400, 300), paintWall);

    // 2. Desenha todos os pontos de interesse no mapa de forma discreta
    final paintPoi = Paint()..color = Colors.blueGrey;
    for (var loc in locations) {
      final pos = Offset(loc['x'], loc['y']);
      canvas.drawCircle(pos, 6, paintPoi);
    }

    // 3. Desenha a linha de rota (caso o destino esteja definido)
    if (destPos != null) {
      final paintRoute = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(userPos, destPos!, paintRoute);

      // Ponto de Destino
      final paintDest = Paint()..color = Colors.red;
      canvas.drawCircle(destPos!, 10, paintDest);
    }

    // 4. Desenha a Posição Atual do Usuário (Marcador Azul)
    final paintUser = Paint()..color = Colors.blue;
    final paintUserBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(userPos, 12, paintUserBorder);
    canvas.drawCircle(userPos, 10, paintUser);
  }

  @override
  bool shouldRepaint(covariant AirportMapPainter oldDelegate) {
    return oldDelegate.userPos != userPos ||
        oldDelegate.destPos != destPos ||
        oldDelegate.locations != locations;
  }
}

// ---------------------------------------------------------------------------
// TELA DE LEITURA DE QR CODE
// ---------------------------------------------------------------------------
class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aponte para o Totem / QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final code = barcode.rawValue!;
              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }
}