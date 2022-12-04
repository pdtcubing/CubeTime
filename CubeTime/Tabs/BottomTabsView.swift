import SwiftUI


struct VHStack<Content: View>: View {
    let vertical: Bool
    let spacing: CGFloat?
    let content: Content

    init(vertical: Bool, spacing: CGFloat? = nil, @ViewBuilder _ content: () -> Content) {
        self.vertical = vertical
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if vertical {
            VStack(spacing: spacing) {
                content
            }
        } else {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}

struct BottomTabsView: View {
    @Environment(\.globalGeometrySize) var globalGeometrySize
    @EnvironmentObject var tabRouter: TabRouter
    
    @Binding var currentTab: Tab
    
    var pad = false
    
    @Namespace private var namespace
    
    var body: some View {
        GeometryReader { geometry in
            VHStack(vertical: pad) {
                VHStack(vertical: pad) {
                    if !(UIDevice.deviceIsPad && UIDevice.deviceIsLandscape(globalGeometrySize) && padFloatingLayout) {
                        TabIconWithBar(
                            currentTab: $currentTab,
                            assignedTab: .timer,
                            systemIconName: "stopwatch",
                            systemIconNameSelected: "stopwatch.fill",
                            pad: pad,
                            namespace: namespace
                        )
                    }
                                                   
                    TabIconWithBar(
                        currentTab: $currentTab,
                        assignedTab: .solves,
                        systemIconName: "hourglass.bottomhalf.filled",
                        systemIconNameSelected: "hourglass.tophalf.filled",
                        pad: pad,
                        namespace: namespace
                    )
                    
                    TabIconWithBar(
                        currentTab: $currentTab,
                        assignedTab: .stats,
                        systemIconName: "chart.pie",
                        systemIconNameSelected: "chart.pie.fill",
                        pad: pad,
                        namespace: namespace
                    )
                    
                    TabIconWithBar(
                        currentTab: $currentTab,
                        assignedTab: .sessions,
                        systemIconName: "line.3.horizontal.circle",
                        systemIconNameSelected: "line.3.horizontal.circle.fill",
                        pad: pad,
                        namespace: namespace
                    )
                }
                .frame(
                    width: pad ? 50 : nil,
                    height: pad ? nil : 50,
                    alignment: pad ? .top : .leading
                )
                .background(Color(uiColor: .systemGray4).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 3.5)
                .animation(.spring(), value: self.currentTab)
                .animation(.spring(), value: tabRouter.padExpandState)
                
                Spacer()
                
                
                
                TabIcon(
                    currentTab: $currentTab,
                    assignedTab: .settings,
                    systemIconName: "gearshape",
                    systemIconNameSelected: "gearshape.fill",
                    pad: pad
                )
            }
            .background(Color(uiColor: .systemGray5).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)))
            .padding(pad ? .vertical : .horizontal)
            .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 3)
        }
        .zIndex(1)
        .ignoresSafeArea(.keyboard)
        .padding(.bottom, SetValues.hasBottomBar ? CGFloat(0) : nil)
        .transition(.move(edge: .bottom).animation(.easeIn(duration: 6)))
        .fixedSize(horizontal: pad, vertical: !pad)
    }
}
