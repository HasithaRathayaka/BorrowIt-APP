import SwiftUI

// MARK: - Screen 7: Schedule / Choose Dates
public struct ScheduleBorrowView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var settings: AppSettingsManager
    public let item: BorrowItem
    
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var addCalendarReminders: Bool = true
    @State private var createdTransaction: BorrowTransaction? = nil
    @State private var navigateToRequestSent: Bool = false
    
    public init(item: BorrowItem) {
        self.item = item
    }
    
    private var numberOfDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }
    
    private var rentalTotal: Double {
        Double(numberOfDays) * item.dailyRate
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Date Range Pickers Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("SELECT DATES")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                DatePicker(
                                    "Pickup Date",
                                    selection: $startDate,
                                    in: Date()...,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                
                                Divider()
                                
                                DatePicker(
                                    "Return Date",
                                    selection: $endDate,
                                    in: startDate...,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            }
                            .padding(18)
                            .squircleCard()
                            
                            // 2. Pickup -> Return Summary Card
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("PICKUP")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                        Text(formattedDate(startDate))
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("from 10:00 AM")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("RETURN")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                        Text(formattedDate(endDate))
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("by 5:00 PM")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(18)
                            .squircleCard()
                            
                            // 3. EventKit Calendar Integration Toggle Card
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $addCalendarReminders) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color.blue)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("EventKit Calendar")
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundColor(.primary)
                                            Text("Add pickup and return reminders to iOS Calendar")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            }
                            .padding(18)
                            .squircleCard()
                            
                            // 4. Cost Breakdown Line
                            VStack(spacing: 10) {
                                HStack {
                                    Text("\(numberOfDays) days @ Rs. \(Int(item.dailyRate))/day")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Rs. \(Int(rentalTotal))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Refundable deposit hold")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Rs. \(Int(item.depositHold))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Due at pickup")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("Rs. \(Int(rentalTotal)) + Rs. \(Int(item.depositHold)) hold")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                }
                            }
                            .padding(18)
                            .squircleCard()
                        }
                        .padding(20)
                    }
                    
                    // Bottom CTA
                    VStack {
                        Button(action: {
                            Task {
                                let tx = await lifecycleVM.submitBorrowRequest(
                                    item: item,
                                    startDate: startDate,
                                    endDate: endDate,
                                    addCalendar: addCalendarReminders
                                )
                                self.createdTransaction = tx
                                self.navigateToRequestSent = true
                            }
                        }) {
                            Text("Continue with these dates")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .buttonStyle(BrandEmeraldButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationTitle("Choose Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToRequestSent) {
                if let tx = createdTransaction {
                    RequestSentView(transaction: tx)
                }
            }
        }
        .liveAccessibilityScale()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}
