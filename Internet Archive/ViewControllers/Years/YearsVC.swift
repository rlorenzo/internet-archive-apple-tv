//
//  YearsVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 9: Modern UIKit patterns with DiffableDataSource
//

import UIKit
import AlamofireImage

@MainActor
class YearsVC: UIViewController, UITableViewDelegate, UICollectionViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblTitle: UILabel!

    private var tableDataSource: UITableViewDiffableDataSource<Int, String>!
    private var collectionDataSource: ItemDataSource!
    private var collectionPrefetcher: ImagePrefetcher!

    var name = ""
    var identifier = ""
    var collection = ""
    var sortedData: [String: [SearchResult]] = [:]
    var sortedKeys = [String]()

    private var selectedRow = 0
    private let screenSize = UIScreen.main.bounds.size

    override func viewDidLoad() {
        super.viewDidLoad()

        self.sortedData.removeAll()
        self.tableView.isHidden = true
        self.collectionView.isHidden = true
        self.lblTitle.isHidden = true
        self.lblTitle.text = name

        // Configure table view appearance for proper label rendering
        self.tableView.backgroundColor = .clear
        self.view.backgroundColor = .clear

        // Configure collection view for dark mode support
        self.collectionView.backgroundColor = .clear

        configureTableView()
        configureCollectionView()

        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                let (_, results) = try await APIManager.sharedManager.getCollectionsTyped(collection: identifier, resultType: collection, limit: 5000)

                AppProgressHUD.sharedManager.hide()

                for item in results {
                    var year = "Undated"

                    // Handle year as either String or Int
                    if let yearStr = item.year {
                        year = yearStr
                    }

                    if var yearData = self.sortedData[year] {
                        yearData.append(item)
                        self.sortedData[year] = yearData
                    } else {
                        self.sortedData[year] = [item]
                    }
                }

                self.sortedKeys = self.sortedData.keys.sorted(by: { year1, year2 -> Bool in
                    year1 > year2
                })

                await self.applyTableSnapshot()
                await self.applyCollectionSnapshot()

                self.tableView.isHidden = false
                self.collectionView.isHidden = false
                self.lblTitle.isHidden = false
            } catch {
                AppProgressHUD.sharedManager.hide()
                NSLog("YearsVC Error: \(error)")
                Global.showServiceUnavailableAlert(target: self)
            }
        }
    }

    // MARK: - Configuration

    private func configureTableView() {
        // Configure diffable data source for table view
        tableDataSource = UITableViewDiffableDataSource<Int, String>(tableView: tableView) { tableView, indexPath, year in
            guard let yearCell = tableView.dequeueReusableCell(withIdentifier: "YearCell", for: indexPath) as? YearCell else {
                return UITableViewCell()
            }
            yearCell.lblYear.text = year
            yearCell.lblYear.textColor = .label

            return yearCell
        }
    }

    private func configureCollectionView() {
        // Set up modern compositional layout
        collectionView.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        collectionView.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        collectionDataSource = ItemDataSource(collectionView: collectionView) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ModernItemCell",
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: itemViewModel)

            return cell
        }

        // Set up image prefetching
        collectionPrefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: collectionDataSource)
    }

    private func applyTableSnapshot() async {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(sortedKeys, toSection: 0)
        await tableDataSource.apply(snapshot, animatingDifferences: true)
    }

    private func applyCollectionSnapshot() async {
        guard !sortedKeys.isEmpty, selectedRow < sortedKeys.count else {
            // Apply empty snapshot
            var snapshot = ItemSnapshot()
            snapshot.appendSections([.main])
            await collectionDataSource.apply(snapshot, animatingDifferences: true)
            return
        }

        let selectedYear = sortedKeys[selectedRow]
        guard let yearData = sortedData[selectedYear] else {
            var snapshot = ItemSnapshot()
            snapshot.appendSections([.main])
            await collectionDataSource.apply(snapshot, animatingDifferences: true)
            return
        }

        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        let viewModels = yearData.map { ItemViewModel(item: $0, section: .main) }
        snapshot.appendItems(viewModels, toSection: .main)
        await collectionDataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        Task {
            await applyCollectionSnapshot()
        }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !sortedKeys.isEmpty,
              selectedRow < sortedKeys.count,
              let yearData = sortedData[sortedKeys[selectedRow]],
              indexPath.row < yearData.count else {
            return
        }

        let item = yearData[indexPath.row]
        let identifier = item.identifier
        let title = item.title
        let archivedBy = item.creator
        let date = Global.formatDate(string: item.date)
        let description = item.description
        let mediaType = item.mediatype
        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")

        guard let itemVC = self.storyboard?.instantiateViewController(withIdentifier: "ItemVC") as? ItemVC else {
            return
        }

        itemVC.iIdentifier = identifier
        itemVC.iTitle = title ?? ""
        itemVC.iArchivedBy = archivedBy ?? ""
        itemVC.iDate = date ?? ""
        itemVC.iDescription = description ?? ""
        itemVC.iMediaType = mediaType ?? ""
        itemVC.iImageURL = imageURL

        self.present(itemVC, animated: true, completion: nil)
    }
}
