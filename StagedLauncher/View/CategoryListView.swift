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
    previewViewModel.selectedCategory = "All"
    
    return CategoryListView(viewModel: previewViewModel)
}
