//
//  LoginView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

import SwiftUI
import DesignSystem


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
                Text(NSLocalizedString("login", comment: ""))
                    .font(.custom("gunplay", size: 40))
                    .foregroundStyle(
                            .linearGradient(
                                colors: [.orange, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    TextField(NSLocalizedString("username", comment: "Password field placeholder"), text: $username)
                        .font(.custom("OrelegaOne-Regular", size: 18))
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                            
                        )
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField(NSLocalizedString("password", comment: "Password field placeholder"), text: $password)                        .font(.custom("OrelegaOne-Regular", size: 18))
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



                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                } else {
                    Button(action: login) {
                        Text(NSLocalizedString("login", comment: ""))
                            .padding()
                            .padding(.horizontal,70)
                            .font(.custom("Jellee", size: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 5)
                                
                            )
                            .foregroundStyle(password.isEmpty ? Color.white.opacity(0.6): Color.white)
                            .background((LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom)))
                            .cornerRadius(20)
                            .shadow(color: .gray.opacity(0.9), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .disabled(username.isEmpty || password.isEmpty)
                }
                if !debugInfo.isEmpty {
                    VStack {
                        Text(debugInfo)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
                NavigationLink(destination: RegisterView(isLoggedIn: $isLoggedIn)) {
                    Text(NSLocalizedString("auth.no_account_register", comment: "No account prompt with registration link"))                        .font(.custom("OrelegaOne-Regular", size: 18))
                        .padding()
                        .foregroundStyle(Color.DesignSystem.szurke)
                        .font(.subheadline)
                      
                    
                }
                
                
                .padding(.top, 20)

                // Debug info


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
        //Bejelentkezés indítása
        debugInfo = ""

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
        debugInfo = ""

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
                        self.debugInfo = " \(loginResponse.message)"
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

struct StrokeText: View {
    let text: String
    let width: CGFloat
    let color: Color

    var body: some View {
        ZStack{
            ZStack{
                Text(text).offset(x:  width, y:  width)
                Text(text).offset(x: -width, y: -width)
                Text(text).offset(x: -width, y:  width)
                Text(text).offset(x:  width, y: -width)
            }
            .foregroundColor(color)
            Text(text)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
