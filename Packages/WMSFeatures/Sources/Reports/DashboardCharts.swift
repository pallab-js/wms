import SwiftUI
import Charts
import WMSServices
import WMSDesignSystem

private let wmsChartPalette: [Color] = [
    .wmsAccent, .orange, .wmsInfo, .wmsSuccess, .purple, .pink, .teal, .indigo
]

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    private let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wmsTextSecondary)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wmsTextPrimary)
                Spacer()
            }
            content
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color.wmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
        )
    }
}

struct MovementTrendChart: View {
    let trend: [DailyMovement]

    var body: some View {
        Chart(trend) { day in
            AreaMark(
                x: .value("Date", day.date, unit: .day),
                y: .value("Quantity", day.stockIn),
                series: .value("Series", "Stock In")
            )
            .foregroundStyle(by: .value("Series", "Stock In"))
            .opacity(0.15)
            .interpolationMethod(.monotone)

            AreaMark(
                x: .value("Date", day.date, unit: .day),
                y: .value("Quantity", day.stockOut),
                series: .value("Series", "Stock Out")
            )
            .foregroundStyle(by: .value("Series", "Stock Out"))
            .opacity(0.15)
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", day.date, unit: .day),
                y: .value("Quantity", day.stockIn),
                series: .value("Series", "Stock In")
            )
            .foregroundStyle(by: .value("Series", "Stock In"))
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", day.date, unit: .day),
                y: .value("Quantity", day.stockOut),
                series: .value("Series", "Stock Out")
            )
            .foregroundStyle(by: .value("Series", "Stock Out"))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(
            domain: ["Stock In", "Stock Out"],
            range: [Color.wmsSuccess, Color.wmsWarning]
        )
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .frame(height: 190)
        .accessibilityLabel("Stock movement trend over the last 14 days")
    }
}

struct ValuePieChart: View {
    let points: [(label: String, value: Double)]
    let innerRatio: CGFloat
    let centerTitle: String?
    let centerValue: String?

    init(
        points: [(label: String, value: Double)],
        innerRatio: CGFloat = 0,
        centerTitle: String? = nil,
        centerValue: String? = nil
    ) {
        self.points = points
        self.innerRatio = innerRatio
        self.centerTitle = centerTitle
        self.centerValue = centerValue
    }

    private var palette: [Color] {
        points.indices.map { wmsChartPalette[$0 % wmsChartPalette.count] }
    }

    var body: some View {
        Chart(Array(points.enumerated()), id: \.offset) { _, point in
            SectorMark(
                angle: .value("Value", point.value),
                innerRadius: .ratio(innerRatio),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Label", point.label))
        }
        .chartForegroundStyleScale(domain: points.map(\.label), range: palette)
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotFrame = proxy.plotFrame, let centerValue {
                    VStack(spacing: 2) {
                        Text(centerValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.wmsTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        if let centerTitle {
                            Text(centerTitle)
                                .font(.wmsCaption)
                                .foregroundColor(.wmsTextTertiary)
                        }
                    }
                    .position(x: geometry[plotFrame].midX, y: geometry[plotFrame].midY)
                }
            }
        }
        .frame(height: 190)
        .accessibilityLabel("Value distribution chart")
    }
}

struct UtilisationBarChart: View {
    let points: [(label: String, percent: Double)]

    var body: some View {
        Chart(Array(points.enumerated()), id: \.offset) { _, point in
            BarMark(
                x: .value("Utilisation", min(point.percent, 100)),
                y: .value("Warehouse", point.label)
            )
            .foregroundStyle(barColor(point.percent))
            .annotation(position: .trailing, spacing: 4) {
                Text("\(Int(point.percent))%")
                    .font(.wmsMonospaceCaption)
                    .foregroundColor(.wmsTextSecondary)
            }
        }
        .chartXScale(domain: 0...100)
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 190)
        .accessibilityLabel("Warehouse utilisation bar chart")
    }

    private func barColor(_ value: Double) -> Color {
        if value > 90 { return .wmsDestructive }
        if value > 75 { return .wmsWarning }
        return .wmsSuccess
    }
}
