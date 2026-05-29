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
        content
            .padding(.leading, 0)
            .background(Color.wmsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
            )
    }

    private var content: some View {
        HStack(spacing: 0) {
            accentBar
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    iconView
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.wmsCaption)
                            .foregroundColor(.wmsTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(value)
                            .font(.system(size: 26, weight: .bold, design: .default))
                            .foregroundColor(.wmsTextPrimary)
                    }
                    Spacer(minLength: 0)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextTertiary)
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .frame(minHeight: 88)
    }

    private var accentBar: some View {
        Rectangle()
            .fill(color)
            .frame(width: 4)
            .frame(maxHeight: .infinity)
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
                .frame(width: 40, height: 40)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
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
