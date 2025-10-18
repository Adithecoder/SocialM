//
//  QuizView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/15/25.
//

import SwiftUI

// MARK: - Quiz Modell
class Quiz: ObservableObject, Identifiable {
    let id: Int
    @Published var title: String
    @Published var description: String
    @Published var category: String
    @Published var difficulty: QuizDifficulty
    @Published var questions: [QuizQuestion]
    @Published var timeLimit: Int // másodpercben
    @Published var maxPlayers: Int
    @Published var createdBy: Int
    @Published var createdAt: Date
    @Published var isPublic: Bool
    @Published var playsCount: Int
    @Published var averageScore: Double
    
    init(id: Int, title: String, description: String, category: String, difficulty: QuizDifficulty, questions: [QuizQuestion], timeLimit: Int = 30, maxPlayers: Int = 4, createdBy: Int, createdAt: Date = Date(), isPublic: Bool = true, playsCount: Int = 0, averageScore: Double = 0.0) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.questions = questions
        self.timeLimit = timeLimit
        self.maxPlayers = maxPlayers
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.isPublic = isPublic
        self.playsCount = playsCount
        self.averageScore = averageScore
    }
}

struct QuizQuestion: Identifiable {
    let id: Int
    var question: String
    var options: [String]
    var correctAnswer: Int
    var explanation: String?
    
    init(id: Int, question: String, options: [String], correctAnswer: Int, explanation: String? = nil) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

enum QuizDifficulty: String, CaseIterable {
    case easy = "Könnyű"
    case medium = "Közepes"
    case hard = "Nehéz"
    case expert = "Szakértő"
}

// MARK: - Quiz Session
class QuizSession: ObservableObject {
    let id: Int
    let quiz: Quiz
    @Published var players: [QuizPlayer]
    @Published var currentQuestionIndex: Int
    @Published var timeRemaining: Int
    @Published var gameState: QuizGameState
    @Published var answers: [Int: [Int: Int]] // [playerId: [questionIndex: selectedAnswer]]
    @Published var startTime: Date?
    @Published var endTime: Date?
    
    init(id: Int, quiz: Quiz, players: [QuizPlayer]) {
        self.id = id
        self.quiz = quiz
        self.players = players
        self.currentQuestionIndex = 0
        self.timeRemaining = quiz.timeLimit
        self.gameState = .waiting
        self.answers = [:]
    }
}

class QuizPlayer: ObservableObject, Identifiable {
    let id: Int
    let userId: Int
    @Published var username: String
    @Published var score: Int
    @Published var isReady: Bool
    @Published var currentAnswer: Int?
    @Published var answerTime: Date?
    
    init(id: Int, userId: Int, username: String, score: Int = 0, isReady: Bool = false) {
        self.id = id
        self.userId = userId
        self.username = username
        self.score = score
        self.isReady = isReady
    }
}

enum QuizGameState {
    case waiting
    case inProgress
    case showingResults
    case finished
}

// MARK: - Quiz View Model
class QuizViewModel: ObservableObject {
    @Published var availableQuizzes: [Quiz] = []
    @Published var activeSessions: [QuizSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String = "Összes"
    
    let categories = [
        "Összes",
        "Tudomány",
        "Történelem",
        "Földrajz",
        "Művészet",
        "Sport",
        "Szórakoztatás",
        "Technológia",
        "Matematika",
        "Nyelvtan"
    ]
    
    init() {
        loadSampleQuizzes()
    }
    
    func loadAvailableQuizzes() {
        isLoading = true
        errorMessage = nil
        
        // Szimuláljuk a betöltési időt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.loadSampleQuizzes()
            print("✅ Kvízek betöltve: \(self.availableQuizzes.count)")
        }
    }
    
