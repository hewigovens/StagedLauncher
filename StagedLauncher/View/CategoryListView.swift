import SwiftUI

struct CategoryListView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        List(selection: $viewModel.selectedCategory) {
            Section("Categories") {
                ForEach(viewModel.categories, id: \.self) { category in
                    Label(
                        viewModel.formatCategoryName(category),
                        systemImage: viewModel.symbolName(forCategory: category)
                    )
                    .badge(viewModel.appCount(in: category))
                    .tag(category as String?)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 280)
    }
}
