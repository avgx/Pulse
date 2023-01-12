// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine
import SwiftUI

final class ConsoleFiltersViewModel: ObservableObject {
    @Published var criteria = ConsoleFilters()
    @Published var isButtonResetEnabled = false

    private(set) var defaultDates: ConsoleFilters.Dates = .default

    let dataNeedsReload = PassthroughSubject<Void, Never>()

    private let store: LoggerStore
    private var cancellables: [AnyCancellable] = []

    init(store: LoggerStore) {
        self.store = store


        if store === LoggerStore.shared {
            criteria.dates = .session
            defaultDates = .session
        }

        $criteria.dropFirst().sink { [weak self] _ in
            self?.isButtonResetEnabled = true
            DispatchQueue.main.async { // important!
                self?.dataNeedsReload.send()
            }
        }.store(in: &cancellables)
    }

    var isDefaultSearchCriteria: Bool {
        isDatesDefault && criteria.filters == .default
    }

    func resetAll() {
        resetDates()
        criteria.filters = .default
        isButtonResetEnabled = false
    }

    var isDatesDefault: Bool {
        criteria.dates == defaultDates
    }

    func resetDates() {
        criteria.dates = defaultDates
    }

    func removeAllPins() {
        store.pins.removeAllPins()

#if os(iOS)
        runHapticFeedback(.success)
        ToastView {
            HStack {
                Image(systemName: "trash")
                Text("All pins removed")
            }
        }.show()
#endif
    }
}
