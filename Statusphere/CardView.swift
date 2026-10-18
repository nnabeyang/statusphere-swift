import SwiftUI

struct CardView<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    content
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.background.secondary, in: .rect(cornerRadius: 12))
  }
}
