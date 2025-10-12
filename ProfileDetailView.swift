//
//  ProfileDetailView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

import SwiftUI

struct ProfileDetailView: View {
    let userId: Int
    let username: String
    
    @State private var user: User?
    @State private var userPosts: [Post2] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showMessageSheet = false
    @State private var showUserMenu = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Profil betöltése...")
                            .padding()
                    } else if let user = user {
                        userProfileHeader(user: user)
                        userStatisticsSection
                        userPostsSection
                    } else if let error = errorMessage {
                        ErrorView(message: error) {
                            loadUserData()
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showUserMenu = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            }
            .onAppear {
                loadUserData()
                loadUserPosts()
            }
            .sheet(isPresented: $showMessageSheet) {
                MessageComposerView(
                    recipientId: userId,
                    recipientName: username,
                    isPresented: $showMessageSheet
                )
            }
            .confirmationDialog("Műveletek", isPresented: $showUserMenu) {
                Button("Üzenet küldése") {
                    showMessageSheet = true
                }
                
                Button("Követés", role: .none) {
                    followUser()
                }
                
                Button("Jelentés", role: .destructive) {
                    reportUser()
                }
                
                Button("Mégse", role: .cancel) {}
            }
        }
    }
    
    private func userProfileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            // Profilkép
            if let profilePicture = user.profile_picture,
               !profilePicture.isEmpty,
               let url = URL(string: "http://localhost:3000\(profilePicture)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
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
            
            // Felhasználó információk
            VStack(spacing: 8) {
                Text(user.username)
                    .font(.custom("Jellee", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let email = user.email {
                    Text(email)
                        .font(.lexend())
                        .foregroundColor(.gray)
                }
                
                // Csatlakozás dátuma - csak évszám
                if let joinYear = getJoinYear(from: user.created_at) {
                    Text("Tag \(joinYear) óta")
                        .font(.lexend3())
                        .foregroundColor(.secondary)
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Művelet gombok
            HStack(spacing: 12) {
                Button(action: {
                    showMessageSheet = true
                }) {
                    Text("Üzenet")
                        .font(.lexend())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .blue]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(20)
                }
                
                Button(action: {
                    followUser()
                }) {
                    Text("Követés")
                        .font(.lexend())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .cornerRadius(20)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
private var userStatisticsSection: some View {
    VStack(spacing: 16) {
        Text("Statisztikák")
            .font(.custom("Jellee", size: 20))
            .padding(.bottom, 8)
        
        HStack {
            StatView(title: "Bejegyzések", value: "\(userPosts.count)")
            Spacer()
            StatView(title: "Like-ok", value: "\(userPosts.reduce(0) { $0 + $1.likes })")
            Spacer()
            StatView(title: "Kommentek", value: "\(userPosts.reduce(0) { $0 + $1.comments.count })")
        }
        .padding(.horizontal)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
}
    
    private var userPostsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bejegyzések")
                .font(.custom("Jellee", size: 20))
                .padding(.horizontal)
            
            if userPosts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Még nincsenek bejegyzések")
                        .font(.lexend())
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(userPosts.prefix(10)) { post in
                        UserPostPreviewView(post: post)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserData() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.fetchUser(userId: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let userData):
                    self.user = userData
                case .failure(let error):
                    self.errorMessage = "Hiba a profil betöltésekor: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadUserPosts() {
        NetworkManager.shared.fetchUserPosts(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let serverPosts):
                    self.userPosts = serverPosts.map { Post2(from: $0) }
                case .failure(let error):
                    print("Hiba a bejegyzések betöltésekor: \(error)")
                }
            }
        }
    }
    
    private func getJoinYear(from dateString: String) -> String? {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return "\(year)"
    }
    
    private func followUser() {
        guard let currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int else { return }
        
        NetworkManager.shared.followUser(followerId: currentUserId, followingId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Sikeres követés")
                case .failure(let error):
                    print("Hiba a követésnél: \(error)")
                }
            }
        }
    }
    
    private func reportUser() {
        // Jelentés funkció implementációja
        print("Felhasználó jelentése: \(userId)")
    }
}

// MARK: - Supporting Views

struct UserPostPreviewView: View {
    let post: Post2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tartalom
            if let content = post.content {
                Text(content)
                    .font(.lexend())
                    .lineLimit(3)
                    .foregroundColor(.primary)
            }
            
            // Kép előnézet
            if let image = post.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(8)
            }
            
            // Statisztikák
            HStack {
                HStack {
                    Image(systemName: "heart")
                        .font(.caption)
                    Text("\(post.likes)")
                        .font(.lexend3())
                }
                .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "text.bubble")
                        .font(.caption)
                    Text("\(post.comments.count)")
                        .font(.lexend3())
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                Text(post.createdAt.timeAgoDisplay())
                    .font(.lexend3())
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}




// MARK: - Network Manager Extension

extension NetworkManager {
    func fetchUserPosts(userId: Int, completion: @escaping (Result<[ServerPost], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/users/\(userId)/posts")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let serverPosts = try JSONDecoder().decode([ServerPost].self, from: data)
                completion(.success(serverPosts))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func followUser(followerId: Int, followingId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/follow")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "follower_id": followerId,
            "following_id": followingId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
}

#Preview {
    ProfileDetailView(userId: 1, username: "Példa Felhasználó")
}
