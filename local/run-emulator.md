# Run the Android emulator with the app

Two pieces: start the emulator, then run the app.

## 1. Put Android tools on PATH

They are not on PATH by default:

```bash
export ANDROID_HOME=/home/dugzino/Tools/Android/Sdk
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
```

Put those in `~/.zshrc` if you don't want to export them every time.

## 2. Start the emulator

```bash
emulator -avd Medium_Phone_API_36.1 -gpu host -no-audio -no-snapshot-save
```

Wait until the phone finishes booting (home screen, not just the window). Or:

```bash
adb wait-for-device
adb shell getprop sys.boot_completed   # should print 1
```

## 3. Run the app

From the repo root:

```bash
cd /home/dugzino/Development/Repositories/Dugzino/shqiperia-transport
flutter run -d emulator-5554
```

If the emulator is the only Android device, `flutter run` is enough.

## Shortcut

Flutter can launch the AVD for you:

```bash
cd /home/dugzino/Development/Repositories/Dugzino/shqiperia-transport
flutter emulators --launch Medium_Phone_API_36.1
# wait for boot, then:
flutter run
```

The first path is preferred so GPU/audio flags stay explicit.

After `flutter run`:

- `r` — hot reload
- `R` — hot restart
- `q` — quit the app (emulator stays open)
