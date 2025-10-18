//
//  PostDetailFullView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/6/25.
//
import SwiftUI

struct PostDetailFullView: View {
    
    @StateObject private var postsViewModel2 = PostsViewModel2()
    @State private var isRefreshing2 = false
    
    let post2: Post2
    @Environment(\.dismiss) private var dismiss
    let onCommentAdded: (String) -> Void
    let onLike: () -> Void
    let onDelete: () -> Void
    let onSave: () -> Void // 👈 ÚJ: mentés callback
    
    @State private var newComment: String = ""
    @State private var isLiked: Bool
    @State private var isSaved: Bool
    @State private var isCommented: Bool

    @State private var showDeleteAlert = false
    @State private var lastRefreshDate = Date()

    init(post2: Post2, onCommentAdded: @escaping (String) -> Void, onLike: @escaping () -> Void, onDelete: @escaping () -> Void, onSave: @escaping () -> Void) {
        self.post2 = post2
        self.onCommentAdded = onCommentAdded
        self.onLike = onLike
        self.onDelete = onDelete
        self.onSave = onSave
        self._isLiked = State(initialValue: post2.userLiked)
        self._isSaved = State(initialValue: post2.userSaved)
        self._isCommented = State(initialValue: post2.userCommented)
    }
    
    @MainActor
    private func refreshFeed() async {
        isRefreshing2 = true
        postsViewModel2.loadPosts()
        lastRefreshDate = Date()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        isRefreshing2 = false
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                
                Divider()
                
                // Content
                contentSection
                    .padding(16)
                
                // Stats & Actions
                statsAndActionsSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                Divider()
                
                // Comments
                commentsSection
                    .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Vissza")
                            .font(.lexend())
                    }
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .blue.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Bejegyzés törlése", systemImage: "trash")
                    }
                    Button(action: {
                        Task {
                            await refreshFeed()
                        }
                    }) {
                        Label("Bejegyzés frissítése", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue, .blue.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            
        }
        .alert("Bejegyzés törlése", isPresented: $showDeleteAlert) {
            Button("Mégse", role: .cancel) {}
            Button("Törlés", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Biztosan törölni szeretnéd ezt a bejegyzést?")
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 36)
                .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post2.username)
                    .font(.custom("Lexend", size:16))
                    .foregroundColor(.primary)
                
                Text(formatDate(post2.createdAt))
                    .font(.lexend3())
                    .foregroundColor(.secondary)
            }
            
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let content = post2.content, !content.isEmpty {
                Text(content)
                    .font(.custom("Lexend", size:20))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let poll = post2.poll {
                PollView(poll: poll, onVote: { optionId in
                    voteInPoll(pollId: poll.id, optionId: optionId)
                })
                .padding(.vertical, 8)
            }
            
            if let image = post2.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            
            if let videoURL = post2.videoURL {
                VideoPlayerView(videoURL: videoURL)
                    .frame(height: 220)
                    .cornerRadius(12)
            }
        }
    }
    
    private var statsAndActionsSection: some View {
        VStack(spacing: 12) {
            // Stats
            HStack(spacing: 20) {
                StatView2(count: post2.likes, icon: "heart.fill", label: "Like")
                StatView2(count: post2.comments.count, icon: "text.bubble.fill", label: "Hozzászólás")
                Spacer()
            }
            .font(.subheadline)
            
            // Action Buttons
            HStack(spacing: 0) {
                ActionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    label: isLiked ? "Kedveled" : "Tetszik",
                    color: isLiked ? .blue : .primary
                ) {
                    isLiked.toggle()
                    post2.userLiked = isLiked
                    onLike()
                }
                
                Spacer()
                
                ActionButton(
                    icon: isSaved ? "bookmark.fill" : "bookmark",
                    label: isSaved ? "Mentve" : "Mentés",
                    color: isSaved ? .blue : .primary
                ) {
                    isSaved.toggle()
                    post2.userSaved = isSaved
                    onSave()
                }
                
                Spacer()
                
                ActionButton(
                    icon: isCommented ? "text.bubble.fill" : "text.bubble",
                    label: "Hozzászólás",
                    color: isCommented ? .blue : .primary
                ) {
                    // Komment fókuszálása
                }
                
                Spacer()
                
                ActionButton(
                    icon: "square.and.arrow.up",
                    label: "Megosztás",
                    color: .primary
                ) {
                    sharePost()
                }
            }
        }
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hozzászólások")
                .font(.custom("Lexend", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // New comment input
            HStack {
                TextField("Szólj hozzá!", text: $newComment)
                    .font(.custom("OrelegaOne-Regular", size: 20))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.1)]), startPoint: .leading, endPoint: .trailing), lineWidth: 3))
                
                Button(action: addComment) {
                    Image(systemName: "paperplane.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 40)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.1)]), startPoint: .leading, endPoint: .trailing))
                        .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                        .padding(.horizontal,5)
                }
                .disabled(newComment.isEmpty)
            }
            
            if post2.comments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.gray, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                    
                    Text("Még nincsenek hozzászólások")
                        .font(.lexend2())
                        .foregroundColor(.secondary)
                    
                    Text("Légy te az első, aki hozzászól!")
                        .font(.lexend2())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Comments list
                LazyVStack(spacing: 12) {
                    ForEach(Array(post2.comments.enumerated()), id: \.offset) { index, comment in
                        CommentRow(comment: comment, index: index)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    // 👇 ÚJ: Szavazás funkció
    private func voteInPoll(pollId: Int, optionId: Int) {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else { return }
        
        NetworkManager.shared.voteInPoll(pollId: pollId, optionId: optionId, userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Szavazat leadva")
                    // Frissítsd a poll adatait
                    self.refreshPollData(pollId: pollId)
                case .failure(let error):
                    print("❌ Hiba a szavazásnál: \(error)")
                }
            }
        }
    }

    private func refreshPollData(pollId: Int) {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else { return }
        
        NetworkManager.shared.fetchPoll(pollId: pollId, userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedPoll):
                    // Frissítsd a post poll-ját
                    post2.poll = updatedPoll
                case .failure(let error):
                    print("❌ Hiba a poll frissítésénél: \(error)")
                }
            }
        }
    }
    
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        onCommentAdded(newComment)
        isCommented = true
        post2.userCommented = true
        newComment = ""
    }
    
    private func sharePost() {
        print("Share post: \(post2.id)")
    }
}

