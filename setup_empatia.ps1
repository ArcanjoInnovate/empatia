# =============================================================================
#  setup_empatia.ps1
#  Aplica todas as correcoes de iOS e Android no projeto Empatia (Windows)
#
#  Como usar:
#    powershell -ExecutionPolicy Bypass -File .\setup_empatia.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

function ok   { param($msg) Write-Host "[OK]  $msg" -ForegroundColor Green }
function info { param($msg) Write-Host "[--]  $msg" -ForegroundColor Cyan }
function warn { param($msg) Write-Host "[!!]  $msg" -ForegroundColor Yellow }
function fail { param($msg) Write-Host "[XX]  $msg" -ForegroundColor Red; exit 1 }
function step { param($msg) Write-Host "`n===  $msg  ===" -ForegroundColor Cyan }

if (-not (Test-Path "pubspec.yaml")) { fail "Execute na RAIZ do projeto empatia (onde esta o pubspec.yaml)." }
if (-not (Test-Path "android"))      { fail "Pasta android\ nao encontrada." }
if (-not (Test-Path "ios"))          { fail "Pasta ios\ nao encontrada." }

info "Raiz do projeto: $(Get-Location)"

# =============================================================================
step "1 - ANDROID - Remover arquivos Kotlin DSL (.kts)"
# =============================================================================

@("android\build.gradle.kts", "android\settings.gradle.kts", "android\app\build.gradle.kts") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_; ok "Removido: $_" }
    else { info "Ja inexistente (ok): $_" }
}

# =============================================================================
step "2 - ANDROID - android\build.gradle"
# =============================================================================

$content = @'
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
'@
[System.IO.File]::WriteAllText("$PWD\android\build.gradle", $content, [System.Text.Encoding]::UTF8)
ok "android\build.gradle"

# =============================================================================
step "3 - ANDROID - android\settings.gradle"
# =============================================================================

$content = @'
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.9.1" apply false
    id "com.google.gms.google-services" version "4.3.15" apply false
    id "org.jetbrains.kotlin.android" version "2.3.10" apply false
}

include ":app"
'@
[System.IO.File]::WriteAllText("$PWD\android\settings.gradle", $content, [System.Text.Encoding]::UTF8)
ok "android\settings.gradle"

# =============================================================================
step "4 - ANDROID - android\gradle.properties"
# =============================================================================

$content = @'
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError -XX:+UseParallelGC -XX:MaxGCPauseMillis=200
android.useAndroidX=true
android.enableJetifier=true
android.nonTransitiveRClass=false
android.newDsl=false
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
org.gradle.vfs.watch=false
org.gradle.workers.max=4
kotlin.code.style=official
android.enableR8.fullMode=true
'@
[System.IO.File]::WriteAllText("$PWD\android\gradle.properties", $content, [System.Text.Encoding]::UTF8)
ok "android\gradle.properties"

# =============================================================================
step "5 - ANDROID - gradle wrapper (gradle-8.11.1)"
# =============================================================================

New-Item -ItemType Directory -Force "android\gradle\wrapper" | Out-Null

$content = @'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-all.zip
'@
[System.IO.File]::WriteAllText("$PWD\android\gradle\wrapper\gradle-wrapper.properties", $content, [System.Text.Encoding]::UTF8)
ok "android\gradle\wrapper\gradle-wrapper.properties"

# =============================================================================
step "6 - ANDROID - android\app\build.gradle"
# =============================================================================

