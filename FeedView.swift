//
//  FeedView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

import SwiftUI
import PhotosUI
import UIKit

class Post: ObservableObject, Identifiable {
    let id = UUID()
    let serverId: Int? // MySQL ID
    @Published var content: String?
    @Published var image: UIImage?
    @Published var videoURL: URL?
    @Published var comments: [String] = []
    @Published var isShared: Bool = false
    @Published var likes: Int = 0
    let userId: Int
    let username: String
    let createdAt: Date
    
    init(serverId: Int? = nil, content: String? = nil, image: UIImage? = nil, videoURL: URL? = nil, userId: Int, username: String, createdAt: Date = Date()) {
        self.serverId = serverId
        self.content = content
        self.image = image
        self.videoURL = videoURL
        self.userId = userId
        self.username = username
        self.createdAt = createdAt
    }
    
    // Konvertálás szerverről érkező adatokból
    convenience init(from serverPost: ServerPost) {
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: serverPost.created_at) ?? Date()
        
        self.init(
            serverId: serverPost.id,
            content: serverPost.content,
            image: nil,
            videoURL: nil,
            userId: serverPost.user_id,
            username: serverPost.username ?? "Ismeretlen",
            createdAt: createdAt
        )
        self.likes = serverPost.likes
        self.comments = serverPost.comments?.map { $0.content } ?? []
    }
}

class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadPosts() {
        isLoading = true
        errorMessage = nil
        
        networkManager.fetchPosts { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let serverPosts):
                    self.posts = serverPosts.map { Post(from: $0) }
                case .failure(let error):
                    self.errorMessage = "Hiba a bejegyzések betöltésekor: \(error.localizedDescription)"
                    print("Hiba a bejegyzések betöltésekor: \(error)")
                }
            }
        }
    }
    
    func addPost(_ post: Post) {
        networkManager.createPost(
            content: post.content,
            image: post.image,
            videoURL: post.videoURL,
            userId: post.userId
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let postId):
                    print("Bejegyzés létrehozva ID: \(postId)")
                    // Frissítjük a post-ot a szerver ID-val
                    let updatedPost = Post(
                        serverId: postId,
                        content: post.content,
                        image: post.image,
                        videoURL: post.videoURL,
                        userId: post.userId,
                        username: post.username
                    )
                    self.posts.insert(updatedPost, at: 0)
                case .failure(let error):
                    self.errorMessage = "Hiba a bejegyzés létrehozásakor: \(error.localizedDescription)"
                    print("Hiba a bejegyzés létrehozásakor: \(error)")
                }
            }
        }
    }
    
    func addComment(to post: Post, comment: String) {
        guard let postId = post.serverId else { return }
        
        networkManager.addComment(to: postId, content: comment, userId: post.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[index].comments.append(comment)
                    }
                case .failure(let error):
                    self.errorMessage = "Hiba a komment hozzáadásakor: \(error.localizedDescription)"
                    print("Hiba a komment hozzáadásakor: \(error)")
                }
            }
        }
    }
    
    func likePost(_ post: Post) {
        guard let postId = post.serverId else { return }
        
        networkManager.likePost(postId, userId: post.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[index].likes += 1
                    }
                case .failure(let error):
                    self.errorMessage = "Hiba a like hozzáadásakor: \(error.localizedDescription)"
                    print("Hiba a like hozzáadásakor: \(error)")
                }
            }
        }
    }
    
    func deletePost(_ post: Post) {
        posts.removeAll { $0.id == post.id }
    }
    
    func deletePosts(at offsets: IndexSet) {
        posts.remove(atOffsets: offsets)
    }
}

struct FeedView: View {
    @StateObject private var postsViewModel = PostsViewModel()
    @State private var isRefreshing = false
    @State private var showSortOptions = false
    @State private var sortOption: SortOption = .newest
    @State private var newPost: String = ""
    @State private var newComment: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedVideoURL: URL?
    @State private var showImagePicker: Bool = false
    @State private var showVideoPicker: Bool = false
    @State private var searchText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showShareConfirmation: Bool = false
    @State private var postToDelete: Post?
    @State private var postToShare: Post?
    @State private var currentUser: User?