// MARK: - Helper Views

struct StatView2: View {
    let count: Int
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
            Text("\(count)")
                .font(.lexend2())

            Text(label)
                .font(.custom("Jellee", size:15))

                .foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 20)
                    .foregroundStyle(.blue, .black)
                    .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                    .padding(.horizontal,5)
                Text(label)
                    .font(.lexend3())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CommentRow: View {
    let comment: String
    let index: Int
    let username: String // 👈 ÚJ: Valódi felhasználónév
    
    init(comment: String, index: Int, username: String = "Felhasználó") {
        self.comment = comment
        self.index = index
        self.username = username
    }
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 20)
                .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(username) // 👈 MÓDOSÍTOTT: hashtag helyett valódi név
                    .font(.custom("Jellee", size:16))
                    .foregroundColor(.primary)
                
                Text(comment)
                    .font(.lexend2())
                    .foregroundColor(.primary)
                
            }
            .padding(.top, 8)

            .padding(.vertical,-10)

            
        }
        .padding(12)
        .background(.linearGradient(
            colors: [.blue.opacity(0.5), .blue.opacity(0.1)],
            startPoint: .leading,
            endPoint: .trailing
        ))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.2)]), startPoint: .leading, endPoint: .trailing), lineWidth: 5)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
            
            VStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Videó lejátszása")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(videoURL.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "hu_HU")
    return formatter.string(from: date)
}

#Preview {
    NavigationView {
        PostDetailFullView(
            post2: Post2(
                serverId: 1,
                content: "Ez egy példa bejegyzés a részletes nézet teszteléséhez.",
                image: UIImage(systemName: "photo")?.withTintColor(.blue, renderingMode: .alwaysOriginal),
                videoURL: nil,
                userId: 123,
                username: "TesztFelhasználó",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            onCommentAdded: { comment in
                print("Új komment: \(comment)")
            },
            onLike: {
                print("Like!")
            },
            onDelete: {
                print("Törlés!")
            },
            onSave: {
                print("Mentés: \(1)") // 👈 JAVÍTVA: post2.serverId használata
            }
        )
    }
}

#Preview("Képes bejegyzés") {
    NavigationView {
        PostDetailFullView(
            post2: Post2(
                serverId: 2,
                content: "Ez egy képes bejegyzés",
                image: UIImage(systemName: "photo.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal),
                videoURL: nil,
                userId: 456,
                username: "FotósFelhasználó",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            onCommentAdded: { _ in },
            onLike: {},
            onDelete: {},
            onSave: {} // 👈 Hozzáadva
        )
    }
}

#Preview("Videós bejegyzés") {
    NavigationView {
        PostDetailFullView(
            post2: Post2(
                serverId: 3,
                content: "Ez egy videós bejegyzés",
                image: nil,
                videoURL: URL(string: "https://example.com/video.mp4"),
                userId: 789,
                username: "VideósFelhasználó",
                createdAt: Date().addingTimeInterval(-1800)
            ),
            onCommentAdded: { _ in },
            onLike: {},
            onDelete: {},
            onSave: {} // 👈 Hozzáadva
        )
    }
}

#Preview("Kommentekkel") {
    let postWithComments = Post2(
        serverId: 4,
        content: "Ez a bejegyzés már tartalmaz kommenteket",
        image: nil,
        videoURL: nil,
        userId: 999,
        username: "NépszerűFelhasználó",
        createdAt: Date().addingTimeInterval(-86400)
    )
    
    postWithComments.comments = [
        "Nagyon tetszik ez a bejegyzés!",
        "Köszönöm, hogy megosztottad!",
        "Érdekes tartalom, várom a folytatást!"
    ]
    postWithComments.likes = 15
    
    return NavigationView {
        PostDetailFullView(
            post2: postWithComments,
            onCommentAdded: { comment in
                print("Új komment: \(comment)")
            },
            onLike: {
                print("Like!")
            },
            onDelete: {
                print("Törlés!")
            },
            onSave: {} // 👈 Hozzáadva
        )
    }
}

#Preview("Üres kommentekkel") {
    NavigationView {
        PostDetailFullView(
            post2: Post2(
                serverId: 5,
                content: "Ez egy friss bejegyzés még kommentek nélkül",
                image: nil,
                videoURL: nil,
                userId: 111,
                username: "ÚjFelhasználó",
                createdAt: Date()
            ),
            onCommentAdded: { _ in },
            onLike: {},
            onDelete: {},
            onSave: {} // 👈 Hozzáadva
        )
    }
}
