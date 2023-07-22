//
//  SearchListViewController.swift
//  OBAKit
//
//  Created by Alan Chu on 4/4/23.
//

import OBAKitCore

protocol SearchListViewControllerDelegate: AnyObject {
    var searchBarText: String { get }
    var searchInteractor: SearchInteractor { get }
}

class SearchListViewController: UIViewController, Scrollable, OBAListViewDataSource {
    var scrollView: UIScrollView {
        listView
    }

    var listView: OBAListView!
    var searchInteractor: SearchInteractor?

    weak var delegate: SearchListViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        listView = OBAListView()
        listView.obaDataSource = self
        listView.backgroundColor = .clear
        view.addSubview(listView)
        listView.pinToSuperview(.edges)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        listView.applyData()
    }

    func updateSearch() {
        listView.applyData()
    }

    func items(for listView: OBAListView) -> [OBAListViewSection] {
        guard let delegate else {
            return []
        }

        var sections = delegate.searchInteractor.searchModeObjects(text: delegate.searchBarText)
        for (idx, _) in sections.enumerated() {
            sections[idx].configuration.backgroundColor = .clear
        }

        return sections
    }

    func emptyData(for listView: OBAListView) -> OBAListView.EmptyData? {
        let image = UIImage(systemName: "magnifyingglass")
        let title = OBALoc("search_controller.empty_set.title", value: "Search", comment: "Title for the empty set indicator on the Search controller.")
        let body = OBALoc("search_controller.empty_set.body", value: "Type in an address, route name, stop number, or vehicle here to search.", comment: "Body for the empty set indicator on the Search controller.")

        return .standard(.init(alignment: .top, title: title, body: body, image: image))
    }
}
