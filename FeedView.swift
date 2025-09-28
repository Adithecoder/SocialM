//
//  FeedView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

// Your imports remain the same
import SwiftUI
import PhotosUI
import UIKit

// Update the Post class to conform to ObservableObject
class Post: ObservableObject, Identifiable {
    let id = UUID()
    @Published var content: String?
    @Published var image: UIImage?
    @Published var videoURL: URL?
    @Published var comments: [String] = []
    @Published var isShared: Bool = false
    @Published var likes: Int = 0
    
    init(content: String? = nil, image: UIImage? = nil, videoURL: URL? = nil) {
        self.content = content
        self.image = image
        self.videoURL = videoURL
    }
}

// Add this ViewModel to manage posts
class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    var filteredPosts: [Post] {
        // Implement your filtering logic here
        posts
    }
    
    func addPost(_ post: Post) {
        posts.append(post)
    }
    
    func addComment(to post: Post, comment: String) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].comments.append(comment)
        }
    }
    
    func deleteComment(from post: Post, comment: String) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].comments.removeAll { $0 == comment }
        }
    }
    
    func deletePost(_ post: Post) {
        posts.removeAll { $0.id == post.id }
    }
    
    func deletePosts(at offsets: IndexSet) {
        posts.remove(atOffsets: offsets)
    }
    
    func likePost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].likes += 1
        }
    }
}

struct FeedView: View {
    // Your @State properties remain the same
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

    // Update the computed properties to use @StateObject
    @StateObject private var postsViewModel = PostsViewModel()

    var sortedPosts: [Post] {
        switch sortOption {
        case .newest:
            return postsViewModel.filteredPosts.reversed()
        case .oldest:
            return postsViewModel.filteredPosts
        case .mostCommented:
            return postsViewModel.filteredPosts.sorted { $0.comments.count > $1.comments.count }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                searchField
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
        }
    }

    // MARK: - Subviews
    
    private var searchField: some View {
        TextField("Keresés...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
    
    private var postCreationSection: some View {
        VStack {
            TextField("Írj bejegyzést (opcionális)...", text: $newPost)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
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
            .padding()
        }
    }

    private var sortOptionsSection: some View {
        HStack {
            Text("Sort by:")
            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(.horizontal)
    }
    
    private var postList: some View {
        List {
            ForEach(sortedPosts) { post in
                PostView(post: post,
                         newComment: $newComment,
                         addComment: { postsViewModel.addComment(to: post, comment: newComment) },
                         deleteComment: { postsViewModel.deleteComment(from: post, comment: $0) },
                         deletePost: { postsViewModel.deletePost(post) },
                         likePost: { postsViewModel.likePost(post) },
                         sharePost: { sharePost(post) })
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
            message: Text("Biztosan törölni szeretnéd a bejegyzést: \(postToDelete?.content ?? "")?"),
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
            message: Text("Biztosan szeretnéd a bejegyzést megosztani: \(postToShare?.content ?? "")?"),
            primaryButton: .default(Text("Megosztás")) {
                if let post = postToShare {
                    post.isShared = true
                }
            },
            secondaryButton: .cancel()
        )
    }

    // MARK: - Helper Methods
    
    private func addPost() {
        if !newPost.isEmpty || selectedImage != nil || selectedVideoURL != nil {
            let post = Post(content: newPost.isEmpty ? nil : newPost, image: selectedImage, videoURL: selectedVideoURL)
            postsViewModel.addPost(post)
            newPost = ""
            selectedImage = nil
            selectedVideoURL = nil
        }
    }

    @MainActor
    private func refreshFeed() async {
        isRefreshing = true
        // Simulate a network request
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        // In a real app, you would fetch new posts here
        isRefreshing = false
    }

    private func sharePost(_ post: Post) {
        postToShare = post
        showShareConfirmation = true
    }
}

// Add this enum for sorting options
enum SortOption: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case mostCommented = "Most Commented"
}

// Update PostView to use ObservableObject
struct PostView: View {
    @ObservedObject var post: Post
    @Binding var newComment: String
    let addComment: () -> Void
    let deleteComment: (String) -> Void
    let deletePost: () -> Void
    let likePost: () -> Void
    let sharePost: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            if let content = post.content {
                Text(content)
                    .font(.headline)
            }
            if let image = post.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            if let videoURL = post.videoURL {
                Text("Videó: \(videoURL.lastPathComponent)")
                    .foregroundColor(.blue)
            }
            ForEach(post.comments, id: \.self) { comment in
                CommentView(comment: comment, deleteAction: { deleteComment(comment) })
            }
            
            if post.isShared {
                commentSection
            }
            
            // Update this section for delete, like, and share buttons
            HStack {
                Button(action: deletePost) {
                    VStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: likePost) {
                    VStack {
                        Image(systemName: "heart")
                        Text("Like (\(post.likes))")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: sharePost) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(.top)
        }
    }
    
    private var commentSection: some View {
        VStack {
            TextField("Kommentelj...", text: $newComment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.vertical)
            
            Button(action: addComment) {
                Text("Küldés")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.bottom)
        }
    }
}

// Your CommentView remains the same
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
    }
}

#Preview {
    FeedView()
}

// End of file. No additional code.
