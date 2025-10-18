//
//  ChatViews.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

import SwiftUI



class ChatViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var currentMessages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    
    private let networkManager = NetworkManager.shared
    
    func loadChatRooms(userId: Int) {
        isLoading = true
        networkManager.getChatRooms(userId: userId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let rooms):
                    self.chatRooms = rooms
                case .failure(let error):
                    self.errorMessage = "Hiba a chat szobák betöltésekor: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadMessages(roomId: Int) {
        isLoading = true
        networkManager.getMessages(roomId: roomId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let messages):
                    self.currentMessages = messages
                case .failure(let error):
                    self.errorMessage = "Hiba az üzenetek betöltésekor: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func sendMessage(roomId: Int, senderId: Int, message: String, completion: @escaping (Bool) -> Void) {
        networkManager.sendMessage(roomId: roomId, senderId: senderId, message: message) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newMessage):
                    self.currentMessages.append(newMessage)
                    completion(true)
                case .failure(let error):
                    self.errorMessage = "Hiba az üzenet küldésekor: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    func loadUnreadCount(userId: Int) {
        networkManager.getUnreadMessagesCount(userId: userId) { result in
            DispatchQueue.main.async {
                if case .success(let count) = result {
                    self.unreadCount = count
                }
            }
        }
    }
}

struct ChatListView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var currentUserId: Int?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Chat szobák betöltése...")
                        .padding()
                }
                
                if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        if let userId = currentUserId {
                            viewModel.loadChatRooms(userId: userId)
                        }
                    }
                }
                
                List(viewModel.chatRooms) { room in
                    NavigationLink(destination: ChatRoomView(room: room, currentUserId: currentUserId ?? 0)) {
                        ChatRoomRow(room: room, currentUserId: currentUserId ?? 0)
                    }
                }
            }
            .navigationTitle("Üzenetek")
            .onAppear {
                currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int
                if let userId = currentUserId {
                    viewModel.loadChatRooms(userId: userId)
                    viewModel.loadUnreadCount(userId: userId)
                }
            }
        }
    }
}

struct ChatRoomRow: View {
    let room: ChatRoom
    let currentUserId: Int
    
    private var otherUserName: String {
        if room.user1_id == currentUserId {
            return room.user2_username ?? "Ismeretlen"
        } else {
            return room.user1_username ?? "Ismeretlen"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(otherUserName)
                    .font(.headline)
                
                if let lastMessage = room.last_message {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let lastTime = room.last_message_time {
                Text(formatDate(lastTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM.dd."
            return dateFormatter.string(from: date)
        }
    }
}

struct ChatRoomView: View {
    let room: ChatRoom
    let currentUserId: Int
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage = ""
    @State private var otherUserName: String = ""
    
    var body: some View {
        VStack {
            // Üzenetek listája
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.currentMessages) { message in
                            MessageBubble(message: message, isCurrentUser: message.sender_id == currentUserId)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.currentMessages.count) { _ in
                    if let lastMessage = viewModel.currentMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Üzenet küldő felület
            HStack {
                TextField("Írj üzenetet...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
        .navigationTitle(otherUserName)
        .onAppear {
            viewModel.loadMessages(roomId: room.id)
            calculateOtherUserName()
            
            // Üzenetek olvasottnak jelölése
            if let userId = UserDefaults.standard.object(forKey: "user_id") as? Int {
                NetworkManager.shared.markMessagesAsRead(roomId: room.id, userId: userId) { _ in }
            }
        }
    }
    
    private func calculateOtherUserName() {
        if room.user1_id == currentUserId {
            otherUserName = room.user2_username ?? "Ismeretlen"
        } else {
            otherUserName = room.user1_username ?? "Ismeretlen"
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        viewModel.sendMessage(roomId: room.id, senderId: currentUserId, message: trimmedMessage) { success in
            if success {
                newMessage = ""
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(12)
                
                Text(formatTime(message.created_at))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
}
