import SwiftUI

// MARK: - Dynamic Card View
struct DynamicMicCard: View {
    let mic: OpenMic
    var isHighlighted: Bool = false
    var isNextUp: Bool = false
    var distanceMiles: Double? = nil
    var onDirections: (() -> Void)? = nil
    var hostOverride: String? = nil
    
    @State private var isPressed: Bool = false

    struct CardLink {
        let title: String
        let urlString: String
        var prominent: Bool = false
    }

    private var cardLinks: [CardLink] {
        var links: [CardLink] = []
        if let signup = mic.webSignup, !signup.isEmpty {
            links.append(CardLink(title: "Sign Up Online", urlString: signup, prominent: true))
        }
        if let list = mic.listUrl, !list.isEmpty {
            links.append(CardLink(title: mic.listLabel?.isEmpty == false ? mic.listLabel! : "View List", urlString: list))
        }
        if let site = mic.website, !site.isEmpty {
            links.append(CardLink(title: "Website", urlString: site))
        }
        if let contact = mic.contact, !contact.isEmpty {
            let title: String
            if contact.contains("instagram.com") { title = "Instagram" }
            else if contact.contains("facebook.com") { title = "Facebook" }
            else { title = "Contact" }
            links.append(CardLink(title: title, urlString: contact))
        }
        if let phone = mic.phone, !phone.isEmpty {
            let digits = phone.filter { $0.isNumber }
            links.append(CardLink(title: "Call \(phone)", urlString: "tel://\(digits)"))
        }
        return links
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Badges Row - Only show "NEXT OPEN MIC" badge
            if isNextUp {
                HStack(spacing: 8) {
                    Text("NEXT OPEN MIC")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.05, green: 0.82, blue: 0.45))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                .padding(.bottom, 12)
            }

            // Main Content
            VStack(alignment: .leading, spacing: 12) {
                // Title and Time
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mic.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let rec = mic.recurrenceText {
                            Text(rec.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                                .tracking(0.5)
                        }
                    }
                    
                    Spacer()
                    
                    // Time display (show start time if available)
                    if let startTime = mic.displayStartTime {
                        Text(startTime)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Signup and Start times
                if let displayStart = mic.displayStartTime {
                    HStack(spacing: 4) {
                        Text("Start")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(displayStart)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                if let displaySignup = mic.displaySignupTime {
                    HStack(spacing: 4) {
                        Text("Signup")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(displaySignup)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                // Venue + Location
                VStack(alignment: .leading, spacing: 2) {
                    if let venue = mic.venue, !venue.isEmpty {
                        Text(venue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text(mic.location)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Distance + Directions (shown when Show Distance is on)
                if let distanceMiles {
                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text("\(String(format: "%.1f", distanceMiles)) mi · ~\(TripMath.driveMinutes(forMiles: distanceMiles)) min drive")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.05, green: 0.82, blue: 0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.05, green: 0.82, blue: 0.45).opacity(0.12))
                        .cornerRadius(6)

                        Spacer()

                        if onDirections != nil {
                            Button(action: { onDirections?() }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.system(size: 11))
                                    Text("Directions & Transit")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(red: 0.05, green: 0.82, blue: 0.45))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
                
                // Tags
                HStack(spacing: 8) {
                    if let type = mic.openMicType, !type.isEmpty {
                        Text(type.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    // Price tag from actual data
                    if let price = mic.priceForTime, !price.isEmpty {
                        Text(price.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    // Age requirement
                    if let age = mic.ageRequirement, !age.isEmpty {
                        Text(age.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    // Signup type (in-person / online)
                    if let signup = mic.signupType, !signup.isEmpty {
                        Text(signup.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    // Wheelchair accessible
                    if mic.wheelchairAccessible == true {
                        Text("♿ ACCESSIBLE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                // Host
                if let host = hostOverride ?? (mic.host?.isEmpty == false ? mic.host : nil) {
                    HStack(spacing: 4) {
                        Text("Host")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(host)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        if hostOverride != nil {
                            Text("MC")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.05, green: 0.82, blue: 0.45))
                                .cornerRadius(3)
                        }
                    }
                }

                // Signup details text
                if let details = mic.signupDetails, !details.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SIGNUP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        Text(details)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(.top, 2)
                }
                
                // Details & Rules Section
                if let info = mic.requirementsInfo, !info.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAILS & RULES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        
                        Text(info)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(.top, 4)
                }
                
                // Link buttons: signup / list / website / contact / call
                let linkButtons = cardLinks
                if !linkButtons.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(linkButtons, id: \.title) { link in
                                Button(action: {
                                    if let url = URL(string: link.urlString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text(link.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(link.prominent ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(link.prominent ? Color(red: 0.05, green: 0.82, blue: 0.45) : Color(white: 0.15))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.white.opacity(link.prominent ? 0 : 0.1), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isHighlighted 
                ? Color(red: 0.05, green: 0.82, blue: 0.45).opacity(0.08)
                : Color(white: 0.08)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHighlighted 
                        ? Color(red: 0.05, green: 0.82, blue: 0.45).opacity(0.5)
                        : Color.white.opacity(0.08),
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(
            color: isHighlighted 
                ? Color(red: 0.05, green: 0.82, blue: 0.45).opacity(isPressed ? 0.4 : 0.2)
                : Color.black.opacity(isPressed ? 0.3 : 0),
            radius: isPressed ? 12 : 8,
            y: isPressed ? 6 : 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                isPressed = true
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } else {
                isPressed = false
            }
        }, perform: {})
    }
}
