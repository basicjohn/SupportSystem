import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(spacing: AppSpacing.sm) {
                    Text("Import Data")
                        .font(.system(size: 18, weight: .bold))

                    Text("Restore links and benefactor codes from a previously exported JSON file.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                if let result = importResult {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Import Complete")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.appGreen)

                        Text("\(result.linksImported) links imported, \(result.linksSkipped) skipped")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)

                        Text("\(result.benefactorsImported) benefactors imported, \(result.benefactorsSkipped) skipped")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(AppSpacing.lg)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.appRed)
                }

                Spacer()

                Button {
                    showingFilePicker = true
                } label: {
                    Text("Choose File")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(Color.appBrand)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .padding(.horizontal, AppSpacing.xl)
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(importResult != nil ? "Done" : "Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Could not access the file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)
            importResult = try DataImporter.importData(from: data, modelContext: modelContext)
            errorMessage = nil
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}
