//
//  DocumentInteractionController.swift
//  SmartOvenDashboard
//
//

import SwiftUI

import SwiftUI
import UIKit

struct DocumentInteractionController: UIViewControllerRepresentable {
    private let viewController = UIViewController()
    var isActive: Binding<Bool>
    var url: URL?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentInteractionController>) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<DocumentInteractionController>) {
        if isActive.wrappedValue {
            if let url = url {
                let docController = UIDocumentInteractionController(url: url)
                docController.delegate = context.coordinator
                docController.presentPreview(animated: true)
            }
            self.isActive.wrappedValue = false
        }
    }
    
    func makeCoordinator() -> Coordintor {
        return Coordintor(owner: self)
    }
    
    final class Coordintor: NSObject, UIDocumentInteractionControllerDelegate { // works as delegate
        let owner: DocumentInteractionController
        init(owner: DocumentInteractionController) {
            self.owner = owner
        }
        
        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            return owner.viewController
        }
        
        func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
            controller.delegate = nil // done, so unlink self
            owner.isActive.wrappedValue = false // notify external about done
        }
    }
}
