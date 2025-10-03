import SwiftUI

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    enum ToastType {
        case success
        case error
        case info
        
        var backgroundColor: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .info:
                return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []
    
    func show(_ toast: Toast) {
        toasts.append(toast)
        
        // Auto dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            self.dismiss(toast)
        }
    }
    
    func dismiss(_ toast: Toast) {
        withAnimation(.easeInOut(duration: 0.3)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }
    
    func dismissAll() {
        withAnimation(.easeInOut(duration: 0.3)) {
            toasts.removeAll()
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundColor(.white)
                .font(.title3)
            
            Text(toast.message)
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
                    .padding(4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Container View

struct ToastContainerView: View {
    @ObservedObject var toastManager: ToastManager
    
    var body: some View {
        VStack {
            Spacer()
            
            ForEach(toastManager.toasts) { toast in
                ToastView(toast: toast) {
                    toastManager.dismiss(toast)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: toastManager.toasts)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - View Extension

extension View {
    func toastContainer(toastManager: ToastManager) -> some View {
        ZStack {
            self
            
            ToastContainerView(toastManager: toastManager)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Text("Toast Demo")
                .font(.title)
            
            Spacer()
        }
        .toastContainer(toastManager: ToastManager())
    }
}