$content = @'
plugins {
    id "com.android.application"
    id 'com.google.gms.google-services'
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) { flutterVersionCode = '1' }

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) { flutterVersionName = '1.0' }

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.arcanjo.empatia"
    compileSdk 36
    ndkVersion "28.2.13676358"

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions { jvmTarget = '17' }

    defaultConfig {
        applicationId "com.arcanjo.empatia"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
            packagingOptions {
                pickFirst '**/libc++_shared.so'
                pickFirst '**/libjsc.so'
                pickFirst '**/lib*.so'
                exclude 'META-INF/DEPENDENCIES'
                exclude 'META-INF/LICENSE'
                exclude 'META-INF/LICENSE.txt'
                exclude 'META-INF/NOTICE'
                exclude 'META-INF/NOTICE.txt'
            }
            debuggable false
            jniDebuggable false
            zipAlignEnabled true
        }
        profile {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
        debug {
            applicationIdSuffix ".debug"
            signingConfig signingConfigs.debug
            minifyEnabled false
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
    implementation platform('com.google.firebase:firebase-bom:33.1.2')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'androidx.multidex:multidex:2.0.1'
}
'@
[System.IO.File]::WriteAllText("$PWD\android\app\build.gradle", $content, [System.Text.Encoding]::UTF8)
ok "android\app\build.gradle"

# =============================================================================
step "7 - ANDROID - AndroidManifest.xml"
# =============================================================================

$content = @'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29"
        tools:replace="android:maxSdkVersion" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <application
        android:label="Empatia"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>

</manifest>
'@
[System.IO.File]::WriteAllText("$PWD\android\app\src\main\AndroidManifest.xml", $content, [System.Text.Encoding]::UTF8)
ok "android\app\src\main\AndroidManifest.xml"

# =============================================================================
step "8 - ANDROID - MainActivity.kt"
# =============================================================================

$newKtDir = "android\app\src\main\kotlin\com\arcanjo\empatia"
$oldKtDir = "android\app\src\main\kotlin\com\example\empatia"

New-Item -ItemType Directory -Force $newKtDir | Out-Null

$content = @'
package com.arcanjo.empatia

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
'@
[System.IO.File]::WriteAllText("$PWD\$newKtDir\MainActivity.kt", $content, [System.Text.Encoding]::UTF8)
ok "$newKtDir\MainActivity.kt"

if ((Test-Path $oldKtDir) -and ($oldKtDir -ne $newKtDir)) {
    Remove-Item -Recurse -Force $oldKtDir
    ok "Removida pasta antiga: $oldKtDir"
}

# =============================================================================
step "9 - ANDROID - Limpar copias extras do google-services.json"
# =============================================================================

@("google-services.json", "android\google-services.json", "android\app\src\google-services.json") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_; ok "Removida copia extra: $_" }
}

if (Test-Path "android\app\google-services.json") {
    $gsRaw = Get-Content "android\app\google-services.json" -Raw
    $gsJson = $gsRaw | ConvertFrom-Json
    $pkg = $gsJson.client[0].client_info.android_client_info.package_name
    if ($pkg -eq "com.arcanjo.empatia") {
        ok "android\app\google-services.json - package_name correto"
    } else {
        warn "google-services.json com package_name='$pkg' - atualize para 'com.arcanjo.empatia' no console Firebase"
    }
} else {
    warn "android\app\google-services.json NAO encontrado - baixe do console Firebase"
}

# =============================================================================
step "10 - iOS - Info.plist"
# =============================================================================

$content = @'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Empatia</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>empatia</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
		<key>UISceneConfigurations</key>
		<dict>
			<key>UIWindowSceneSessionRoleApplication</key>
			<array>
				<dict>
					<key>UISceneClassName</key>
					<string>UIWindowScene</string>
					<key>UISceneConfigurationName</key>
					<string>flutter</string>
					<key>UISceneDelegateClassName</key>
					<string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
					<key>UISceneStoryboardFile</key>
					<string>Main</string>
				</dict>
			</array>
		</dict>
	</dict>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Usamos sua localizacao para mostrar usuarios e conexoes proximos.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>Usamos sua localizacao para mostrar usuarios e conexoes proximos.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>Usamos sua localizacao para mostrar usuarios e conexoes proximos.</string>
	<key>NSCameraUsageDescription</key>
	<string>Usamos a camera para fotos de perfil e posts.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Usamos sua galeria para enviar fotos.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>Permitimos salvar fotos no seu dispositivo.</string>
	<key>FirebaseAppDelegateProxyEnabled</key>
	<true/>
</dict>
</plist>
'@
[System.IO.File]::WriteAllText("$PWD\ios\Runner\Info.plist", $content, [System.Text.Encoding]::UTF8)
ok "ios\Runner\Info.plist"

# =============================================================================
step "11 - iOS - AppDelegate.swift"
# =============================================================================

$content = @'
import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
'@
[System.IO.File]::WriteAllText("$PWD\ios\Runner\AppDelegate.swift", $content, [System.Text.Encoding]::UTF8)
ok "ios\Runner\AppDelegate.swift"

