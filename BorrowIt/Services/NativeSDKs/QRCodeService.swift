import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision
import SwiftUI

// MARK: - On-Device QR Code Generation & Vision Barcode Verification
public class QRCodeService: QRServiceProtocol {
    public static let shared = QRCodeService()
    
    private let context = CIContext()
    
    public init() {}
    
    // MARK: - CoreImage QR Generation
    public func generateQRCodeImage(from payload: QRPayload) -> CGImage? {
        guard let jsonString = payload.toJSONString(),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let outputCIImage = filter.outputImage else { return nil }
        
        // Scale up sharp nearest-neighbor for high-contrast scanning
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = outputCIImage.transformed(by: transform)
        
        return context.createCGImage(scaledCIImage, from: scaledCIImage.extent)
    }
    
    // MARK: - Vision VNDetectBarcodesRequest Decoding (On-Device)
    public func decodeQRCode(from image: CGImage) async throws -> QRPayload {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNBarcodeObservation],
                      let qrCode = observations.first(where: { $0.symbology == .qr }),
                      let payloadString = qrCode.payloadStringValue else {
                    continuation.resume(throwing: BorrowStateError.invalidTokenSignature)
                    return
                }
                
                do {
                    let decodedPayload = try QRPayload.from(jsonString: payloadString)
                    continuation.resume(returning: decodedPayload)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Specify barcode symbology
            request.symbologies = [.qr]
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Payload Verification & Expiration Validation
    public func verifyPayload(_ payload: QRPayload) -> Bool {
        // Must have non-empty rotating token and valid signature within 5m window
        guard !payload.rotatingToken.isEmpty else { return false }
        return payload.isValid(windowSeconds: AppConfig.qrTokenExpirationSeconds)
    }
}