    private func loadSampleQuizzes() {
        // Minta adatok létrehozása
        let sampleQuizzes = [
            Quiz(
                id: 1,
                title: "Általános tudás",
                description: "Teszteld általános tudásodat ezzel a klasszikus kvízzel",
                category: "Tudomány",
                difficulty: .medium,
                questions: [
                    QuizQuestion(
                        id: 1,
                        question: "Mi a Föld legnagyobb óceánja?",
                        options: ["Atlanti-óceán", "Indiai-óceán", "Csendes-óceán", "Északi-sarki-óceán"],
                        correctAnswer: 2
                    ),
                    QuizQuestion(
                        id: 2,
                        question: "Hány kontinens van a Földön?",
                        options: ["5", "6", "7", "8"],
                        correctAnswer: 2
                    )
                ],
                timeLimit: 30,
                maxPlayers: 4,
                createdBy: 1,
                playsCount: 24,
                averageScore: 65.5
            ),
            Quiz(
                id: 2,
                title: "Magyar történelem",
                description: "Fontos dátumok és események a magyar történelemből",
                category: "Történelem",
                difficulty: .hard,
                questions: [
                    QuizQuestion(
                        id: 1,
                        question: "Mikor volt a honfoglalás?",
                        options: ["896", "1000", "1241", "1526"],
                        correctAnswer: 0
                    )
                ],
                timeLimit: 45,
                maxPlayers: 6,
                createdBy: 1,
                playsCount: 15,
                averageScore: 42.3
            ),
            Quiz(
                id: 3,
                title: "Sport világa",
                description: "Különböző sportágak és szabályaik",
                category: "Sport",
                difficulty: .easy,
                questions: [
                    QuizQuestion(
                        id: 1,
                        question: "Hány játékosból áll egy kosárlabda csapat?",
                        options: ["5", "6", "7", "8"],
                        correctAnswer: 0
                    )
                ],
                timeLimit: 25,
                maxPlayers: 8,
                createdBy: 1,
                playsCount: 32,
                averageScore: 78.9
            )
        ]
        
        self.availableQuizzes = sampleQuizzes
    }
    
    func createQuizSession(quiz: Quiz, invitedUsers: [Int] = []) {
        print("✅ Kvíz session létrehozva: \(quiz.title)")
        // Itt lehetne helyi session-t létrehozni
        // Például: navigate to game view with local session
    }
    
    func joinQuizSession(sessionId: Int) {
        print("✅ Csatlakozás session-hez: \(sessionId)")
        // Helyi session kezelés
    }
    
    var filteredQuizzes: [Quiz] {
        if selectedCategory == "Összes" {
            return availableQuizzes
        }
        return availableQuizzes.filter { $0.category == selectedCategory }
    }
}

// MARK: - Fő Quiz View
struct QuizGameView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @State private var showCreateQuiz = false
    @State private var showJoinSession = false
    @State private var searchText = ""
    @State private var selectedDifficulty: QuizDifficulty?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Háttér gradient
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.1), .green.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fejléc
                    headerSection
                    
                    // Kategória szűrők
                    categoryFilterSection
                    
                    // Fő tartalom
                    ScrollView {
                        VStack(spacing: 20) {
                            // Gyors műveletek
                            quickActionsSection
                            
                            // Kvíz lista
                            quizzesListSection
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateQuiz) {
                CreateQuizView(isPresented: $showCreateQuiz)
            }
            .sheet(isPresented: $showJoinSession) {
                JoinSessionView(isPresented: $showJoinSession)
            }
            .onAppear {
                quizViewModel.loadAvailableQuizzes()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kvízjátékok")
                        .font(.custom("Jellee", size:28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Játssz és tanulj közben!")
                        .font(.lexend3())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profil kép
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.horizontal)
            
            // Kereső sáv
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Keresés kvízek között...", text: $searchText)
                    .font(.lexend2())

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quizViewModel.categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: quizViewModel.selectedCategory == category,
                        action: { quizViewModel.selectedCategory = category }
                    )
                }
            }
            
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    private var quickActionsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            QuickActionCard(
                icon: "plus.circle.fill",
                title: "Új kvíz",
                subtitle: "Készítsd el saját kvízed",
                color: .blue,
                action: { showCreateQuiz = true }
            )
            
            QuickActionCard(
                icon: "person.2.fill",
                title: "Csatlakozás",
                subtitle: "Csatlakozz barátaidhoz",
                color: .green,
                action: { showJoinSession = true }
            )
            
            QuickActionCard(
                icon: "chart.bar.fill",
                title: "Ranglista",
                subtitle: "Nézd meg az eredményeidet",
                color: .orange,
                action: { print("Ranglista megnyitva") }
            )
            
            QuickActionCard(
                icon: "crown.fill",
                title: "Kihívás",
                subtitle: "Versenyzz másokkal",
                color: .red,
                action: { print("Kihívás megnyitva") }
            )
        }
    }
    
    private var quizzesListSection: some View {
        LazyVStack(spacing: 16) {
            if quizViewModel.isLoading {
                ForEach(0..<3, id: \.self) { _ in
                    QuizCardSkeleton()
                }
            } else if quizViewModel.filteredQuizzes.isEmpty {
                EmptyQuizzesView()
            } else {
                ForEach(quizViewModel.filteredQuizzes) { quiz in
                    QuizCard(quiz: quiz) {
                        // Kvíz indítása
                        quizViewModel.createQuizSession(quiz: quiz)
                    }
                }
            }
        }
    }
}

