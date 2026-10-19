import Foundation
import Observation
import StatusphereKit

/// The state behind every screen: who is logged in and their status.
@Observable
final class AppModel {
  enum Phase {
    case launching
    case loggedOut
    case loggedIn(Session)
  }

  static let statusOptions = ["👍", "👎", "💙", "😎", "🦋", "🚀"]

  private(set) var phase: Phase = .launching
  private(set) var myStatus: String?
  private(set) var isLoggingIn = false
  /// Shown in the login form.
  private(set) var loginError: String?
  /// Shown at the top of the screen, for failures after logging in.
  var errorMessage: String?

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
        await didLogIn(session)
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
      await didLogIn(try await auth.login(handle: handle))
    } catch {
      loginError = error.localizedDescription
    }
  }

  func signOut() async {
    guard case .loggedIn(let session) = phase else { return }
    expiryTask?.cancel()
    await auth.signOut(session)
    myStatus = nil
    errorMessage = nil
    phase = .loggedOut
  }

  func setStatus(_ status: String) async {
    guard case .loggedIn(let session) = phase else { return }
    // Show the choice right away, like the web version does.
    let previous = myStatus
    myStatus = status
    do {
      _ = try await session.setStatus(status)
    } catch {
      myStatus = previous
      errorMessage = error.localizedDescription
    }
  }

  private func didLogIn(_ session: Session) async {
    phase = .loggedIn(session)
    expiryTask = Task { [weak self] in
      for await _ in session.expired {}
      guard !Task.isCancelled else { return }
      self?.phase = .loggedOut
      self?.loginError = "Your session has expired. Please log in again."
    }
    myStatus = try? await session.latestStatus()?.status
  }
}
