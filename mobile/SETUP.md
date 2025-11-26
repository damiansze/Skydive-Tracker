# Setup-Anleitung für die Mobile App

## Voraussetzungen

### 1. Node.js und npm
- **Node.js** >= 18.x installieren: https://nodejs.org/
- npm wird automatisch mit Node.js installiert
- Installation prüfen:
```bash
node --version
npm --version
```

### 2. React Native CLI
```bash
npm install -g react-native-cli
```

### 3. Für Android Entwicklung

#### Android Studio installieren
1. **Android Studio** herunterladen: https://developer.android.com/studio
2. Während der Installation sicherstellen, dass folgende Komponenten installiert werden:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
   - Intel x86 Emulator Accelerator (HAXM installer) - für bessere Performance

#### Android SDK konfigurieren
1. Android Studio öffnen
2. **Tools** → **SDK Manager**
3. Unter **SDK Platforms** Tab:
   - Mindestens eine Android Version auswählen (z.B. Android 13.0 "Tiramisu" oder neuer)
4. Unter **SDK Tools** Tab sicherstellen, dass installiert sind:
   - Android SDK Build-Tools
   - Android Emulator
   - Android SDK Platform-Tools
   - Intel x86 Emulator Accelerator (HAXM)

#### Umgebungsvariablen setzen (Linux/Mac)
Füge zu deiner `~/.bashrc` oder `~/.zshrc` hinzu:
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

Dann neu laden:
```bash
source ~/.bashrc  # oder source ~/.zshrc
```

#### Android Virtual Device (AVD) erstellen
1. Android Studio öffnen
2. **Tools** → **Device Manager**
3. **Create Device** klicken
4. Ein Gerät auswählen (z.B. Pixel 5)
5. System Image auswählen (z.B. Android 13.0)
6. **Finish** klicken

### 4. Für iOS Entwicklung (nur macOS)

#### Xcode installieren
1. **Xcode** aus dem App Store installieren
2. Xcode öffnen und die Lizenz akzeptieren
3. Command Line Tools installieren:
```bash
xcode-select --install
```

#### CocoaPods installieren
```bash
sudo gem install cocoapods
```

## VSCode Extensions (empfohlen)

VSCode selbst kann **keinen Emulator** ausführen, aber diese Extensions helfen bei der Entwicklung:

### Wichtige Extensions:
1. **React Native Tools** (von Microsoft)
   - Syntax-Highlighting, Debugging, IntelliSense
   - Extension ID: `msjsdiag.vscode-react-native`

2. **ES7+ React/Redux/React-Native snippets**
   - Code-Snippets für React Native
   - Extension ID: `dsznajder.es7-react-js-snippets`

3. **Prettier - Code formatter**
   - Automatische Code-Formatierung
   - Extension ID: `esbenp.prettier-vscode`

4. **ESLint**
   - Code-Qualität und Linting
   - Extension ID: `dbaeumer.vscode-eslint`

### Extension installieren:
1. VSCode öffnen
2. **View** → **Extensions** (oder `Ctrl+Shift+X`)
3. Nach den Extension-Namen suchen
4. **Install** klicken

## Projekt Setup

### 1. Dependencies installieren
```bash
cd mobile
npm install
```

### 2. iOS Dependencies (nur macOS)
```bash
cd ios
pod install
cd ..
```

### 3. Metro Bundler starten
In einem Terminal:
```bash
cd mobile
npm start
```

Der Metro Bundler läuft dann auf `http://localhost:8081`

## App starten

### Option 1: Android Emulator

1. **Android Emulator starten:**
   - Android Studio öffnen
   - **Tools** → **Device Manager**
   - Bei deinem AVD auf das ▶️ Play-Symbol klicken
   - Oder über Command Line:
   ```bash
   emulator -avd <AVD_NAME>
   ```
   (AVD-Name findest du mit: `emulator -list-avds`)

2. **App auf Emulator starten:**
   In einem neuen Terminal (während Metro Bundler läuft):
   ```bash
   cd mobile
   npm run android
   ```

### Option 2: iOS Simulator (nur macOS)

1. **iOS Simulator starten:**
   ```bash
   open -a Simulator
   ```
   Oder: Xcode → **Open Developer Tool** → **Simulator**

2. **App auf Simulator starten:**
   In einem neuen Terminal (während Metro Bundler läuft):
   ```bash
   cd mobile
   npm run ios
   ```

### Option 3: Physisches Gerät

#### Android:
1. USB-Debugging auf dem Gerät aktivieren:
   - **Einstellungen** → **Über das Telefon** → **Build-Nummer** 7x tippen
   - **Einstellungen** → **Entwickleroptionen** → **USB-Debugging** aktivieren
2. Gerät per USB verbinden
3. Prüfen ob erkannt:
   ```bash
   adb devices
   ```
4. App starten:
   ```bash
   npm run android
   ```

#### iOS:
1. Gerät per USB verbinden
2. In Xcode: Gerät als Ziel auswählen
3. App starten:
   ```bash
   npm run ios
   ```

## Troubleshooting

### "Command not found: react-native"
```bash
npm install -g react-native-cli
```

### Android: "SDK location not found"
- ANDROID_HOME Umgebungsvariable prüfen
- In Android Studio: **File** → **Project Structure** → SDK Location prüfen

### Android: "Unable to load script"
- Metro Bundler neu starten: `npm start -- --reset-cache`
- Cache löschen: `cd android && ./gradlew clean`

### iOS: "pod: command not found"
```bash
sudo gem install cocoapods
cd ios && pod install
```

### Port 8081 bereits belegt
```bash
# Prozess finden
lsof -i :8081
# Prozess beenden (PID aus vorherigem Befehl)
kill -9 <PID>
```

## Nützliche Befehle

```bash
# Metro Bundler mit Cache-Reset starten
npm start -- --reset-cache

# Android Build Cache löschen
cd android && ./gradlew clean && cd ..

# iOS Build Cache löschen
cd ios && rm -rf build && cd ..

# Alle Dependencies neu installieren
rm -rf node_modules package-lock.json
npm install

# TypeScript Type-Check
npm run type-check

# Tests ausführen
npm test

# Linting
npm run lint
```

## Debugging

### React Native Debugger
1. Chrome öffnen: `http://localhost:8081/debugger-ui`
2. Oder: Im Emulator/Simulator `Cmd+D` (iOS) oder `Ctrl+M` (Android) drücken
3. **Debug** auswählen

### VSCode Debugging
Mit der **React Native Tools** Extension:
1. Debug-Panel öffnen (`Ctrl+Shift+D`)
2. "Debug Android" oder "Debug iOS" auswählen
3. Play-Button drücken

## Zusammenfassung: Was du brauchst

**Minimum für Android:**
- ✅ Node.js >= 18
- ✅ Android Studio
- ✅ Android Virtual Device (AVD)
- ✅ React Native CLI

**Zusätzlich für iOS (nur macOS):**
- ✅ Xcode
- ✅ CocoaPods

**Empfohlene VSCode Extensions:**
- ✅ React Native Tools
- ✅ Prettier
- ✅ ESLint

**Wichtig:** VSCode selbst hat **keinen integrierten Emulator**. Du musst Android Studio (für Android) oder Xcode (für iOS) verwenden, um die Emulatoren zu starten. VSCode Extensions helfen nur bei der Entwicklung (Code-Completion, Debugging, etc.), aber nicht beim Ausführen der App.
