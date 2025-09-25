import SwiftUI

/// View for setting search filters and sorting options
struct FilterView: View {
    @Binding var filter: RestaurantFilter
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilter: RestaurantFilter
    
    init(filter: Binding<RestaurantFilter>, onApply: @escaping () -> Void) {
        self._filter = filter
        self.onApply = onApply
        self._tempFilter = State(initialValue: filter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Price Range Section
                priceRangeSection
                
                // Rating Section
                ratingSection
                
                // Distance Section
                distanceSection
                
                // Categories Section
                categoriesSection
                
                // Open Now Section
                openNowSection
                
                // Sort Section
                sortSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Price Range Section
    
    private var priceRangeSection: some View {
        Section("Price Range") {
            Picker("Price Range", selection: $tempFilter.priceRange) {
                ForEach(PriceRange.allCases, id: \.self) { range in
                    HStack {
                        Text(range.displayName)
                        Spacer()
                        Text(range.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(range)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        Section("Minimum Rating") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(String(format: "%.1f", tempFilter.minRating)) stars")
                        .font(.headline)
                    Spacer()
                    Text("Any rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $tempFilter.minRating,
                    in: 0...5,
                    step: 0.1
                )
                .accentColor(.orange)
                
                HStack {
                    Text("0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("5.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Distance Section
    
    private var distanceSection: some View {
        Section("Maximum Distance") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(String(format: "%.1f", tempFilter.maxDistance)) miles")
                        .font(.headline)
                    Spacer()
                    Text("25 miles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $tempFilter.maxDistance,
                    in: 0.1...25,
                    step: 0.1
                )
                .accentColor(.orange)
                
                HStack {
                    Text("0.1 mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("25 mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        Section("Categories") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(restaurantCategories, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: tempFilter.categories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
    }
    
    // MARK: - Open Now Section
    
    private var openNowSection: some View {
        Section("Availability") {
            Toggle("Open Now", isOn: $tempFilter.openNow)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
    }
    
    // MARK: - Sort Section
    
    private var sortSection: some View {
        Section("Sort By") {
            Picker("Sort By", selection: $tempFilter.sortBy) {
                ForEach(SearchParameters.SortOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Private Methods
    
    private func resetFilters() {
        tempFilter = RestaurantFilter()
    }
    
    private func applyFilters() {
        filter = tempFilter
        onApply()
        dismiss()
    }
    
    private func toggleCategory(_ category: String) {
        if tempFilter.categories.contains(category) {
            tempFilter.categories.remove(category)
        } else {
            tempFilter.categories.insert(category)
        }
    }
    
    // MARK: - Restaurant Categories
    
    private let restaurantCategories = [
        "Italian",
        "Pizza",
        "Chinese",
        "Japanese",
        "Mexican",
        "Thai",
        "Indian",
        "American",
        "French",
        "Mediterranean",
        "Korean",
        "Vietnamese",
        "Seafood",
        "Steakhouse",
        "Fast Food",
        "Cafe",
        "Bakery",
        "Dessert",
        "Bar",
        "Brewery"
    ]
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Filter View

/// A compact view for quick filter access
struct QuickFilterView: View {
    @Binding var filter: RestaurantFilter
    let onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Price range quick select
            HStack {
                Text("Price:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(PriceRange.allCases, id: \.self) { range in
                        Button(range.displayName) {
                            filter.priceRange = range
                            onApply()
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(filter.priceRange == range ? Color.orange : Color(.systemGray5))
                        .foregroundColor(filter.priceRange == range ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Sort options
            HStack {
                Text("Sort:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Picker("Sort", selection: $filter.sortBy) {
                    ForEach(SearchParameters.SortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: filter.sortBy) { _ in
                    onApply()
                }
            }
            
            // Open now toggle
            HStack {
                Text("Open Now:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $filter.openNow)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    .onChange(of: filter.openNow) { _ in
                        onApply()
                    }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Summary View

/// A view showing current filter settings
struct FilterSummaryView: View {
    let filter: RestaurantFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Filters")
                .font(.headline)
            
            if hasActiveFilters {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    if filter.priceRange != .all {
                        FilterChip(
                            title: "Price: \(filter.priceRange.displayName)",
                            isSelected: true,
                            onTap: {}
                        )
                    }
                    
                    if filter.minRating > 0 {
                        FilterChip(
                            title: "Rating: \(String(format: "%.1f+", filter.minRating))",
                            isSelected: true,
                            onTap: {}
                        )
                    }
                    
                    if filter.maxDistance < 25 {
                        FilterChip(
                            title: "Distance: \(String(format: "%.1f mi", filter.maxDistance))",
                            isSelected: true,
                            onTap: {}
                        )
                    }
                    
                    if filter.openNow {
                        FilterChip(
                            title: "Open Now",
                            isSelected: true,
                            onTap: {}
                        )
                    }
                    
                    if !filter.categories.isEmpty {
                        FilterChip(
                            title: "\(filter.categories.count) categories",
                            isSelected: true,
                            onTap: {}
                        )
                    }
                }
            } else {
                Text("No filters applied")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var hasActiveFilters: Bool {
        return filter.priceRange != .all ||
               filter.minRating > 0 ||
               filter.maxDistance < 25 ||
               filter.openNow ||
               !filter.categories.isEmpty
    }
}

// MARK: - Preview

#Preview {
    FilterView(filter: .constant(RestaurantFilter())) {
        print("Apply filters")
    }
}

#Preview("Quick Filter") {
    QuickFilterView(filter: .constant(RestaurantFilter())) {
        print("Apply quick filter")
    }
    .padding()
}

#Preview("Filter Summary") {
    FilterSummaryView(filter: RestaurantFilter())
        .padding()
}
