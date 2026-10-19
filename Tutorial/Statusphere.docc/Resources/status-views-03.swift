import StatusphereKit
import SwiftUI

struct StatusPickerView: View {
  let model: AppModel

  private let columns = [GridItem(.adaptive(minimum: 56))]

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Signed in as @\(model.myHandle ?? "")")
            .lineLimit(1)
          Spacer()
          Button("Sign out") {
            Task { await model.signOut() }
          }
        }
        Text("Set your status")
          .font(.headline)
        LazyVGrid(columns: columns, spacing: 8) {
          ForEach(AppModel.statusOptions, id: \.self) { status in
            Button {
              Task { await model.setStatus(status) }
            } label: {
              Text(status)
                .font(.largeTitle)
                .frame(width: 56, height: 56)
                .background(
                  status == model.myStatus ? Color.accentColor.opacity(0.25) : .clear,
                  in: .rect(cornerRadius: 10)
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(status == model.myStatus ? .isSelected : [])
          }
        }
      }
    }
  }
}

struct TopStatusesView: View {
  let top: [StatusIndex.TopStatus]

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Top Statuses")
          .font(.headline)
        FlowLayout(spacing: 8) {
          ForEach(top) { item in
            HStack(spacing: 4) {
              Text(item.status)
              Text("\(item.count)")
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.fill.tertiary, in: .capsule)
          }
        }
      }
    }
  }
}

struct RecentStatusesView: View {
  let recent: [StatusEntry]
  let handles: [String: String]

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Recent")
          .font(.headline)
        if recent.isEmpty {
          Text("No statuses yet. Be the first!")
            .foregroundStyle(.secondary)
        } else {
          TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 8) {
              ForEach(recent) { entry in
                HStack {
                  Text(entry.status)
                    .font(.title2)
                  Text("@\(handles[entry.authorDid] ?? entry.authorDid)")
                    .lineLimit(1)
                  Spacer()
                  Text(Self.relativeTime(from: entry.createdAt, to: context.date))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
              }
            }
          }
        }
      }
    }
  }

  /// "just now", "5m", "3h" or "2d", like the web version.
  static func relativeTime(from date: Date, to now: Date) -> String {
    let seconds = max(0, Int(now.timeIntervalSince(date)))
    switch seconds {
    case ..<60: return "just now"
    case ..<3600: return "\(seconds / 60)m"
    case ..<86_400: return "\(seconds / 3600)h"
    default: return "\(seconds / 86_400)d"
    }
  }
}

/// Lays its subviews out in rows, wrapping onto a new row when one is full.
struct FlowLayout: Layout {
  var spacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let rows = rows(for: subviews, width: proposal.width ?? .infinity)
    let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
    let width = rows.map(\.width).max() ?? 0
    return CGSize(width: width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var y = bounds.minY
    for row in rows(for: subviews, width: bounds.width) {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
      y += row.height + spacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
    var rows = [Row()]
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      if !rows[rows.count - 1].indices.isEmpty,
        rows[rows.count - 1].width + spacing + size.width > width
      {
        rows.append(Row())
      }
      var row = rows[rows.count - 1]
      row.width += (row.indices.isEmpty ? 0 : spacing) + size.width
      row.height = max(row.height, size.height)
      row.indices.append(index)
      rows[rows.count - 1] = row
    }
    return rows
  }
}
