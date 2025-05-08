import LSAppCategory
import SwiftUI

struct CategoryListView: View {
    // Observe the ViewModel passed from ContentView
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        // --- Sidebar: Category List ---
        List {
            ForEach(viewModel.categories, id: \.self) { category in
                // Wrap in HStack and add Spacer to fill width
                HStack {
                    Text(emojiForCategory(category)) // Add emoji
                    Text(viewModel.formatCategoryName(category))
                    Spacer() // Make HStack fill the row width
                }
                // Define the tappable area explicitly
                .contentShape(Rectangle())
                // Add background for selection indication
                .listRowBackground(viewModel.selectedCategory == category ? Color.accentColor : nil)
                .tag(category as String?)
                // Handle selection manually and defer update
                .onTapGesture {
                    DispatchQueue.main.async {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
        .navigationTitle("Categories")
        // Add translucent background material
        .background(.ultraThinMaterial)
    }

    // Helper function to get an emoji for a category
    private func emojiForCategory(_ category: String) -> String {
        if category == Constants.categoryAllApps {
            return "🌐"
        }
        return AppCategory(string: category).emoji
    }
}
