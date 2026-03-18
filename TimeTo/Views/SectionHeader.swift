import SwiftUI

struct SectionHeader: View {
    let title: String
    let onAdd: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                onAdd()
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }
}
