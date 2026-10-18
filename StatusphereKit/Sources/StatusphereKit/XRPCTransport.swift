import Foundation
import GermConvenience
import GermConvenienceHTTP
import HTTPTypes
import SwiftAtproto

extension SwiftAtproto.XRPCRequestComponents {
  /// Builds the HTTP request for this XRPC call against `serviceEndpoint`.
  func bundledRequest(serviceEndpoint: URL) throws -> BundledHTTPRequest {
    var components = try URLComponents(
      url: serviceEndpoint,
      resolvingAgainstBaseURL: false
    ).tryUnwrap
    components.path = relativePath
    if !queryItems.isEmpty {
      components.percentEncodedQueryItems = queryItems
    }

    var headerFields = headers
    headerFields[.accept] = "application/json"

    return try BundledHTTPRequest(
      method: method,
      url: components.url.tryUnwrap,
      headerFields: headerFields,
      body: body
    )
  }
}

extension HTTPDataResponse {
  /// Returns the response body, or throws the XRPC error the service sent.
  ///
  /// The generated methods convert an `UnExpectedError` into their own error
  /// type, so the service's `error` and `message` reach the caller.
  func xrpcData() throws -> Data {
    guard response.status.kind == .successful else {
      let body = try? JSONDecoder().decode(XRPCErrorBody.self, from: data)
      throw UnExpectedError(
        error: body?.error ?? "HTTP \(response.status.code)",
        message: body?.message
      )
    }
    return data
  }
}

private struct XRPCErrorBody: Decodable {
  let error: String?
  let message: String?
}
