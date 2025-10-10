//
//  FeedView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

import SwiftUI
import PhotosUI
import UIKit
import DesignSystem

class Post2: ObservableObject, Identifiable {
    let id = UUID()
    let serverId: Int? // MySQL ID
    @Published var content: String?
    @Published var image: UIImage?
    @Published var videoURL: URL?
    @Published var comments: [String] = []
    @Published var isShared: Bool = false
    @Published var likes: Int = 0
    @Published var userLiked: Bool = false
    @Published var userCommented: Bool = false
    @Published var userSaved: Bool = false
    @Published var poll: Poll? // 👈 ÚJ: Szavazás hozzáadása
    let userId: Int
    let username: String
    let createdAt: Date
    
    init(serverId: Int? = nil, content: String? = nil, image: UIImage? = nil, videoURL: URL? = nil, userId: Int, username: String, createdAt: Date = Date(), poll: Poll? = nil) {
        self.serverId = serverId
        self.content = content
        self.image = image
        self.videoURL = videoURL
        self.userId = userId
        self.username = username
        self.createdAt = createdAt
        self.poll = poll // 👈 ÚJ
    }
    
    // Konvertálás szerverről érkező adatokból
    convenience init(from serverPost: ServerPost) {
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: serverPost.created_at) ?? Date()
        
        self.init(
            serverId: serverPost.id,
            content: serverPost.content,
            image: nil, // Később implementálhatod a képbetöltést
            videoURL: nil, // Később implementálhatod a videóbetöltést
            userId: serverPost.user_id,
            username: serverPost.username ?? "Ismeretlen",
            createdAt: createdAt
        )
        
        self.likes = serverPost.likes
        self.comments = serverPost.comments?.map { $0.content } ?? []
        
        if let currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int {
            self.userLiked = serverPost.user_liked ?? false
            self.userCommented = serverPost.user_commented ?? false
            self.userSaved = serverPost.user_saved ?? false
        }
        
