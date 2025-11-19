# vibramag

Aplicación Flutter llamada `vibramag`.

Descripción
:
Proyecto Flutter que sirve como código fuente para la aplicación `vibramag`.
Este repositorio contiene la app para múltiples plataformas (Android, iOS, web y escritorio) y la configuración necesaria para construir, probar y distribuir la app.

Estado
:
- Lenguaje: Dart + Flutter
- Rama principal: `main`

Tecnologías y plugins relevantes
:
- Flutter SDK
- Complementos nativos (ver `pubspec.yaml` y la carpeta `android/`, `ios/`, `linux/`, `windows/`, `macos/`)

Requisitos previos
:
- Instalar Flutter (versión compatible). Sigue https://docs.flutter.dev/get-started/install
- Android SDK / Android Studio para builds Android
- Xcode para builds iOS (macOS)
- Visual Studio para builds Windows (si es necesario)

Instalación y ejecución (desarrollo)
:
1. Obtener dependencias:

```
pwsh
flutter pub get
```

2. Ejecutar en un dispositivo/emulador conectado:

```
pwsh
flutter run -d <device-id>
```

3. Limpiar artefactos build (si es necesario):

```
pwsh
flutter clean
```

Comandos de build
:
- Android APK: `flutter build apk`
- Android App Bundle: `flutter build appbundle`
- iOS: `flutter build ios`
- Web: `flutter build web`
- Windows: `flutter build windows`

Pruebas y verificación
:
- Ejecutar tests unitarios: `flutter test`
- Analizar código: `flutter analyze`

Estructura del proyecto (resumen)
:
- `lib/` - Código Dart principal (punto de entrada: `lib/main.dart`)
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` - Plataformas nativas
- `assets/` - Recursos (imágenes, fuentes, etc.)
- `test/` - Pruebas unitarias

Notas importantes
:
- Revisa `pubspec.yaml` para ver las dependencias y versiones usadas.
- Si agregas dependencias nativas, ejecuta `flutter pub get` y reconstruye los proyectos nativos.

Contribuir
:
1. Crea un fork y una rama feature: `git checkout -b feature/nombre`
2. Añade tests cuando corresponda
3. Abre un Pull Request contra `main` describiendo cambios

Contacto y soporte
:
Para preguntas o problemas, abre un issue en el repositorio o contacta al mantenedor.

Licencia
:
Este repositorio no incluye un archivo de licencia por defecto. Añade `LICENSE` si deseas publicar bajo una licencia abierta (por ejemplo MIT).
