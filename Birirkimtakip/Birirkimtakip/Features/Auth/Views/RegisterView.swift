//
//  RegisterView.swift
//  Birirkimtakip
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Yeni Hesap")
                .font(.title.bold())
                .padding(.top, 8)

            VStack(spacing: 12) {
                TextField("E-posta", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                SecureField("Şifre (en az 6 karakter)", text: $viewModel.password)
                    .textContentType(.oneTimeCode)   // AutoFill'i devre dışı bırakır
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                SecureField("Şifre (tekrar)", text: $viewModel.passwordConfirm)
                    .textContentType(.oneTimeCode)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
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
                Task {
                    await viewModel.register()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text("Kayıt Ol").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.tint)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canSubmitRegister)

            Spacer()
        }
        .padding()
        .navigationTitle("Kayıt")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { RegisterView() }
}