        // 👈 JAVÍTOTT: Poll adatok betöltése
        if let serverPoll = serverPost.poll {
            var pollOptions: [PollOption] = []
            for serverOption in serverPoll.options {
                let option = PollOption(
                    id: serverOption.id,
                    text: serverOption.option_text,
                    votesCount: serverOption.votes_count,
                    percentage: 0, // Ezt később számoljuk
                    userVoted: false // Ezt később állítjuk
                )
                pollOptions.append(option)
            }
            
            // Százalékok számítása
            let totalVotes = serverPoll.total_votes
            if totalVotes > 0 {
                for option in pollOptions {
                    option.percentage = Int(Double(option.votesCount) / Double(totalVotes) * 100)
                }
            }
            
            let pollCreatedAt = dateFormatter.date(from: serverPoll.created_at) ?? Date()
            
            self.poll = Poll(
                id: serverPoll.id,
                question: serverPoll.question,
                options: pollOptions,
                totalVotes: totalVotes,
                userHasVoted: serverPoll.user_has_voted,
                postId: serverPoll.post_id,
                userId: serverPoll.user_id,
                createdAt: pollCreatedAt
            )
        }
    }
}
class PostsViewModel2: ObservableObject {
    @Published var posts: [Post2] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    
    func toggleSavePost(_ post2: Post2) {
        guard let postId = post2.serverId else { return }
        
        networkManager.toggleSavePost(postId, userId: post2.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isSaved):
                    if let index = self.posts.firstIndex(where: { $0.id == post2.id }) {
                        self.posts[index].userSaved = isSaved
                    }
                case .failure(let error):
                    self.errorMessage = "Hiba a mentés váltásakor: \(error.localizedDescription)"
                    print("Hiba a mentés váltásakor: \(error)")
                }
            }
        }
    }
    func loadPosts() {
        isLoading = true
        errorMessage = nil
        
        // Használd a debug verziót először
        networkManager.fetchPostsWithDebug { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let serverPosts):
                    self.posts = serverPosts.map { Post2(from: $0) }
                    print("✅ Bejegyzések betöltve: \(self.posts.count)")
                case .failure(let error):
                    self.errorMessage = "Hiba a bejegyzések betöltésekor: \(error.localizedDescription)"
                    print("❌ Hiba a bejegyzések betöltésekor: \(error)")
                }
            }
        }
    }
    
    func addPost(_ post2: Post2, completion: ((Result<Int, Error>) -> Void)? = nil) {
        networkManager.createPost(
            content: post2.content,
            image: post2.image,
            videoURL: post2.videoURL,
            userId: post2.userId
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let postId):
                    print("Bejegyzés létrehozva ID: \(postId)")
                    // Frissítjük a post2-ot a szerver ID-val
                    let updatedPost = Post2(
                        serverId: postId,
                        content: post2.content,
                        image: post2.image,
                        videoURL: post2.videoURL,
                        userId: post2.userId,
                        username: post2.username,
                        poll: post2.poll // 👈 Fontos: poll átadása
                    )
                    self.posts.insert(updatedPost, at: 0)
                    completion?(.success(postId))
                case .failure(let error):
                    self.errorMessage = "Hiba a bejegyzés létrehozásakor: \(error.localizedDescription)"
                    print("Hiba a bejegyzés létrehozásakor: \(error)")
                    completion?(.failure(error))
                }
            }
        }
    }
    
    func addComment(to post2: Post2, comment: String) {
        guard let postId = post2.serverId else { return }
        
        networkManager.addComment(to: postId, content: comment, userId: post2.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self.posts.firstIndex(where: { $0.id == post2.id }) {
                        self.posts[index].comments.append(comment)
                        self.posts[index].userCommented = true

                    }
                case .failure(let error):
                    self.errorMessage = "Hiba a komment hozzáadásakor: \(error.localizedDescription)"
                    print("Hiba a komment hozzáadásakor: \(error)")
                }
            }
        }
    }
    func unlikePost(_ post2: Post2) {
           guard let postId = post2.serverId else { return }
           
           // Ha a felhasználó még nem likeolta, ne csinálj semmit
           if !post2.userLiked {
               return
           }
           
           networkManager.likePost(postId, userId: post2.userId) { result in
               DispatchQueue.main.async {
                   switch result {
                   case .success:
                       if let index = self.posts.firstIndex(where: { $0.id == post2.id }) {
                           // Csak akkor csökkentjük a like számát, ha likeolta
                           if self.posts[index].userLiked {
                               self.posts[index].likes -= 1
                               self.posts[index].userLiked = false
                           }
                       }
                   case .failure(let error):
                       self.errorMessage = "Hiba a like eltávolításakor: \(error.localizedDescription)"
                       print("Hiba a like eltávolításakor: \(error)")
                   }
               }
           }
       }
    
    func likePost(_ post2: Post2) {
        guard let postId = post2.serverId else { return }
        
        // Ha a felhasználó már likeolta, ne csinálj semmit
        if post2.userLiked {
            return
        }
        
        networkManager.likePost(postId, userId: post2.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self.posts.firstIndex(where: { $0.id == post2.id }) {
                        // Csak akkor növeljük a like számát, ha még nem likeolta
                        if !self.posts[index].userLiked {
                            self.posts[index].likes += 1
                            self.posts[index].userLiked = true
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Hiba a like hozzáadásakor: \(error.localizedDescription)"
                    print("Hiba a like hozzáadásakor: \(error)")
                }
            }
        }
    }
    
    func deletePost2(_ post2: Post2) {
        posts.removeAll { $0.id == post2.id }
    }
    
    func deletePosts2(at offsets: IndexSet) {
        posts.remove(atOffsets: offsets)
    }
}
// Extension a Date osztályhoz
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: now)
        
        // Ha ugyanazon a napon van
        if calendar.isDateInToday(self) {
            if let hours = components.hour, hours > 0 {
                return "\(hours) órája"
            } else if let minutes = components.minute, minutes > 0 {
                return "\(minutes) perce"
            } else {
                return "Épp most"
            }
        }
        // Ha tegnapi
        else if calendar.isDateInYesterday(self) {
            return "Tegnap"
        }
        // Egy héten belül
        else if let days = components.day, days < 7 {
            return "\(days) napja"
        }
        // Egy hónapon belül
        else if let weeks = components.day, weeks < 30 {
            let weekCount = weeks / 7
            return "\(weekCount) hete"
        }
        // Egy évben belül
        else if let months = components.month, months < 12 {
            return "\(months) hónapja"
        }
        // Több mint egy éve
        else if let years = components.year, years > 0 {
            return "\(years) éve"
        }
        
        return "Régen"
    }
}
struct FeedView2: View {
    @StateObject private var postsViewModel2 = PostsViewModel2()
    @State private var isRefreshing2 = false
    @State private var showSortOptions2 = false
    @State private var sortOption2: SortOption2 = .newest
    @State private var newPost2: String = ""
    @State private var newComment2: String = ""
    @State private var selectedImage2: UIImage?
    @State private var selectedVideoURL2: URL?
    @State private var showImagePicker2: Bool = false
    @State private var showVideoPicker2: Bool = false
    @State private var searchText2: String = ""
    @State private var showDeleteConfirmation2 = false
    @State private var postToDelete2: Post2?
    @State private var currentUser2: User?
    @State private var unreadCount = 0

    // 👇 MÓDOSÍTOTT: NavigationLink-hez
    @State private var selectedPostForDetail: Post2?
    
    @State private var commentTexts2: [UUID: String] = [:]
    @State private var showSearchBar = false
    
    @State private var lastRefreshDate = Date()
    @State private var refreshTimer: Timer?
    
    @State private var showUserSearch = false

    @State private var showUserMenu = false
    @State private var selectedUserForMenu: Post2?
    @State private var showPollCreation = false
    @State private var selectedPostForPoll: Post2?
    
