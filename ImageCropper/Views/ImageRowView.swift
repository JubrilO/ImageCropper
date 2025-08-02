import SwiftUI

struct ImageRowView: View {
    @ObservedObject var processedImage: ProcessedImage
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            imageView(image: processedImage.originalImage, label: "Original")
            
            Divider()
                .frame(width: 2)
                .background(Color.gray.opacity(0.3))
            
            if processedImage.isProcessing {
                loadingView
            } else if let croppedImage = processedImage.croppedImage {
                imageView(image: croppedImage, label: "Processed")
            } else if processedImage.error != nil {
                errorView
            } else {
                loadingView
            }
        }
        .frame(height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
    
    private func imageView(image: UIImage, label: String) -> some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)
                .cornerRadius(8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Processing...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Processing Failed")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}