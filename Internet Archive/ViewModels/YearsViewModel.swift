//
//  YearsViewModel.swift
//  Internet Archive
//
//  ViewModel for years/dates grouped collection view with testable business logic
//

import Foundation

/// ViewModel state for years view
struct YearsViewState: Sendable {
    var isLoading: Bool = false
    var name: String = ""
    var identifier: String = ""
    var collection: String = ""
    var sortedData: [String: [SearchResult]] = [:]
    var sortedKeys: [String] = []
    var selectedYearIndex: Int = 0
    var errorMessage: String?

    static let initial = YearsViewState()

    /// Check if there are years to display
    var hasYears: Bool {
        !sortedKeys.isEmpty
    }

    /// Get count of years
    var yearsCount: Int {
        sortedKeys.count
    }

    /// Get the currently selected year
    var selectedYear: String? {
        guard selectedYearIndex >= 0 && selectedYearIndex < sortedKeys.count else { return nil }
        return sortedKeys[selectedYearIndex]
    }

    /// Get items for the currently selected year
    var selectedYearItems: [SearchResult] {
        guard let year = selectedYear, let items = sortedData[year] else { return [] }
        return items
    }

    /// Get count of items in selected year
    var selectedYearItemCount: Int {
        selectedYearItems.count
    }
}

/// ViewModel for years screen - handles all business logic
@MainActor
final class YearsViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = YearsViewState.initial

    // MARK: - Dependencies

    private let collectionService: CollectionServiceProtocol

    // MARK: - Initialization

    init(collectionService: CollectionServiceProtocol) {
        self.collectionService = collectionService
    }

    // MARK: - Public Methods

    /// Configure the view model with item data
    func configure(name: String, identifier: String, collection: String) {
        state.name = name
        state.identifier = identifier
        state.collection = collection
    }

    /// Load years data
    func loadYearsData() async {
        guard !state.identifier.isEmpty else {
            state.errorMessage = "Missing collection information"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let (_, results) = try await RetryMechanism.execute(config: .standard) {
                try await self.collectionService.getCollections(
                    collection: self.state.identifier,
                    resultType: self.state.collection,
                    limit: 5000
                )
            }

            // Group items by year
            let grouped = groupByYear(results)
            state.sortedData = grouped

            // Sort keys (years) in descending order
            state.sortedKeys = grouped.keys.sorted { year1, year2 in
                year1 > year2
            }

            state.selectedYearIndex = 0
            state.isLoading = false

            ErrorLogger.shared.logSuccess(
                operation: .getCollections,
                info: [
                    "identifier": state.identifier,
                    "years_count": state.sortedKeys.count,
                    "total_items": results.count
                ]
            )

        } catch {
            state.isLoading = false
            state.errorMessage = mapErrorToMessage(error)

            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getCollections,
                    additionalInfo: ["identifier": state.identifier]
                )
            )
        }
    }

    /// Group items by year
    func groupByYear(_ items: [SearchResult]) -> [String: [SearchResult]] {
        var grouped: [String: [SearchResult]] = [:]

        for item in items {
            let year = item.year ?? "Undated"

            if var yearItems = grouped[year] {
                yearItems.append(item)
                grouped[year] = yearItems
            } else {
                grouped[year] = [item]
            }
        }

        return grouped
    }

    /// Select a year by index
    func selectYear(at index: Int) {
        guard index >= 0 && index < state.sortedKeys.count else { return }
        state.selectedYearIndex = index
    }

    /// Get year at index
    func year(at index: Int) -> String? {
        guard index >= 0 && index < state.sortedKeys.count else { return nil }
        return state.sortedKeys[index]
    }

    /// Get items for year at index
    func items(forYearAt index: Int) -> [SearchResult] {
        guard let year = year(at: index), let items = state.sortedData[year] else {
            return []
        }
        return items
    }

    /// Get item from selected year at index
    func item(at index: Int) -> SearchResult? {
        let items = state.selectedYearItems
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }

    /// Build navigation data for item at index
    func buildItemNavigationData(at index: Int) -> ItemNavigationData? {
        guard let item = item(at: index) else { return nil }

        return ItemNavigationData(
            identifier: item.identifier,
            title: item.title ?? "",
            archivedBy: item.creator ?? "",
            date: Global.formatDate(string: item.date) ?? "",
            description: item.description ?? "",
            mediaType: item.mediatype ?? "",
            imageURL: URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")
        )
    }

    /// Clear error message
    func clearError() {
        state.errorMessage = nil
    }

    // MARK: - Private Methods

    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Item Navigation Data

/// Data needed to navigate to item detail
struct ItemNavigationData: Equatable {
    let identifier: String
    let title: String
    let archivedBy: String
    let date: String
    let description: String
    let mediaType: String
    let imageURL: URL?
}
