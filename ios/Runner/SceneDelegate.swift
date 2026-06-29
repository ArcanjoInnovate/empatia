import Flutter
import UIKit

// ─────────────────────────────────────────────────────────────────────────────
// SceneDelegate — Proteção de tela (iOS)
//
// O app usa UIApplicationSceneManifest → a window é criada pelo
// FlutterSceneDelegate, não pelo AppDelegate. Por isso toda proteção
// de tela fica aqui, onde self.window já existe.
//
// PROTEÇÃO 1 — Screenshot e gravação de tela (tela preta):
//   Técnica: move window.layer para dentro do UITextField seguro.
//   Compatível iOS 15–18.
//
// PROTEÇÃO 2 — Detecção + punição via Flutter:
//   Screenshot → userDidTakeScreenshotNotification → MethodChannel
//   Gravação   → capturedDidChangeNotification → overlay preto imediato
// ─────────────────────────────────────────────────────────────────────────────

class SceneDelegate: FlutterSceneDelegate {

  private let secureField = UITextField()
  private var recordingOverlay: UIView?

  // ── Ciclo de vida da Scene ─────────────────────────────────────────────────

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    setupScreenProtection()
    setupNotifications()
    setupMethodChannel()
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    secureField.isSecureTextEntry = false
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    secureField.isSecureTextEntry = true
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    NotificationCenter.default.removeObserver(self)
  }

  // ── PROTEÇÃO 1: layer segura ───────────────────────────────────────────────

  private func setupScreenProtection() {
    guard let window = self.window else {
      DispatchQueue.main.async { self.setupScreenProtection() }
      return
    }

    secureField.isSecureTextEntry = true
    secureField.translatesAutoresizingMaskIntoConstraints = false

    guard !window.subviews.contains(secureField) else { return }

    window.addSubview(secureField)
    secureField.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
    secureField.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true

    window.layer.superlayer?.addSublayer(secureField.layer)

    if #available(iOS 17.0, *) {
      secureField.layer.sublayers?.last?.addSublayer(window.layer)
    } else {
      secureField.layer.sublayers?.first?.addSublayer(window.layer)
    }

    print("🔒 Proteção de tela aplicada (iOS \(UIDevice.current.systemVersion))")
  }

  // ── PROTEÇÃO 2: detecção + punição ────────────────────────────────────────

  private func setupNotifications() {
    let nc = NotificationCenter.default

    nc.addObserver(
      self,
      selector: #selector(onCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    nc.addObserver(
      self,
      selector: #selector(onScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )

    updateRecordingOverlay()
  }

  @objc private func onCaptureChanged() {
    updateRecordingOverlay()
  }

  private func updateRecordingOverlay() {
    if UIScreen.main.isCaptured {
      showRecordingOverlay()
    } else {
      hideRecordingOverlay()
    }
  }

  private func showRecordingOverlay() {
    guard recordingOverlay == nil, let window = self.window else { return }

    let overlay = UIView()
    overlay.backgroundColor = .black
    overlay.translatesAutoresizingMaskIntoConstraints = false
    overlay.isUserInteractionEnabled = false

    window.addSubview(overlay)
    NSLayoutConstraint.activate([
      overlay.topAnchor.constraint(equalTo: window.topAnchor),
      overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor),
      overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
    ])
    window.layoutIfNeeded()

    recordingOverlay = overlay
  }

  private func hideRecordingOverlay() {
    recordingOverlay?.removeFromSuperview()
    recordingOverlay = nil
  }

  // ── MethodChannel → Flutter ───────────────────────────────────────────────

  private func setupMethodChannel() {
    guard let flutterVC = window?.rootViewController as? FlutterViewController
    else { return }

    let channel = FlutterMethodChannel(
      name: "empatia/screen_security",
      binaryMessenger: flutterVC.engine.binaryMessenger
    )

    _methodChannel = channel
  }

  private var _methodChannel: FlutterMethodChannel?

  @objc private func onScreenshot() {
    if _methodChannel == nil { setupMethodChannel() }
    _methodChannel?.invokeMethod("screenshotDetected", arguments: nil)
    print("📸 Screenshot detectada — Flutter notificado")
  }
}