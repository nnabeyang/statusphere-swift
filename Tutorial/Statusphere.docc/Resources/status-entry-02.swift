import Foundation
import SwiftAtproto

/// One `xyz.statusphere.status` record.
public struct StatusEntry: Sendable, Hashable, Identifiable {
  public let uri: String
  public let authorDid: String
  public let status: String
  public let createdAt: Date

  public var id: String { uri }

  public init(uri: String, authorDid: String, status: String, createdAt: Date) {
    self.uri = uri
    self.authorDid = authorDid
    self.status = status
    self.createdAt = createdAt
  }

  init(uri: String, authorDid: String, record: Xyz.Statusphere.Status) {
    self.init(
      uri: uri,
      authorDid: authorDid,
      status: record.status,
      createdAt: record.createdAt.typed ?? .distantPast
    )
  }
}

extension Session {
  /// Writes a new status record to the user's repository.
  public func setStatus(_ status: String) async throws -> StatusEntry {
    let record = try Xyz.Statusphere.Status.make(createdAt: .init(Date()), status: status)
    let output = try await pds.RepoCreateRecord(
      input: .init(
        collection: .init(rawValue: Xyz.Statusphere.Status.nsId),
        record: .record(record),
        repo: .init(rawValue: did)
      )
    )
    return StatusEntry(uri: output.uri.rawValue, authorDid: did, record: record)
  }
}
