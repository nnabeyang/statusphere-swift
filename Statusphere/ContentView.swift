import SwiftUI

struct ContentView: View {
  @State private var model = AppModel()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Sign in with your Atmosphere account.")
            .foregroundStyle(.secondary)

          switch model.phase {
          case .launching:
            ProgressView()
              .frame(maxWidth: .infinity)
          case .loggedOut:
            LoginView(model: model)
          case .loggedIn:
            SignedInView(model: model)
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
