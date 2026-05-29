import SwiftUI

public struct WMSCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(Color.wmsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
            )
    }
}

public struct WMSStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?

    public init(title: String, value: String, icon: String, color: Color = .wmsAccent, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 0) {
            iconView
                .padding(.bottom, 12)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.wmsTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.wmsCaption)
                .foregroundColor(.wmsTextSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.top, 2)
            if let subtitle {
                Text(subtitle)
                    .font(.wmsCaption)
                    .foregroundColor(.wmsTextTertiary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.wmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
        )
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

public struct WMSErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    public init(message: String, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.wmsWarning)
            Text(message)
                .font(.wmsBody)
                .foregroundColor(.wmsTextPrimary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.wmsTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.wmsWarning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.wmsWarning.opacity(0.3), lineWidth: 1)
        )
    }
}

public struct WMSToast: View {
    let message: String
    let icon: String
    let color: Color

    public init(message: String, icon: String = "checkmark.circle.fill", color: Color = .wmsSuccess) {
        self.message = message
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.wmsCallout)
                .foregroundColor(.wmsTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

public struct WMSLoadingView: View {
    let message: String

    public init(message: String = "Loading...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.wmsCaption)
                .foregroundColor(.wmsTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public extension View {
    func wmsToast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", color: Color = .wmsSuccess) -> some View {
        self.overlay(alignment: .top) {
            if isPresented.wrappedValue {
                WMSToast(message: message, icon: icon, color: color)
                    .padding(.top, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented.wrappedValue)
    }
}

public struct WMSBadge: View {
    let text: String
    let color: Color

    public init(text: String, color: Color = .wmsAccent) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.wmsMonospaceCaption)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
}
