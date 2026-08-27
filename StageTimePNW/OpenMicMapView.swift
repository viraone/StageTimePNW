//
//  OpenMicMapView.swift
//  StageTimePNW
//

import SwiftUI
import MapKit

struct OpenMicMapView: View {
    @State private var mics: [OpenMic] = []
    @State private var selectedMicID: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Pacific Northwest overview (Seattle → Portland corridor)
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -122.5),
            span: MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 4.5)
        )
    )

    private var selectedMic: OpenMic? {
        mics.first { $0.id == selectedMicID }
    }

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedMicID) {
            ForEach(mics) { mic in
                Marker(mic.name, systemImage: "music.mic", coordinate: mic.coordinate)
                    .tint(.purple)
                    .tag(mic.id)
            }
        }
        .navigationTitle("Open Mic Map")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading {
                ProgressView("Loading open mics…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .overlay(alignment: .bottom) {
            if let message = errorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
            }
        }
        .sheet(item: Binding(
            get: { selectedMic },
            set: { if $0 == nil { selectedMicID = nil } }
        )) { mic in
            OpenMicDetailSheet(mic: mic)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task { await loadMics() }
    }

    private func loadMics() async {
        isLoading = true
        errorMessage = nil
        do {
            mics = try await OpenMicService.fetchOpenMics()
        } catch {
            errorMessage = "Couldn't load open mics. Check your connection."
        }
        isLoading = false
    }
}

struct OpenMicDetailSheet: View {
    let mic: OpenMic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(mic.name)
                    .font(.title2.bold())

                Label(mic.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)

                if let recurrence = mic.recurrenceText, !recurrence.isEmpty {
                    Label(recurrence, systemImage: "calendar")
                } else if !mic.activeDays.isEmpty {
                    Label(mic.activeDays.joined(separator: ", "), systemImage: "calendar")
                }

                if let time = mic.timeSignupStart, !time.isEmpty {
                    Label(time, systemImage: "clock")
                }

                if let signup = mic.signupDetails, !signup.isEmpty {
                    Label(signup, systemImage: "pencil.line")
                }

                if let price = mic.priceForTime, !price.isEmpty {
                    Label(price, systemImage: "dollarsign.circle")
                }

                if let age = mic.ageRequirement, !age.isEmpty {
                    Label(age, systemImage: "person.crop.circle.badge.checkmark")
                }

                if let host = mic.host, !host.isEmpty {
                    Label("Hosted by \(host)", systemImage: "music.mic")
                }

                if let info = mic.requirementsInfo, !info.isEmpty {
                    Text(info)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let signupURL = urlIfValid(mic.webSignup) {
                    Link(destination: signupURL) {
                        Label("Sign up online", systemImage: "link")
                    }
                }

                if let site = urlIfValid(mic.website) {
                    Link(destination: site) {
                        Label("Website", systemImage: "globe")
                    }
                }

                Button {
                    openInMaps()
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func urlIfValid(_ string: String?) -> URL? {
        guard let string, !string.isEmpty, let url = URL(string: string),
              url.scheme?.hasPrefix("http") == true else { return nil }
        return url
    }

    private func openInMaps() {
        let location = CLLocation(latitude: mic.latitude, longitude: mic.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = mic.name
        item.openInMaps()
    }
}

#Preview {
    NavigationStack {
        OpenMicMapView()
    }
}
