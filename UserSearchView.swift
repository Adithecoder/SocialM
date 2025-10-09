//
//  UserSearchView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

import SwiftUI



struct UserSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchedUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showChatRoom: Bool = false
    @State private var selectedRoom: ChatRoom?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Keresőmező
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Keresés felhasználónév vagy email alapján...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            if newValue.count >= 2 {
                                searchUsers(query: newValue)
                            } else {
                                searchResults.removeAll()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults.removeAll()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Keresés...")
                        .padding()
                }
                
                if let error = errorMessage {
                    VStack {
                        Text("Hiba történt")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Újrapróbálás") {
                            if !searchText.isEmpty {
                                searchUsers(query: searchText)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                if searchResults.isEmpty && !searchText.isEmpty && !isLoading {
                    Text("Nincs találat")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                }
                
                // Találatok listája
                List(searchResults) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)
                            
                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Regisztrálva: \(formatDate(user.created_at))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Csetelés gomb
                        Button(action: {
                            startChat(with: user)
                        }) {
                            Image(systemName: "message")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle("Felhasználó Keresés")
            .navigationBarItems(trailing: Button("Bezárás") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showChatRoom) {
                if let room = selectedRoom, let currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int {
                    ChatRoomView(room: room, currentUserId: currentUserId)
                }
            }
        }
    }
    
    private func searchUsers(query: String) {
        isLoading = true
        errorMessage = nil
        
        // Üres query esetén ürítsük a találatokat
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchResults = []
            isLoading = false
            return
        }
        
        NetworkManager.shared.searchUsers(query: query) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let users):
                    self.searchResults = users
                    print("✅ Találatok: \(users.count) felhasználó")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.searchResults = []
                    print("❌ Keresési hiba: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startChat(with user: SearchedUser) {
        guard let currentUserId = UserDefaults.standard.object(forKey: "user_id") as? Int else {
            errorMessage = "Nincs bejelentkezve felhasználó"
            return
        }
        
        isLoading = true
        NetworkManager.shared.getOrCreateChatRoom(user1Id: currentUserId, user2Id: user.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let room):
                    self.selectedRoom = room
                    self.showChatRoom = true
                    print("✅ Chat szoba létrehozva: \(room.id)")
                case .failure(let error):
                    self.errorMessage = "Hiba a chat indításakor: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "ismeretlen" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd."
        dateFormatter.locale = Locale(identifier: "hu_HU")
        return dateFormatter.string(from: date)
    }
}

#Preview {
    UserSearchView()
}
