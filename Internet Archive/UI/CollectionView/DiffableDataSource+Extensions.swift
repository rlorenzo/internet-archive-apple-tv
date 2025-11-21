//
//  DiffableDataSource+Extensions.swift
//  Internet Archive
//
//
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit

// MARK: - Section Definition

/// Sections for collection view organization
enum CollectionSection: Int, Hashable, CaseIterable {
    case main
    case videos
    case music
    case people

    var title: String {
        switch self {
        case .main: return "All Items"
        case .videos: return "Videos"
        case .music: return "Music"
        case .people: return "People"
        }
    }
}

// MARK: - Item View Model

/// Wrapper for SearchResult to make it work with DiffableDataSource
/// Hashable requirement for NSDiffableDataSourceSnapshot
struct ItemViewModel: Hashable, Sendable {
    let item: SearchResult
    let section: CollectionSection

    init(item: SearchResult, section: CollectionSection = .main) {
        self.item = item
        self.section = section
    }

    // Hashable conformance
    static func == (lhs: ItemViewModel, rhs: ItemViewModel) -> Bool {
        lhs.item.identifier == rhs.item.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(item.identifier)
    }
}

// MARK: - Diffable Data Source Extensions

extension UICollectionViewDiffableDataSource {

    /// Apply items to a section with animation
    /// - Parameters:
    ///   - items: Items to display
    ///   - section: Section to update
    ///   - animatingDifferences: Whether to animate changes
    @MainActor
    func applyItems(
        _ items: [ItemIdentifierType],
        to section: SectionIdentifierType,
        animatingDifferences: Bool = true
    ) async {
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        await apply(snapshot, animatingDifferences: animatingDifferences)
    }

    /// Update specific items in place
    /// - Parameters:
    ///   - items: Items to update
    @MainActor
    func reloadItems(
        _ items: [ItemIdentifierType]
    ) async {
        var snapshot = self.snapshot()
        snapshot.reloadItems(items)
        await apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Snapshot Extensions

extension NSDiffableDataSourceSnapshot {

    /// Check if snapshot is empty
    var isEmpty: Bool {
        numberOfItems == 0
    }

    /// Get all items across all sections
    var allItems: [ItemIdentifierType] {
        sectionIdentifiers.flatMap { itemIdentifiers(inSection: $0) }
    }
}

// MARK: - Type Aliases

typealias ItemDataSource = UICollectionViewDiffableDataSource<CollectionSection, ItemViewModel>
typealias ItemSnapshot = NSDiffableDataSourceSnapshot<CollectionSection, ItemViewModel>
