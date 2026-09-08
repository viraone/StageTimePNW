import SwiftUI

// MARK: - Day Summary Card (mirrors the website's Selected Day panel)
struct DaySummaryCard: View {
    let day: Weekday
    let mics: [OpenMic]
    let nextUpID: String?
    let onSelect: (OpenMic) -> Void

    private let pnwGreen = Color(red: 0.05, green: 0.82, blue: 0.45)
    private let pnwRed = Color(red: 1.0, green: 0.35, blue: 0.35)

    private var nextMic: OpenMic? {
        if let nextUpID { return mics.first(where: { $0.id == nextUpID }) }
        return mics.first
    }

    private var lastMic: OpenMic? {
        mics.max(by: { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SELECTED DAY")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(pnwRed)
                    Text("\(day.fullName)'s Mics")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Text("\(mics.count) open mic\(mics.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color(white: 0.14))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }

            // Next / Last boxes
            HStack(spacing: 10) {
                summaryBox(label: "NEXT", mic: nextMic)
                summaryBox(label: "LAST", mic: lastMic)
            }

            Divider().background(Color.white.opacity(0.1))

            // Mic rows
            VStack(spacing: 0) {
                ForEach(mics) { mic in
                    Button(action: { onSelect(mic) }) {
                        HStack(spacing: 14) {
                            Text(mic.displayStartTime ?? "—")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(mic.id == nextUpID ? pnwGreen : .gray)
                                .frame(width: 68, alignment: .leading)

                            Text(mic.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if mic.id != mics.last?.id {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(white: 0.07))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func summaryBox(label: String, mic: OpenMic?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(.gray)
            Text(mic.map { "\($0.displayStartTime ?? "—") · \($0.name)" } ?? "—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(white: 0.10))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
