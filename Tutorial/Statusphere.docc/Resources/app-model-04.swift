import Foundation
import Observation
import StatusphereKit

/// The state behind every screen: who is logged in, their status, and the
/// statuses seen on the network.
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
  private(set) var statuses = StatusIndex()
  private(set) var isLoggingIn = false
  /// Shown in the login form.
  private(set) var loginError: String?
  /// Shown at the top of the screen, for failures after logging in.
  var errorMessage: String?

  private let auth: AuthService
  private var feedTask: Task<Void, Never>?
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
    startFeed()
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
      let entry = try await session.setStatus(status)
      statuses.apply(.upsert(entry))
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

  /// Follows statuses from the whole network, starting a day back.
  private func startFeed() {
    feedTask = Task { [weak self] in
      let since = Date().addingTimeInterval(-24 * 60 * 60)
      for await event in Jetstream().statusEvents(since: since) {
        guard let self else { return }
        statuses.apply(event)
      }
    }
  }
}
