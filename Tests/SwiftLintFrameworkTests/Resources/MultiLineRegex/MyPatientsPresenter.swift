//
//  PatientsPresenter.swift
//
//  Created by Les Melnychuk on 1/16/19.
//

import Foundation
import struct UIKit.CGRect

private extension Constants.Digits {
    struct Chacters {
        static let maximumNumberOfCharacters = 10
    }
}
extension Constants.Strings {
    struct Chacters {
        static let punctuationItems: [String] = ["-", ".", Constants.Strings.space]
    }
}

protocol MyPatientsPresentable: Presenter {
    var controller: MyPatientsViewControllable? { get set }

    var itemsCount: Int { get }

    func fill(item: PlainModelFillable, atIndex index: Int)
    func item(selectedAtIndex index: Int)
    func search(filterUpdatedTo newValue: String?)
}

class MyPatientsPresenter: MyPatientsPresentable {
    var controller: MyPatientsViewControllable?

    var menuSelected: Model.EmptyOptionalHandler
    var patientSelected: ((PatientPlainModel) -> Void)?

    var itemsCount: Int {
        return model.patients.count
    }

    private let model: MyPatientsModellable

    private var filter: PatientsFilter {
        didSet {
            filterUpdated(with: filter)
        }
    }
    private var savedFilter: MyPatientsFilterType {
        return MyPatientsFilterManager.shared.current
    }

    init(with model: MyPatientsModellable) {
        self.model = model
        self.filter = .system(section: MyPatientsFilterManager.shared.current)

        MyPatientsFilterManager.shared.add(observer: self)
    }

    func viewLoaded() {
        updateList()
        filterUpdated(with: filter)
    }

    func fill(item: PlainModelFillable, atIndex index: Int) {
        guard model.patients.indices.contains(index) else {
            Log.assertionFailure("Corrupted logic")
            return
        }

        let plainModel = MyPatientsCellPlainModel(from: model.patients[index], and: controller)
        item.fill(with: plainModel)
    }

    func item(selectedAtIndex index: Int) {
        guard let patient = model.patients[safe: index] else {
            return
        }

        patientSelected?(patient)
    }

    func search(filterUpdatedTo newValue: String?) {
        guard let value = newValue else {
            filter = .system(section: .default)
            return
        }

        controller?.isSearchModeOn = false
        filter = .custom(searchFilter: value, inSection: .default)
    }
}

extension MyPatientsPresenter: MyPatientsFilterObservable {
    func filter(updatedTo newOne: MyPatientsFilterType, andOwner owner: Any) {
        filter = .system(section: newOne)
    }
}

