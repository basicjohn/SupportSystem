import SwiftUI
import SwiftData

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(spacing: AppSpacing.sm) {
                    Text("Export Your Data")
                        .font(.system(size: 18, weight: .bold))

                    Text("Save all your links and benefactor codes as a JSON file you can back up or transfer.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.appRed)
                }

                Spacer()

                Button {
                    exportData()
                } label: {
                    Text("Export Data")
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
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportData() {
        do {
            let data = try DataExporter.exportAll(modelContext: modelContext)
            let url = try DataExporter.exportURL(data: data)
            exportURL = url
            showingShareSheet = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
