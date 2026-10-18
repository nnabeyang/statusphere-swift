import Foundation
import GermConvenienceURLSession
import SwiftAtproto

/// An unauthenticated XRPC client for the Bluesky AppView.
///
/// Used to resolve handles when logging in.
public struct PublicClient: XRPCCallable {
  public static let serviceEndpoint = URL(string: "https://public.api.bsky.app")!

  public init() {}

  public func getProxy(nsid: String) -> String? { nil }

  public func response(_ requestComponents: SwiftAtproto.XRPCRequestComponents) async throws -> Data {
    let request = try requestComponents.bundledRequest(serviceEndpoint: Self.serviceEndpoint)
    return try await URLSession.shared.data(for: request).xrpcData()
  }
}
