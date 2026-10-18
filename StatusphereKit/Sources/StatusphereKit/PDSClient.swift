import AtprotoOAuth
import Foundation
import OAuth4Swift
import SwiftAtproto

/// An XRPC client for the logged-in user's PDS.
///
/// The generated methods prepare each request; the OAuth agent sends it with
/// the access token and a DPoP proof, and refreshes the token when needed.
public struct PDSClient: XRPCCallable {
  let agent: AtprotoOAuthAgent
  let serviceEndpoint: URL

  public func getProxy(nsid: String) -> String? { nil }

  public func response(_ requestComponents: SwiftAtproto.XRPCRequestComponents) async throws -> Data {
    let request = try requestComponents.bundledRequest(serviceEndpoint: serviceEndpoint)
    return try await agent.authResponse(for: request).xrpcData()
  }
}
