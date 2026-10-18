import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import AuthenticationServices
import Foundation
import GermConvenience
import GermConvenienceURLSession
import OAuth4Swift

/// Logs in with atproto OAuth, restores the saved session, and logs out.
public struct AuthService: Sendable {
  private let client: AtprotoOAuthClient
  private let resolver = IdentityResolver()
  private let store = SessionStore()

  public init(configuration: OAuthConfiguration) {
    client = AtprotoOAuthClient(
      clientInfo: configuration.clientInfo,
      resolver: resolver,
      authFetcher: ManualRedirectFetcher(),
      userAuthenticator: ASWebAuthenticationSession.userAuthenticator()
    )
  }

  /// Opens the authorization server's login page for `handle` and returns
  /// the new session.
  public func login(handle: String) async throws -> Session {
    let (sessionArchive, did) = try await client.authorize(
      identity: .handle(try Atproto.Handle(string: handle))
    )
    let archive = AtprotoOAuthAgent.Archive(did: did.rawValue, session: sessionArchive)
    try store.save(archive)
    return try await start(archive: archive)
  }

  /// Returns the session saved by a previous launch, if any.
  public func restore() async throws -> Session? {
    guard let archive = try store.load(), archive.session != nil else {
      return nil
    }
    return try await start(archive: archive)
  }

  /// Revokes the session's refresh token and forgets the session.
  public func signOut(_ session: Session) async {
    if let refreshToken = try? store.load()?.session?.tokenState.refreshToken,
      let metadata = try? await session.agent.authServerMetadata
    {
      try? await session.agent.revocationRequest(authServerMetadata: metadata, token: refreshToken)
    }
    session.stop()
    store.delete()
  }

  private func start(archive: AtprotoOAuthAgent.Archive) async throws -> Session {
    let (agent, tokenUpdates) = try client.restore(archive: archive)
    let document = try await resolver.resolve(did: agent.authenticatedDID).tryUnwrap
    return Session(
      agent: agent,
      pds: PDSClient(agent: agent, serviceEndpoint: try document.pdsUrl),
      archive: archive,
      tokenUpdates: tokenUpdates,
      store: store
    )
  }
}

/// A logged-in user.
public final class Session: Sendable {
  public let did: String
  public let pds: PDSClient
  /// Finishes when the session can no longer be refreshed and the user has
  /// to log in again.
  public let expired: AsyncStream<Void>

  let agent: AtprotoOAuthAgent
  private let persistence: Task<Void, Never>

  init(
    agent: AtprotoOAuthAgent,
    pds: PDSClient,
    archive: AtprotoOAuthAgent.Archive,
    tokenUpdates: AsyncStream<OAuth.SessionState.TokenState?>,
    store: SessionStore
  ) {
    did = agent.authenticatedDID.rawValue
    self.agent = agent
    self.pds = pds

    let (expired, expiredContinuation) = AsyncStream<Void>.makeStream()
    self.expired = expired

    // Refreshed tokens only arrive here, so save each one; otherwise the next
    // launch would restore a refresh token that has already been used.
    persistence = Task {
      var archive = archive
      for await tokenState in tokenUpdates {
        guard let tokenState else {
          store.delete()
          expiredContinuation.finish()
          return
        }
        archive.session?.tokenState = tokenState
        try? store.save(archive)
      }
    }
  }

  deinit {
    persistence.cancel()
  }

  func stop() {
    persistence.cancel()
  }
}
