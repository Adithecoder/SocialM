//
//  LoginView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var debugInfo: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Bejelentkezés")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    TextField("Felhasználónév", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Jelszó", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                // Szerver információk
                VStack {
                    Text("Szerver: \(NetworkManager.shared.baseURL)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                } else {
                    Button(action: login) {
                        Text("Bejelentkezés")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(username.isEmpty || password.isEmpty)
                }

                NavigationLink(destination: RegisterView(isLoggedIn: $isLoggedIn)) {
                    Text("Még nincs fiókod? Regisztrálj itt")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                .padding(.top, 20)

                // Debug info
                if !debugInfo.isEmpty {
                    VStack {
                        Text("Debug Info:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text(debugInfo)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Bejelentkezés"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
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
        debugInfo = "Bejelentkezés indítása..."

        // Először teszteljük a szerver kapcsolatot
        testServerConnection { success in
            if success {
                performLogin()
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "A szerver nem elérhető. Ellenőrizd az ngrok kapcsolatot!"
                    self.showAlert = true
                    self.debugInfo = "Szerver nem elérhető"
                }
            }
        }
    }

    private func testServerConnection(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/test") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.debugInfo = "Hiba: \(error.localizedDescription)"
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.debugInfo = "HTTP Status: \(httpResponse.statusCode)"
                    completion(httpResponse.statusCode == 200)
                } else {
                    self.debugInfo = "Érvénytelen válasz"
                    completion(false)
                }
            }
        }
        task.resume()
    }

    private func performLogin() {
        debugInfo = "Bejelentkezési kérés küldése..."

        NetworkManager.shared.login(username: username, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let loginResponse):
                    if loginResponse.message.contains("sikeres") || loginResponse.message.contains("Sikeres") {
                        // Sikeres bejelentkezés
                        self.isLoggedIn = true
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(self.username, forKey: "username")
                        
                        if let token = loginResponse.token {
                            UserDefaults.standard.set(token, forKey: "userToken")
                        }
                        
                        if let userId = loginResponse.user_id {
                            UserDefaults.standard.set(userId, forKey: "user_id")
                        }
                        
                        self.alertMessage = "Sikeres bejelentkezés! Üdvözöljük, \(self.username)!"
                        self.debugInfo = "Sikeres bejelentkezés"
                    } else {
                        self.alertMessage = loginResponse.message
                        self.debugInfo = "Szerver hiba: \(loginResponse.message)"
                    }
                    
                case .failure(let error):
                    self.alertMessage = "Bejelentkezési hiba: \(error.localizedDescription)"
                    self.debugInfo = "Hiba: \(error.localizedDescription)"
                }
                
                self.showAlert = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
