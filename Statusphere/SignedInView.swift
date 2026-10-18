import SwiftUI

struct SignedInView: View {
  let model: AppModel

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Signed in as \(model.did ?? "")")
            .font(.callout.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
          Spacer()
          Button("Sign out") {
            Task { await model.signOut() }
          }
        }
        Text("Authentication working!")
          .foregroundStyle(.green)
      }
    }
  }
}