// MARK: - Segéd View-ok
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Lexend", size:12))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Jellee", size:20))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.custom("Lexend", size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuizCard: View {
    let quiz: Quiz
    let onPlay: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(quiz.title)
                        .font(.lexend())
                        .foregroundColor(.primary)
                    
                    Text(quiz.description)
                        .font(.lexend2())
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Nehézség badge
                DifficultyBadge(difficulty: quiz.difficulty)
            }
            
            // Meta információk
            HStack {
                Label("\(quiz.questions.count) kérdés", systemImage: "questionmark.circle")
                    .font(.lexend3())

                Spacer()
                
                Label("\(quiz.playsCount)", systemImage: "play.circle")
                    .font(.lexend3())

                Spacer()
                
                Label("\(quiz.timeLimit)s", systemImage: "clock")
                    .font(.lexend3())
            }
            .foregroundColor(.secondary)
            
            // Művelet gomb
            Button(action: onPlay) {
                HStack {
                    Text("Játék indítása")
                        .font(.custom("Jellee", size:18))

                    Spacer()
                    
                    Image(systemName: "play.fill")
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct DifficultyBadge: View {
    let difficulty: QuizDifficulty
    
    var color: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .expert: return .purple
        }
    }
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.custom("Jellee", size:13))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct QuizCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Skeleton placeholders
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .cornerRadius(4)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
                .cornerRadius(4)
            
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .cornerRadius(4)
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 44)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EmptyQuizzesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("Még nincsenek kvízek")
                .font(.custom("Jellee", size:20))
                .foregroundColor(.primary)
            
            Text("Legyél te az első, aki létrehoz egy kvízt!")
                .font(.lexend3())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Kvíz Létrehozás View
