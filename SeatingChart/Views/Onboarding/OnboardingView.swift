//
//  OnboardingView.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showStorageSelection = false

    var body: some View {
        ZStack {
            if showStorageSelection {
                StorageSelectionView()
            } else {
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    FeaturePage(
                        icon: "square.grid.3x3",
                        title: "Flexible Layouts",
                        description: "Create custom classroom layouts with desks arranged however you like - rows, clusters, U-shapes, or anything else."
                    )
                    .tag(1)

                    FeaturePage(
                        icon: "person.3.fill",
                        title: "Easy Seating",
                        description: "Drag and drop students onto desks. See their photos on the seating chart for quick identification."
                    )
                    .tag(2)

                    FeaturePage(
                        icon: "calendar",
                        title: "Quick Attendance",
                        description: "Mark attendance directly from the seating chart. Track present, absent, and tardy students with one tap."
                    )
                    .tag(3)

                    GetStartedPage(action: {
                        withAnimation {
                            showStorageSelection = true
                        }
                    })
                    .tag(4)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)

            Text("Welcome to\nSeating Chart")
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)

            Text("The simple way to manage classroom seating and attendance")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

struct FeaturePage: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text(title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            Text(description)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

struct GetStartedPage: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Ready to Start?")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Let's set up your storage preferences")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: action) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(Constants.cornerRadius)
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppStateManager.shared)
    }
}
