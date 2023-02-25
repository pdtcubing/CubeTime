import SwiftUI
import CoreData



struct TimeCard: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @EnvironmentObject var stopWatchManager: StopWatchManager
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .accentColor
    
    var solve: Solves
    
    let formattedTime: String
    let pen: PenTypes
    
    @Binding var currentSolve: Solves?
    @Binding var isSelectMode: Bool
    
    @Binding var selectedSolves: Set<Solves>
    
    var isSelected = false
    
    @Environment(\.sizeCategory) var sizeCategory
    
    private var cardWidth: CGFloat {
        if sizeCategory > ContentSizeCategory.extraLarge {
            return 200
        } else if sizeCategory < ContentSizeCategory.small {
            return 100
        } else {
            return 120
        }
    }
    
    private var cardHeight: CGFloat {
        if sizeCategory > ContentSizeCategory.extraLarge {
            return 60
        } else if sizeCategory < ContentSizeCategory.small {
            return 50
        } else {
            return 55
        }
    }
    
    
    @Binding var sessionsCanMoveTo: [Sessions]?
    @State var sessionsCanMoveTo_playground: [Sessions]? = nil
    
    init(solve: Solves, currentSolve: Binding<Solves?>, isSelectMode: Binding<Bool>, selectedSolves: Binding<Set<Solves>>, sessionsCanMoveTo: Binding<[Sessions]?>? = nil) {
        self.solve = solve
        self.formattedTime = formatSolveTime(secs: solve.time, penType: PenTypes(rawValue: solve.penalty)!)
        self.pen = PenTypes(rawValue: solve.penalty)!
        self._currentSolve = currentSolve
        self._isSelectMode = isSelectMode
        self._selectedSolves = selectedSolves
        self.isSelected = selectedSolves.wrappedValue.contains(solve)
        self._sessionsCanMoveTo = sessionsCanMoveTo ?? Binding.constant(nil)
    }
    
    var body: some View {
        let sess_type = stopWatchManager.currentSession.session_type
        ZStack {
            #warning("TODO:  check operforamcne of the on tap/long hold gestures on the zstack vs the rounded rectangle")
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected
                      ? Color.Theme.grey(colourScheme, 2)
                      : colourScheme == .dark
                        ? Color(uiColor: .systemGray6)
                        : Color(uiColor: .systemBackground))
                .frame(maxWidth: cardWidth, minHeight: cardHeight, maxHeight: cardHeight)

                .onTapGesture {
                    if isSelectMode {
                        withAnimation {
                            if isSelected {
//                                isSelected = false
                                selectedSolves.remove(solve)
                            } else {
//                                isSelected = true
                                selectedSolves.insert(solve)
                            }
                        }
                    } else {
                        currentSolve = solve
                    }
                }
                .onLongPressGesture {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                
                
            VStack {
                Text(formattedTime)
                    .font(.body.weight(.bold))
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColour)
                }
            }
        }

        
//        .onChange(of: isSelectMode) {newValue in
//            if !newValue && isSelected {
//                withAnimation {
//                    isSelected = false
//                }
//            }
//        }
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 10, style: .continuous))
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in print("DRAG")}
        )
        .contextMenu {
//            Button {
//            } label: {
//                Label("Move To", systemImage: "arrow.up.forward.circle")
//            }
//
            
            
            Button {
                copySolve(solve: solve)
            } label: {
                Label {
                    Text("Copy Solve")
                } icon: {
                    Image(systemName: "doc.on.doc")
                }
            }
            
            Menu {
                Button {
                    stopWatchManager.changePen(solve: self.solve, pen: .none)
                } label: {
                    Label("No Penalty", systemImage: "checkmark.circle")
                }
                
                Button {
                    stopWatchManager.changePen(solve: self.solve, pen: .plustwo)
                } label: {
                    Label("+2", image: "+2.label")
                }
                
                Button {
                    stopWatchManager.changePen(solve: self.solve, pen: .dnf)
                } label: {
                    Label("DNF", systemImage: "xmark.circle")
                }
            } label: {
                Label("Penalty", systemImage: "exclamationmark.triangle")
            }
            
            if sess_type != SessionTypes.compsim.rawValue {
                SessionPickerMenu(sessions: sess_type == SessionTypes.playground.rawValue ? sessionsCanMoveTo_playground : sessionsCanMoveTo) { session in
                    withAnimation {
                        stopWatchManager.moveSolve(solve: solve, to: session)
                    }
                }
            }
            
            
            Divider()
            
            
            Button(role: .destructive) {
                managedObjectContext.delete(solve)
                try! managedObjectContext.save()
                stopWatchManager.tryUpdateCurrentSolveth()
                
                withAnimation {
                    stopWatchManager.delete(solve: solve)
                }
            } label: {
                Label {
                    Text("Delete Solve")
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
        .if(sess_type == SessionTypes.playground.rawValue) { view in
            view
                .task {
                    #warning("Optimize this :sob:")
                    sessionsCanMoveTo_playground = getSessionsCanMoveTo(managedObjectContext: managedObjectContext, scrambleType: solve.scramble_type, currentSession: stopWatchManager.currentSession)
                }
        }
    }
}
