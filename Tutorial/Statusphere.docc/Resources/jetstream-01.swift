import Foundation
import SwiftAtproto

/// A change to someone's `xyz.statusphere.status` records.
public enum StatusEvent: Sendable {
  case upsert(StatusEntry)
  case delete(uri: String)
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
