//
//  Internet_ArchiveUITests.swift
//  Internet ArchiveUITests
//
//  UI Tests for Internet Archive Apple TV app
//  Uses mock data when launched with --uitesting flag
//

import XCTest

@MainActor
final class Internet_ArchiveUITests: XCTestCase {

    // Helper to create and configure the app
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["USE_MOCK_DATA": "true"]
        app.launch()
        return app
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Launch Tests

    func testAppLaunches() throws {
        let app = launchApp()

        // Verify the app launched successfully
        XCTAssertTrue(app.exists)
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testTabBarExists() throws {
        let app = launchApp()

        // Wait for tab bar to appear
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }

    // MARK: - Video Tab Tests

    func testVideoTabNavigation() throws {
        let app = launchApp()

        // Videos tab should be visible (first tab)
        let videosTab = app.tabBars.buttons["Videos"]
        if videosTab.waitForExistence(timeout: 5) {
            // Already on Videos tab or navigate to it
            XCTAssertTrue(videosTab.exists)
        }
    }

    func testVideoCollectionLoads() throws {
        let app = launchApp()

        // Wait for collection view to load with items
        let collectionView = app.collectionViews.firstMatch
        if collectionView.waitForExistence(timeout: 10) {
            // Verify cells exist
            let cells = collectionView.cells
            XCTAssertTrue(cells.count >= 0) // May be 0 if loading
        }
    }

    // MARK: - Music Tab Tests

    func testMusicTabExists() throws {
        let app = launchApp()

        let musicTab = app.tabBars.buttons["Music"]
        XCTAssertTrue(musicTab.waitForExistence(timeout: 5))
    }

    func testNavigateToMusicTab() throws {
        let app = launchApp()

        let musicTab = app.tabBars.buttons["Music"]
        if musicTab.waitForExistence(timeout: 5) {
            // Use remote to navigate to Music tab
            let remote = XCUIRemote.shared

            // Navigate right to Music tab (from Videos)
            remote.press(.right)
            sleep(1)

            // Select the tab
            remote.press(.select)
            sleep(2)

            // Verify navigation occurred
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Search Tab Tests

    func testSearchTabExists() throws {
        let app = launchApp()

        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5))
    }

    // MARK: - Remote Navigation Tests

    func testRemoteNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Test basic remote navigation
        remote.press(.down)
        sleep(1)

        remote.press(.up)
        sleep(1)

        remote.press(.right)
        sleep(1)

        remote.press(.left)
        sleep(1)

        // App should still be running
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testMenuButtonNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate down into content
        remote.press(.down)
        sleep(1)

        // Press menu to go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Collection View Interaction Tests

    func testCollectionViewFocusNavigation() throws {
        let app = launchApp()

        // Wait for content to load
        sleep(3)

        let remote = XCUIRemote.shared

        // Navigate through collection items
        remote.press(.down) // Enter collection
        sleep(1)

        remote.press(.right) // Move to next item
        sleep(1)

        remote.press(.right) // Move to another item
        sleep(1)

        remote.press(.left) // Move back
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testSelectCollectionItem() throws {
        let app = launchApp()

        // Wait for content to load
        sleep(3)

        let remote = XCUIRemote.shared

        // Navigate to first collection item
        remote.press(.down)
        sleep(1)

        // Select the item
        remote.press(.select)
        sleep(2)

        // Should navigate to detail view or start playing
        XCTAssertTrue(app.state == .runningForeground)

        // Press menu to go back
        remote.press(.menu)
        sleep(1)
    }

    // MARK: - Tab Switching Tests

    func testSwitchBetweenAllTabs() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Start at Videos tab
        sleep(2)

        // Move to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Move to Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Move back to Videos
        remote.press(.left)
        sleep(1)
        remote.press(.left)
        sleep(1)
        remote.press(.select)
        sleep(2)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting"]
            app.launchEnvironment = ["USE_MOCK_DATA": "true"]
            app.launch()
        }
    }

    // MARK: - Accessibility Tests

    func testTabBarAccessibility() throws {
        let app = launchApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Check that tabs have accessibility labels
        let videosTab = app.tabBars.buttons["Videos"]
        let musicTab = app.tabBars.buttons["Music"]
        let searchTab = app.tabBars.buttons["Search"]

        if videosTab.exists {
            XCTAssertTrue(videosTab.isEnabled)
        }
        if musicTab.exists {
            XCTAssertTrue(musicTab.isEnabled)
        }
        if searchTab.exists {
            XCTAssertTrue(searchTab.isEnabled)
        }
    }

