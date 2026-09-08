import SwiftUI

struct RickshawInfoView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {

        ZStack {

            Color.pnwDarkBg
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 18) {

                    // MARK: - Rickshaw Header

                    VStack(spacing: 8) {

                        Text("EVERY FRIDAY NIGHT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.pnwRedText)
                            .tracking(2)

                        Text("7PM - 9PM")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        Image("RickshawLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 125)
                            .padding(.vertical, 6)
                    }

                    // MARK: - Address

                    Link(
                        destination: URL(
                            string: "http://maps.apple.com/?q=322+N+105th+St+Seattle+WA+98133"
                        )!
                    ) {

                        VStack(spacing: 4) {

                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18))
                                .foregroundColor(.pnwRedText)

                            Text("322 N 105th St")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Seattle, WA 98133")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(Color.pnwCardBg)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    Color.pnwCardBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Instagram

                    VStack(spacing: 12) {

                        HStack(spacing: 8) {

                            Image(systemName: "camera.fill")
                                .font(.system(size: 15))

                            Text("Follow us on Instagram")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)

                        VStack(spacing: 10) {

                            Link(
                                "@therickshawhaha",
                                destination: URL(
                                    string: "https://www.instagram.com/therickshawhaha/"
                                )!
                            )
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.pnwRedText)

                            Link(
                                "@rickshawseattle",
                                destination: URL(
                                    string: "https://www.instagram.com/rickshawseattle/"
                                )!
                            )
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.pnwRedText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(Color.pnwCardBg)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.pnwCardBorder,
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal)

                    // MARK: - Tagline

                    VStack(spacing: 8) {

                        Text("Best Open Mic in Seattle")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)

                        Text("Great Local Comics • Amazing Food")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(Color.pnwCardBg)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.pnwCardBorder,
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }
}
