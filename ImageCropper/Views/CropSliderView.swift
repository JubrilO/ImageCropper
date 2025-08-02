import SwiftUI

struct CropSliderView: View {
    @Binding var cropPercentage: CropPercentage
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Crop Amount")
                    .font(.headline)
                Spacer()
                Text("\(Int(cropPercentage.value))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { cropPercentage.value },
                    set: { newValue in
                        cropPercentage.update(newValue)
                    }
                ),
                in: CropPercentage.minimum...CropPercentage.maximum,
                step: 1
            )
            .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}