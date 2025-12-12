//
//  CompositionalLayoutBuilder.swift
//  Internet Archive
//
//
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit

/// Builder for creating modern UICollectionViewCompositionalLayouts
@MainActor
struct CompositionalLayoutBuilder {

    // MARK: - Layout Types

    /// Creates a grid layout with specified columns
    /// - Parameters:
    ///   - columns: Number of columns
    ///   - spacing: Spacing between items
    ///   - aspectRatio: Item aspect ratio (width/height)
    /// - Returns: Configured compositional layout
    static func createGridLayout(
        columns: Int = 5,
        spacing: CGFloat = 40,
        aspectRatio: CGFloat = 0.75
    ) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(
                top: spacing / 2,
                leading: spacing / 2,
                bottom: spacing / 2,
                trailing: spacing / 2
            )

            // Group
            let groupHeight = environment.container.contentSize.width / CGFloat(columns) / aspectRatio
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(groupHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: spacing,
                leading: spacing,
                bottom: spacing,
                trailing: spacing
            )

            return section
        }

        return layout
    }

    /// Creates a list layout for years or categories
    /// - Parameters:
    ///   - itemHeight: Height of each item
    ///   - spacing: Spacing between items
    /// - Returns: Configured compositional layout
    static func createListLayout(
        itemHeight: CGFloat = 80,
        spacing: CGFloat = 20
    ) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: spacing,
                leading: spacing,
                bottom: spacing,
                trailing: spacing
            )

            return section
        }

        return layout
    }

    /// Creates a horizontal scrolling layout
    /// - Parameters:
    ///   - itemWidth: Width of each item
    ///   - itemHeight: Height of each item
    ///   - spacing: Spacing between items
    /// - Returns: Configured compositional layout
    static func createHorizontalLayout(
        itemWidth: CGFloat = 400,
        itemHeight: CGFloat = 300,
        spacing: CGFloat = 40
    ) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: spacing,
                leading: spacing,
                bottom: spacing,
                trailing: spacing
            )

            return section
        }

        return layout
    }

    /// Creates a multi-section layout with different configurations per section
    /// - Parameter sectionProvider: Closure that provides section configuration
    /// - Returns: Configured compositional layout
    static func createMultiSectionLayout(
        sectionProvider: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?
    ) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            sectionProvider(sectionIndex, environment)
        }

        return layout
    }
}

// MARK: - Common Configurations

extension CompositionalLayoutBuilder {

    /// Standard grid for video and music collections (5 columns)
    static var standardGrid: UICollectionViewLayout {
        createGridLayout(columns: 5, spacing: 40, aspectRatio: 0.75)
    }

    /// Compact grid for search results (6 columns)
    static var compactGrid: UICollectionViewLayout {
        createGridLayout(columns: 6, spacing: 30, aspectRatio: 0.75)
    }

    /// Large item grid for featured content (4 columns)
    static var largeItemGrid: UICollectionViewLayout {
        createGridLayout(columns: 4, spacing: 50, aspectRatio: 0.67)
    }

    /// List layout for years or categories
    static var listLayout: UICollectionViewLayout {
        createListLayout(itemHeight: 80, spacing: 20)
    }
}

// MARK: - Continue Watching Layouts

extension CompositionalLayoutBuilder {

    /// Creates a horizontal scrolling section for Continue Watching/Listening
    /// - Parameter environment: Layout environment
    /// - Returns: Configured section for horizontal scrolling
    static func createContinueWatchingSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // Item size - larger for featured appearance
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(400),
            heightDimension: .absolute(320)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Group - horizontal, single item
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(400),
            heightDimension: .absolute(320)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        // Section - horizontal scrolling
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 40
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 20,
            leading: 60,
            bottom: 40,
            trailing: 60
        )

        // Add section header
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(60)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    /// Creates a standard grid section for main content
    /// - Parameter environment: Layout environment
    /// - Returns: Configured section for grid display
    static func createMainGridSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let columns = 5
        let spacing: CGFloat = 40

        // Item
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: spacing / 2,
            leading: spacing / 2,
            bottom: spacing / 2,
            trailing: spacing / 2
        )

        // Group
        let groupHeight = environment.container.contentSize.width / CGFloat(columns) / 0.75
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(groupHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: spacing,
            leading: spacing,
            bottom: spacing,
            trailing: spacing
        )

        return section
    }

    /// Creates a layout for VideoVC with optional Continue Watching section at top
    /// - Parameter hasContinueWatching: Whether to include Continue Watching section
    /// - Returns: Configured compositional layout
    static func createVideoHomeLayout(hasContinueWatching: Bool) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            if hasContinueWatching {
                if sectionIndex == 0 {
                    return createContinueWatchingSection(environment: environment)
                } else {
                    return createMainGridSection(environment: environment)
                }
            } else {
                return createMainGridSection(environment: environment)
            }
        }

        return layout
    }

    /// Creates a layout for MusicVC with optional Continue Listening section at top
    /// - Parameter hasContinueListening: Whether to include Continue Listening section
    /// - Returns: Configured compositional layout
    static func createMusicHomeLayout(hasContinueListening: Bool) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            if hasContinueListening {
                if sectionIndex == 0 {
                    return createContinueWatchingSection(environment: environment)
                } else {
                    return createMainGridSection(environment: environment)
                }
            } else {
                return createMainGridSection(environment: environment)
            }
        }

        return layout
    }
}
