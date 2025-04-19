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
        switch category {
        case Constants.categoryAllApps:
            return "🌐"
        case "public.app-category.developer-tools":
            return "🛠️"
        case "public.app-category.productivity":
            return "📊"
        case "public.app-category.utilities":
            return "🔧"
        case "public.app-category.games":
            return "🎮"
        case "public.app-category.graphics-design":
            return "🎨"
        case "public.app-category.social-networking":
            return "💬"
        case "public.app-category.entertainment":
            return "🎬"
        case "public.app-category.music":
             return "🎵"
        case "public.app-category.photography":
             return "📸"
        case "public.app-category.education":
             return "🎓"
        case "public.app-category.finance":
             return "💰"
        case "public.app-category.health-fitness":
             return "💪"
        case "public.app-category.lifestyle":
             return "🛋️"
        case "public.app-category.medical":
             return "⚕️"
        case "public.app-category.reference":
             return "📖"
        case "public.app-category.travel":
             return "✈️"
        case "public.app-category.weather":
             return "☀️"
        case "Other":
            return "📁"
        default:
            // Check if it's a UTI format and try to extract a general type
            if category.starts(with: "public.app-category.") {
                return "📄" // Generic document/app icon
            }
            return "❓" // Unknown category
        }
    }
}

#Preview {
    let previewAppStore = AppStore()
    // Add some dummy data to previewAppStore to generate categories
    previewAppStore.managedApps = [
        ManagedApp.new(name: "DevToolApp", bundleIdentifier: "com.example.devtool", bookmark: nil, category: "public.app-category.developer-tools"),
        ManagedApp.new(name: "ProdApp", bundleIdentifier: "com.example.prodapp", bookmark: nil, category: "public.app-category.productivity"),
        ManagedApp.new(name: "OtherApp", bundleIdentifier: "com.example.otherapp", bookmark: nil, category: "Other"),
        ManagedApp.new(name: "AnotherDevApp", bundleIdentifier: "com.example.anotherdev", bookmark: nil, category: "public.app-category.developer-tools")
    ]

    let previewViewModel = ContentViewModel(appStore: previewAppStore)

    // Set the initial selected category for preview
    previewViewModel.selectedCategory = Constants.categoryAllApps

    return CategoryListView(viewModel: previewViewModel)
}
