//
//  SearchResultsController.swift
//  OBANext
//
//  Created by Aaron Brethorst on 1/23/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit
import OBAKitCore
import MapKit

public class SearchResultsController: UIViewController, ListProvider {
    public lazy var collectionController = CollectionController(application: application, dataSource: self)
    var scrollView: UIScrollView { collectionController.collectionView }

    private weak var delegate: ModalDelegate?

    private let application: Application

    private let searchResponse: SearchResponse

    private let titleView = StackedTitleView.autolayoutNew()

    public init(searchResponse: SearchResponse, application: Application, delegate: ModalDelegate?) {
        self.searchResponse = searchResponse
        self.application = application
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("search_results_controller.title", value: "Search Results", comment: "The title of the Search Results controller.")
        titleView.titleLabel.text = title
        titleView.subtitleLabel.text = subtitleText(from: searchResponse)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UIViewController Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = titleView

        view.backgroundColor = ThemeColors.shared.systemBackground
        addChildController(collectionController)
        collectionController.view.pinToSuperview(.edges)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.close, style: .plain, target: self, action: #selector(close))
    }

    // MARK: - Actions

    @objc private func close() {
        delegate?.dismissModalController(self)
    }

    // MARK: - Private

    private func subtitleText(from response: SearchResponse) -> String {
        let subtitleFormat: String
        switch searchResponse.request.searchType {
        case .address:
            subtitleFormat = NSLocalizedString("search_results_controller.subtitle.address_fmt", value: "%@", comment: "A format string for address searches. In English, this is just the address itself without any adornment.")
        case .route:
            subtitleFormat = NSLocalizedString("search_results_controller.subtitle.route_fmt", value: "Route %@", comment: "A format string for address searches. e.g. in english: Route search: \"{SEARCH TEXT}\"")
        case .stopNumber:
            subtitleFormat = NSLocalizedString("search_results_controller.subtitle.stop_number_fmt", value: "Stop number %@", comment: "A format string for stop number searches. e.g. in english: Stop number: \"{SEARCH TEXT}\"")
        case .vehicleID:
            subtitleFormat = NSLocalizedString("search_results_controller.subtitle.vehicle_id_fmt", value: "Vehicle ID %@", comment: "A format string for stop number searches. e.g. in english: Stop number: \"{SEARCH TEXT}\"")
        }
        return String(format: subtitleFormat, searchResponse.request.query)
    }
}

extension SearchResultsController: ListAdapterDataSource {

    private func tableRowData(from item: Any) -> TableRowData? {
        let row: TableRowData

        switch item {
        case let item as MKMapItem:
            row = TableRowData(title: item.name ?? "???", accessoryType: .none, tapped: nil)
        case let item as Route:
            row = TableRowData(title: item.shortName, subtitle: item.agency.name, accessoryType: .none, tapped: nil)
        case let item as Stop:
            row = TableRowData(title: item.name, accessoryType: .none, tapped: nil)
        case let item as VehicleStatus:
            row = TableRowData(title: item.vehicleID, accessoryType: .none, tapped: nil)
        default:
            return nil
        }

        row.tapped = { [weak self] _ in
            guard let self = self else { return }
            self.application.mapRegionManager.searchResponse = SearchResponse(response: self.searchResponse, substituteResult: item)
            self.delegate?.dismissModalController(self)
        }

        return row
    }

    public func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        let rows = searchResponse.results.compactMap { tableRowData(from: $0) }
        let tableSection = TableSectionData(title: nil, rows: rows)
        return [tableSection]
    }

    public func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        switch object {
        case is TableSectionData: return TableSectionController()
        default:
            fatalError()
        }
    }

    public func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}