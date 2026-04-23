import SwiftUI
import SwiftData

struct SettingsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Preferences
                Section("Preferences") {
                    Button {
                        viewModel.showingThemePicker = true
                    } label: {
                        HStack {
                            Text("Theme")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(viewModel.currentTheme.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.quaternary)
                        }
                    }
                }

                // Data
                Section("Data") {
                    Button {
                        viewModel.showingExport = true
                    } label: {
                        Text("Export Data")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        viewModel.showingImport = true
                    } label: {
                        Text("Import Data")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        viewModel.showingClearConfirmation = true
                    } label: {
                        Text("Clear All Data")
                            .foregroundStyle(Color.appRed)
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    // Privacy Policy placeholder
                    Button {
                        // TODO: Open privacy policy URL
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.quaternary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadTheme(modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.showingThemePicker) {
                ThemePickerView(
                    currentTheme: viewModel.currentTheme,
                    onSelect: { theme in
                        viewModel.setTheme(theme, modelContext: modelContext)
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.showingExport) {
                ExportDataView()
            }
            .sheet(isPresented: $viewModel.showingImport) {
                ImportDataView()
            }
            .alert("Clear All Data", isPresented: $viewModel.showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Everything", role: .destructive) {
                    viewModel.clearAllData(modelContext: modelContext)
                }
            } message: {
                Text("This will permanently delete all your saved links and benefactor codes. This action cannot be undone.")
            }
        }
    }
}

extension AppTheme {
    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
