//
//  FavoritesViewTests.swift
//  Internet ArchiveTests
//
//  Tests for FavoritesView-specific types
//  Note: FavoriteItem, FavoritesResponse, and FavoritesViewState tests are in
//  FavoritesModelsTests.swift and FavoritesViewModelTests.swift
//

import XCTest
@testable import Internet_Archive

// MARK: - PersonNavigation Tests

/// Tests for PersonNavigation type used in favorites people navigation
final class PersonNavigationTests: XCTestCase {

    func testPersonNavigation_hasUniqueId() {
        // PersonNavigation uses UUID for unique identity
        let nav1 = PersonNavigation(identifier: "user1", name: "User One")
        let nav2 = PersonNavigation(identifier: "user1", name: "User One")

        // Each instance has a unique UUID id
        XCTAssertNotEqual(nav1.id, nav2.id)
    }

    func testPersonNavigation_sameInstance_isEqual() {
        let nav = PersonNavigation(identifier: "user1", name: "User One")

        // Same instance should equal itself
        XCTAssertEqual(nav, nav)
    }

    func testPersonNavigation_canBeUsedInSet() {
        let nav = PersonNavigation(identifier: "user1", name: "User One")

        var set: Set<PersonNavigation> = []
        set.insert(nav)

        XCTAssertEqual(set.count, 1)
        XCTAssertTrue(set.contains(nav))
    }

    func testPersonNavigation_accessesProperties() {
        let nav = PersonNavigation(identifier: "user123", name: "Test User")

        XCTAssertEqual(nav.identifier, "user123")
        XCTAssertEqual(nav.name, "Test User")
    }

    func testPersonNavigation_isIdentifiable() {
        let nav = PersonNavigation(identifier: "user1", name: "User One")

        // Should have an id property (UUID)
        XCTAssertNotNil(nav.id)
    }

    func testPersonNavigation_differentInstances_notEqual() {
        let nav1 = PersonNavigation(identifier: "user1", name: "User One")
        let nav2 = PersonNavigation(identifier: "user1", name: "User One")

        // Different instances with same data are not equal (UUID-based)
        XCTAssertNotEqual(nav1, nav2)
    }
}
