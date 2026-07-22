//
//  PrimaryButton.swift
//  Birirkimtakip
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.tint)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
