#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - CameraPicker
//
// Minimal SwiftUI wrapper around UIImagePickerController configured for the
// rear camera. No editing UI. Reports back via the bound UIImage? and calls
// onDismiss on cancel or capture.

@available(iOS 18.0, *)
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onDismiss: () -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = false
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let captured = info[.originalImage] as? UIImage {
                parent.image = captured
            }
            parent.onDismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}
#endif
