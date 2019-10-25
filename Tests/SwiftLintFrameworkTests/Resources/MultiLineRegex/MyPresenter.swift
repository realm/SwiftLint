//
//  Presenter.swift
//

import Foundation
import struct UIKit.CGRect

private extension Constants {
    static let punctuationItems: [String] = ["-", "."]
}


protocol MyPresentable: Presenter {
    var controller: MyViewControllable? { get set }

    var itemsCount: Int { get }

    func item(selectedAtIndex index: Int)
    func filter(updatedTo newOne: MyFilterType, andOwner owner: Any)
}

class MyPresenter: MyPresentable {
    var controller: MyViewControllable?

    var menuSelected: Handler

    var itemsCount: Int {
        return Constants.oneHundred
    }

    func item(selectedAtIndex index: Int) {
        guard let patient = model.patients[safe: index] else {
            return
        }

        patientSelected?(patient)
    }
}

extension MyPresenter: MyObservable {
    func filter(updatedTo newOne: MyFilterType, andOwner owner: Any) {
        filter = .system(section: newOne)
    }
}

