//
//  VideoViewModel.swift
//  Internet Archive
//
//  ViewModel for video collections with testable business logic
//

import Foundation

// Note: Uses CollectionServiceProtocol defined in CollectionViewModel.swift

/// ViewModel for the video screen - a `MediaCollectionViewModel` configured
/// for movie collections (see `MediaCollectionConfiguration.video`).
@MainActor
final class VideoViewModel: MediaCollectionViewModel {

    init(collectionService: CollectionServiceProtocol) {
        super.init(collectionService: collectionService, configuration: .video)
    }

    /// Initialize with a specific collection
    convenience init(collectionService: CollectionServiceProtocol, collection: String) {
        self.init(collectionService: collectionService)
        setCollection(collection)
    }
}