# =============================================================================
step "12 - iOS - SceneDelegate.swift"
# =============================================================================

$content = @'
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    NotificationCenter.default.removeObserver(self)
  }

  override func sceneWillResignActive(_ scene: UIScene) {}

  override func sceneDidBecomeActive(_ scene: UIScene) {}
}
'@
[System.IO.File]::WriteAllText("$PWD\ios\Runner\SceneDelegate.swift", $content, [System.Text.Encoding]::UTF8)
ok "ios\Runner\SceneDelegate.swift"

# =============================================================================
step "13 - iOS - Runner.entitlements"
# =============================================================================

$content = @'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
</dict>
</plist>
'@
[System.IO.File]::WriteAllText("$PWD\ios\Runner\Runner.entitlements", $content, [System.Text.Encoding]::UTF8)
ok "ios\Runner\Runner.entitlements"

# =============================================================================
step "14 - iOS - project.pbxproj (bundle ID + deployment target + entitlements)"
# =============================================================================

$pbxproj = "ios\Runner.xcodeproj\project.pbxproj"

if (-not (Test-Path $pbxproj)) { fail "$pbxproj nao encontrado!" }

Copy-Item $pbxproj "$pbxproj.bak"
ok "Backup: $pbxproj.bak"

$content = [System.IO.File]::ReadAllText("$PWD\$pbxproj", [System.Text.Encoding]::UTF8)

$content = $content -replace 'IPHONEOS_DEPLOYMENT_TARGET = 13\.0;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;'
$content = $content -replace 'PRODUCT_BUNDLE_IDENTIFIER = com\.example\.empatia;', 'PRODUCT_BUNDLE_IDENTIFIER = com.arcanjo.empatia;'
$content = $content -replace 'PRODUCT_BUNDLE_IDENTIFIER = com\.example\.empatia\.RunnerTests;', 'PRODUCT_BUNDLE_IDENTIFIER = com.arcanjo.empatia.RunnerTests;'

if ($content -notmatch 'CODE_SIGN_ENTITLEMENTS') {
    $content = $content -replace '(\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com\.arcanjo\.empatia;)', "`t`t`t`tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;`n`$1"
}

[System.IO.File]::WriteAllText("$PWD\$pbxproj", $content, [System.Text.Encoding]::UTF8)
ok "ios\Runner.xcodeproj\project.pbxproj atualizado"

# =============================================================================
step "15 - iOS - Verificar GoogleService-Info.plist"
# =============================================================================

if (Test-Path "ios\Runner\GoogleService-Info.plist") {
    ok "ios\Runner\GoogleService-Info.plist encontrado - verifique que BUNDLE_ID = com.arcanjo.empatia"
} else {
    warn "ios\Runner\GoogleService-Info.plist NAO encontrado"
    warn "Baixe do console Firebase (projeto empatia-34400) e coloque em ios\Runner\"
}

# =============================================================================
step "16 - flutter pub get"
# =============================================================================

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter pub get
    ok "flutter pub get"
} else {
    warn "flutter nao encontrado no PATH - rode 'flutter pub get' manualmente."
}

# =============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Todas as correcoes aplicadas com sucesso! " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Acoes manuais ainda necessarias:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. android\app\google-services.json" -ForegroundColor White
Write-Host "     -> package_name deve ser com.arcanjo.empatia" -ForegroundColor Gray
Write-Host "     -> Se nao tiver, baixe do console Firebase e coloque em android\app\" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. ios\Runner\GoogleService-Info.plist" -ForegroundColor White
Write-Host "     -> Baixe do Firebase > projeto empatia-34400 > app iOS" -ForegroundColor Gray
Write-Host "     -> BUNDLE_ID deve ser com.arcanjo.empatia" -ForegroundColor Gray
Write-Host "     -> Coloque em ios\Runner\GoogleService-Info.plist" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. No Mac (para buildar iOS):" -ForegroundColor White
Write-Host "     -> cd ios && pod install" -ForegroundColor Gray
Write-Host "     -> Abra ios\Runner.xcworkspace no Xcode" -ForegroundColor Gray
Write-Host "     -> Em Signing & Capabilities, selecione seu Team" -ForegroundColor Gray
Write-Host ""