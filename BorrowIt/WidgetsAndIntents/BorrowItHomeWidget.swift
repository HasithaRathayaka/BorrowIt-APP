import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Timeline Entry
public struct BorrowWidgetEntry: TimelineEntry {
    public let date: Date
    public let itemTitle: String
    public let lenderName: String
    public let returnDueTime: String
    public let hoursRemaining: Int
    public let progressFraction: Double
    
    public init(
        date: Date = Date(),
        itemTitle: String = "DeWalt 20V Drill",
        lenderName: String = "Maya R.",
        returnDueTime: String = "5:00 PM",
        hoursRemaining: Int = 2,
        progressFraction: Double = 0.65
    ) {
        self.date = date
        self.itemTitle = itemTitle
        self.lenderName = lenderName
        self.returnDueTime = returnDueTime
        self.hoursRemaining = hoursRemaining
        self.progressFraction = progressFraction
    }
}

// MARK: - Widget Provider
public struct BorrowWidgetProvider: TimelineProvider {
    public func placeholder(in context: Context) -> BorrowWidgetEntry {
        BorrowWidgetEntry()
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (BorrowWidgetEntry) -> Void) {
        completion(BorrowWidgetEntry())
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<BorrowWidgetEntry>) -> Void) {
        let entry = BorrowWidgetEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry View
public struct BorrowItWidgetEntryView: View {
    public var entry: BorrowWidgetProvider.Entry
    
    public init(entry: BorrowWidgetProvider.Entry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "hand.raised.square.on.square.fill")
                        .foregroundColor(Color.brandEmerald)
                        .font(.system(size: 13))
                    Text("BorrowIt")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("\(entry.hoursRemaining)h left")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandEmerald)
            }
            
            // Item & Lender Info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.itemTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("Return to \(entry.lenderName) by \(entry.returnDueTime)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.brandEmerald)
                        .frame(width: geo.size.width * entry.progressFraction, height: 5)
                }
            }
            .frame(height: 5)
            
            Spacer()
            
            // Interactive AppIntent Button for iOS 17+
            Button(intent: InitiateReturnHandoffIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .bold))
                    Text("Ready for Return")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.brandEmerald)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .containerBackground(Color.darkNavyPass, for: .widget)
    }
}

// MARK: - Widget Definition
public struct BorrowItHomeWidget: Widget {
    public let kind: String = "com.borrowit.homewidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BorrowWidgetProvider()) { entry in
            BorrowItWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Active Borrow Status")
        .description("Track your active borrowed item countdown and initiate return with one tap.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
