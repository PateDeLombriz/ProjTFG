# front_end

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


LLANÇAR L'APLICACIO AL DISPOSITIU VIRTUAL ES FA:
    --Llançant eld docker, obviament
    --Terminal dedicada al contenedor amb la inttrucció:  docker exec -it flutter-docker bash
    --Una vegada dins es pot tirar ñ'emulador amb : flutter run -d emulator-5554--tarda massa

    --COMPROVACIONS dins contenidor flutter:
        flutter devices
        flutter doctor
        ehich sdkmanager
        netstart -an |grep (aixo es linux crec) 5037
        RUN yes |sdkmanager --licenses  en cas de haver de acceptar el permisos de les dependencies de android