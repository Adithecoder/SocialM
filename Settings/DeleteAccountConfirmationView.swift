import SwiftUI

struct DeleteConfirmationView: View {
    @Binding var isLoggedIn: Bool // Bejelentkezési állapot
    @State private var selectedReason: String? // Kijelentkezési ok
    @State private var otherReason: String = "" // Egyéb ok szövegdoboz tartalma
    let reasons = [
        "Személyes okok",
        "Nem használom az alkalmazást",
        "Másik alkalmazásra váltok",
        "Nem tetszik az alkalmazás",
        "Egyéb"
    ] // Kijelentkezési okok
    @State private var showAlert = false // Kijelentkezési megerősítő alert

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                

                Text("Miért szeretnél kijelentkezni?")
                    .font(.headline)

                List {
                    ForEach(reasons, id: \.self) { reason in
                        Button(action: {
                            if reason == "Egyéb" {
                                selectedReason = nil // Az "Egyéb" kiválasztásakor töröljük a kiválasztott okot
                            } else {
                                selectedReason = reason // Kijelentkezési ok kiválasztása
                                otherReason = "" // Töröljük az egyéb okot, ha másik opciót választanak
                            }
                        }) {
                            HStack {
                                Text(reason)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill") // Piros jelölő
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // Szövegdoboz az "Egyéb" okhoz
                    if selectedReason == nil {
                        TextField("Kérlek, írd le néhány szóban...", text: $otherReason)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                }

                // Kijelentkező gomb
                Button(action: {
                    if selectedReason != nil || !otherReason.isEmpty {
                        showAlert = true // Kijelentkezési megerősítő alert megjelenítése
                    }
                }) {
                    Text("Kijelentkezés")
                        .padding()
                        .background((selectedReason != nil || !otherReason.isEmpty) ? Color.red : Color.gray) // Színváltozás a kiválasztott ok alapján
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedReason == nil && otherReason.isEmpty) // Gomb letiltása, ha nincs kiválasztott ok
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Biztosan ki szeretnél jelentkezni?"),
                          
                          primaryButton: .destructive(Text("Kijelentkezés")) {
                            logout() // Kijelentkezés logika
                          },
                          secondaryButton: .cancel())
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Kijelentkezés")
        }
    }

    private func logout() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn") // Bejelentkezési állapot törlése
        UserDefaults.standard.removeObject(forKey: "username") // Felhasználónév törlése (opcionális)
    }
}

struct DeleteConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutConfirmationView(isLoggedIn: .constant(true)) // Példa a bejelentkezési állapotra
    }
}
