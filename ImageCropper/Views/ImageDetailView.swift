import SwiftUI

struct ImageDetailView: View {
    @ObservedObject var processedImage: ProcessedImage
    @Environment(\.dismiss) private var dismiss
    @State private var showingOriginal = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var currentImage: UIImage {
        showingOriginal ? processedImage.originalImage : (processedImage.croppedImage ?? processedImage.originalImage)
    }
    
    var body: some View {
        NavigationStack {
            ZoomableImageView(
                image: currentImage,
                scale: $scale,
                offset: $offset,
                lastOffset: $lastOffset
            )
            .navigationTitle(showingOriginal ? "Original" : "Processed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingOriginal ? "Show Processed" : "Show Original") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingOriginal.toggle()
                            resetZoom()
                        }
                    }
                    .disabled(processedImage.croppedImage == nil && !showingOriginal)
                }
            }
        }
    }
    
    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .gesture(
                    SimultaneousGesture(
                        magnificationGesture,
                        dragGesture(in: geometry)
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
        }
        .background(Color.black)
        .clipped()
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, 0.5), 5.0)
            }
            .onEnded { _ in
                lastScale = scale
                
                if scale < 1.0 {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }
    
    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                
                let maxOffsetX = max(0, (geometry.size.width * scale - geometry.size.width) / 2)
                let maxOffsetY = max(0, (geometry.size.height * scale - geometry.size.height) / 2)
                
                offset = CGSize(
                    width: min(max(newOffset.width, -maxOffsetX), maxOffsetX),
                    height: min(max(newOffset.height, -maxOffsetY), maxOffsetY)
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    @State private var lastScale: CGFloat = 1.0
}