    var sortedPosts2: [Post2] {
        let filtered = postsViewModel2.posts.filter { post2 in
            searchText2.isEmpty ||
            (post2.content?.localizedCaseInsensitiveContains(searchText2) == true) ||
            post2.username.localizedCaseInsensitiveContains(searchText2)
        }
        
        switch sortOption2 {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
//        case .oldest:
//            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            return filtered.sorted { $0.likes > $1.likes }
        case .mostCommented:
            return filtered.sorted { $0.comments.count > $1.comments.count }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if postsViewModel2.isLoading {
                        ProgressView("Bejegyzések betöltése...")
                            .padding()
                    }
                    
                    if let error = postsViewModel2.errorMessage {
                        ErrorView2(message: error) {
                            postsViewModel2.loadPosts()
                        }
                    }
                    
                    postCreationSection
                    sortOptionsSection
                    postList
                    // Módosítsd a FeedView2-ben a popup részét:
                    // User menu popup
                    // A meglévő .overlay rész cseréje a FeedView2-ben:
                    .overlay(
                        Group {
                            if showUserMenu, let post = selectedUserForMenu {
                                UserMenuPopup(
                                    username: post.username,
                                    userId: post.userId,
                                    isPresented: $showUserMenu,
                                    post: post
                                )
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.1, dampingFraction: 0.8), value: showUserMenu)
                            }
                        }
                    )
                