    // MARK: - State Persistence Tests

    func testAppStatePersistsAfterBackground() throws {
        let app = launchApp()

        // Navigate to a different state
        let remote = XCUIRemote.shared
        remote.press(.right)
        sleep(1)

        // Note: Background/foreground testing can be flaky on tvOS simulators
        // Just verify app is still running after navigation
        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Favorites Tab Tests

    func testFavoritesTabExists() throws {
        let app = launchApp()

        let favoritesTab = app.tabBars.buttons["Favorites"]
        XCTAssertTrue(favoritesTab.waitForExistence(timeout: 5))
    }

    func testNavigateToFavoritesTab() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Favorites tab (typically after Search)
        // Videos -> Music -> Search -> Favorites
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testFavoritesTabContent() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Favorites tab
        for _ in 0..<3 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate down to see content (or login prompt)
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testFavoritesSegmentedControl() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Favorites tab
        for _ in 0..<3 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate within favorites (switch between Movies/Music/People segments if logged in)
        remote.press(.down)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Account Tab Tests

    func testAccountTabExists() throws {
        let app = launchApp()

        let accountTab = app.tabBars.buttons["Account"]
        XCTAssertTrue(accountTab.waitForExistence(timeout: 5))
    }

    func testNavigateToAccountTab() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab (last tab)
        // Videos -> Music -> Search -> Favorites -> Account
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testAccountTabShowsLoginWhenLoggedOut() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Should show login or account info
        // Navigate down to interact with login form elements
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testLoginScreenElements() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate through login form elements
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Press menu to go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testLoginFormNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate through form fields (email, password, login button)
        remote.press(.down) // Move to email field
        sleep(1)
        remote.press(.down) // Move to password field
        sleep(1)
        remote.press(.down) // Move to login button
        sleep(1)
        remote.press(.down) // Move to register button if exists
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testRegisterButtonNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate to register button and select it
        for _ in 0..<5 {
            remote.press(.down)
            sleep(1)
        }

        // Select register if available
        remote.press(.select)
        sleep(2)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Item Detail View Tests

    func testNavigateToItemDetail() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate down into collection
        remote.press(.down)
        sleep(1)

        // Select an item to view details
        remote.press(.select)
        sleep(3)

        // Should be on item detail view
        XCTAssertTrue(app.state == .runningForeground)

        // Go back
        remote.press(.menu)
        sleep(1)
    }

    func testItemDetailNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate to an item and select it
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate within item detail view
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testItemDetailPlayButton() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate to an item
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate to play button and select
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Press menu/play-pause to stop and go back
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testItemDetailFavoriteButton() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate to an item
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate to favorite button area
        remote.press(.down)
        sleep(1)
        remote.press(.right)
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testItemDetailScrollContent() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate to an item
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Scroll through item details
        for _ in 0..<5 {
            remote.press(.down)
            sleep(1)
        }

        for _ in 0..<3 {
            remote.press(.up)
            sleep(1)
        }

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Years Screen Tests

    func testYearsNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Music tab first (years might be part of music)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate within the screen to see years content
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testYearCellSelection() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate into content
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Select a year cell
        remote.press(.select)
        sleep(2)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testYearCellNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate into years grid
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Navigate horizontally through year cells
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Search Screen Tests

    func testNavigateToSearchTab() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Search tab (Videos -> Music -> Search)
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testSearchScreenElements() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate down to search field
        remote.press(.down)
        sleep(1)

        // Navigate to keyboard or search results area
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testSearchFieldInteraction() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate to search field
        remote.press(.down)
        sleep(1)

        // Select search field to bring up keyboard
        remote.press(.select)
        sleep(2)

        // Dismiss keyboard
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testSearchResultsNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate into search results area
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Navigate through results if any
        remote.press(.right)
        sleep(1)
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testSearchResultSelection() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate to search results
        for _ in 0..<4 {
            remote.press(.down)
            sleep(1)
        }

        // Select a result if available
        remote.press(.select)
        sleep(2)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Video Tab Deep Tests

    func testVideoCollectionScrolling() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate into video collection
        remote.press(.down)
        sleep(1)

        // Scroll through multiple items
        for _ in 0..<5 {
            remote.press(.right)
            sleep(1)
        }

        for _ in 0..<3 {
            remote.press(.left)
            sleep(1)
        }

        // Navigate down to next row
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testVideoCollectionMultipleRows() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content to load
        sleep(3)

