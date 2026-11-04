//
//  ForgotPasswordView.swift
//  habit-tracker
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var sent = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.brandGradient)
                        .frame(width: 110, height: 110)
                        .blur(radius: 40)
                        .opacity(0.6)
                    Image(systemName: sent ? "envelope.open.fill" : "key.horizontal.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Theme.brandGradient)
                        .contentTransition(.symbolEffect(.replace))
                }

                VStack(spacing: 8) {
                    Text(sent ? "Check your inbox" : "Reset your password")
                        .font(.title.weight(.bold))
                    Text(sent
                         ? "We sent a reset link to \(email). It can take a minute to arrive."
                         : "Enter the email you signed up with and we'll send you a reset link.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if sent {
                    Button("Back to sign in") { dismiss() }
                        .buttonStyle(BrandButtonStyle())
                } else {
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email, contentType: .emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    Button {
                        Task { await resetPassword() }
                    } label: {
                        if authManager.isLoading {
                            CustomLoadingView(tintColor: .white)
                        } else {
                            Text("Send reset link")
                        }
                    }
                    .buttonStyle(BrandButtonStyle())
                    .disabled(email.isEmpty || authManager.isLoading)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sent)
            .brandScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .alert("Couldn't send link", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "Something went wrong.")
            }
        }
    }

    private func resetPassword() async {
        guard !email.isEmpty else { return }
        do {
            try await authManager.resetPassword(email: email)
            sent = true
            Haptics.success()
        } catch {
            showError = true
            Haptics.error()
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthenticationManager())
}
