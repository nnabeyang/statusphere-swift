import Foundation

/// The statuses seen so far, and the views the home screen shows.
public struct StatusIndex: Sendable {
  private var entries: [String: StatusEntry] = [:]

  public init() {}

  public var isEmpty: Bool { entries.isEmpty }

  public mutating func apply(_ event: StatusEvent) {
    switch event {
    case .upsert(let entry):
      entries[entry.uri] = entry
    case .delete(let uri):
      entries[uri] = nil
    }
  }

  /// The newest statuses, most recent first.
  public func recent(limit: Int = 5) -> [StatusEntry] {
    Array(entries.values.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
  }
}