// MARK: - Kvíz Létrehozás View
struct CreateQuizView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = CreateQuizViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Fejléc section
                    Text("Új kvíz létrehozása")
                        .font(.custom("Lexend", size: 24))
                        .foregroundColor(.primary)
                .listRowBackground(Color.clear)

                // Kvíz alap információk section
                Section(header: Text("Kvíz információk")
                    .font(.lexend())
                    .foregroundStyle(Color.DesignSystem.fokekszin)
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Kvíz címe...", text: $viewModel.title)
                            .font(.custom("Jellee", size: 16))
                            .padding(8)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.1)]),
                                startPoint: .leading, endPoint: .trailing),
                                lineWidth: 3
                            )
                    )
                    .listRowBackground(Color.clear)

                    
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Leírás...", text: $viewModel.description)
                            .font(.custom("Jellee", size: 16))
                            .padding(8)
                    }
                    
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.1)]),
                                startPoint: .leading, endPoint: .trailing),
                                lineWidth: 3
                            )
                    )
                    .listRowBackground(Color.clear)

                    // Kategória választó
                    HStack {
                        Text("Kategória")
                            .font(.lexend())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $viewModel.selectedCategory) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                Text(category).tag(category)
                                    .font(.lexend())
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)

                    // Nehézség választó
                    HStack {
                        Text("Nehézség")
                            .font(.lexend())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $viewModel.difficulty) {
                            ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.rawValue).tag(difficulty)
                                    .font(.lexend())
                            }
                        }

                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                // Kérdések section
                Section(header: Text("Kérdések")
                    .font(.lexend())
                    .foregroundStyle(Color.DesignSystem.fokekszin)
                ) {
                    ForEach(viewModel.questions.indices, id: \.self) { index in
                        QuestionEditorView(
                            question: $viewModel.questions[index],
                            onDelete: { viewModel.deleteQuestion(at: index) }
                        )
                        .listRowBackground(Color.clear)
                    }
                    
                    Button(action: {
                        viewModel.addQuestion()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 30)
                                .foregroundStyle(LinearGradient(
                                    gradient: Gradient(colors: [.DesignSystem.fokekszin, .DesignSystem.fokekszin.opacity(0.1)]),
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                                .padding(.horizontal, 5)
                            
                            Text("Új kérdés hozzáadása")
                                .font(.lexend())
                                .foregroundStyle(Color.DesignSystem.fokekszin)
                        }
                    }
                    .disabled(viewModel.questions.count >= 10)
                }
                .listRowBackground(Color.clear)

                // Beállítások section
                Section(header: Text("Beállítások")
                    .font(.lexend())
                    .foregroundStyle(Color.DesignSystem.fokekszin)
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Időkorlát: \(viewModel.timeLimit) másodperc")
                                .font(.lexend())
                            
                            Spacer()
                            
                            Button(action: {
                                if viewModel.timeLimit > 10 {
                                    viewModel.timeLimit -= 5
                                }
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                if viewModel.timeLimit < 120 {
                                    viewModel.timeLimit += 5
                                }
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Maximum játékosok: \(viewModel.maxPlayers)")
                                .font(.lexend())
                            
                            Spacer()
                            
                            Button(action: {
                                if viewModel.maxPlayers > 1 {
                                    viewModel.maxPlayers -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                if viewModel.maxPlayers < 8 {
                                    viewModel.maxPlayers += 1
                                }
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Toggle("Nyilvános kvíz", isOn: $viewModel.isPublic)
                        .font(.lexend())
                }
                .listRowBackground(Color.clear)

                // Létrehozás gomb section
                Section {
                    Button("Kvíz létrehozása") {
                        viewModel.createQuiz()
                        isPresented = false
                    }
                    .font(.custom("Jellee", size: 20))
                    .disabled(!viewModel.isValid)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(LinearGradient(
                        gradient: Gradient(colors: [
                            .green.opacity(0.9),
                            .green.opacity(0.7),
                            .green.opacity(0.5),
                            .green.opacity(0.3),
                            .green.opacity(0.2)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ), lineWidth: 5)
                    )
                    .cornerRadius(20)
                }
                .listRowBackground(Color.clear)
            }
            .listRowBackground(Color.clear)
            .navigationTitle("Új kvíz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Mégse") {
                    isPresented = false
                }
                .font(.lexend()),
                trailing: Button("Létrehozás") {
                    viewModel.createQuiz()
                    isPresented = false
                }
                .font(.lexend())
                .disabled(!viewModel.isValid)
            )
        }
    }
}

struct QuestionEditorView: View {
    @StateObject private var questionWrapper: QuestionWrapper
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    @State private var questionType: QuestionType = .singleChoice
    
    init(question: Binding<QuizQuestion>, onDelete: @escaping () -> Void) {
        self._questionWrapper = StateObject(wrappedValue: QuestionWrapper(question: question.wrappedValue))
        self.onDelete = onDelete
    }
    
    enum QuestionType {
        case singleChoice, multipleChoice
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {

                
                // Question type selector
                Picker("Típus", selection: $questionType) {
                    Text("Egy válasz").tag(QuestionType.singleChoice)
                    Text("Több válasz").tag(QuestionType.multipleChoice)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                
                Spacer()
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            // Question input
            VStack(alignment: .leading, spacing: 6) {

                
                TextField("Írd ide a kérdést...", text: $questionWrapper.question, axis: .vertical)
                    .font(.lexend2())
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    .onChange(of: questionWrapper.question) { newValue in
                        questionWrapper.object.question = newValue
                    }
            }
            
            // Options section
            VStack(alignment: .leading, spacing: 8) {

                LazyVStack(spacing: 8) {
                    ForEach(0..<questionWrapper.object.options.count, id: \.self) { index in
                        OptionRow(
                            index: index,
                            text: $questionWrapper.options[index],
                            isCorrect: questionWrapper.correctAnswers.contains(index),
                            questionType: questionType,
                            onTextChange: { newValue in
                                questionWrapper.object.options[index] = newValue
                            },
                            onSelect: {
                                handleAnswerSelection(for: index)
                            }
                        )
                    }
                }
            }
            
            // Correct answer indicator
            if !questionWrapper.correctAnswers.isEmpty {
                HStack {
                    Image(systemName: questionType == .multipleChoice ? "checkmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    if questionType == .singleChoice, let correctIndex = questionWrapper.correctAnswers.first {
                        Text("Helyes válasz: **\(questionWrapper.object.options[correctIndex])**")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Helyes válaszok: \(questionWrapper.correctAnswers.map { String($0 + 1) }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
        .onAppear {
            updateQuestionType()
        }
        .onChange(of: questionType) { newType in
            updateAnswersForNewType(newType)
        }
        .alert("Kérdés törlése", isPresented: $showingDeleteAlert) {
            Button("Mégse", role: .cancel) { }
            Button("Törlés", role: .destructive, action: onDelete)
        } message: {
            Text("Biztosan törölni szeretnéd ezt a kérdést?")
        }
    }
    
    private func handleAnswerSelection(for index: Int) {
        switch questionType {
        case .singleChoice:
            questionWrapper.correctAnswers = [index]
            questionWrapper.object.correctAnswer = index
        case .multipleChoice:
            if questionWrapper.correctAnswers.contains(index) {
                questionWrapper.correctAnswers.remove(index)
            } else {
                questionWrapper.correctAnswers.insert(index)
            }
            // Multiple choice esetén a correctAnswer property-t is frissítjük az első helyes válaszra
            if let firstCorrect = questionWrapper.correctAnswers.first {
                questionWrapper.object.correctAnswer = firstCorrect
            }
        }
    }
    
    private func updateQuestionType() {
        if questionWrapper.correctAnswers.count > 1 {
            questionType = .multipleChoice
        } else {
            questionType = .singleChoice
        }
    }
    
    private func updateAnswersForNewType(_ newType: QuestionType) {
        if newType == .singleChoice, let firstCorrect = questionWrapper.correctAnswers.first {
            questionWrapper.correctAnswers = [firstCorrect]
        }
    }
}

struct OptionRow: View {
    let index: Int
    @Binding var text: String
    let isCorrect: Bool
    let questionType: QuestionEditorView.QuestionType
    let onTextChange: (String) -> Void
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    // Extracted selection button view
    private var selectionButton: some View {
        Button(action: onSelect) {
            ZStack {
                if questionType == .singleChoice {
                    Circle()
                        .stroke(selectionStrokeColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isCorrect {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selectionStrokeColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isCorrect {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var selectionStrokeColor: Color {
        isCorrect ? Color.green : Color.gray.opacity(0.4)
    }
    
    // Extracted option number badge
//    private var optionNumberBadge: some View {
//        Text("\(index + 1)")
//            .font(.caption2)
//            .fontWeight(.medium)
//            .foregroundColor(.white)
//            .frame(width: 18, height: 18)
//            .background(
//                Circle()
//                    .fill(badgeColor)
//            )
//    }
    
    private var badgeColor: Color {
        isCorrect ? Color.green : Color.blue
    }
    
    // Gradient stroke replacements for the text field overlay and stroke
    
    private var textFieldStrokeGradient: LinearGradient {
        if isCorrect {
            return LinearGradient(
                colors: [Color.green.opacity(0.6), Color.green.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var textFieldStrokeGradient2: LinearGradient {
        if isCorrect {
            return LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    // Extracted text field
    private var optionTextField: some View {
        TextField("Opció \(index + 1)", text: $text, axis: .vertical)
            .font(.custom("Jellee", size:16))
            .padding(10)
            .background(textFieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isCorrect ? textFieldStrokeGradient : textFieldStrokeGradient2)
                    )
            
            .onChange(of: text, perform: onTextChange)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(textFieldFillColor)
            .stroke(isCorrect ? textFieldStrokeGradient : textFieldStrokeGradient2, lineWidth: 3)
    }
    
    private var textFieldFillColor: Color {
        isCorrect ? Color.green.opacity(0.05) : Color.gray.opacity(0.05)
    }
    
    // Extracted correct answer indicator
    @ViewBuilder
    private var correctAnswerIndicator: some View {
        if isCorrect {

        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            selectionButton
//            optionNumberBadge
            optionTextField
            correctAnswerIndicator
        }
        .padding(6)
        .background(rowBackground)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isHovered ? Color.gray.opacity(0.03) : Color.clear)
    }
}

// Helper extension for better shadows
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}



// ViewModel változatlan marad, de biztosítsuk, hogy a QuizQuestion struct legyen

class CreateQuizViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategory = "Tudomány"
    @Published var difficulty: QuizDifficulty = .medium
    @Published var questions: [QuizQuestion] = [QuizQuestion(id: 0, question: "", options: ["", "", "", ""], correctAnswer: 0)]
    @Published var timeLimit = 30
    @Published var maxPlayers = 4
    @Published var isPublic = true
    
    let categories = ["Tudomány", "Történelem", "Földrajz", "Művészet", "Sport", "Szórakoztatás", "Technológia", "Matematika", "Nyelvtan"]
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        questions.allSatisfy { question in
            !question.question.trimmingCharacters(in: .whitespaces).isEmpty &&
            question.options.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
    }
    
    func addQuestion() {
        let newQuestion = QuizQuestion(
            id: questions.count,
            question: "",
            options: ["", "", "", ""],
            correctAnswer: 0
        )
        questions.append(newQuestion)
    }
    
    func deleteQuestion(at index: Int) {
        if questions.count > 1 {
            questions.remove(at: index)
        }
    }
    
    func createQuiz() {
        // Helyi kvíz létrehozása
        print("✅ Kvíz létrehozva: \(title)")
        print("📝 Leírás: \(description)")
        print("📂 Kategória: \(selectedCategory)")
        print("🎯 Nehézség: \(difficulty.rawValue)")
        print("❓ Kérdések száma: \(questions.count)")
    }
}



// Segéd osztály a kérdés kezeléséhez
class QuestionWrapper: ObservableObject {
    @Published var object: QuizQuestion
    @Published var question: String
    @Published var options: [String]
    @Published var correctAnswers: Set<Int>
    
    var correctAnswer: Int {
        get { object.correctAnswer }
        set { object.correctAnswer = newValue }
    }
    
    init(question: QuizQuestion) {
        self.object = question
        self.question = question.question
        self.options = question.options
        // Kezdetben egy elemű set, de többet is tárolhat
        self.correctAnswers = [question.correctAnswer]
    }
}

struct RadioButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
        }
    }
}

// MARK: - Session Csatlakozás View
struct JoinSessionView: View {
    @Binding var isPresented: Bool
    @State private var sessionCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 16) {
                    Text("Csatlakozás session-hez")
                        .font(.headline)
                    
                    Text("Add meg a session kódot, hogy csatlakozhass a játékhoz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                TextField("Session kód", text: $sessionCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Button("Csatlakozás") {
                    // Session-hez csatlakozás logika
                    print("✅ Csatlakozás session-hez: \(sessionCode)")
                    isPresented = false
                }
                .disabled(sessionCode.isEmpty)
                .buttonStyle(PrimaryButtonStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Csatlakozás")
            .navigationBarItems(trailing: Button("Bezárás") {
                isPresented = false
            })
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.blue, .green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    QuizGameView()
}
