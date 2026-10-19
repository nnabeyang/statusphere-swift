import Foundation
import Observation
import StatusphereKit

/// The state behind every screen: who is logged in.
@Observable
final class AppModel {
  enum Phase {
    case launching
    case loggedOut
    case loggedIn(Session)
  }

  private(set) var phase: Phase = .launching
  private(set) var isLoggingIn = false
  /// Shown in the login form.
  private(set) var loginError: String?

  private let auth: AuthService
  private var expiryTask: Task<Void, Never>?

  init() {
    // Set by STATUSPHERE_OAUTH_HOST in Config/Base.xcconfig.
    guard let host = Bundle.main.object(forInfoDictionaryKey: "StatusphereOAuthHost") as? String else {
      preconditionFailure("StatusphereOAuthHost is missing from Info.plist")
    }
    auth = AuthService(configuration: OAuthConfiguration(host: host))
  }

  var did: String? {
    guard case .loggedIn(let session) = phase else { return nil }
    return session.did
  }

  func start() async {
    do {
      if let session = try await auth.restore() {
        didLogIn(session)
      } else {
        phase = .loggedOut
      }
    } catch {
      phase = .loggedOut
      loginError = error.localizedDescription
    }
  }

  func login(handle: String) async {
    var handle = handle.trimmingCharacters(in: .whitespaces)
    if handle.hasPrefix("@") {
      handle.removeFirst()
    }
    guard !handle.isEmpty else { return }
    isLoggingIn = true
    defer { isLoggingIn = false }
    loginError = nil
    do {
      didLogIn(try await auth.login(handle: handle))
    } catch {
      loginError = error.localizedDescription
    }
  }

  func signOut() async {
    guard case .loggedIn(let session) = phase else { return }
    expiryTask?.cancel()
    await auth.signOut(session)
    phase = .loggedOut
  }

  private func didLogIn(_ session: Session) {
    phase = .loggedIn(session)
    expiryTask = Task { [weak self] in
      for await _ in session.expired {}
      guard !Task.isCancelled else { return }
      self?.phase = .loggedOut
      self?.loginError = "Your session has expired. Please log in again."
    }
  }
}
