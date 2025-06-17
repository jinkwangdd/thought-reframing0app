import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @AppStorage("username") private var username = "사용자"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var dailyReminder = true
    @State private var streakGoal = 7
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("프로필")) {
                    TextField("사용자명", text: $username)
                        .onChange(of: username) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "username")
                        }
                }
                
                Section(header: Text("앱 설정")) {
                    Toggle("다크 모드", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "isDarkMode")
                        }
                    Toggle("일일 알림", isOn: $dailyReminder)
                    
                    HStack {
                        Text("연속 목표")
                        Spacer()
                        Stepper("\(streakGoal)일", value: $streakGoal, in: 1...30)
                    }
                }
                
                Section(header: Text("언어")) {
                    Picker("언어 선택", selection: $thoughtViewModel.language) {
                        Text("한국어").tag("ko")
                        Text("English").tag("en")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("데이터")) {
                    Button("데이터 내보내기") {
                        // 데이터 내보내기 기능
                    }
                    
                    Button("데이터 초기화") {
                        // 데이터 초기화 기능
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("정보")) {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
} 