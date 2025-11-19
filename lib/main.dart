import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:math';

// Constante para el umbral de activación (en microteslas)
const double UMBRAL_MAGNETICO = 50.0;
// Duración de la vibración en milisegundos (1 segundo)
const int DURACION_VIBRACION_MS = 1000;

void main() {
  // Asegúrate de que Flutter está inicializado antes de ejecutar la aplicación
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MagneticSensorApp());
}

class MagneticSensorApp extends StatelessWidget {
  const MagneticSensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detector Magnético',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MagneticDetectorScreen(),
    );
  }
}

class MagneticDetectorScreen extends StatefulWidget {
  const MagneticDetectorScreen({super.key});

  @override
  State<MagneticDetectorScreen> createState() => _MagneticDetectorScreenState();
}

class _MagneticDetectorScreenState extends State<MagneticDetectorScreen> {
  // Almacena las lecturas del sensor
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  // Almacena la magnitud del campo magnético
  double _magnitud = 0.0;
  // Almacena la suscripción al stream del sensor
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  // Bandera para evitar vibraciones repetidas muy rápidamente
  bool _estaVibrando = false;

  @override
  void initState() {
    super.initState();
    // Suscribirse a los eventos del magnetómetro
    _magnetometerSubscription = magnetometerEventStream().listen(
      (MagnetometerEvent event) {
        // Calcular la magnitud del campo magnético total (en microteslas)
        final double magnitudCalculada = sqrt(
          pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
        );

        setState(() {
          _x = event.x;
          _y = event.y;
          _z = event.z;
          _magnitud = magnitudCalculada;
        });

        // Comprobar el umbral
        if (_magnitud > UMBRAL_MAGNETICO && !_estaVibrando) {
          _vibrarDispositivo();
        }
      },
      onError: (error) {
        // Manejo de errores (por ejemplo, sensor no disponible)
        setState(() {
          _x = double.nan;
          _y = double.nan;
          _z = double.nan;
          _magnitud = double.nan;
        });
        print('Error en el sensor magnético: $error');
      },
      cancelOnError: true,
    );
  }

  // Función para manejar la vibración
  void _vibrarDispositivo() async {
    // 1. Comprueba si el dispositivo puede vibrar
    if (await Vibration.hasVibrator() ?? false) {
      _estaVibrando = true;

      // 2. Vibrar durante el tiempo especificado
      Vibration.vibrate(duration: DURACION_VIBRACION_MS);

      // 3. Esperar el tiempo de vibración + un pequeño margen antes de permitir otra vibración
      await Future.delayed(
        const Duration(milliseconds: DURACION_VIBRACION_MS + 500),
      );

      _estaVibrando = false;
    } else {
      print(
        'El dispositivo no tiene capacidad de vibración o el permiso no está concedido.',
      );
    }
  }

  @override
  void dispose() {
    // Cancelar la suscripción para evitar fugas de memoria
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool umbralSuperado = _magnitud > UMBRAL_MAGNETICO;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Campo Magnético'),
        backgroundColor: umbralSuperado ? Colors.red : Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Indicador de estado visual
              Icon(
                umbralSuperado ? Icons.warning : Icons.check_circle,
                color: umbralSuperado ? Colors.red : Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),

              Text(
                umbralSuperado
                    ? '⚠️ ¡UMBRAL SUPERADO! El móvil vibró.'
                    : 'Campo Magnético Normal.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: umbralSuperado ? Colors.red : Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Valores del sensor
              const Text(
                'Lecturas del Magnetómetro:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),

              // Magnitud Total
              Card(
                color: umbralSuperado
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Magnitud Total: ${_magnitud.toStringAsFixed(2)} μT',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Componentes X, Y, Z
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSensorValue('Eje X', _x),
                  _buildSensorValue('Eje Y', _y),
                  _buildSensorValue('Eje Z', _z),
                ],
              ),
              const SizedBox(height: 30),

              // Umbral de activación
              Text(
                'Umbral de Vibración: ${UMBRAL_MAGNETICO.toStringAsFixed(1)} μT',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para mostrar los valores individuales
  Widget _buildSensorValue(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text(
          value.isNaN ? 'N/A' : value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
