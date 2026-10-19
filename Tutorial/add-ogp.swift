// Adds a title and Open Graph tags to the static site that `docc convert`
// writes, so that link previews show the tutorial instead of a blank card.
//
// DocC sets the title in JavaScript, which link preview crawlers do not run,
// and writes the same index.html for every page. This fills each page's
// index.html from that page's JSON, and makes the site root redirect to the
// tutorials overview.
//
// Usage: swift add-ogp.swift <site directory> <site URL ending in "/">

import Foundation

struct Page: Decodable {
  struct Metadata: Decodable {
    let title: String
    let role: String?
  }

  struct Section: Decodable {
    let kind: String
    let content: [Block]?
  }

  struct Block: Decodable {
    let type: String
    let inlineContent: [Inline]?
  }

  struct Inline: Decodable {
    let text: String?
    let code: String?
    let inlineContent: [Inline]?

    var plainText: String {
      text ?? code ?? (inlineContent ?? []).map(\.plainText).joined()
    }
  }

  let metadata: Metadata
  let sections: [Section]

  /// The first paragraph of the page's introduction.
  var summary: String {
    let hero = sections.first { $0.kind == "hero" }
    let paragraph = hero?.content?.first { $0.type == "paragraph" }
    return (paragraph?.inlineContent ?? []).map(\.plainText).joined()
  }
}

func escaped(_ text: String) -> String {
  text
    .replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
    .replacingOccurrences(of: "\"", with: "&quot;")
}

func tags(for page: Page, url: String, imageURL: String) -> String {
  let title = escaped(page.metadata.title)
  let summary = escaped(page.summary)
  return """
    <meta name="description" content="\(summary)">
    <meta property="og:type" content="article">
    <meta property="og:site_name" content="Statusphere for Swift">
    <meta property="og:title" content="\(title)">
    <meta property="og:description" content="\(summary)">
    <meta property="og:url" content="\(escaped(url))">
    <meta property="og:image" content="\(escaped(imageURL))">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="Statusphere for Swift">
    <meta name="twitter:card" content="summary_large_image">

    """
}

func replacingOnce(_ target: String, with replacement: String, in text: String, file: URL) -> String {
  guard let range = text.range(of: target) else {
    fatalError("\(target) not found in \(file.path)")
  }
  return text.replacingCharacters(in: range, with: replacement)
}

let arguments = CommandLine.arguments
guard arguments.count == 3, arguments[2].hasSuffix("/") else {
  FileHandle.standardError.write(Data("usage: swift add-ogp.swift <site directory> <site URL ending in \"/\">\n".utf8))
  exit(1)
}
let site = URL(fileURLWithPath: arguments[1])
let siteURL = arguments[2]
let imageURL = siteURL + "og.png"

let data = site.appendingPathComponent("data")
let enumerator = FileManager.default.enumerator(at: data, includingPropertiesForKeys: nil)!
var overview: (page: Page, path: String)?

for case let json as URL in enumerator where json.pathExtension == "json" {
  let page = try JSONDecoder().decode(Page.self, from: Data(contentsOf: json))
  // data/tutorials/statusphere.json is served at tutorials/statusphere/.
  let path = String(json.deletingPathExtension().path.dropFirst(data.path.count + 1)) + "/"
  let html = site.appendingPathComponent(path).appendingPathComponent("index.html")

  var text = try String(contentsOf: html, encoding: .utf8)
  text = replacingOnce(
    "<title>Documentation</title>", with: "<title>\(escaped(page.metadata.title))</title>", in: text, file: html)
  text = replacingOnce(
    "</head>", with: tags(for: page, url: siteURL + path, imageURL: imageURL) + "</head>", in: text, file: html)
  try text.write(to: html, atomically: true, encoding: .utf8)
  print("added Open Graph tags to \(path)")

  if page.metadata.role == "overview" {
    overview = (page, path)
  }
}

guard let overview else {
  fatalError("no tutorials overview page in \(data.path)")
}

// The catalog has only tutorials, so the site root sends visitors to them.
let redirect = """
  <!doctype html>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=\(overview.path)">
  <link rel="canonical" href="\(siteURL + overview.path)">
  <title>\(escaped(overview.page.metadata.title))</title>
  \(tags(for: overview.page, url: siteURL + overview.path, imageURL: imageURL))<a href="\(overview.path)">\(escaped(overview.page.metadata.title))</a>

  """
try redirect.write(to: site.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
print("redirected the site root to \(overview.path)")
