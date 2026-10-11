import SwiftUI

/// Example of `@Binding`: the component does NOT own the value — it reads and writes
/// someone else's state (here `viewModel.sort`). That makes it reusable with any source.
struct SortMenu: View {
    @Binding var selection: ProductSort

    var body: some View {
        Menu {
            Picker("Sort by", selection: $selection) {
                ForEach(ProductSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}

extension ProductSort {
    var title: LocalizedStringKey {
        switch self {
        case .relevance: "Relevance"
        case .priceLowToHigh: "Price: Low to High"
        case .priceHighToLow: "Price: High to Low"
        case .rating: "Top Rated"
        }
    }
}

#Preview {
    @Previewable @State var sort = ProductSort.relevance
    SortMenu(selection: $sort)
}
