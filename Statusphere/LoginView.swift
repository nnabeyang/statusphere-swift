import SwiftUI

struct LoginView: View {
  let model: AppModel
  @State private var handle = ""

  var body: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Handle")
          .font(.headline)
        TextField("alice.bsky.social", text: $handle)
          .textFieldStyle(.roundedBorder)
          .textContentType(.username)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .onSubmit(login)
        if let loginError = model.loginError {
          Text(loginError)
            .font(.callout)
            .foregroundStyle(.red)
        }
        Button(action: login) {
          Text(model.isLoggingIn ? "Logging in..." : "Login to the Atmosphere")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(handle.isEmpty || model.isLoggingIn)
      }
    }
  }

  private func login() {
    Task { await model.login(handle: handle) }
  }
}