                    // 👇 HIDDEN NAVIGATION LINK
                    NavigationLink(
                        destination: Group {
                            if let post = selectedPostForDetail {
                                PostDetailFullView(
                                    post2: post,
                                    onCommentAdded: { comment in
                                        postsViewModel2.addComment(to: post, comment: comment)
                                    },
                                    onLike: {
                                        postsViewModel2.likePost(post)
                                    },
                                    onDelete: {
                                        postsViewModel2.deletePost2(post)
                                        selectedPostForDetail = nil
                                    },
                                    onSave: { // 👈 ÚJ: mentés callback hozzáadása
                                        // Itt hívd meg a mentés funkciót
                                          postsViewModel2.toggleSavePost(post)
                                        print("Mentés: \(post.id)")
                                    }
                                )
                            }
                        },
                        isActive: Binding(
                            get: { selectedPostForDetail != nil },
                            set: { if !$0 { selectedPostForDetail = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .navigationTitle("Közösségi Média")
                
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showUserSearch = true
                        }) {
                            Image(systemName: "person.2")
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                        }
                    }
                    // 👇 ÚJ: Mentett posztok gomb
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SavedPostsView()) {
                            Image(systemName: "bookmark")
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                         NavigationLink(destination: ChatListView()) {
                             ZStack {
                                 Image(systemName: "message")
                                     .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                                 
                                 // Olvasatlan üzenetek jelzője
                                 if unreadCount > 0 {
                                     Text("\(unreadCount)")
                                         .font(.caption2)
                                         .foregroundColor(.white)
                                         .padding(4)
                                         .background(Color.red)
                                         .clipShape(Circle())
                                         .offset(x: 10, y: -10)
                                 }
                             }
                         }
                     }
                     
                }
                
                .sheet(isPresented: $showPollCreation) {
                    PollCreationView(isPresented: $showPollCreation) { question, options in
                        createPoll(question: question, options: options)
                    }
                }

                .sheet(isPresented: $showImagePicker2) {
                    ImagePickerView(image: $selectedImage2)
                }
                .sheet(isPresented: $showVideoPicker2) {
                    VideoPickerView(videoURL: $selectedVideoURL2)
                }
                .sheet(isPresented: $showUserSearch) {
                    UserSearchView()
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
                    postsViewModel2.loadPosts()
                }
                .onAppear {
                    startAutoRefresh()
                }
                .onDisappear {
                    stopAutoRefresh()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Subviews
    // FeedView2.swift - JAVÍTOTT createPoll függvény

    private func createPoll(question: String, options: [String]) {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else { return }
        
        let username = UserDefaults.standard.string(forKey: "username") ?? "Felhasználó"
        
        // Új poszt létrehozása CSAK a szavazással
        let newPost = Post2(
            content: "📊 Szavazás: \(question)", // Adjunk tartalmat a szavazáshoz
            image: nil,
            videoURL: nil,
            userId: userId,
            username: username
        )
        
        // Először hozd létre a posztot
        postsViewModel2.addPost(newPost) { result in
            switch result {
            case .success(let postId):
                // Most, hogy megvan a postId, hozzuk létre a szavazást
                NetworkManager.shared.createPoll(
                    postId: postId,
                    question: question,
                    options: options,
                    userId: userId
                ) { pollResult in
                    DispatchQueue.main.async {
                        switch pollResult {
                        case .success(let pollId):
                            print("✅ Szavazás létrehozva ID: \(pollId)")
                            // Frissítsük a posztot a poll adataival
                            if let index = self.postsViewModel2.posts.firstIndex(where: { $0.serverId == postId }) {
                                // Ideiglenes poll objektum létrehozása
                                let tempPoll = Poll(
                                    id: pollId,
                                    question: question,
                                    options: options.map { PollOption(id: 0, text: $0) }, // Ideiglenes opciók
                                    totalVotes: 0,
                                    userHasVoted: false,
                                    postId: postId,
                                    userId: userId
                                )
                                self.postsViewModel2.posts[index].poll = tempPoll
                            }
                        case .failure(let error):
                            print("❌ Hiba a szavazás létrehozásakor: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("❌ Hiba a poszt létrehozásakor: \(error)")
            }
        }
    }
    
    private func loadUnreadCount(userId: Int) {
        NetworkManager.shared.getUnreadMessagesCount(userId: userId) { result in
            DispatchQueue.main.async {
                if case .success(let count) = result {
                    unreadCount = count
                }
            }
        }
    }
    
    private var postCreationSection: some View {
        VStack {
            HStack {
                VStack{
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 30)
                        .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                        .padding(.horizontal,10)
                    
                    
                }
//                TextField("Írj bejegyzést...", text: $newPost2)
                TextField("Egy menő bejegyzés, \(currentUser2?.username ?? UserDefaults.standard.string(forKey: "username") ?? "Felhasználó")?", text: $newPost2)
                    .font(.custom("OrelegaOne-Regular", size:16))
                    .padding()
                
                Menu {
                    Button {
                        showImagePicker2 = true
                    } label: {
                        Label("Fotó feltöltése", systemImage: "photo")
                        
                    }
                    
                    Button {
                        showVideoPicker2 = true
                    } label: {
                        Label("Videó feltöltése", systemImage: "video")
                    }
                    
                    Button {
                        // Új: Szavazás létrehozása
                        selectedPostForPoll = nil // Új poszthoz
                        showPollCreation = true
                    } label: {
                        Label("Szavazás létrehozása", systemImage: "chart.bar")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle") // 3 pontos ikon
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 30)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                        .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                        .padding(.horizontal,5)
                }
                
                
                
                if !newPost2.isEmpty || selectedImage2 != nil || selectedVideoURL2 != nil {
                    Button(action: addPost2) {
                        Image(systemName: "paperplane.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 30)
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                            .padding(.horizontal,5)
                    }
                    .disabled(newPost2.isEmpty && selectedImage2 == nil && selectedVideoURL2 != nil)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: !newPost2.isEmpty || selectedImage2 != nil || selectedVideoURL2 != nil)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 3)
            )
            .padding(10)
        }
        .background(Color.gray.opacity(0.1))
    }

    private var sortOptionsSection: some View {
        HStack {
            Menu {
                Section("Rendezés") {
                    ForEach(SortOption2.allCases, id: \.self) { option in
                        Button {
                            sortOption2 = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption2 == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                
                Divider()
                
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 30)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                    .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                    .padding(.horizontal,5)
            }
            
            
            if showSearchBar {
                TextField("Keresés...", text: $searchText2)
                    .font(.custom("OrelegaOne-Regular", size:16))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSearchBar)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 3)
                    )
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSearchBar.toggle()
                    if !showSearchBar {
                        searchText2 = ""
                    }
                }
            } label: {
                Image(systemName: "magnifyingglass.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 30)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                    .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                    .padding(.horizontal,5)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        
    }
    
    
    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedPosts2) { post2 in
                    PostView2(
                        post2: post2,
                        newComment: $newComment2,
                        addComment: {
                            postsViewModel2.addComment(to: post2, comment: newComment2)
                            newComment2 = ""
                        },
                        deleteComment: { comment in
                            if let index = postsViewModel2.posts.firstIndex(where: { $0.id == post2.id }) {
                                postsViewModel2.posts[index].comments.removeAll { $0 == comment }
                            }
                        },
                        deletePost: {
                            postToDelete2 = post2
                            showDeleteConfirmation2 = true
                        },
                        likePost: {
                            postsViewModel2.likePost(post2)
                        },
                        sharePost: {
                            sharePost(post2)
                        },
                        showDetail: {
                            selectedPostForDetail = post2
                        },
                        // 👇 ÚJ: User menu callback hozzáadása
                        showUserMenu: {
                            selectedUserForMenu = post2
                            showUserMenu = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await refreshFeed()
        }
    }
    
//    private var deleteConfirmationAlert: Alert {
//        Alert(
//            title: Text("Bejegyzés törlése"),
//            message: Text("Biztosan törölni szeretnéd a bejegyzést?"),
//            primaryButton: .destructive(Text("Törlés")) {
//                if let post2 = postToDelete2 {
//                    postsViewModel2.deletePost2(post2)
//                }
//            },
//            secondaryButton: .cancel()
//        )
//    }

    // MARK: - Helper Methods
    
    private func loadCurrentUser() {
        if let userId = UserDefaults.standard.object(forKey: "user_id") as? Int {
            NetworkManager.shared.fetchUser(userId: userId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        self.currentUser2 = user
                    case .failure(let error):
                        print("Hiba a felhasználó betöltésekor: \(error)")
                    }
                }
            }
        }
    }
    
    private func addPost2() {
        guard let userId = UserDefaults.standard.object(forKey: "user_id") as? Int else {
            print("Nincs bejelentkezve felhasználó")
            return
        }
        
        let username = UserDefaults.standard.string(forKey: "username") ?? "Felhasználó"
        
        let post2 = Post2(
            content: newPost2.isEmpty ? nil : newPost2,
            image: selectedImage2,
            videoURL: selectedVideoURL2,
            userId: userId,
            username: username
            
        )
        
        postsViewModel2.addPost(post2)
        newPost2 = ""
        selectedImage2 = nil
        selectedVideoURL2 = nil
    }

    @MainActor
       private func refreshFeed() async {
           isRefreshing2 = true
           postsViewModel2.loadPosts()
           lastRefreshDate = Date()
           try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
           isRefreshing2 = false
       }
    
    private func startAutoRefresh() {
        // Frissítés 1 percenként
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await refreshFeed()
            }
        }
    }
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func sharePost(_ post2: Post2) {
        post2.isShared = true
    }
}
struct UserMenuPopup: View {
    let username: String
    let userId: Int
    @Binding var isPresented: Bool
    let post: Post2
    
