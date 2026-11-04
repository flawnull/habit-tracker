//
//  SignUpView.swift
//  habit-tracker
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showError = false
    @State private var agreeToTerms = false
    @FocusState private var focusedField: Field?

    enum Field {
        case fullName, email, password, confirmPassword
    }

    private var isEmailValid: Bool {
        email.wholeMatch(of: #/[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}/#) != nil
    }

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isEmailValid &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    header
                    formFields
                    terms
                    Button {
                        Task { await signUp() }
                    } label: {
                        if authManager.isLoading {
                            CustomLoadingView(tintColor: .white)
                        } else {
                            Text("Create account")
                        }
                    }
                    .buttonStyle(BrandButtonStyle())
                    .disabled(!isFormValid || authManager.isLoading)

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?").foregroundStyle(.secondary)
                            Text("Sign in").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .brandScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
            .alert("Couldn't create account", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "Something went wrong.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            BrandMark(size: 84)
            Text("Create your account")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("Sync your profile and keep every streak.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            CustomTextField(icon: "person.fill", placeholder: "Full name", text: $fullName, contentType: .name)
                .focused($focusedField, equals: .fullName)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit { focusedField = .email }

            CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email, contentType: .emailAddress)
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            CustomTextField(
                icon: "lock.fill",
                placeholder: "Password (6+ characters)",
                text: $password,
                isSecure: !showPassword,
                showPasswordToggle: true,
                showPassword: $showPassword,
                contentType: .newPassword
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.next)
            .onSubmit { focusedField = .confirmPassword }

            if !password.isEmpty {
                PasswordStrengthMeter(password: password)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            CustomTextField(
                icon: "lock.rotation",
                placeholder: "Confirm password",
                text: $confirmPassword,
                isSecure: !showConfirmPassword,
                showPasswordToggle: true,
                showPassword: $showConfirmPassword,
                contentType: .newPassword
            )
            .focused($focusedField, equals: .confirmPassword)
            .submitLabel(.go)
            .onSubmit { Task { await signUp() } }

            if !confirmPassword.isEmpty && password != confirmPassword {
                Label("Passwords don't match", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: password.isEmpty)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: password == confirmPassword)
    }

    private var terms: some View {
        Button {
            agreeToTerms.toggle()
            Haptics.tap(.light)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(agreeToTerms ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                    .contentTransition(.symbolEffect(.replace))
                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private func signUp() async {
        guard isFormValid else { return }
        do {
            try await authManager.signUp(email: email, password: password, fullName: fullName.trimmingCharacters(in: .whitespaces))
            Haptics.success()
            dismiss()
        } catch {
            showError = true
            Haptics.error()
        }
    }
}

struct PasswordStrengthMeter: View {
    let password: String

    private var score: Int {
        var points = 0
        if password.count >= 8 { points += 1 }
        if password.count >= 12 { points += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { points += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil && password.rangeOfCharacter(from: .lowercaseLetters) != nil { points += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters.union(.symbols)) != nil { points += 1 }
        return min(max(points, password.count >= 6 ? 1 : 0), 4)
    }

    private var label: (String, Color) {
        switch score {
        case 0: return ("Too short", .red)
        case 1: return ("Weak", .orange)
        case 2: return ("Okay", .yellow)
        case 3: return ("Strong", Theme.teal)
        default: return ("Excellent", Theme.mint)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index < score ? AnyShapeStyle(label.1.gradient) : AnyShapeStyle(Color.primary.opacity(0.1)))
                        .frame(height: 5)
                }
            }
            Text(label.0)
                .font(.caption.weight(.semibold))
                .foregroundStyle(label.1)
                .frame(width: 70, alignment: .trailing)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: score)
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthenticationManager())
}
