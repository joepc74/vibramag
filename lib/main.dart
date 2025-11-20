import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';
import 'dart:math';

// Valores predeterminados y claves de Shared Preferences
const double umbralDefecto = 150.0;
const double duracionEfectoSegundos = 1.0;
const double pausaEfectoSegundos = 2.0;
const int amplitudDefecto = 128;

const String keyUmbral = 'umbral';
const String keyDuracion = 'duracion';
const String keyPausa = 'pausa';
const String keyAmplitud = 'amplitud';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MagneticSensorApp());
}

class MagneticSensorApp extends StatelessWidget {
  const MagneticSensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Vibramag: Detector Magnético',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const MagneticDetectorScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MagneticDetectorScreen extends StatefulWidget {
  const MagneticDetectorScreen({super.key});

  @override
  State<MagneticDetectorScreen> createState() => _MagneticDetectorScreenState();
}

class _MagneticDetectorScreenState extends State<MagneticDetectorScreen> {
  // Configuración de la aplicación
  double _umbral = umbralDefecto; // Umbral de campo magnético (100 a 500)
  double _duracionS =
      duracionEfectoSegundos; // Duración de vibración en segundos (1 a 3)
  double _pausaS =
      pausaEfectoSegundos; // Pausa entre vibraciones en segundos (0 a 5)
  int _amplitud = amplitudDefecto; // Amplitud de vibración (1 a 255)

  // Lecturas del sensor
  double _magnitud = 0.0;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  bool _estaVibrando = false;

  // Para la persistencia de datos
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  // --- PERSISTENCIA DE DATOS (SharedPreferences) ---

  // 1. Cargar la configuración guardada
  void _cargarConfiguracion() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _umbral = _prefs.getDouble(keyUmbral) ?? umbralDefecto;
      _duracionS = _prefs.getDouble(keyDuracion) ?? duracionEfectoSegundos;
      _pausaS = _prefs.getDouble(keyPausa) ?? pausaEfectoSegundos;
      _amplitud = _prefs.getInt(keyAmplitud) ?? amplitudDefecto;
    });
    // Iniciar el sensor una vez que la configuración se ha cargado
    _iniciarSensor();
  }

  // 2. Guardar el nuevo valor del umbral
  void _guardarUmbral(double nuevoUmbral) async {
    setState(() => _umbral = nuevoUmbral);
    await _prefs.setDouble(keyUmbral, nuevoUmbral);
  }

  // 3. Guardar el nuevo valor de la duración
  void _guardarDuracion(double nuevaDuracion) async {
    setState(() => _duracionS = nuevaDuracion);
    await _prefs.setDouble(keyDuracion, nuevaDuracion);
  }

  // 4. Guardar el nuevo valor de la pausa
  void _guardarPausa(double nuevaPausa) async {
    setState(() => _pausaS = nuevaPausa);
    await _prefs.setDouble(keyPausa, nuevaPausa);
  }

  // 5. Guardar el nuevo valor de la amplitud
  void _guardarAmplitud(int nuevaAmplitud) async {
    setState(() => _amplitud = nuevaAmplitud);
    await _prefs.setInt(keyAmplitud, nuevaAmplitud);
  }

  // --- GESTIÓN DEL SENSOR ---

  void _iniciarSensor() {
    _magnetometerSubscription = magnetometerEventStream().listen(
      (MagnetometerEvent event) {
        // Calcular la magnitud del campo magnético total (en microteslas)
        final double magnitudCalculada = sqrt(
          pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
        );

        setState(() {
          _magnitud = magnitudCalculada;
        });

        // Comprobar el umbral
        if (_magnitud > _umbral && !_estaVibrando) {
          _vibrarDispositivo();
        }
      },
      onError: (error) {
        toastification.show(
          title: Text('Error en el sensor magnético: $error'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 5),
        );
        setState(() => _magnitud = double.nan);
      },
      cancelOnError: true,
    );
  }

  // Función para manejar la vibración
  void _vibrarDispositivo() async {
    // Calcular duraciones en milisegundos
    final int duracionMs = (_duracionS * 1000).round();
    final int pausaMs = (_pausaS * 1000).round();

    // Comprueba si el dispositivo puede vibrar
    if (await Vibration.hasVibrator()) {
      _estaVibrando = true;

      // Vibrar durante el tiempo especificado
      Vibration.vibrate(
        duration: duracionMs,
        amplitude:
            _amplitud, // Amplitud media para evitar vibraciones muy fuertes
      );
      // Esperar el tiempo de la pausa antes de permitir otra vibración
      // NOTA: Se espera la pausa, no la duración, para evitar un bucle de vibración constante
      // si el campo magnético sigue alto.
      await Future.delayed(Duration(milliseconds: pausaMs));

      _estaVibrando = false;
    } else {
      toastification.show(
        title: const Text('El dispositivo no puede vibrar o falta el permiso.'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  // --- INTERFAZ DE USUARIO (BUILD) ---

  @override
  Widget build(BuildContext context) {
    final bool umbralSuperado = _magnitud > _umbral;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibramag: Detector Magnético'),
        backgroundColor: umbralSuperado ? Colors.red : Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Sección de Detección en Tiempo Real
            _buildDetectionStatus(umbralSuperado),

            const Divider(height: 30),

            // Sección de Configuración
            Text(
              'Ajustes de Vibración',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // 1. Slider de Umbral Magnético
            _buildSlider(
              'Umbral de Vibración (μT)',
              _umbral,
              10.0,
              500.0,
              (value) => _guardarUmbral(value),
              '${_umbral.toStringAsFixed(0)} μT',
            ),
            const SizedBox(height: 20),

            // 2. Slider de Duración de Vibración
            _buildSlider(
              'Duración de la Vibración (s)',
              _duracionS,
              1.0,
              3.0,
              (value) => _guardarDuracion(value),
              '${_duracionS.toStringAsFixed(1)} s',
            ),
            const SizedBox(height: 20),

            // 3. Slider de Pausa entre Vibraciones
            _buildSlider(
              'Pausa entre Vibraciones (s)',
              _pausaS,
              0.0,
              5.0,
              (value) => _guardarPausa(value),
              '${_pausaS.toStringAsFixed(1)} s',
            ),
            // 4. Slider de amplitud
            _buildSlider(
              'Amplitud de las Vibraciones',
              _amplitud.toDouble(),
              1.0,
              255.0,
              (value) => _guardarAmplitud(value.round()),
              _amplitud.toStringAsFixed(0),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el estado de detección
  Widget _buildDetectionStatus(bool umbralSuperado) {
    return Card(
      color: umbralSuperado ? Colors.red.shade100 : Colors.green.shade100,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              umbralSuperado ? Icons.warning : Icons.sensors,
              color: umbralSuperado ? Colors.red : Colors.green.shade700,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              'Magnitud Actual:',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            Text(
              _magnitud.isNaN ? 'N/A' : '${_magnitud.toStringAsFixed(2)} μT',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: umbralSuperado
                    ? Colors.red.shade800
                    : Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              umbralSuperado
                  ? '¡UMBRAL SUPERADO! (${_umbral.toStringAsFixed(0)} μT)'
                  : 'Por debajo del umbral.',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir cada Slider de configuración
  Widget _buildSlider(
    String label,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue, {
    int divisiones = 10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: ((max - min) * divisiones)
              .round(), // 10 divisiones por unidad para mejor granularidad
          label: displayValue,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              max.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
