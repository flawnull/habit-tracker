//
//  ContentView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: AppTab = .today

    enum AppTab: Hashable {
        case today, stats, habits, profile
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "checkmark.circle.fill", value: AppTab.today) {
                TodayView()
            }
            Tab("Insights", systemImage: "chart.xyaxis.line", value: AppTab.stats) {
                StatisticsView()
            }
            Tab("Habits", systemImage: "square.stack.3d.up.fill", value: AppTab.habits) {
                HabitsListView()
            }
            Tab("Profile", systemImage: "person.crop.circle.fill", value: AppTab.profile) {
                ProfileView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .modelContainer(SampleData.previewContainer)
}
