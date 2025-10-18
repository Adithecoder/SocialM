//
//  ProfileView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @State private var user: User?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    
    // ProfileView struct-hoz add hozzá ezt a konstruktort:
    init(isLoggedIn: Binding<Bool>, userId: Int? = nil) {
        self._isLoggedIn = isLoggedIn
        if let userId = userId {
            // Más felhasználó profiljának betöltése
        } else {
            // Saját profil betöltése
        }
    }
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Adatok betöltése...")
                        .padding()
                } else if let user = user {
                    userProfileView(user: user)
                } else if let error = errorMessage {
                    ErrorView3(message: error) {
                        loadUserData()
                    }
                }
                
                Spacer()
                
                Button(action: logout) {
                    NavigationLink(destination: LogoutView(isLoggedIn: $isLoggedIn)) {
                        
                        Text("Kijelentkezés")
                            .font(.lexend())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                .linearGradient(
                                    colors: [.red.opacity(0.8), .red.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )                        .cornerRadius(20)
                    }
                    .padding()
                }
            }
            .onAppear {
                loadUserData()
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    uploadProfilePicture(image: image)
                }
            }
        }
    }
    
    private func userProfileView(user: User) -> some View {
        VStack(spacing: 20) {
            // Profilkép megjelenítése
            VStack(spacing: 10) {
                if let profilePicture = user.profile_picture,
                   !profilePicture.isEmpty,
                   let url = URL(string: "http://localhost:3000\(profilePicture)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        case .failure:
                            defaultProfileImage
                        @unknown default:
                            defaultProfileImage
                        }
                    }
                } else {
                    defaultProfileImage
                }
                
                // Profilkép módosítás gombok
                HStack(spacing: 15) {
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        Text("Kép módosítása")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: photosPickerItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                            }
                        }
                    }
                    
                    if user.profile_picture != nil && !user.profile_picture!.isEmpty {
                        Button(action: {
                            removeProfilePicture()
                        }) {
                            Text("Eltávolítás")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            VStack(spacing: 8) {
                Text(user.username)
                    .font(.custom("Jellee", size:28))
                    .fontWeight(.bold)
                
                if let email = user.email {
                    Text(email)
                        .font(.lexend())
                        .foregroundColor(.gray)
                }
                
                
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                

            }
            .padding()
            
            // Statisztikák
            VStack(spacing: 16) {
                Text("Statisztikák")
                    .font(.custom("Jellee", size:20))
                    .padding(.bottom, 8)
                
                HStack {
                    StatView(title: "Bejegyzések", value: "0")
                    Spacer()
                    StatView(title: "Like-ok", value: "0")
                    Spacer()
                    StatView(title: "Kommentek", value: "0")
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            HStack {
                VStack {
                    Text("Regisztrálva")
                        .font(.custom("Jellee", size:16))
                        .foregroundColor(.gray)
                    Text(formatDate(user.created_at))
                        .font(.lexend3())
                        .fontWeight(.medium)
                }

                Spacer()
                VStack {
                    Text("Utolsó bejelentkezés")
                        .font(.custom("Jellee", size:16))
                        .foregroundColor(.gray)
                    Text(user.last_login != nil ? formatDate(user.last_login!) : "Még nem")
                        .font(.lexend3())
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
    }
    
    private func loadUserData() {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else {
            errorMessage = "Nincs bejelentkezve felhasználó"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.fetchUser(userId: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let userData):
                    self.user = userData
                case .failure(let error):
                    self.errorMessage = "Hiba az adatok betöltésekor: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadProfilePicture(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            return
        }
        
        isLoading = true
        
        let url = URL(string: "http://localhost:3000/api/upload-profile-picture")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Kép hozzáadása
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profilePicture\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.errorMessage = "Hiba a feltöltéskor: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "Nincs válasz a szervertől"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ProfilePictureResponse.self, from: data)
                    // Frissítsd a felhasználó adatait
                    loadUserData()
                } catch {
                    print("JSON dekódolási hiba: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Szerver válasza: \(responseString)")
                    }
                    self.errorMessage = "Hiba a válasz feldolgozásakor"
                }
            }
        }.resume()
    }
    
    private func removeProfilePicture() {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            return
        }
        
        isLoading = true
        
        let url = URL(string: "http://localhost:3000/api/remove-profile-picture")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.errorMessage = "Hiba a törléskor: \(error.localizedDescription)"
                    return
                }
                
                // Frissítsd a felhasználó adatait
                loadUserData()
            }
        }.resume()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        displayFormatter.locale = Locale(identifier: "hu_HU")
        
        return displayFormatter.string(from: date)
    }
    
    private func logout() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "user_id")
    }
}
struct LoginRecord: Codable, Identifiable {
    let id: Int
    let login_date: String
    let device: String?
    let location: String?
}

// Popup view a bejelentkezési előzményekhez
struct LoginHistoryPopup: View {
    @Binding var isShowing: Bool
    let loginHistory: [LoginRecord]
    let isLoading: Bool
    let user: User
    
    var body: some View {
        VStack(spacing: 0) {
            // Fejléc
            HStack {
                Text("Bejelentkezési előzmények")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Regisztráció és utolsó bejelentkezés információk
            VStack(spacing: 12) {
                HStack {
                    VStack {
                        Text("Regisztrálva")
                            .font(.custom("Jellee", size:14))
                            .foregroundColor(.gray)
                        Text(formatDisplayDate(user.created_at))
                            .font(.lexend3())
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Utolsó bejelentkezés")
                            .font(.custom("Jellee", size:14))
                            .foregroundColor(.gray)
                        Text(user.last_login != nil ? formatDisplayDate(user.last_login!) : "Még nem")
                            .font(.lexend3())
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
                
                Divider()
            }
            .padding(.top, 8)
            
            if isLoading {
                ProgressView("Előzmények betöltése...")
                    .padding()
            } else if loginHistory.isEmpty {
                Text("Nincs elérhető bejelentkezési adat")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(loginHistory) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDisplayDate(record.login_date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            if let device = record.device {
                                Text(device)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let location = record.location {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(width: 320, height: 450)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    private func formatDisplayDate(_ dateString: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        displayFormatter.locale = Locale(identifier: "hu_HU")
        
        return displayFormatter.string(from: date)
    }
}
// Segéd struktúrák
struct ProfilePictureResponse: Codable {
    let message: String
    let imageUrl: String
}



struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.lexend())
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(title)
                .font(.lexend3())
                .foregroundColor(.gray)
        }
    }
}

struct ErrorView3: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Újrapróbálás", action: onRetry)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(isLoggedIn: .constant(true))
    }
}
