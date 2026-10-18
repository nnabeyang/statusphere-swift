import Foundation
import SwiftAtproto

/// Looks up handles for DIDs with the Bluesky AppView, 25 at a time.
public actor HandleDirectory {
  private let client = PublicClient()
  private var handles: [String: String] = [:]

  public init() {}

  /// Returns the handles of `dids`, fetching the ones not seen yet. A DID
  /// whose profile cannot be found is left out.
  public func handles(for dids: some Sequence<String>) async -> [String: String] {
    let missing = Array(Set(dids).subtracting(handles.keys))
    for start in stride(from: 0, to: missing.count, by: 25) {
      let batch = missing[start..<min(start + 25, missing.count)]
      guard
        let output = try? await client.ActorGetProfiles(
          actors: batch.map { .init(rawValue: $0) }
        )
      else {
        continue
      }
      for profile in output.profiles {
        handles[profile.did.rawValue] = profile.handle.rawValue
      }
    }
    return handles
  }
}
