//
//  CameraService.swift
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

import AVFoundation
import os.log
import Combine

final class CameraService: NSObject {
    private (set) var session: AVCaptureSession?
    private let queue = DispatchQueue(label: String(describing: CameraService.self))
    let quickResponseCodePublisher = PassthroughSubject<AVMetadataMachineReadableCodeObject, Never>()
}

// MARK: - Session configuration
extension CameraService {
    public func configureVideoSession() async throws {
        return try await withCheckedThrowingContinuation({ [weak self] continuation in
            
            queue.async { [weak self] in

                guard let weakSelf = self else {
                    continuation.resume(throwing: ScannerError.operationFailed)
                    return
                }
                
                let session = AVCaptureSession()
                session.beginConfiguration()
                
                let captureDevice: AVCaptureDevice
                let videoInput: AVCaptureDeviceInput
                
                do {
                    captureDevice = try AVCaptureDevice.captureDevice(in: .back)
                    videoInput = try AVCaptureDeviceInput(device: captureDevice)
                } catch {
                    continuation.resume(throwing: ScannerError.operationFailed)
                    return
                }
                
                guard session.canAddInput(videoInput) else {
                    continuation.resume(throwing: ScannerError.operationFailed)
                    return
                }

                session.addInput(videoInput)
                
                let output = AVCaptureMetadataOutput()
                guard session.canAddOutput(output) else {
                    continuation.resume(throwing: ScannerError.operationFailed)
                    return
                }
                
                session.addOutput(output)
                output.setMetadataObjectsDelegate(weakSelf, queue: weakSelf.queue)
                output.metadataObjectTypes = [.qr]
                session.commitConfiguration()

                weakSelf.session = session
                continuation.resume(returning: ())
            }
        })
    }
}

// MARK: - Session start / stop
extension CameraService {
    public func startRunning() async throws {
        return try await withCheckedThrowingContinuation({ [weak self] continuation in
            queue.async { [weak self] in
                
                guard let session = self?.session, !session.isRunning else {
                    continuation.resume(throwing: ScannerError.operationFailed)
                    return
                }
                
                session.startRunning()
                continuation.resume(returning: ())
            }
        })
    }

    public func stopRunning() async throws {
        return try await withCheckedThrowingContinuation({ [weak self] continuation in
            queue.async { [weak self] in
                
                guard let session = self?.session, session.isRunning else {
                    continuation.resume(throwing: ScannerError.operationFailed)
                    return
                }
                
                session.stopRunning()
                continuation.resume(returning: ())
            }
        })
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension CameraService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let code = metadataObjects.first(where: { $0.type == .qr }) as? AVMetadataMachineReadableCodeObject else { return }
        quickResponseCodePublisher.send(code)
    }
}