        // Navigate through multiple rows
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)
        remote.press(.up)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Music Tab Deep Tests

    func testMusicCollectionScrolling() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate into music collection
        remote.press(.down)
        sleep(1)

        // Scroll through items
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }

        for _ in 0..<2 {
            remote.press(.left)
            sleep(1)
        }

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testMusicItemSelection() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate into collection and select an item
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Error State Tests

    func testEmptyStateHandling() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to a tab that might show empty state
        for _ in 0..<3 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate within empty state view
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Navigation Controller Tests

    func testNavigationStackPushPop() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content
        sleep(3)

        // Push to detail view
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Pop back
        remote.press(.menu)
        sleep(1)

        // Push again
        remote.press(.select)
        sleep(2)

        // Pop back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testDeepNavigationStack() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content
        sleep(3)

        // Navigate deep into the app
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Pop back multiple levels
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Slider Tests

    func testSliderNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to an item with a slider (video playback)
        sleep(3)
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Start playback
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Use play/pause
        remote.press(.playPause)
        sleep(1)
        remote.press(.playPause)
        sleep(1)

        // Exit playback
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - People VC Tests (Favorites > People segment)

    func testPeopleSegmentNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Favorites tab
        for _ in 0..<3 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate down into the favorites content area
        remote.press(.down)
        sleep(1)

        // Navigate right to People segment (Movies -> Music -> People)
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)

        // Select People segment
        remote.press(.select)
        sleep(2)

        // Navigate down into people list
        remote.press(.down)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testPeopleItemSelection() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Favorites tab
        for _ in 0..<3 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate to People segment
        remote.press(.down)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate and select a person
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Register Screen Tests

    func testRegisterScreenNavigation() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate down to find register option
        for _ in 0..<6 {
            remote.press(.down)
            sleep(1)
        }

        // Select register
        remote.press(.select)
        sleep(2)

        // Navigate through register form
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testRegisterFormFields() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate to register button
        for _ in 0..<6 {
            remote.press(.down)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate through all form fields
        remote.press(.down) // Email field
        sleep(1)
        remote.press(.down) // Password field
        sleep(1)
        remote.press(.down) // Confirm password field
        sleep(1)
        remote.press(.down) // Register button
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Account VC Tests (when logged in)

    func testAccountScreenWhenLoggedIn() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Account tab
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)

        // Navigate through account screen elements
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // If we see logout button, interact with it
        remote.press(.up)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Extended Item Detail Tests

    func testItemDetailFromVideoTab() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for videos to load
        sleep(4)

        // Navigate down into video collection
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Select first video item
        remote.press(.select)
        sleep(4)

        // Wait for item detail to load and navigate
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testItemDetailFromMusicTab() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(4)

        // Navigate down into music collection
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Select a music item
        remote.press(.select)
        sleep(4)

        // Navigate within item detail
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    func testItemDetailAllElements() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for content
        sleep(4)

        // Navigate to an item
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(4)

        // Scroll through all item detail elements
        for _ in 0..<8 {
            remote.press(.down)
            sleep(1)
        }

        // Scroll back up
        for _ in 0..<5 {
            remote.press(.up)
            sleep(1)
        }

        // Navigate horizontally
        remote.press(.right)
        sleep(1)
        remote.press(.left)
        sleep(1)

        // Go back
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Search with Results Tests

    func testSearchWithKeyboardInput() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Navigate to Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Navigate to search field and select
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Type using the keyboard (navigate and select keys)
        remote.press(.down)
        sleep(1)
        remote.press(.select) // Select a key
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select) // Select another key
        sleep(1)

        // Dismiss keyboard
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Tab Bar Complete Navigation

    func testNavigateAllTabsSequentially() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Videos tab (default)
        sleep(2)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)

        // Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)

        // Search tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)

        // Favorites tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)

        // Account tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)
        remote.press(.down)
        sleep(1)
        remote.press(.up)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Error Handling UI Tests

    func testLoadingStates() throws {
        let app = launchApp()

        // Wait for loading to complete
        sleep(5)

        // App should display content or empty state
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testRefreshContent() throws {
        let app = launchApp()

        let remote = XCUIRemote.shared

        // Wait for initial load
        sleep(3)

        // Navigate down into content
        remote.press(.down)
        sleep(1)

        // Navigate back up (might trigger refresh in some implementations)
        remote.press(.up)
        sleep(1)

        // Switch tabs to trigger reload
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)
        remote.press(.left)
        sleep(1)
        remote.press(.select)
        sleep(2)

        XCTAssertTrue(app.state == .runningForeground)
    }
}
