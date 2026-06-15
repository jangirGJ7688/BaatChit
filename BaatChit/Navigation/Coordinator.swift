//
//  Coordinator.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import UIKit

protocol Coordinator: AnyObject {

    var navigationController: UINavigationController { get }

    func start()
}
