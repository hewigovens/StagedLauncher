import LSAppCategory
import SwiftUI

struct CategoryListView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar)
                .ignoresSafeArea()
            List(selection: $viewModel.selectedCategory) {
                ForEach(viewModel.categories, id: \.self) { category in
                    HStack {
                        Text(emojiForCategory(category))
                        Text(viewModel.formatCategoryName(category))
                        Spacer()
                    }
                    .tag(category as String?)
                }
            }
            .listStyle(.sidebar)
            .background(.clear)
        }
        .navigationTitle("Categories")
    }

    private func emojiForCategory(_ category: String) -> String {
        if category == Constants.categoryAllApps {
            return "🌐"
        }
        return AppCategory(string: category).emoji
    }
}