    @State private var commentTexts: [UUID: String] = [:]

    
    var sortedPosts: [Post] {
        let filtered = postsViewModel.posts.filter { post in
            searchText.isEmpty ||
            (post.content?.localizedCaseInsensitiveContains(searchText) == true) ||
            post.username.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortOption {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            return filtered.sorted { $0.likes > $1.likes }
        case .mostCommented:
            return filtered.sorted { $0.comments.count > $1.comments.count }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                searchField
                
                if postsViewModel.isLoading {
                    ProgressView("Bejegyzések betöltése...")
                        .padding()
                }
                
                if let error = postsViewModel.errorMessage {
                    ErrorView(message: error) {
                        postsViewModel.loadPosts()
                    }
                }
                
                postCreationSection
                sortOptionsSection
                postList
            }
            .navigationTitle("Közösségi Média")
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedImage)
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPickerView(videoURL: $selectedVideoURL)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                deleteConfirmationAlert
            }
            .alert(isPresented: $showShareConfirmation) {
                shareConfirmationAlert
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshFeed()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                loadCurrentUser()
                postsViewModel.loadPosts()
            }
        }
    }

    // MARK: - Subviews
    
    private var searchField: some View {
        TextField("Keresés...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    private var postCreationSection: some View {
        VStack {
            
            HStack{
                Image(systemName: "people")
                
                TextField("Írj bejegyzést...", text: $newPost)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
            
            
            HStack {
                Button("Kép feltöltése") {
                    showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Videó feltöltése") {
                    showVideoPicker = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: addPost) {
                Text("Megosztás")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.bottom)
            .disabled(newPost.isEmpty && selectedImage == nil && selectedVideoURL == nil)
        }
        .background(Color.gray.opacity(0.1))
    }

    private var sortOptionsSection: some View {
        HStack {
            Text("Rendezés:")
            Picker("Rendezés", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var postList: some View {
        List {
            ForEach(sortedPosts) { post in
                PostView(
                    post: post,
                    newComment: $newComment,
                    addComment: {
                        postsViewModel.addComment(to: post, comment: newComment)
                        newComment = ""
                    },
                    deleteComment: { comment in
                        // Lokális törlés - szerver oldali implementáció később
                        if let index = postsViewModel.posts.firstIndex(where: { $0.id == post.id }) {
                            postsViewModel.posts[index].comments.removeAll { $0 == comment }
                        }
                    },
                    deletePost: {
                        postToDelete = post
                        showDeleteConfirmation = true
                    },
                    likePost: {
                        postsViewModel.likePost(post)
                    },
                    sharePost: {
                        sharePost(post)
                    }
                )
                .padding(.vertical, 8)
            }
            .onDelete(perform: postsViewModel.deletePosts)
        }
        .refreshable {
            await refreshFeed()
        }
    }
    
    private var deleteConfirmationAlert: Alert {
        Alert(
            title: Text("Bejegyzés törlése"),
            message: Text("Biztosan törölni szeretnéd a bejegyzést?"),
            primaryButton: .destructive(Text("Törlés")) {
                if let post = postToDelete {
                    postsViewModel.deletePost(post)
                }
            },
            secondaryButton: .cancel()
        )
    }
    
    private var shareConfirmationAlert: Alert {
        Alert(
            title: Text("Bejegyzés megosztása"),
            message: Text("Biztosan szeretnéd a bejegyzést megosztani?"),
            primaryButton: .default(Text("Megosztás")) {
                if let post = postToShare {
                    post.isShared = true
                }
            },
            secondaryButton: .cancel()
        )
    }

    // MARK: - Helper Methods
    
    private func loadCurrentUser() {
        if let userId = UserDefaults.standard.object(forKey: "user_id") as? Int {
            NetworkManager.shared.fetchUser(userId: userId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        self.currentUser = user
                    case .failure(let error):
                        print("Hiba a felhasználó betöltésekor: \(error)")
                    }
                }
            }
        }
    }
    
    private func addPost() {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else {
            print("Nincs bejelentkezve felhasználó")
            return
        }
        
        let username = UserDefaults.standard.string(forKey: "username") ?? "Felhasználó"
        
        let post = Post(
            content: newPost.isEmpty ? nil : newPost,
            image: selectedImage,
            videoURL: selectedVideoURL,
            userId: userId,
            username: username
        )
        
        postsViewModel.addPost(post)
        newPost = ""
        selectedImage = nil
        selectedVideoURL = nil
    }

    @MainActor
    private func refreshFeed() async {
        isRefreshing = true
        postsViewModel.loadPosts()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        isRefreshing = false
    }

    private func sharePost(_ post: Post) {
        postToShare = post
        showShareConfirmation = true
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack {
            Text("Hiba")
                .font(.headline)
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
            Button("Újrapróbálás", action: onRetry)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}

enum SortOption: String, CaseIterable {
    case newest = "Legújabb"
    case oldest = "Legrégebbi"
    case mostLiked = "Legtöbb like"
    case mostCommented = "Legtöbb komment"
}

struct PostView: View {
    @ObservedObject var post: Post
    @Binding var newComment: String
    let addComment: () -> Void
    let deleteComment: (String) -> Void
    let deletePost: () -> Void
    let likePost: () -> Void
    let sharePost: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Felhasználó fejléc
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
            }
            
            // Tartalom
            if let content = post.content {
                Text(content)
                    .font(.body)
                    .padding(.vertical, 4)
            }
            
            // Kép
            if let image = post.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(8)
            }
            
            // Videó
            if let videoURL = post.videoURL {
                Text("Videó: \(videoURL.lastPathComponent)")
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Statisztikák
            HStack {
                Text("\(post.likes) like")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(post.comments.count) komment")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            // Művelet gombok
            HStack {
                Button(action: likePost) {
                    HStack {
                        Image(systemName: "heart")
                        Text("Like")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: sharePost) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.green)
                }
                
                Spacer()
                
                Button(action: deletePost) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .foregroundColor(.red)
                }
            }
            .buttonStyle(.borderless)
            .font(.caption)
            
            // Kommentek
            if !post.comments.isEmpty {
                VStack(alignment: .leading) {
                    Text("Kommentek:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 4)
                    
                    ForEach(post.comments, id: \.self) { comment in
                        CommentView(comment: comment, deleteAction: { deleteComment(comment) })
                    }
                }
            }
            
            // Új komment
            if post.isShared {
                VStack {
                    TextField("Írj kommentet...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addComment) {
                        Text("Küldés")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct CommentView: View {
    let comment: String
    let deleteAction: () -> Void
    
    var body: some View {
        HStack {
            Text("• \(comment)")
                .font(.subheadline)
                .padding(.leading)
            
            Spacer()
            
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(5)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    FeedView()
}
