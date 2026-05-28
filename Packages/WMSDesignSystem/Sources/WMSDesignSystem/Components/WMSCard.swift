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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.wmsSeparator, lineWidth: 1)
            )
    }
}

public struct WMSStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    public init(title: String, value: String, icon: String, color: Color = .wmsAccent) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        WMSCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.wmsTitle)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextSecondary)
                    Text(value)
                        .font(.wmsTitle)
                        .foregroundColor(.wmsTextPrimary)
                }

                Spacer()
            }
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
