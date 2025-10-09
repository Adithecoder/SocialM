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
                    .font(.custom("gunplay", size: 40))
                    .foregroundStyle(
                            .linearGradient(
                                colors: [.orange, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    TextField("Felhasználónév", text: $username)
                        .font(.custom("OrelegaOne-Regular", size: 18))
                        .padding()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                            
                        )
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)

                    TextField("E-mail", text: $email)               .font(.custom("OrelegaOne-Regular", size: 18))

                        .padding()
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                            
                        )
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)

                    SecureField("Jelszó", text: $password)
                        .font(.custom("OrelegaOne-Regular", size: 18))
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                            
                        )
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)

                    SecureField("Jelszó megerősítése", text: $confirmPassword)
                        .font(.custom("OrelegaOne-Regular", size: 18))
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                            
                        )
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                
                .padding(.horizontal)

                // Szerver információk
//                VStack {
//                    Text("Szerver: //\(NetworkManager.shared.baseURL)")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                .padding()

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                } else {
                    Button(action: register) {
                        Text("Regisztráció")
                            .padding()
                            .padding(.horizontal,70)
                            .font(.custom("Jellee", size: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                                
                            )
                            .foregroundStyle(isFormValid ? Color.white: Color.white.opacity(0.6))
                            .background((LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom)))
                            .cornerRadius(20)
                            .shadow(color: .gray.opacity(0.9), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .disabled(!isFormValid)
                }
//                Circle()
//                    .strokeBorder(
//                        AngularGradient(gradient: //Gradient(colors: [.red, .yellow, //.green, .blue, .purple, .red]), //center: .center, startAngle: .zero, //endAngle: .degrees(360)),
//                        lineWidth: 50
//                    )
//                    .frame(width: 200, height: 200)
                VStack {
                    Text("Regisztrációddal elfogad alkalmazásunk általános szerződési feltételeit. Bővebben a ... oldalon olvashatsz.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top,200)

                

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
extension View {
    func multicolorGlow() -> some View {
        ZStack {
            ForEach(0..<2) { i in
                Rectangle()
                    .fill(AngularGradient(gradient: Gradient(colors:
[Color.blue, Color.purple, Color.orange, Color.red]), center: .center))
                    .frame(width: 400, height: 300)
                    .mask(self.blur(radius: 20))
                    .overlay(self.blur(radius: 5 - CGFloat(i * 5)))
            }
        }
    }
}
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(isLoggedIn: .constant(false))
    }
}