    @State private var showProfile = false
    @State private var showMessageSheet = false
    @State private var messageText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fejléc rész
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .DesignSystem.fokekszin]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(username)
                        .font(.lexend())
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Vékony elválasztó vonal
            Rectangle()
                .fill(Color.DesignSystem.szurke)
                .frame(height: 1)
                .padding(.horizontal, 8)
            
            // Művelet gombok
            VStack(spacing: 0) {
                MenuButton(
                    icon: "person.text.rectangle",
                    iconColor: .DesignSystem.fokekszin,
                    title: "Profil megtekintése",
                    action: {
                        showProfile = true
                        isPresented = false
                    }
                )
                
                MenuButton(
                    icon: "message",
                    iconColor: .DesignSystem.oliva,
                    title: "Üzenet küldése",
                    action: {
                        showMessageSheet = true
                        isPresented = false
                    }
                )
                
                MenuButton(
                    icon: "person.badge.plus",
                    iconColor: .DesignSystem.barack,
                    title: "Követés",
                    action: {
                        print("Követés: \(username)")
                        isPresented = false
                    }
                )
                
                // Csak a saját posztjainál jelenjen meg
                if let currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int,
                   currentUserId == userId {
                    MenuButton(
                        icon: "pencil",
                        iconColor: .DesignSystem.bordosszin,
                        title: "Poszt szerkesztése",
                        action: {
                            print("Poszt szerkesztése")
                            isPresented = false
                        }
                    )
                } else {
                    // Más felhasználó posztjainál
                    MenuButton(
                        icon: "exclamationmark.triangle",
                        iconColor: .DesignSystem.bordosszin,
                        title: "Jelentés",
                        action: {
                            print("Felhasználó jelentése")
                            isPresented = false
                        }
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .orange]),
                    startPoint: .bottomLeading,
                    endPoint: .topLeading
                ))
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.DesignSystem.barack.opacity(0.9), .DesignSystem.fokekszin.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .frame(width: 320)
    }
}

// Segéd nézet a menü gombokhoz - VILÁGOS változat
struct MenuButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.lexend2())
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        // Vékony elválasztó vonal
        Rectangle()
            .fill(Color.DesignSystem.szurke)
            .frame(height: 1)
            .padding(.leading, 56)
    }
}
struct UserProfileView: View {
    let userId: Int
    let username: String
    
    @State private var userPosts: [Post2] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profil fejléc
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(username)
                            .font(.lexend())
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Posztok
                LazyVStack(spacing: 12) {
                    ForEach(userPosts) { post in
                        // Egyszerűsített poszt megjelenítés
                        VStack(alignment: .leading) {
                            if let content = post.content {
                                Text(content)
                                    .font(.body)
                                    .padding()
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Profil")
        .onAppear {
            loadUserPosts()
        }
    }
    
    private func loadUserPosts() {
        // Itt implementálhatod a felhasználó posztjainak betöltését
        isLoading = false // Temporarily set to false
    }
}
// MARK: - Message Composer View
struct MessageComposerView: View {
    let recipientId: Int
    let recipientName: String
    @Binding var isPresented: Bool
    @State private var errorMessage: String?
    
    @State private var messageText = ""
    @State private var isSending = false
    
    var body: some View {
            VStack(spacing: 16) {
                // Címzett info
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Üzenet küldése")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(recipientName)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Üzenet szövege
                TextEditor(text: $messageText)
                    .frame(height: 150)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                Spacer()
                
                // Küldés gomb
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Üzenet küldése")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Group {
                        if messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending {
                            Color.gray
                        } else {
                            LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom)
                        }
                    }
                )
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle("Új üzenet")
            .navigationBarItems(
                leading: Button("Mégse") {
                    isPresented = false
                }
            )
        
    }
    
    // Helyettesítsd a sendMessage függvényt ezzel:
    // Helyettesítsd a sendMessage függvényt ezzel:
    private func sendMessage() {
        guard let currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int else { return }
        
        isSending = true
        errorMessage = nil
        
        // Először hozzunk létre egy chat szobát vagy használjunk meglévőt
        NetworkManager.shared.getOrCreateChatRoom(
            user1Id: currentUserId,
            user2Id: recipientId
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chatRoom):
                    // Most küldjük az üzenetet
                    NetworkManager.shared.sendMessage(
                        roomId: chatRoom.id,
                        senderId: currentUserId,
                        message: messageText
                    ) { messageResult in
                        DispatchQueue.main.async {
                            isSending = false
                            
                            switch messageResult {
                            case .success:
                                isPresented = false
                                print("Üzenet sikeresen elküldve")
                            case .failure(let error):
                                errorMessage = "Hiba az üzenet küldésekor: \(error.localizedDescription)"
                                print("Hiba az üzenet küldésekor: \(error)")
                            }
                        }
                    }
                    
                case .failure(let error):
                    isSending = false
                    errorMessage = "Hiba a chat szoba létrehozásakor: \(error.localizedDescription)"
                    print("Hiba a chat szoba létrehozásakor: \(error)")
                }
            }
        }
    }
}

