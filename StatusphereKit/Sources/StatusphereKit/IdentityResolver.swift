import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenienceURLSession

/// Resolves a handle to a DID with the Bluesky AppView, and a DID to its
/// document with plc.directory or the did:web host.
///
/// AtprotoOAuth checks that the handle and the document point at each other
/// (`verifiedResolve`), so trusting the AppView for the first step is enough.
public struct IdentityResolver: Atproto.Resolver {
  private let publicClient = PublicClient()
  private let plcResolver: Atproto.DidPlcResolver
  private let webResolver: Atproto.DidWebResolver

  public init() {
    let fetcher = ManualRedirectFetcher()
    // The default directory is a valid https origin, so this cannot throw.
    plcResolver = try! Atproto.DidPlcResolver(fetcher: fetcher)
    webResolver = Atproto.DidWebResolver(fetcher: fetcher)
  }

  public func resolve(handle: Atproto.Handle) async throws -> Atproto.DID? {
    let output = try await publicClient.IdentityResolveHandle(handle: .init(rawValue: handle.rawValue))
    return try Atproto.DID(string: output.did.rawValue)
  }

  public func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument? {
    if did.rawValue.hasPrefix("did:web:") {
      try await webResolver.resolve(did: did)
    } else {
      try await plcResolver.resolve(did: did)
    }
  }
}
