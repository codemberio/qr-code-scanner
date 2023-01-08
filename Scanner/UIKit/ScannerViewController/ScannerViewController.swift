//
//  ScannerViewController.swift
//  Scanner
//
//  Copyright © 2022 Ruvim Miksanskiy
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import os.log
import AVFoundation
import Combine

final class ScannerViewController: UIViewController {
    @IBOutlet weak var outlineView: OutlineView!
    private let cameraService = CameraService()
    private var subscriptions = Set<AnyCancellable>()
    let hideOutlinePublisher = PassthroughSubject<Void, Never>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraPreview()
        configureSubscribers()
    }
}

// MARK: - Setup Controller
extension ScannerViewController {
    private func setupPreviewView() throws {
        guard let previewView = view as? ScannerPreviewView else {
            throw ScannerError.operationFailed
        }
        previewView.session = cameraService.session
    }
    
    func setupCameraPreview() {
        Task {
            do {
                // Check camera permissions, system will present
                // permissions alert if permission state .notDetermined.
                try await AVCaptureDevice.requestVideoPermissionIfNeeded()

                // Configure capture session
                try await cameraService.configureVideoSession()

                // Setup preview view
                try setupPreviewView()

                // Start session
                try await cameraService.startRunning()
            } catch {
                os_log("setupCameraPreview failed")
            }
        }
    }
    
}

// MARK: - Configure subscribers
extension ScannerViewController {
    
    private func configureSubscribers() {
        cameraService
            .quickResponseCodePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] code in
                self?.handleDetectedQRCode(code: code)
            }).store(in: &subscriptions)

        hideOutlinePublisher
            .debounce(for: .seconds(0.7), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] code in
                self?.outlineView.hideOutlineView()
        }).store(in: &subscriptions)
    }
    
    private func handleDetectedQRCode(code: AVMetadataMachineReadableCodeObject) {
        do {
            let metadata = try transformCodeToViewCoordinates(code: code)
            outlineView.updatePositionIfNeeded(frame: metadata.bounds)
            hideOutlinePublisher.send()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    private func transformCodeToViewCoordinates(code: AVMetadataMachineReadableCodeObject) throws -> AVMetadataMachineReadableCodeObject {
                
        guard let previewView = view as? ScannerPreviewView,
                let metadata = previewView.previewLayer.transformedMetadataObject(for: code) as? AVMetadataMachineReadableCodeObject else {
            throw ScannerError.operationFailed
        }
        
        return metadata
    }
}
