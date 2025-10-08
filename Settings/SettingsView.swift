import SwiftUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool // Bejelentkezési állapot
    @State private var showDeleteAccountConfirmation = false // Fiók törlése megerősítés
    @State private var selectedReason: String = "" // Kijelentkezési ok
    let reasons = ["Személyes okok", "Nem használom", "Másik alkalmazásra váltok", "Egyéb"] // Kijelentkezési okok

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Fiók")) {
                    Button(action: {
                        // Fiók beállítások logika
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Fiók kezelése")
                        }
                    }

                    Button(action: {
                        // Jelszó megváltoztatás logika
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Jelszó megváltoztatása")
                        }
                    }
                }

                Section(header: Text("Alapbeállítások")) {
                    Button(action: {
                        // Értesítések beállításai logika
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Értesítések")
                        }
                    }

                    Button(action: {
                        // Nyelv beállításai logika
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            
                            Text("Nyelv")
                            
                        }
                    }

                    Button(action: {
                        // Témák beállításai logika
                    }) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                            Text("Téma")
                        }
                    }
                }

                // Kijelentkezés szekció
                Section(header: Text("Kijelentkezés")) {
                    NavigationLink(destination: LogoutConfirmationView(isLoggedIn: $isLoggedIn)) {
                        HStack {
                            Image(systemName: "arrow.right.circle.")
                            Text("Kijelentkezés")
                                .foregroundColor(.red)
                        }
                    }
                }

                // Fiók törlése szekció
                Section(header: Text("Fiók törlése")) {
                    Button(action: {
                        showDeleteAccountConfirmation = true // Fiók törlése megerősítés megjelenítése
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Fiók törlése")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Beállítások")
            .alert(isPresented: $showDeleteAccountConfirmation) {
                Alert(title: Text("Fiók törlése"),
                      message: Text("Biztosan törölni szeretnéd a fiókodat? Ez a művelet visszafordíthatatlan."),
                      primaryButton: .destructive(Text("Fiók törlése")) {
                        deleteAccount() // Fiók törlése logika
                      },
                      secondaryButton: .cancel())
            }
        }
    }

    private func deleteAccount() {
        // Itt implementáld a fiók törlésének logikáját
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn") // Bejelentkezési állapot törlése
        UserDefaults.standard.removeObject(forKey: "username") // Felhasználónév törlése (opcionális)
        // További fiók törlési logika, pl. adatbázisból való törlés
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isLoggedIn: .constant(true)) // Példa a bejelentkezési állapotra
    }
}
