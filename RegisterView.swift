//
//  RegisterView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

import SwiftUI

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var debugInfo: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Regisztráció")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    TextField("Felhasználónév", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("E-mail", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Jelszó", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    SecureField("Jelszó megerősítése", text: $confirmPassword)
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
                    Button(action: register) {
                        Text("Regisztráció")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(!isFormValid)
                }

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
                    title: Text("Regisztráció"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword
    }

    private func register() {
        guard isFormValid else {
            alertMessage = "Kérjük, töltsd ki minden mezőt helyesen!"
            showAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = "A jelszavak nem egyeznek!"
            showAlert = true
            return
        }

        isLoading = true
        debugInfo = "Regisztráció indítása..."

        // Először teszteljük a szerver kapcsolatot
        testServerConnection { success in
            if success {
                performRegistration()
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

    private func performRegistration() {
        debugInfo = "Regisztrációs kérés küldése..."

        NetworkManager.shared.register(username: username, email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let registerResponse):
                    self.alertMessage = registerResponse.message
                    
                    if registerResponse.message == "Sikeres regisztráció" {
                        // Sikeres regisztráció után automatikus bejelentkezés
                        self.debugInfo = "Sikeres regisztráció"
                        // Itt lehetne automatikusan bejelentkeztetni
                    }
                    
                case .failure(let error):
                    self.alertMessage = "Regisztrációs hiba: \(error.localizedDescription)"
                    self.debugInfo = "Hiba: \(error.localizedDescription)"
                }
                
                self.showAlert = true
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(isLoggedIn: .constant(false))
    }
}
