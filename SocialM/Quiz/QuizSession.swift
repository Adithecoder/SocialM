//
//  QuizSession.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/15/25.
//

//
//  QuizSessionView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2023. 11. 21.
//

import SwiftUI

// MARK: - Quiz Session View
struct QuizSessionView: View {
    @StateObject private var session: QuizSession
    @State private var showResults = false
    @State private var selectedAnswer: Int?
    @State private var progress: Double = 1.0
    @State private var timer: Timer?
    @Environment(\.presentationMode) var presentationMode
    
    init(session: QuizSession) {
        _session = StateObject(wrappedValue: session)
    }
    
    var body: some View {
        ZStack {
            // Háttér
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.1), .green.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fejléc
                headerSection
                
                // Fő tartalom
                if session.gameState == .waiting {
                    waitingRoomView
                } else if session.gameState == .inProgress {
                    gameInProgressView
                } else if session.gameState == .showingResults {
                    resultsView
                } else {
                    finishedView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startSession()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Fejléc
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(session.quiz.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(session.currentQuestionIndex + 1) / \(session.quiz.questions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Timer vagy állapot ikon
                if session.gameState == .inProgress {
                    Circle()
                        .fill(
                            progress > 0.3 ? .green :
                            progress > 0.1 ? .orange : .red
                        )
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Progress bar
            if session.gameState == .inProgress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var progressColor: Color {
        progress > 0.3 ? .green :
        progress > 0.1 ? .orange : .red
    }
    
    // MARK: - Várakozó szoba
    private var waitingRoomView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.7))
                
                VStack(spacing: 12) {
                    Text("Várakozás a játékosokra")
                        .font(.title2.bold())
                    
                    Text("A játék akkor indul, ha mindenki kész")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Játékos lista
                LazyVStack(spacing: 12) {
                    ForEach(session.players) { player in
                        PlayerRow(player: player, isHost: player.id == 1)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Kész gomb
                if let currentPlayer = session.players.first(where: { $0.id == 1 }) {
                    Button(action: {
                        toggleReady(player: currentPlayer)
                    }) {
                        HStack {
                            Text(currentPlayer.isReady ? "Visszavonás" : "Kész vagyok")
                            Image(systemName: currentPlayer.isReady ? "checkmark.circle.fill" : "circle")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            currentPlayer.isReady ?
                            LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Indítás gomb (csak hostnak)
                if allPlayersReady && session.players.first(where: { $0.id == 1 }) != nil {
                    Button("Játék indítása") {
                        startGame()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 32)
        }
    }
    
    private var allPlayersReady: Bool {
        !session.players.isEmpty && session.players.allSatisfy { $0.isReady }
    }
    
    // MARK: - Játék közbeni nézet
    private var gameInProgressView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Kérdés
                VStack(spacing: 16) {
                    Text("Kérdés \(session.currentQuestionIndex + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    Text(currentQuestion.question)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Válaszlehetőségek
                LazyVStack(spacing: 12) {
                    ForEach(0..<currentQuestion.options.count, id: \.self) { index in
                        AnswerOption(
                            option: currentQuestion.options[index],
                            index: index,
                            isSelected: selectedAnswer == index,
                            isCorrect: showResults && index == currentQuestion.correctAnswer,
                            isWrong: showResults && selectedAnswer == index && index != currentQuestion.correctAnswer,
                            action: { selectAnswer(index) }
                        )
                        .disabled(showResults)
                    }
                }
                .padding(.horizontal)
                
                // Következő gomb
                if showResults {
                    Button("Következő kérdés") {
                        nextQuestion()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Magyarázat (ha van és látható)
                if showResults, let explanation = currentQuestion.explanation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Magyarázat")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(explanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Eredmények nézet
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Kérdés eredménye")
                    .font(.title2.bold())
                
                VStack(spacing: 16) {
                    ForEach(session.players) { player in
                        PlayerResultRow(
                            player: player,
                            isCorrect: didPlayerAnswerCorrectly(playerId: player.id),
                            currentAnswer: getPlayerAnswer(playerId: player.id)
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                Button("Következő kérdés") {
                    nextQuestion()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical, 32)
        }
    }
    
    // MARK: - Játék vége nézet
    private var finishedView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Játék vége!")
                    .font(.largeTitle.bold())
                
                // Végeredmények
                VStack(spacing: 16) {
                    Text("Végeredmény")
                        .font(.title2.bold())
                        .padding(.bottom, 8)
                    
                    ForEach(session.players.sorted { $0.score > $1.score }) { player in
                        FinalScoreRow(player: player, rank: getPlayerRank(player))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Művelet gombok
                VStack(spacing: 12) {
                    Button("Új játék") {
                        restartGame()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button("Vissza a főképernyőre") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 32)
        }
    }
    
    // MARK: - Számított tulajdonságok
    private var currentQuestion: QuizQuestion {
        session.quiz.questions[session.currentQuestionIndex]
    }
    
    // MARK: - Műveletek
    private func startSession() {
        if session.gameState == .waiting {
            // Szimuláljuk, hogy más játékosok csatlakoznak
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if session.players.count < 4 {
                    let newPlayer = QuizPlayer(
                        id: session.players.count + 1,
                        userId: session.players.count + 100,
                        username: "Játékos \(session.players.count + 1)"
                    )
                    session.players.append(newPlayer)
                }
            }
        }
    }
    
    private func toggleReady(player: QuizPlayer) {
        if let index = session.players.firstIndex(where: { $0.id == player.id }) {
            session.players[index].isReady.toggle()
        }
    }
    
    private func startGame() {
        session.gameState = .inProgress
        session.startTime = Date()
        startTimer()
    }
    
    private func startTimer() {
        progress = 1.0
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if progress > 0 {
                progress -= 0.1 / Double(session.quiz.timeLimit)
            } else {
                timeUp()
            }
        }
    }
    
    private func timeUp() {
        timer?.invalidate()
        showResults = true
        // Automatikus válasz szimulálása a többi játékosnak
        simulateOtherPlayersAnswers()
    }
    
    private func selectAnswer(_ answerIndex: Int) {
        selectedAnswer = answerIndex
        session.players[0].currentAnswer = answerIndex // Current user
        session.players[0].answerTime = Date()
        
        // Timer leállítása és eredmények mutatása
        timer?.invalidate()
        showResults = true
        simulateOtherPlayersAnswers()
    }
    
    private func simulateOtherPlayersAnswers() {
        // Szimuláljuk a többi játékos válaszait
        for i in 1..<session.players.count {
            let randomAnswer = Int.random(in: 0..<currentQuestion.options.count)
            let isCorrect = randomAnswer == currentQuestion.correctAnswer
            
            session.players[i].currentAnswer = randomAnswer
            session.players[i].answerTime = Date()
            
            if isCorrect {
                session.players[i].score += 10
            }
        }
        
        // Jelenlegi játékos pontozása
        if let selectedAnswer = selectedAnswer, selectedAnswer == currentQuestion.correctAnswer {
            session.players[0].score += 10
        }
    }
    
    private func nextQuestion() {
        if session.currentQuestionIndex < session.quiz.questions.count - 1 {
            session.currentQuestionIndex += 1
            selectedAnswer = nil
            showResults = false
            startTimer()
        } else {
            session.gameState = .finished
            session.endTime = Date()
        }
    }
    
    private func restartGame() {
        // Reset session
        session.currentQuestionIndex = 0
        session.gameState = .waiting
        selectedAnswer = nil
        showResults = false
        progress = 1.0
        
        // Reset players
        for i in 0..<session.players.count {
            session.players[i].score = 0
            session.players[i].isReady = false
            session.players[i].currentAnswer = nil
            session.players[i].answerTime = nil
        }
        
        timer?.invalidate()
    }
    
    // MARK: - Segéd függvények
    private func didPlayerAnswerCorrectly(playerId: Int) -> Bool {
        guard let player = session.players.first(where: { $0.id == playerId }),
              let answer = player.currentAnswer else { return false }
        return answer == currentQuestion.correctAnswer
    }
    
    private func getPlayerAnswer(playerId: Int) -> Int? {
        session.players.first(where: { $0.id == playerId })?.currentAnswer
    }
    
    private func getPlayerRank(_ player: QuizPlayer) -> Int {
        let sortedPlayers = session.players.sorted { $0.score > $1.score }
        return (sortedPlayers.firstIndex(where: { $0.id == player.id }) ?? 0) + 1
    }
}

// MARK: - Segéd View-ok
struct PlayerRow: View {
    let player: QuizPlayer
    let isHost: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.username)
                    .font(.headline)
                
                if isHost {
                    Text("Házigazda")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if player.isReady {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AnswerOption: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        if isCorrect {
            return .green.opacity(0.2)
        } else if isWrong {
            return .red.opacity(0.2)
        } else if isSelected {
            return .blue.opacity(0.2)
        } else {
            return .gray.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else if isSelected {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isCorrect || isWrong || isSelected {
            return .primary
        } else {
            return .primary
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.body)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                } else if isSelected {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlayerResultRow: View {
    let player: QuizPlayer
    let isCorrect: Bool
    let currentAnswer: Int?
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.username)
                    .font(.headline)
                
                if let answer = currentAnswer {
                    Text("Válasz: \(answer + 1). lehetőség")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Nem válaszolt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("+10")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("0")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FinalScoreRow: View {
    let player: QuizPlayer
    let rank: Int
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
    
    var body: some View {
        HStack {
            Text(rankIcon)
                .font(.title2)
            
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.username)
                    .font(.headline)
                
                Text("\(player.score) pont")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if rank <= 3 {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(rank <= 3 ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        QuizSessionView(session: createSampleSession())
    }
}

private func createSampleSession() -> QuizSession {
    let sampleQuiz = Quiz(
        id: 1,
        title: "Általános tudás",
        description: "Teszteld általános tudásodat",
        category: "Tudomány",
        difficulty: .medium,
        questions: [
            QuizQuestion(
                id: 1,
                question: "Mi a Föld legnagyobb óceánja?",
                options: ["Atlanti-óceán", "Indiai-óceán", "Csendes-óceán", "Északi-sarki-óceán"],
                correctAnswer: 2,
                explanation: "A Csendes-óceán a legnagyobb óceán a Földön, amely több mint egyharmadát lefedi a Föld felszínének."
            ),
            QuizQuestion(
                id: 2,
                question: "Hány kontinens van a Földön?",
                options: ["5", "6", "7", "8"],
                correctAnswer: 2,
                explanation: "Hagyományosan 7 kontinenst különböztetünk meg: Észak-Amerika, Dél-Amerika, Európa, Ázsia, Afrika, Ausztrália és Antarktisz."
            )
        ],
        timeLimit: 30,
        maxPlayers: 4,
        createdBy: 1
    )
    
    let players = [
        QuizPlayer(id: 1, userId: 100, username: "Te", isReady: true),
        QuizPlayer(id: 2, userId: 101, username: "Játékos 2", isReady: true),
        QuizPlayer(id: 3, userId: 102, username: "Játékos 3", isReady: false)
    ]
    
    return QuizSession(id: 1, quiz: sampleQuiz, players: players)
}
