import Foundation

/// The statuses seen so far, and the views the home screen shows.
public struct StatusIndex: Sendable {
  public struct TopStatus: Sendable, Hashable, Identifiable {
    public let status: String
    public let count: Int

    public var id: String { status }
  }

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

  /// The statuses people currently have — each author's newest — ranked by
  /// how many people have them.
  public func top(limit: Int = 10) -> [TopStatus] {
    var current: [String: StatusEntry] = [:]
    for entry in entries.values {
      if let existing = current[entry.authorDid], existing.createdAt >= entry.createdAt {
        continue
      }
      current[entry.authorDid] = entry
    }

    var counts: [String: Int] = [:]
    for entry in current.values {
      counts[entry.status, default: 0] += 1
    }
    return
      counts
      .map { TopStatus(status: $0.key, count: $0.value) }
      .sorted { $0.count != $1.count ? $0.count > $1.count : $0.status < $1.status }
      .prefix(limit)
      .map { $0 }
  }
}
