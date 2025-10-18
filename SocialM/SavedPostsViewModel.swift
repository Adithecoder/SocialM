//
//  SavedPostsViewModel.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/7/25.
//


//
//  SavedPostsView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

import SwiftUI

class SavedPostsViewModel: ObservableObject {
    @Published var savedPosts: [Post2] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadSavedPosts() {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else {
            errorMessage = "No user logged in. Consider checking login status."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(networkManager.baseURL)/users/\(userId)/saved-posts") else {
            errorMessage = "Érvénytelen URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Hiba a mentett posztok betöltésekor: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "Nincs adat a válaszban"
                    return
                }
                
                do {
                    let serverPosts = try JSONDecoder().decode([ServerPost].self, from: data)
                    self.savedPosts = serverPosts.map { Post2(from: $0) }
                } catch {
                    self.errorMessage = "Hiba az adatok feldolgozásakor: \(error.localizedDescription)"
                    print("JSON dekódolási hiba: \(error)")
                }
            }
        }.resume()
    }
    
    func removeFromSaved(_ post: Post2) {
        guard let postId = post.serverId,
              let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else { return }
        
        let url = URL(string: "\(networkManager.baseURL)/posts/\(postId)/save")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["user_id": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Hiba a mentés visszavonásakor: \(error.localizedDescription)"
                    return
                }
                
                // Frissítjük a lokális listát
                self.savedPosts.removeAll { $0.id == post.id }
            }
        }.resume()
    }
}

struct SavedPostsView: View {
    @StateObject private var viewModel = SavedPostsViewModel()
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Mentett posztok betöltése...")
                        .padding()
                }
                
                if let error = viewModel.errorMessage {
                    ErrorView2(message: error) {
                        viewModel.loadSavedPosts()
                    }
                }
                
                if viewModel.savedPosts.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    postsList
                }
            }
            .navigationTitle("Mentett posztok")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.loadSavedPosts()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.brown, .brown.opacity(0.1)]), startPoint: .leading, endPoint: .trailing))
            Text("Nincsenek mentett posztok")
                .font(.lexend())
                .fontWeight(.semibold)
            
            Text("Amikor mentesz egy posztot, az itt fog megjelenni.")
                .font(.lexend2())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.savedPosts) { post in
                    SavedPostCard(post: post, onRemove: {
                        viewModel.removeFromSaved(post)
                    })
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await refresh()
        }
    }
    
    @MainActor
    private func refresh() async {
        isRefreshing = true
        viewModel.loadSavedPosts()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        isRefreshing = false
    }
}

struct SavedPostCard: View {
    let post: Post2
    let onRemove: () -> Void
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Fejléc
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(post.username)
                        .font(.headline)
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Eltávolítás gomb
                Button(action: onRemove) {
                    Image(systemName: "bookmark.slash")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
            }
            
            // Tartalom előnézet
            if let content = post.content {
                Text(content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.primary)
            }
            
            // Kép előnézet
            if post.image != nil {
                Text("[Kép]")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
            }
            
            // Videó előnézet
            if post.videoURL != nil {
                Text("[Videó]")
                    .font(.caption)
                    .foregroundColor(.green)
                    .italic()
            }
            
            // Statisztikák
            HStack {
                HStack {
                    Image(systemName: "heart")
                        .font(.caption)
                    Text("\(post.likes)")
                        .font(.caption)
                }
                .foregroundColor(.red)
                
                HStack {
                    Image(systemName: "text.bubble")
                        .font(.caption)
                    Text("\(post.comments.count)")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Megtekintés") {
                    showDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showDetail) {
            NavigationView {
                PostDetailFullView(
                    post2: post,
                    onCommentAdded: { _ in },
                    onLike: { },
                    onDelete: { },
                    onSave: { }
                )
            }
        }
    }
}


#Preview {
    SavedPostsView()
}
