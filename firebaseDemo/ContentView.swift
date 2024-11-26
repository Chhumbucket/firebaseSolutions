import SwiftUI
import FirebaseCore
import FirebaseFirestore

// User struct
struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let isAdult: Bool
    let age: Int
}

struct ContentView: View {
    @State private var users: [User] = []
    @State private var showAddUserSheet = false
    
    
    //Creating instance
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            List {
                ForEach(users) { user in
                    VStack(alignment: .leading) {
                        Text(user.username).font(.headline)
                        Text(user.email).font(.subheadline)
                        Text("Age: \(user.age) (\(user.isAdult ? "Adult" : "Minor"))")
                            .font(.subheadline)
                            .foregroundColor(user.isAdult ? .green : .red)
                    }
                    .contextMenu {
                        Button("Remove") {
                            removeUser(id: user.id)
                        }
                    }
                }
            }
            .navigationTitle("Users")
            .toolbar {
                Button(action: { showAddUserSheet.toggle() }) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                fetchUsers()
            }
            .sheet(isPresented: $showAddUserSheet) {
                AddUserView()
            }
        }
    }
    //Example of a fetch
    private func fetchUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            DispatchQueue.main.async {
                self.users = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    guard
                        let username = data["username"] as? String,
                        let email = data["email"] as? String,
                        let age = data["age"] as? Int
                    else { return nil }
                    return User(
                        id: document.documentID,
                        username: username,
                        email: email,
                        isAdult: age >= 18,
                        age: age
                    )
                } ?? []
            }
        }
    }

    // Remove a user from Firestore
    private func removeUser(id: String) {
        db.collection("users").document(id).delete { error in
            if let error = error {
                print("Error removing user: \(error)")
                return
            }
            fetchUsers() // Refresh the user list
        }
    }
}

// Add User View
struct AddUserView: View {
    @Environment(\.dismiss) var dismiss
    private let db = Firestore.firestore()

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var age: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Details")) {
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add User")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let userAge = Int(age), !username.isEmpty, !email.isEmpty {
                            addUser(username: username, email: email, age: userAge)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // Add a new user to Firestore
    private func addUser(username: String, email: String, age: Int) {
        let newUser = [
            "username": username,
            "email": email,
            "age": age,
            "isAdult": age >= 18
        ] as [String: Any]

        db.collection("pie").addDocument(data: newUser) { error in
            if let error = error {
                print("Error adding user: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
