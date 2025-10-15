//
//  NetworkManager.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

import Foundation
import UIKit

struct ChatRoom: Codable, Identifiable {
    let id: Int
    let user1_id: Int
    let user2_id: Int
    let user1_username: String?
    let user2_username: String?
    let last_message: String?
    let last_message_time: String?
    let created_at: String
}

struct ChatMessage: Codable, Identifiable {
    let id: Int
    let room_id: Int
    let sender_id: Int
    let sender_username: String?
    let message: String
    let is_read: Bool
    let created_at: String
}

struct UnreadMessagesCount: Codable {
    let unread_count: Int
}


class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    public let baseURL = "https://pseudogenteel-tanisha-unrationally.ngrok-free.dev"

    
    private init() {}
        
        // MARK: - Auth műveletek
        func login(username: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
            guard let url = URL(string: "\(baseURL)/login") else {
                completion(.failure(NetworkError.invalidURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 30 // Növeld az időt
            
            let parameters: [String: Any] = [
                "username": username,
                "password": password
            ]
        
            do {
                        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                        print("🔐 Login kérés küldése: \(url.absoluteString)")
                    } catch {
                        completion(.failure(error))
                        return
                    }
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        // Debug információk
                        if let error = error {
                            print("❌ Hálózati hiba: \(error.localizedDescription)")
                        }
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            print("📡 HTTP Status: \(httpResponse.statusCode)")
                        }
                        
                        DispatchQueue.main.async {
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            guard let data = data else {
                                completion(.failure(NetworkError.noData))
                                return
                            }
                
                            // Debug: nyers válasz kiírása
                                          if let responseString = String(data: data, encoding: .utf8) {
                                              print("📨 Szerver válasz: \(responseString)")
                                          }
                                          
                                          do {
                                              let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                                              completion(.success(loginResponse))
                                          } catch {
                                              print("❌ JSON dekódolási hiba: \(error)")
                                              completion(.failure(error))
                                          }
                                      }
                                  }.resume()
                              }
    
    func register(username: String, email: String, password: String, completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/register") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                    completion(.success(registerResponse))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - POST műveletek
    
    func createPost(content: String?, image: UIImage?, videoURL: URL?, userId: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Kép feltöltés - egyszerűsítve, csak a szöveges adatokat küldjük
        let parameters: [String: Any] = [
            "user_id": userId,
            "content": content ?? "",
            "image_url": "", // Itt később implementálhatod a képfeltöltést
            "video_url": ""  // Itt később implementálhatod a videófeltöltést
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PostResponse.self, from: data)
                    completion(.success(response.post_id))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func addComment(to postId: Int, content: String, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/comments") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "user_id": userId,
            "content": content
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(true))
            }
        }.resume()
    }
    
    func likePost(_ postId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/like") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(true))
            }
        }.resume()
    }
    
    // MARK: - GET műveletek
    
    func fetchPosts(completion: @escaping (Result<[ServerPost], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let posts = try JSONDecoder().decode([ServerPost].self, from: data)
                    completion(.success(posts))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    func fetchPostsWithDebug(completion: @escaping (Result<[ServerPost], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🔍 FetchPosts URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Debug információk
            if let error = error {
                print("❌ Hálózati hiba: \(error.localizedDescription)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                // Részletes debug
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📨 Szerver válasz teljes hossz: \(responseString.count) karakter")
                    print("📨 Első 500 karakter: \(responseString.prefix(500))")
                    
                    // Nézzük meg, van-e poll a válaszban
                    if responseString.contains("poll") {
                        print("✅ Poll adatok észlelve a válaszban!")
                    }
                }
                
                do {
                    let posts = try JSONDecoder().decode([ServerPost].self, from: data)
                    print("✅ Sikeres dekódolás: \(posts.count) bejegyzés")
                    
                    // Ellenőrizzük a poll adatokat
                    let postsWithPoll = posts.filter { $0.poll != nil }
                    print("📊 \(postsWithPoll.count) bejegyzés tartalmaz szavazást")
                    
                    completion(.success(posts))
                } catch {
                    print("❌ JSON dekódolási hiba: \(error)")
                    print("❌ Hiba részletei: \(error.localizedDescription)")
                    
                    // További debug információ
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("❌ Hiányzó kulcs: \(key) - \(context)")
                        case .typeMismatch(let type, let context):
                            print("❌ Típus hiba: \(type) - \(context)")
                        case .valueNotFound(let type, let context):
                            print("❌ Hiányzó érték: \(type) - \(context)")
                        case .dataCorrupted(let context):
                            print("❌ Sérült adat: \(context)")
                        @unknown default:
                            print("❌ Ismeretlen dekódolási hiba")
                        }
                    }
                    
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Felhasználó keresés
    func searchUsers(query: String, completion: @escaping (Result<[SearchedUser], Error>) -> Void) {
        // URL encoding javítása
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty,
              let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/users/search?query=\(encodedQuery)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🔍 Keresési URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Debug információk
            if let error = error {
                print("❌ Hálózati hiba: \(error.localizedDescription)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Hálózati hiba: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("❌ Nincs adat a válaszban")
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                // Debug: írjuk ki a nyers választ
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📨 Szerver válasz: \(responseString)")
                }
                
                do {
                    let users = try JSONDecoder().decode([SearchedUser].self, from: data)
                    print("✅ Sikeres dekódolás: \(users.count) felhasználó")
                    completion(.success(users))
                } catch {
                    print("❌ JSON dekódolási hiba: \(error)")
                    print("❌ Hiba részletei: \(error.localizedDescription)")
                    
                    // Alternatív próbálkozás: próbáljuk meg string-ként értelmezni
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Nyers válasz stringként: \(responseString)")
                        
                        // Ha üres array jön vissza
                        if responseString == "[]" {
                            completion(.success([]))
                            return
                        }
                    }
                    
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Profilkép feltöltése
    func uploadProfilePicture(image: UIImage, completion: @escaping (Result<ProfilePictureResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/upload-profile-picture"),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Kép konvertálása Data formátumba
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NetworkError.invalidImage))
            return
        }
        
        var body = Data()
        
        // Kép hozzáadása a request body-hoz
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profilePicture\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                // Debug: print the response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Upload response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(ProfilePictureResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("JSON decode error: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Profilkép eltávolítása
    func removeProfilePicture(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/remove-profile-picture"),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    completion(.success(true))
                } else {
                    completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
    // Felhasználó adatainak lekérése
    func fetchUser(userId: Int, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Add hozzá ezeket a NetworkManager osztályhoz

    func toggleSavePost(_ postId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/save") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let isSaved = json["saved"] as? Bool {
                        completion(.success(isSaved))
                    } else {
                        completion(.failure(NetworkError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func getSaveStatus(postId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/save-status?user_id=\(userId)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let isSaved = json["saved"] as? Bool {
                        completion(.success(isSaved))
                    } else {
                        completion(.failure(NetworkError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
// NetworkManager.swift - JAVÍTOTT VERZIÓ
extension NetworkManager {
    func createPoll(postId: Int, question: String, options: [String], userId: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/poll") else {
            completion(.failure(NSError(domain: "PollError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let parameters: [String: Any] = [
            "user_id": userId,
            "question": question,
            "options": options.map { ["text": $0] }
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "PollError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: írd ki a választ
            if let responseString = String(data: data, encoding: .utf8) {
                print("📊 Poll creation response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let pollId = json["poll_id"] as? Int {
                    completion(.success(pollId))
                } else {
                    completion(.failure(NSError(domain: "PollError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func voteInPoll(pollId: Int, optionId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/polls/\(pollId)/vote") else {
            completion(.failure(NSError(domain: "PollError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let parameters: [String: Any] = [
            "user_id": userId,
            "option_id": optionId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(.success(true))
            } else {
                completion(.failure(NSError(domain: "PollError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Vote failed"])))
            }
        }.resume()
    }
    
    func fetchPoll(pollId: Int, userId: Int, completion: @escaping (Result<Poll, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/polls/\(pollId)?user_id=\(userId)") else {
            completion(.failure(NSError(domain: "PollError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "PollError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: írd ki a választ
            if let responseString = String(data: data, encoding: .utf8) {
                print("📊 Fetch poll response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let poll = PollParser.parsePoll(from: json, userId: userId) {
                    completion(.success(poll))
                } else {
                    completion(.failure(NSError(domain: "PollError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse poll data"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension NetworkManager {
    
    // Chat szoba létrehozása vagy lekérése
    func getOrCreateChatRoom(user1Id: Int, user2Id: Int, completion: @escaping (Result<ChatRoom, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/rooms") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "user1_id": user1Id,
            "user2_id": user2Id
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let room = try JSONDecoder().decode(ChatRoom.self, from: data)
                    completion(.success(room))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Üzenet küldése
    func sendMessage(roomId: Int, senderId: Int, message: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/messages") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "room_id": roomId,
            "sender_id": senderId,
            "message": message
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
                    completion(.success(chatMessage))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Üzenetek lekérése egy szobából
    func getMessages(roomId: Int, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/rooms/\(roomId)/messages") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
                    completion(.success(messages))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Felhasználó chat szobáinak lekérése
    func getChatRooms(userId: Int, completion: @escaping (Result<[ChatRoom], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/chat-rooms") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let rooms = try JSONDecoder().decode([ChatRoom].self, from: data)
                    completion(.success(rooms))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Olvasatlan üzenetek számának lekérése
    func getUnreadMessagesCount(userId: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/unread-messages") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(UnreadMessagesCount.self, from: data)
                    completion(.success(result.unread_count))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Üzenetek olvasottnak jelölése
    func markMessagesAsRead(roomId: Int, userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/rooms/\(roomId)/mark-read") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(true))
            }
        }.resume()
    }
}
// MARK: - Poll Parser
class PollParser {
    static func parsePoll(from json: [String: Any], userId: Int) -> Poll? {
        guard let id = json["id"] as? Int,
              let question = json["question"] as? String,
              let postId = json["post_id"] as? Int,
              let pollUserId = json["user_id"] as? Int,
              let optionsArray = json["options"] as? [[String: Any]] else {
            return nil
        }
        
        let totalVotes = json["total_votes"] as? Int ?? 0
        let userHasVoted = json["user_has_voted"] as? Bool ?? false
        
        var pollOptions: [PollOption] = []
        
        for optionDict in optionsArray {
            if let option = parsePollOption(from: optionDict) {
                pollOptions.append(option)
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: json["created_at"] as? String ?? "") ?? Date()
        
        return Poll(
            id: id,
            question: question,
            options: pollOptions,
            totalVotes: totalVotes,
            userHasVoted: userHasVoted,
            postId: postId,
            userId: pollUserId,
            createdAt: createdAt
        )
    }
    
    private static func parsePollOption(from json: [String: Any]) -> PollOption? {
        guard let id = json["id"] as? Int,
              let text = json["option_text"] as? String else {
            return nil
        }
        
        let votesCount = json["votes_count"] as? Int ?? 0
        let percentage = json["percentage"] as? Int ?? 0
        let userVoted = json["user_voted"] as? Bool ?? false
        
        let option = PollOption(
            id: id,
            text: text,
            votesCount: votesCount,
            percentage: percentage,
            userVoted: userVoted
        )
        
        return option
    }
    
    static func parsePollList(from jsonArray: [[String: Any]], userId: Int) -> [Poll] {
        var polls: [Poll] = []
        
        for pollDict in jsonArray {
            if let poll = parsePoll(from: pollDict, userId: userId) {
                polls.append(poll)
            }
        }
        
        return polls
    }
}
// MARK: - Adatmodellek

struct LoginResponse: Codable {
    let message: String
    let token: String?
    let username: String?
    let user_id: Int?
}

struct RegisterResponse: Codable {
    let message: String
}

struct PostResponse: Codable {
    let message: String
    let post_id: Int
}

struct ServerPost: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String?
    let content: String?
    let image_url: String?
    let video_url: String?
    let likes: Int
    let created_at: String
    let comments: [ServerComment]?
    let user_liked: Bool?
    let user_commented: Bool?
    let user_saved: Bool?
    let poll: ServerPoll?
    
    // Rugalmas inicializálás hiányzó mezők esetén
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        user_id = try container.decode(Int.self, forKey: .user_id)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
        video_url = try container.decodeIfPresent(String.self, forKey: .video_url)
        
        // Rugalmas likes kezelés
        do {
            likes = try container.decode(Int.self, forKey: .likes)
        } catch {
            likes = 0
        }
        
        created_at = try container.decode(String.self, forKey: .created_at)
        comments = try container.decodeIfPresent([ServerComment].self, forKey: .comments) ?? []
        user_liked = try container.decodeIfPresent(Bool.self, forKey: .user_liked) ?? false
        user_commented = try container.decodeIfPresent(Bool.self, forKey: .user_commented) ?? false
        user_saved = try container.decodeIfPresent(Bool.self, forKey: .user_saved) ?? false
        poll = try container.decodeIfPresent(ServerPoll.self, forKey: .poll)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, user_id, username, content, image_url, video_url, likes, created_at, comments, user_liked, user_commented, user_saved, poll
    }
}

struct ServerComment: Codable, Identifiable {
    let id: Int
    let post_id: Int
    let user_id: Int
    let username: String?
    let content: String
    let created_at: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        post_id = try container.decode(Int.self, forKey: .post_id)
        user_id = try container.decode(Int.self, forKey: .user_id)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        content = try container.decode(String.self, forKey: .content)
        created_at = try container.decode(String.self, forKey: .created_at)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, post_id, user_id, username, content, created_at
    }
}
struct ServerPoll: Codable {
    let id: Int
    let post_id: Int
    let user_id: Int
    let question: String
    let created_at: String
    let options: [ServerPollOption]
    let total_votes: Int
    let user_has_voted: Bool
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        post_id = try container.decode(Int.self, forKey: .post_id)
        user_id = try container.decode(Int.self, forKey: .user_id)
        question = try container.decode(String.self, forKey: .question)
        created_at = try container.decode(String.self, forKey: .created_at)
        options = try container.decode([ServerPollOption].self, forKey: .options)
        
        // Rugalmas total_votes kezelés
        do {
            total_votes = try container.decode(Int.self, forKey: .total_votes)
        } catch {
            total_votes = 0
        }
        
        // Rugalmas user_has_voted kezelés
        do {
            user_has_voted = try container.decode(Bool.self, forKey: .user_has_voted)
        } catch {
            user_has_voted = false
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, post_id, user_id, question, created_at, options, total_votes, user_has_voted
    }
}

struct ServerPollOption: Codable {
    let id: Int
    let poll_id: Int
    let option_text: String
    let votes_count: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        poll_id = try container.decode(Int.self, forKey: .poll_id)
        option_text = try container.decode(String.self, forKey: .option_text)
        
        // Rugalmas votes_count kezelés
        do {
            votes_count = try container.decode(Int.self, forKey: .votes_count)
        } catch {
            votes_count = 0
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, poll_id, option_text, votes_count
    }
}

struct User: Codable {
    let id: Int
    let username: String
    let email: String?
    let profile_picture: String?
    let bio: String?
    let created_at: String
    let last_login: String?
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case serverError(statusCode: Int)
    case invalidImage
    case unauthorized
    
}

struct SearchedUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let created_at: String
    let last_login: String?
    
    // Rugalmas dátumkezelés
    enum CodingKeys: String, CodingKey {
        case id, username, email, created_at, last_login
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        
        // Rugalmas dátumkezelés
        do {
            created_at = try container.decode(String.self, forKey: .created_at)
        } catch {
            created_at = "Ismeretlen dátum"
        }
        
        do {
            last_login = try container.decodeIfPresent(String.self, forKey: .last_login)
        } catch {
            last_login = nil
        }
    }
}
