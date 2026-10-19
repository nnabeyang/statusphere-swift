import SwiftUI

struct ContentView: View {
  @State private var model = AppModel()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Set your status on the Atmosphere.")
            .foregroundStyle(.secondary)

          if let errorMessage = model.errorMessage {
            Text(errorMessage)
              .font(.callout)
              .foregroundStyle(.red)
          }

          switch model.phase {
          case .launching:
            ProgressView()
              .frame(maxWidth: .infinity)
          case .loggedOut:
            LoginView(model: model)
          case .loggedIn:
            StatusPickerView(model: model)
          }
        }
        .padding()
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
      }
      .navigationTitle("Statusphere")
    }
    .task {
      await model.start()
    }
  }
}

#Preview {
  ContentView()
}
