import Foundation
import SwiftAtproto

/// A change to someone's `xyz.statusphere.status` records.
public enum StatusEvent: Sendable {
  case upsert(StatusEntry)
  case delete(uri: String)
}

/// Streams status records from the whole network through Jetstream.
///
/// There is no server here to keep an index, so the app replays the recent
/// past on launch (Jetstream keeps roughly a day of events) and then follows
/// new events live.
public struct Jetstream: Sendable {
  public static let endpoint = URL(string: "wss://jetstream2.us-east.bsky.network/subscribe")!

  public init() {}

  /// Events since `start`, reconnecting from the last seen event on failure.
  public func statusEvents(since start: Date) -> AsyncStream<StatusEvent> {
    AsyncStream { continuation in
      let task = Task {
        var cursor = Int64(start.timeIntervalSince1970 * 1_000_000)
        while !Task.isCancelled {
          do {
            try await receive(from: cursor) { event, timeUs in
              cursor = timeUs
              if let event {
                continuation.yield(event)
              }
            }
          } catch {
            try? await Task.sleep(for: .seconds(3))
          }
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func receive(
    from cursor: Int64,
    handle: (StatusEvent?, Int64) -> Void
  ) async throws {
    var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "wantedCollections", value: Xyz.Statusphere.Status.nsId),
      URLQueryItem(name: "cursor", value: String(cursor)),
    ]
    let socket = URLSession.shared.webSocketTask(with: components.url!)
    socket.resume()
    defer { socket.cancel(with: .goingAway, reason: nil) }

    let decoder = JSONDecoder()
    while !Task.isCancelled {
      let data: Data
      switch try await socket.receive() {
      case .data(let message):
        data = message
      case .string(let message):
        data = Data(message.utf8)
      @unknown default:
        continue
      }
      guard let message = try? decoder.decode(Message.self, from: data) else {
        continue
      }
      handle(message.event, message.timeUs)
    }
  }
}

private struct Message: Decodable {
  struct Commit: Decodable {
    let operation: String
    let collection: String
    let rkey: String
    let record: Xyz.Statusphere.Status?

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      operation = try container.decode(String.self, forKey: .operation)
      collection = try container.decode(String.self, forKey: .collection)
      rkey = try container.decode(String.self, forKey: .rkey)
      // A record that does not follow the Lexicon is skipped, like the
      // Node.js version does.
      record = try? container.decodeIfPresent(Xyz.Statusphere.Status.self, forKey: .record)
    }

    enum CodingKeys: String, CodingKey {
      case operation, collection, rkey, record
    }
  }

  let did: String
  let timeUs: Int64
  let kind: String
  let commit: Commit?

  enum CodingKeys: String, CodingKey {
    case did
    case timeUs = "time_us"
    case kind
    case commit
  }

  var event: StatusEvent? {
    guard kind == "commit", let commit, commit.collection == Xyz.Statusphere.Status.nsId else {
      return nil
    }
    let uri = "at://\(did)/\(commit.collection)/\(commit.rkey)"
    switch commit.operation {
    case "create", "update":
      guard let record = commit.record else { return nil }
      return .upsert(StatusEntry(uri: uri, authorDid: did, record: record))
    case "delete":
      return .delete(uri: uri)
    default:
      return nil
    }
  }
}
