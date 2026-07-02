//
//  MusicViewModel.swift
//  Internet Archive
//
//  ViewModel for music collections with testable business logic
//

import Foundation

// Note: Uses CollectionServiceProtocol defined in CollectionViewModel.swift

/// ViewModel for the music screen - a `MediaCollectionViewModel` configured
/// for live music collections, including fetching the collection's display
/// title from metadata (see `MediaCollectionConfiguration.music`).
@MainActor
final class MusicViewModel: MediaCollectionViewModel {

    init(collectionService: CollectionServiceProtocol) {
        super.init(collectionService: collectionService, configuration: .music)
    }

    /// Initialize with a specific collection
    convenience init(collectionService: CollectionServiceProtocol, collection: String) {
        self.init(collectionService: collectionService)
        setCollection(collection)
    }
}
