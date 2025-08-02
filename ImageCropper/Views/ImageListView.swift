import SwiftUI
import PhotosUI

struct ImageListView: View {
    @StateObject private var viewModel = ImageListViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var selectedImage: ProcessedImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.processedImages.isEmpty {
                    emptyStateView
                } else {
                    imagesList
                }
                
                bottomControls
            }
            .navigationTitle("Image Processor")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
            .sheet(item: $selectedImage) { image in
                ImageDetailView(processedImage: image)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Images Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the button below to select images from your photo library")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var imagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.processedImages) { processedImage in
                    ImageRowView(processedImage: processedImage) {
                        selectedImage = processedImage
                    }
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .onAppear {
                        viewModel.markImageVisible(processedImage)
                    }
                    .onDisappear {
                        viewModel.markImageInvisible(processedImage)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            if !viewModel.processedImages.isEmpty {
                CropSliderView(cropPercentage: $viewModel.cropPercentage)
                    .padding(.horizontal)
            }
            
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 100,
                matching: .images,
                preferredItemEncoding: .automatic
            ) {
                Label("Select Images", systemImage: "photo.fill.on.rectangle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading)
            .onChange(of: selectedItems) { _, newItems in
                if !newItems.isEmpty {
                    viewModel.processSelectedImages(newItems)
                    selectedItems = []
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
    }
}