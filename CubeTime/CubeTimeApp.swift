import SwiftUI
import UIKit
import CoreData


@main
struct CubeTime: App {
    @Environment(\.scenePhase) var phase
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /*
    var shortcutItem: UIApplicationShortcutItem?
     */
    
    @AppStorage("onboarding") var showOnboarding: Bool = true
    
    let persistenceController: PersistenceController
    private let moc: NSManagedObjectContext
    
    @StateObject var stopwatchManager: StopwatchManager
    @StateObject var fontManager: FontManager = FontManager()
    @StateObject var tabRouter: TabRouter = TabRouter.shared
    
    @State var showUpdates: Bool = false
    @State var pageIndex: Int = 0
    
    
    init() {
        persistenceController = PersistenceController.shared
        let moc = persistenceController.container.viewContext
        
        #warning("TODO: move to WM")
        UIApplication.shared.isIdleTimerDisabled = true
        

        let userDefaults = UserDefaults.standard
        
        // https://swiftui-lab.com/random-lessons/#data-10
        self._stopwatchManager = StateObject(wrappedValue: StopwatchManager(currentSession: nil, managedObjectContext: moc))
        
        
        self.moc = moc
        
        
        // check for update
        let newVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
        let currentVersion = UserDefaults.standard.string(forKey: "currentVersion")
        
        self._showUpdates = State(initialValue: currentVersion != newVersion && !showOnboarding)
        UserDefaults.standard.set(newVersion, forKey: "currentVersion")
        
        userDefaults.register(
            defaults: [
                // timer settings
                gsKeys.inspection.rawValue: false,
                gsKeys.inspectionCountsDown.rawValue: false,
                gsKeys.showCancelInspection.rawValue: true,
                gsKeys.inspectionAlert.rawValue: true,
                gsKeys.inspectionAlertType.rawValue: 0,
                
                gsKeys.freeze.rawValue: 0.5,
                gsKeys.timeDpWhenRunning.rawValue: 3,
                gsKeys.showSessionName.rawValue: false,
                
                // timer tools
                gsKeys.showScramble.rawValue: true,
                gsKeys.showStats.rawValue: true,
                
                // accessibility
                gsKeys.hapBool.rawValue: true,
                gsKeys.hapType.rawValue: UIImpactFeedbackGenerator.FeedbackStyle.rigid.rawValue,
                gsKeys.forceAppZoom.rawValue: false,
                gsKeys.appZoom.rawValue: 3,
                gsKeys.gestureDistance.rawValue: 50,
                
                // show previous time afte solve deleted
                gsKeys.showPrevTime.rawValue: false,
                
                // statistics
                gsKeys.displayDP.rawValue: 3,
                
                // colours
                asKeys.graphGlow.rawValue: true,
                
                asKeys.scrambleSize.rawValue: 18,
                asKeys.fontWeight.rawValue: 516.0,
                asKeys.fontCasual.rawValue: 0.0,
            ]
        )
    }
    
    
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .sheet(isPresented: $showUpdates, onDismiss: { showUpdates = false }) {
                    Updates(showUpdates: $showUpdates)
                }
                .sheet(isPresented: $showOnboarding, onDismiss: {
                    pageIndex = 0
                }) {
                    OnboardingView(showOnboarding: showOnboarding, pageIndex: $pageIndex)
                }
                .if(dynamicTypeSize != DynamicTypeSize.large) { view in
                    view
                        .alert(isPresented: $showUpdates) {
                            Alert(title: Text("DynamicType Detected"), message: Text("CubeTime only supports standard DyanmicType sizes. Accessibility DynamicType modes are currently not supported, so layouts may not be rendered correctly."), dismissButton: .default(Text("Got it!")))
                        }
                }
                .environment(\.managedObjectContext, moc)
                .environmentObject(stopwatchManager)
                .environmentObject(fontManager)
                .environmentObject(tabRouter)
//                .onAppear {
//                    self.deviceManager.deviceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
//                }
        }
        .onChange(of: phase) { newValue in
            switch(newValue) {
            case .background:
                stopwatchManager.addSessionQuickActions()
                break
            case .active:
                if let pendingSession = tabRouter.pendingSessionURL {
                    let url = URL(string: pendingSession as String)
                    let objID = moc.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: url!)!
                    stopwatchManager.currentSession = try! moc.existingObject(with: objID) as! Sessions
                    tabRouter.pendingSessionURL = nil
                }
            default: break
            }
        }
    }
}


private struct GlobalGeometrySize: EnvironmentKey {
    static let defaultValue: CGSize = UIScreen.main.bounds.size
}

extension EnvironmentValues {
    var globalGeometrySize: CGSize {
        get {
            self[GlobalGeometrySize.self]
            
        }
        set {
            self[GlobalGeometrySize.self] = newValue
            
        }
    }
}

struct MainView: View {
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .accentColor
    @StateObject var tabRouter: TabRouter = TabRouter.shared
    
    
    @AppStorage(asKeys.overrideDM.rawValue) private var overrideSystemAppearance: Bool = false
    @AppStorage(asKeys.dmBool.rawValue) private var darkMode: Bool = false

        
    var body: some View {
        GeometryReader { geo in
            Group {
                MainTabsView()
            }
            .tint(accentColour)
            .preferredColorScheme(overrideSystemAppearance ? (darkMode ? .dark : .light) : nil)
            .environment(\.globalGeometrySize, geo.size)
            .environmentObject(tabRouter)
        }
    }
}
