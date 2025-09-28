// LoginView.swift - javított verzió
import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Bejelentkezés")
                    .font(.largeTitle)
                    .padding()

                TextField("Felhasználónév", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Jelszó", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Button(action: login) {
                        Text("Bejelentkezés")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                NavigationLink(destination: RegisterView(isLoggedIn: $isLoggedIn)) {
                    Text("Regisztrálj itt")
                        .foregroundColor(.blue)
                }
                .padding()

                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Hiba"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Kérjük, töltsd ki mindkét mezőt!"
            showAlert = true
            return
        }

        isLoading = true
        
        guard let url = URL(string: "http://192.168.0.162:3000/login") else {
            alertMessage = "Érvénytelen URL"
            showAlert = true
            isLoading = false
            return
        }
        
        let parameters = ["username": username, "password": password]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            alertMessage = "Hiba a kérés elkészítésekor"
            showAlert = true
            isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = "Hálózati hiba: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Érvénytelen válasz"
                    showAlert = true
                    return
                }
                
                guard let data = data else {
                    alertMessage = "Nincs adat a válaszban"
                    showAlert = true
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Server response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                    if response.message == "Bejelentkezés sikeres!" {
                        isLoggedIn = true
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                        if let token = response.token {
                            UserDefaults.standard.set(token, forKey: "userToken")
                        }
                    } else {
                        alertMessage = response.message
                        showAlert = true
                    }
                } catch {
                    alertMessage = "Hiba a válasz feldolgozásakor: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        task.resume()
    }
}

struct LoginResponse: Codable {
    let message: String
    let token: String?
    let username: String?
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
