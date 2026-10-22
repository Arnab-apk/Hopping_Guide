import SwiftUI
import CoreLocation

struct ReturnHomePlannerView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("return_home_station_v1") private var homeStationID = ""
    @AppStorage("return_home_buffer_v1") private var boardingBufferMinutes = 20
    @AppStorage("return_home_operating_date_v1") private var operatingDate = Self.dateKey(for: .now)
    @State private var isStationPickerPresented = false
    @State private var stationSearch = ""
    @State private var walkingEstimate: WalkingRoute?
    @State private var estimateCreatedAt: Date?
    @State private var isEstimating = false
    @State private var estimateError: String?

    private var homeStation: TransitStation? { env.stations.byId(homeStationID) }
    private var filteredStations: [TransitStation] {
        let query = SearchNormalize.normalize(stationSearch)
        let stations = env.stations.allStations
        guard !query.isEmpty else { return stations }
        return stations.filter {
            SearchNormalize.normalize("\($0.name) \($0.code ?? "") \($0.nameBn ?? "")").contains(query)
        }
    }
    private var operatingDateBinding: Binding<Date> {
        Binding(get: { Self.date(from: operatingDate) ?? .now }, set: { operatingDate = Self.dateKey(for: $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(PujaColors.durgaRed.opacity(0.14)).frame(width: 48, height: 48)
                    Image(systemName: "house.and.flag.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(PujaColors.durgaRed)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Get home")
                        .font(PujaTypography.rounded(18, weight: .bold))
                    Text("Plan your walk to a station")
                        .font(PujaTypography.rounded(12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PujaColors.festivalGold)
            }

            Button { isStationPickerPresented = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: homeStation?.isMetro == true ? "tram.fill" : "train.side.front.car")
                        .foregroundStyle(homeStation?.isMetro == true ? PujaColors.metroBlue : PujaColors.railwayPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(homeStation?.displayName ?? "Choose your home station")
                            .font(PujaTypography.rounded(14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(homeStation?.typeLabel ?? "\(env.stations.allStations.count) metro and railway stations")
                            .font(PujaTypography.rounded(11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .liquidBackground(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                DatePicker("Operating date", selection: operatingDateBinding, displayedComponents: .date)
                    .font(PujaTypography.rounded(12, weight: .medium))
                    .environment(\.calendar, Self.kolkataCalendar)
                    .environment(\.timeZone, Self.kolkataTimeZone)
                Spacer(minLength: 0)
            }

            Stepper(value: $boardingBufferMinutes, in: 5...60, step: 5) {
                Label("Boarding buffer · \(boardingBufferMinutes) min", systemImage: "clock.badge.checkmark")
                    .font(PujaTypography.rounded(12, weight: .medium))
                    .foregroundStyle(.primary)
            }

            Button {
                Task { await estimateWalk() }
            } label: {
                HStack(spacing: 8) {
                    if isEstimating { ProgressView().tint(.white) }
                    else { Image(systemName: "figure.walk") }
                    Text(isEstimating ? "Finding a walking route…" : "Estimate walk to station")
                        .font(PujaTypography.rounded(13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .liquidBackground(.interactive, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .background(PujaColors.durgaRed.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(homeStation == nil || isEstimating)

            if let walkingEstimate {
                estimateSummary(walkingEstimate)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
            if let estimateError {
                Label(estimateError, systemImage: "location.slash")
                    .font(PujaTypography.rounded(11))
                    .foregroundStyle(PujaColors.crowdHigh)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label("No verified departures are available for this release. Arrival is a walking estimate only; check live operator information and station signage. Uma does not estimate a last train or leave-by time.",
                  systemImage: "info.circle.fill")
                .font(PujaTypography.rounded(10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .liquidCard(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(PujaColors.festivalGold.opacity(0.22), lineWidth: 1))
        .sheet(isPresented: $isStationPickerPresented) { stationPicker }
        .onAppear { env.location.startLiveTracking(for: .returnHome) }
        .onDisappear { env.location.stopLiveTracking(for: .returnHome) }
        .onChange(of: homeStationID) { _, _ in
            walkingEstimate = nil
            estimateError = nil
        }
        .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.82), value: walkingEstimate?.destinationTitle)
    }

    private func estimateSummary(_ route: WalkingRoute) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(route.formattedDistance, systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                Spacer()
                Label(route.formattedDuration, systemImage: "clock")
            }
            .font(PujaTypography.rounded(12, weight: .semibold))
            .foregroundStyle(.primary)

            if let estimateCreatedAt {
                let arrival = estimateCreatedAt.addingTimeInterval(route.durationSeconds + Double(boardingBufferMinutes * 60))
                Text("Allow about \(Self.timeString(route.durationSeconds + Double(boardingBufferMinutes * 60))) to reach \(route.destinationTitle), including your buffer. Estimated arrival: \(Self.timeString(arrival)).")
                    .font(PujaTypography.rounded(11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if route.isFallback {
                Label("Street directions are unavailable. This uses a rough distance estimate.", systemImage: "exclamationmark.triangle")
                    .font(PujaTypography.rounded(10.5))
                    .foregroundStyle(PujaColors.crowdMedium)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .liquidBackground(.ultraThin, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var stationPicker: some View {
        NavigationStack {
            List(filteredStations) { station in
                Button {
                    homeStationID = station.id
                    isStationPickerPresented = false
                    Haptics.selection()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: station.isMetro ? "tram.fill" : "train.side.front.car")
                            .foregroundStyle(station.isMetro ? PujaColors.metroBlue : PujaColors.railwayPurple)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(station.name).foregroundStyle(.primary)
                            if let nameBn = station.nameBn, !nameBn.isEmpty {
                                Text(nameBn).font(PujaTypography.bengali(14)).foregroundStyle(.secondary)
                            }
                            Text([station.typeLabel, station.code, station.lines.first].compactMap { $0 }.joined(separator: " · "))
                                .font(PujaTypography.rounded(11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if station.id == homeStationID {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(PujaColors.durgaRed)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $stationSearch, prompt: "Search station or station code")
            .navigationTitle("Choose a station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isStationPickerPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func estimateWalk() async {
        guard let station = homeStation else { return }
        guard let start = env.location.currentPosition() else {
            estimateError = "Turn on location access and wait for a current GPS fix to estimate the walk."
            return
        }
        isEstimating = true
        estimateError = nil
        defer { isEstimating = false }
        let route = await env.routing.getWalkingRoute(
            start: start,
            destination: station.coordinate,
            destinationName: station.displayName)
        walkingEstimate = route
        estimateCreatedAt = .now
    }

    private static var kolkataTimeZone: TimeZone { TimeZone(identifier: "Asia/Kolkata") ?? .current }
    private static var kolkataCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = kolkataTimeZone
        return calendar
    }
    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = kolkataCalendar
        formatter.timeZone = kolkataTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    private static func date(from key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = kolkataCalendar
        formatter.timeZone = kolkataTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
    private static func timeString(_ seconds: Double) -> String {
        let duration = max(0, Int(seconds.rounded()))
        let hours = duration / 3600
        let minutes = (duration % 3600 + 59) / 60
        if hours == 0 { return "\(minutes) min" }
        if minutes == 0 { return "\(hours) hr" }
        return "\(hours) hr \(minutes) min"
    }
    private static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = kolkataTimeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