// MARK: - Segédeszközök

struct ErrorView2: View {
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

enum SortOption2: String, CaseIterable {
    case newest = "Legújabb"
//    case oldest = "Legrégebbi"
    case mostLiked = "Legtöbb like"
    case mostCommented = "Legtöbb komment"
}

struct PostView2: View {
    @ObservedObject var post2: Post2
    @Binding var newComment: String
    @State private var isLiked = false
    @State private var isCommented = false
    @State private var isSaved = false
    let addComment: () -> Void
    let deleteComment: (String) -> Void
    let deletePost: () -> Void
    let likePost: () -> Void
    let sharePost: () -> Void
    let showDetail: () -> Void
    let showUserMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Felhasználó fejléc
            HStack {
                
                Button(action: {
                                    showUserMenu()
                                }) {
                                    Image(systemName: "person.crop.circle")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxHeight: 30)
                                                        .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                                                        .foregroundStyle(.black)
                                                    
                                    HStack {
                                        Text("• \(post2.username)")
                                            .font(.custom("OrelegaOne-Regular", size: 20))
                                            .foregroundStyle(.black)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle()) // Ez eltünteti a gomb stílust
                                
                                Spacer()
                            }
            
            // Tartalom
            if let content = post2.content {
                Text(content)
                    .font(.lexend())
                    .bold()
                    .padding(.vertical, 4)
                    .foregroundStyle(.blue)
            }
            
            // 👈 ÚJ: Szavazás megjelenítése
            if let poll = post2.poll {
                PollView(poll: poll, onVote: { optionId in
                    // Szavazás funkció itt lesz implementálva
                    voteInPoll(pollId: poll.id, optionId: optionId)
                })
                .padding(.vertical, 8)
            }
            
            // Kép
            if let image = post2.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(8)
            }
            
            // Videó
            if let videoURL = post2.videoURL {
                Text("Videó: \(videoURL.lastPathComponent)")
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Művelet gombok
            HStack(spacing: 20) {
                // Like gomb
                Button(action: {
                    isLiked.toggle()
                    likePost()
                }) {
                    VStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                            .foregroundStyle(isLiked ?
                                             (LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom)) :
                                LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.bounce, value: isLiked)
                        
                        Text("\(post2.likes)")
                            .font(.lexend3())
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    post2.isShared.toggle()
                }) {
                    VStack {
                        Image(systemName: isCommented ? "text.bubble.fill" : "text.bubble")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                            .foregroundStyle(isCommented ?
                                LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom) :
                                LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                        
                        Text("\(post2.comments.count)")
                            .font(.lexend3())
                            .foregroundColor(.gray)
                    }
                }
                
