import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isLoggedIn") // Ellenőrizd a bejelentkezési állapotot

    var body: some View {
        if isLoggedIn {
            TabView {
                FeedView()
                    .tabItem {
                        Label("Hírcsatorna", systemImage: "house")
                    }
                MemeView()
                    .tabItem {
                        Label("Mémek", systemImage: "photo")
                    }
                ProfileView(isLoggedIn: $isLoggedIn) // Átadjuk a bejelentkezési állapotot
                    .tabItem {
                        Label("Profil", systemImage: "person")
                    }
                // További nézetek...
                
                
                SettingsView(isLoggedIn: $isLoggedIn) // Átadjuk a bejelentkezési állapotot
                    .tabItem {
                        Label("Beállítások", systemImage: "gear")
                    }
                
            }
        } else {
            LoginView(isLoggedIn: $isLoggedIn) // Bejelentkezési nézet
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
