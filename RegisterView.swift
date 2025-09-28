import SwiftUI

private struct RegisterResponse: Decodable {
    let message: String
}

import Network

struct RegisterView: View {
    @Binding var isLoggedIn: Bool // Bejelentkezési állapot
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("Regisztráció")
                    .font(.largeTitle)
                    .padding()

                TextField("Felhasználónév", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("E-mail", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Jelszó", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: register) {
                    Text("Regisztráció")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Hiba"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                Spacer()
            }
            .padding() // Padding hozzáadása a VStack-hoz
            .onAppear {
                // Itt frissítheted a nézetet, ha szükséges
            }
        }
    }

    private func register() {
        guard let url = URL(string: "http://192.168.0.162:3000/register") else { return }
        let parameters = ["username": username, "email": email, "password": password]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Hiba a JSON kódolásakor: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
                return
            }
            guard let data = data else { return }
            if let registerResponse = try? JSONDecoder().decode(RegisterResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.alertMessage = registerResponse.message
                    if registerResponse.message == "Regisztráció sikeres!" {
                        self.isLoggedIn = true
                    }
                    self.showAlert = true
                }
            }
        }
        task.resume()
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(isLoggedIn: .constant(false))
    }
}