                // Mentés gomb
                Button(action: {
                    isSaved.toggle()
                    post2.userSaved = isSaved
                }) {
                    VStack {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                            .foregroundStyle(isSaved ?
                                LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom) :
                                LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                        
                        Text("Mentés")
                            .font(.lexend3())
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Kinyitás gomb
                Button(action: showDetail) {
                    VStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                        
                        Text("Részletek")
                            .font(.lexend3())
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .onAppear {
            isLiked = post2.userLiked
            isCommented = post2.userCommented
            isSaved = post2.userSaved
        }
        .onChange(of: post2.userLiked) { newValue in
            isLiked = newValue
        }
        .onChange(of: post2.userCommented) { newValue in
            isCommented = newValue
        }
        .onChange(of: post2.userSaved) { newValue in
            isSaved = newValue
        }
    }
    
    // 👈 ÚJ: Szavazás funkció
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
}
struct PostDetailView: View {
    let post2: Post2
    @Binding var isPresented: Bool
    let onCommentAdded: (String) -> Void
    let onLike: () -> Void
    let onDelete: () -> Void
    var deleteAction: (() -> Void)? = nil

    @State private var newComment: String = ""
    @State private var isLiked: Bool
    @State private var isSharing: Bool = false
    
    init(post: Post2, isPresented: Binding<Bool>, onCommentAdded: @escaping (String) -> Void, onLike: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.post2 = post
        self._isPresented = isPresented
        self.onCommentAdded = onCommentAdded
        self.onLike = onLike
        self.onDelete = onDelete
        self._isLiked = State(initialValue: post.likes > 0)
        self.$isSharing
        
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Fejléc
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(post2.username)
                                .font(.headline)
                            Text(post2.createdAt.timeAgoDisplay()) // 👈 Itt is
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button("Bezárás") {
                            isPresented = false
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Tartalom
                    if let content = post2.content {
                        Text(content)
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                            .foregroundStyle(.blue)
                    }
                    
                    // Kép
                    if let image = post2.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Videó
                    if let videoURL = post2.videoURL {
                        VStack {
                            Text("Videó: \(videoURL.lastPathComponent)")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Statisztikák
                    HStack {
                        HStack{
                            Image(systemName: "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 20)
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                            Text("\(post2.likes) like")
                        }
                        HStack{
                            Image(systemName: "text.bubble")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 20)
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                                .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                            Text("\(post2.comments.count) hozzászólás")
                        }
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    
                    // Művelet gombok
                    HStack(spacing: 20) {
                        Button(action: {
                            isLiked.toggle()
                            onLike()
                        }) {
                            HStack {
                                Image(systemName: isLiked ? "heart" : "heart.fill")
                                Text("Like")
                            }
                            .scaledToFit()
                            .frame(height: 24)
                            .foregroundStyle(isLiked ?
                                LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom) :
                                LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.bounce, value: isLiked)
                        }
                        
                        Button(action: {
                            // Share funkció
                        }) {
                            HStack {
                                Image(systemName: isSharing ? "square.and.arrow.up.circle.fill" : "square.and.arrow.up.circle")
                                Text("Megosztás")
                            }
                            .scaledToFit()
                            .frame(height: 24)
                            .foregroundStyle(isSharing ?
                                LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom) :
                                LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.bounce, value: isSharing)
                        }
                        
                        Spacer()
                        
                        Button(action: onDelete) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Törlés")
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Kommentek szekció
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kommentek")
                            .font(.headline)
                            .padding(.horizontal)
                        HStack {
                            TextField("Szólj hozzá!", text: $newComment)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 3))
                            
                            Button(action: {
                                if !newComment.isEmpty {
                                    onCommentAdded(newComment)
                                    newComment = ""
                                }
                            }) {
                                Image(systemName: "paperplane.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 30)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                                    .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                                    .padding(.horizontal,5)
                            }
                            .disabled(newComment.isEmpty)
                        }
                        .padding(.horizontal)
                        if post2.comments.isEmpty {
                            Text("Még nincsenek kommentek")
                                .foregroundColor(.gray)
                                .italic()
                                .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(post2.comments, id: \.self) { comment in
                                    HStack(alignment: .top) {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                        HStack{
                                                Text("Felhasználó")
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                                Divider()
                                                    .frame(width: 1)
                                                    .overlay(.white)
                                                Text(comment)
                                                    .font(.body)
                                            Menu {
                                                // Rendezési opciók gombokként
                                                Button(action: { deleteAction?() }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.purple)
                                                        .padding(5)
                                                }
                                                
                                                Divider()
                                                
                                                
                                            } label: {
                                                Image(systemName: "trash.circle")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxHeight: 30)
                                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom))
                                                    .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                                                    .padding(.horizontal,5)
                                            }
//                                            Button(action: deleteAction) {
//                                                Image(systemName: "trash")
//                                                    .foregroundColor(.purple)
//                                                    .padding(5)
//                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 3)
                                    )
                                    .background((LinearGradient(gradient: Gradient(colors: [.yellow, .blue]), startPoint: .top, endPoint: .bottom)))
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Új komment hozzáadása
                        
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Poll Modell
class Poll: ObservableObject, Identifiable {
    let id: Int
    @Published var question: String
    @Published var options: [PollOption]
    @Published var totalVotes: Int
    @Published var userHasVoted: Bool
    let postId: Int
    let userId: Int
    let createdAt: Date
    
    init(id: Int, question: String, options: [PollOption], totalVotes: Int, userHasVoted: Bool, postId: Int, userId: Int, createdAt: Date = Date()) {
        self.id = id
        self.question = question
        self.options = options
        self.totalVotes = totalVotes
        self.userHasVoted = userHasVoted
        self.postId = postId
        self.userId = userId
        self.createdAt = createdAt
    }
}

class PollOption: ObservableObject, Identifiable {
    let id: Int
    @Published var text: String
    @Published var votesCount: Int
    @Published var percentage: Int
    @Published var userVoted: Bool
    
    init(id: Int, text: String, votesCount: Int = 0, percentage: Int = 0, userVoted: Bool = false) {
        self.id = id
        self.text = text
        self.votesCount = votesCount
        self.percentage = percentage
        self.userVoted = userVoted
    }
}

// MARK: - Poll Creation View
struct PollCreationView: View {
    @Binding var isPresented: Bool
    let onCreatePoll: (String, [String]) -> Void
    
    @State private var question: String = ""
    @State private var options: [String] = ["", ""]
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Szavazás kérdése")) {
                    TextField("Add meg a kérdést...", text: $question)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Választható opciók")) {
                    ForEach(0..<options.count, id: \.self) { index in
                        HStack {
                            TextField("Opció \(index + 1)", text: $options[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if options.count > 2 {
                                Button(action: {
                                    removeOption(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Button(action: addOption) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Új opció hozzáadása")
                        }
                    }
                    .disabled(options.count >= 6)
                }
                
                Section {
                    Button("Szavazás létrehozása") {
                        createPoll()
                    }
                    .disabled(!isValidPoll)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(isValidPoll ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Új szavazás")
            .navigationBarItems(
                leading: Button("Mégse") {
                    isPresented = false
                },
                trailing: Button("Kész") {
                    createPoll()
                }
                .disabled(!isValidPoll)
            )
            .alert("Hiba", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValidPoll: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty &&
        options.filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }).count >= 2
    }
    
    private func addOption() {
        if options.count < 6 {
            options.append("")
        }
    }
    
    private func removeOption(at index: Int) {
        if options.count > 2 {
            options.remove(at: index)
        }
    }
    
    private func createPoll() {
        let validOptions = options
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard validOptions.count >= 2 else {
            errorMessage = "Legalább 2 opciót meg kell adni!"
            showError = true
            return
        }
        
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "A kérdés megadása kötelező!"
            showError = true
            return
        }
        
        onCreatePoll(question, validOptions)
        isPresented = false
    }
}

// MARK: - Poll Display View
struct PollView: View {
    @ObservedObject var poll: Poll
    let onVote: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(.lexend(fontWeight: .regular))
                .padding(.bottom, 4)
            
            ForEach(poll.options) { option in
                PollOptionView(
                    option: option,
                    totalVotes: poll.totalVotes,
                    userHasVoted: poll.userHasVoted,
                    onVote: {
                        if !poll.userHasVoted {
                            onVote(option.id)
                        }
                    }
                )
            }
            
            HStack {
                Text("\(poll.totalVotes) szavazat")
                    .font(.custom("Jellee", size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
                
                if poll.userHasVoted {
                    Text("✓ Szavazat leadva")
                        .font(.custom("Jellee", size:14))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.DesignSystem.fokekszin.opacity(0.1))
        .cornerRadius(20)
    }
}

struct PollOptionView: View {
    @ObservedObject var option: PollOption
    let totalVotes: Int
    let userHasVoted: Bool
    let onVote: () -> Void
    
    var body: some View {
        Button(action: onVote) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.text)
                        .font(.lexend2(fontWeight: .regular))
                        .foregroundColor(userHasVoted ? .primary : .blue)
                    
                    if userHasVoted {
                        HStack {
                            ProgressView(value: Double(option.percentage), total: 100)
                                .tint(userHasVoted && option.userVoted ? Color.green : Color.gray.opacity(0.3)
                                )
                                .frame(height: 6)
                            
                            Text("\(option.percentage)%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                if userHasVoted && option.userVoted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: userHasVoted && option.userVoted ? 25 : 15)
                    .stroke(userHasVoted && option.userVoted ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        (userHasVoted && option.userVoted ? Color.green.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: userHasVoted && option.userVoted ? 28 : 20))
                    )
            )
        }
        .disabled(userHasVoted)
    }
}


struct CommentView2: View {
    let comment: String
    let deleteAction: () -> Void
    @State private var sortOption2: SortOption = .newest

    var body: some View {
        HStack {
            
            //Mukodo torles
//            Menu {
//                // Rendezési opciók gombokként
//                Button(action: deleteAction) {
//                    Image(systemName: "trash")
//                        .foregroundColor(.purple)
//                        .padding(5)
//                }
//
//                Divider()
//
//
//            } label: {
//                Image(systemName: "trash.circle")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxHeight: 30)
//                    .foregroundStyle(LinearGradient(gradient: //Gradient(colors: [.orange, .blue]), startPoint: //.top, endPoint: .bottom))
//                    .symbolEffect(.bounce.down.wholeSymbol, options: //.nonRepeating)
//                    .padding(.horizontal,5)
//            }
            
            Text("• \(comment)")
                .font(.subheadline)
                .foregroundStyle(.purple)
                .padding()
            

        }
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom), lineWidth: 3)
        )
        .padding(.vertical, 2)
    }
}

#Preview {
    FeedView2()
}

#Preview("PollView – minta") {
    // Minta opciók
    let option1 = PollOption(id: 1, text: "iOS", votesCount: 12, percentage: 60, userVoted: true)
    let option2 = PollOption(id: 2, text: "Android", votesCount: 6, percentage: 30, userVoted: false)
    let option3 = PollOption(id: 3, text: "Egyéb", votesCount: 2, percentage: 10, userVoted: false)
    
    // Minta poll
    let samplePoll = Poll(
        id: 101,
        question: "Melyik platformot preferálod?",
        options: [option1, option2, option3],
        totalVotes: 20,
        userHasVoted: true, // állítsd false-ra, ha szavazatlan állapotot akarsz látni
        postId: 999,
        userId: 1
    )
    
    return VStack(spacing: 20) {
        PollView(poll: samplePoll) { optionId in
            print("Szavazat leadva opcióra: \(optionId)")
            // Itt lehetne frissíteni a poll állapotát a preview-ban is
        }
        
        // Másik állapot: felhasználó még nem szavazott
        let notVotedOption1 = PollOption(id: 1, text: "SwiftUI", votesCount: 3, percentage: 50, userVoted: false)
        let notVotedOption2 = PollOption(id: 2, text: "UIKit", votesCount: 3, percentage: 50, userVoted: false)
        let notVotedPoll = Poll(
            id: 102,
            question: "Melyik UI keretrendszert kedveled jobban?",
            options: [notVotedOption1, notVotedOption2],
            totalVotes: 6,
            userHasVoted: false,
            postId: 1000,
            userId: 1
        )
        
        PollView(poll: notVotedPoll) { optionId in
            print("Szavazat leadva opcióra: \(optionId)")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

