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
