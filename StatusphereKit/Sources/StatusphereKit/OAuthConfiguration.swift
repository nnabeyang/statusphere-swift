import Foundation
import OAuth4Swift

/// The OAuth client this app logs in as.
///
/// The client metadata is served by soyokaze-pds at
/// `https://<host>/statusphere/client-metadata.json`. A native client's
/// redirect scheme must be the client_id host reversed, so the host alone
/// determines the whole configuration.
public struct OAuthConfiguration: Sendable {
  public static let scopes = ["atproto", "repo:xyz.statusphere.status"]

  public let host: String

  public init(host: String) {
    self.host = host
  }

  public var clientId: String {
    "https://\(host)/statusphere/client-metadata.json"
  }

  public var redirectURI: URL {
    let scheme = host.split(separator: ".").reversed().joined(separator: ".")
    return URL(string: "\(scheme):/oauth")!
  }

  public var clientInfo: OAuth.ClientInfo {
    .init(clientId: clientId, scopes: Self.scopes, redirectURI: redirectURI)
  }
}
