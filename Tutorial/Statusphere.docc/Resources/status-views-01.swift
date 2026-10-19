import SwiftUI

struct StatusPickerView: View {
  let model: AppModel

  private let columns = [GridItem(.adaptive(minimum: 56))]

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Signed in as \(model.did ?? "")")
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
