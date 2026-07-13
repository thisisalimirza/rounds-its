//
//  StreakCalendarView.swift
//  Rounds
//
//  A month calendar highlighting the days the user played, to make the
//  streak (and streak-freeze protection) tangible.
//

import SwiftUI

struct StreakCalendarCard: View {
    /// Start-of-day dates the user played a case.
    let playedDays: Set<Date>
    let currentStreak: Int

    @State private var monthOffset = 0
    private let calendar = Calendar.current

    private var displayedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            weekdayHeader
            monthGrid
            legend
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { monthOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthTitle(displayedMonth))
                    .font(.system(.headline, design: .rounded))
                if currentStreak > 0 {
                    Text("🔥 \(currentStreak) day streak")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { monthOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(monthOffset >= 0 ? Color.secondary.opacity(0.3) : .secondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(monthOffset >= 0) // don't page into the future
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var monthGrid: some View {
        let days = daysInMonthGrid()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 34)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isPlayed = playedDays.contains(calendar.startOfDay(for: date))
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        let dayNumber = calendar.component(.day, from: date)

        return Text("\(dayNumber)")
            .font(.system(size: 13, weight: isPlayed ? .bold : .regular, design: .rounded))
            .foregroundStyle(isPlayed ? .white : (isFuture ? Color.secondary.opacity(0.4) : .primary))
            .frame(width: 34, height: 34)
            .background(
                Circle().fill(
                    isPlayed
                    ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.clear)
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.orange, lineWidth: isToday ? 2 : 0)
            )
    }

    private var legend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 12, height: 12)
                Text("Played").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 5) {
                Circle().stroke(Color.orange, lineWidth: 2).frame(width: 12, height: 12)
                Text("Today").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Date helpers

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private var shortWeekdaySymbols: [String] {
        // Reorder so the first symbol matches the calendar's first weekday.
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    /// Returns an array of optional dates for the month grid (nil = leading blank).
    private func daysInMonthGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for dayOffset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay) {
                cells.append(date)
            }
        }
        return cells
    }
}
