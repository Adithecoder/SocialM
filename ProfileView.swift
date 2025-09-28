import SwiftUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool // Bejelentkezési állapot

    var body: some View {
        VStack {
            Text("Profil")
                .font(.largeTitle)
                .padding()

            // Itt megjelenítheted a felhasználói információkat
            Text("Felhasználónév: \(UserDefaults.standard.string(forKey: "username") ?? "N/A")")
                .padding()

            Button(action: logout) {
                Text("Kijelentkezés")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
        }
        .padding()
    }

    private func logout() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn") // Bejelentkezési állapot törlése
        UserDefaults.standard.removeObject(forKey: "username") // Felhasználónév törlése (opcionális)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(isLoggedIn: .constant(true)) // Példa a bejelentkezési állapotra
    }
}
