//
//  LoginView.swift
//  Birirkimtakip
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showingRegister = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header

                VStack(spacing: 12) {
                    TextField("E-posta", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    SecureField("Şifre", text: $viewModel.password)
                        .textContentType(.oneTimeCode)   // AutoFill'i kapat
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focus, equals: .password)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text("Giriş Yap").bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.canSubmitLogin)

                HStack(spacing: 4) {
                    Text("Hesabın yok mu?")
                        .foregroundStyle(.secondary)
                    Button("Kayıt ol") { showingRegister = true }
                }
                .font(.subheadline)

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .padding(.top, 32)

            Text("Birikim Takip")
                .font(.largeTitle.bold())

            Text("Nereye yatırsam daha iyi?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    LoginView()
}
