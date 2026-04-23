import SwiftUI
import SwiftData

struct BenefactorFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let merchantDomain: String?

    @State private var domain: String = ""
    @State private var creatorName: String = ""
    @State private var code: String = ""
    @State private var codeType: CodeType = .affiliate
    @State private var notes: String = ""
    @State private var existingBenefactor: Benefactor?

    private var isEditing: Bool { existingBenefactor != nil }
    private var canSave: Bool { !domain.isEmpty && !creatorName.isEmpty && !code.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // Merchant section
                Section {
                    if merchantDomain != nil {
                        HStack {
                            Text("Store")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(MerchantResolver.displayName(for: domain))
                                .foregroundStyle(.primary)
                        }
                    } else {
                        TextField("Store domain (e.g. amazon.com)", text: $domain)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                } header: {
                    Text("Merchant")
                }

                // Creator section
                Section {
                    TextField("Creator Name", text: $creatorName)
                        .textContentType(.name)

                    TextField("Code", text: $code)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)

                    Picker("Code Type", selection: $codeType) {
                        ForEach(CodeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Benefactor")
                } footer: {
                    Text("Find codes in creator's video descriptions, social bios, or podcast show notes.")
                        .font(AppTypography.footnote)
                }

                // Delete button for editing
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let benefactor = existingBenefactor {
                                modelContext.delete(benefactor)
                                try? modelContext.save()
                            }
                            dismiss()
                        } label: {
                            Text("Remove Benefactor")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Benefactor" : "Add Benefactor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        if let merchantDomain {
            domain = merchantDomain

            // Check for existing benefactor
            let fetchDomain = merchantDomain
            let descriptor = FetchDescriptor<Benefactor>(
                predicate: #Predicate { $0.merchantDomain == fetchDomain && $0.isActive }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existingBenefactor = existing
                creatorName = existing.creatorName
                code = existing.code
                codeType = existing.codeType
                notes = existing.notes ?? ""
            }
        }
    }

    private func save() {
        if let existing = existingBenefactor {
            existing.creatorName = creatorName
            existing.code = code
            existing.codeType = codeType
            existing.notes = notes.isEmpty ? nil : notes
            existing.updatedAt = Date()
        } else {
            let benefactor = Benefactor(
                merchantDomain: domain,
                creatorName: creatorName,
                code: code,
                codeType: codeType
            )
            benefactor.merchantDisplayName = MerchantResolver.displayName(for: domain)
            benefactor.notes = notes.isEmpty ? nil : notes
            modelContext.insert(benefactor)
        }

        try? modelContext.save()
        dismiss()
    }
}

extension CodeType {
    var displayName: String {
        switch self {
        case .affiliate: "Affiliate"
        case .referral: "Referral"
        case .coupon: "Coupon"
        case .creatorCode: "Creator Code"
        }
    }
}
