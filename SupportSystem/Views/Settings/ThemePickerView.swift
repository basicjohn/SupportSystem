import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let currentTheme: AppTheme
    var onSelect: (AppTheme) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        onSelect(theme)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: theme.iconName)
                                .frame(width: 24)
                                .foregroundStyle(.primary)

                            Text(theme.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if theme == currentTheme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.appBlue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension AppTheme {
    var iconName: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}
