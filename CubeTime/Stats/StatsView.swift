import SwiftUI
import CoreData


extension View {
    public func gradientForeground(gradientSelected: Int) -> some View {
        self.overlay(getGradient(gradientArray: CustomGradientColours.gradientColours, gradientSelected: gradientSelected))
            .mask(self)
    }
}



struct StatsBlock<Content: View>: View {
    @Environment(\.colorScheme) var colourScheme
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    let dataView: Content
    let title: String
    let blockHeight: CGFloat?
    let bigBlock: Bool
    let coloured: Bool
    
    
    
    init(_ title: String, _ blockHeight: CGFloat?, _ bigBlock: Bool, _ coloured: Bool, @ViewBuilder _ dataView: () -> Content) {
        self.dataView = dataView()
        self.title = title
        self.bigBlock = bigBlock
        self.coloured = coloured
        self.blockHeight = blockHeight
    }
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    HStack {
                        Text(title)
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .foregroundColor(Color(uiColor: coloured ? .systemGray5 : .systemGray))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 9)
                .padding(.leading, 12)
                
                dataView
            }
        }
        .frame(height: blockHeight)
        .if(coloured) { view in
            view.background(getGradient(gradientArray: CustomGradientColours.gradientColours, gradientSelected: gradientSelected)                                        .clipShape(RoundedRectangle(cornerRadius:16)))
        }
        .if(!coloured) { view in
            view.background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
        }
        .if(bigBlock) { view in
            view.padding(.horizontal)
        }
    }
}

struct StatsBlockText: View {
    @Environment(\.colorScheme) var colourScheme
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    let displayText: String
    let colouredText: Bool
    let colouredBlock: Bool
    let displayDetail: Bool
    let nilCondition: Optional<Any>
    
    init(_ displayText: String, _ colouredText: Bool, _ colouredBlock: Bool, _ displayDetail: Bool, _ nilCondition: Bool) {
        self.displayText = displayText
        self.colouredText = colouredText
        self.colouredBlock = colouredBlock
        self.displayDetail = displayDetail
        self.nilCondition = nilCondition
    }
    
    var body: some View {
        if !displayDetail {
            VStack {
                Spacer()
                
                HStack {
                    if nilCondition != nil {
                        Text(displayText)
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .modifier(DynamicText())
                        
                            .if(!colouredText) { view in
                                view.foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                            }
                            .if(colouredText) { view in
                                view.gradientForeground(gradientSelected: gradientSelected)
                            }
                    } else {
                        Text("-")
                            .font(.system(size: 28, weight: .medium, design: .default))
                            .foregroundColor(Color(uiColor: .systemGray5))
                    }
                    
                    Spacer()
                }
            }
            .padding(.bottom, 9)
            .padding(.leading, 12)
        } else {
            EmptyView()
        }
    }
}

struct StatsDivider: View {
    @Environment(\.colorScheme) var colourScheme

    var body: some View {
        Divider()
            .frame(width: UIScreen.screenWidth/2)
            .background(Color(uiColor: colourScheme == .light ? .systemGray5 : .systemGray))
    }
}



struct StatsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    
    @Binding var currentSession: Sessions
    
    @State var isShowingStatsView: Bool = false
    @State var presentedAvg: CalculatedAverage? = nil
    @State var showBestSinglePopup = false
    
    let columns = [GridItem(spacing: 10), GridItem(spacing: 10)]
    
    // best averages
    let ao5: CalculatedAverage?
    let ao12: CalculatedAverage?
    let ao100: CalculatedAverage?
    
    // current averages
    let currentAo5: CalculatedAverage?
    let currentAo12: CalculatedAverage?
    let currentAo100: CalculatedAverage?
    
    // other block calculations
    let bestSingle: Solves?
    let sessionMean: Double?
    
    
    // raw values for graphs
    let timesByDateNoDNFs: [Double]
    let timesBySpeedNoDNFs: [Double]
    
    
    // comp sim stats
    let compSimCount: Int
    let reachedTargets: Int
    
    let allCompsimAveragesByDate: [Double] // has no dnfs!!
    let allCompsimAveragesByTime: [Double]
    
    let bestCompsimAverage: CalculatedAverage?
    let currentCompsimAverage: CalculatedAverage?
    
    let currentMeanOfTen: Double?
    let bestMeanOfTen: Double?
   
    // get stats
    let stats: Stats
    
    
    
    init(currentSession: Binding<Sessions>, managedObjectContext: NSManagedObjectContext) {
        self._currentSession = currentSession
        stats = Stats(currentSession: currentSession.wrappedValue)
        
        
        self.ao5 = stats.getBestMovingAverageOf(5)
        self.ao12 = stats.getBestMovingAverageOf(12)
        self.ao100 = stats.getBestMovingAverageOf(100)
        
        self.currentAo5 = stats.getCurrentAverageOf(5)
        self.currentAo12 = stats.getCurrentAverageOf(12)
        self.currentAo100 = stats.getCurrentAverageOf(100)
        
        
        self.bestSingle = stats.getMin()
        self.sessionMean = stats.getSessionMean()
        
        
        // raw values
        self.timesByDateNoDNFs = stats.solvesNoDNFsbyDate.map { timeWithPlusTwoForSolve($0) }
        self.timesBySpeedNoDNFs = stats.solvesNoDNFs.map { timeWithPlusTwoForSolve($0) }
        
        
        // comp sim
        self.compSimCount = stats.getNumberOfAverages()
        self.reachedTargets = stats.getReachedTargets()
       
        self.allCompsimAveragesByDate = stats.getBestCompsimAverageAndArrayOfCompsimAverages().1.map { $0.average! }
        self.allCompsimAveragesByTime = self.allCompsimAveragesByDate.sorted(by: <)
        
        self.currentCompsimAverage = stats.getCurrentCompsimAverage()
        self.bestCompsimAverage = stats.getBestCompsimAverageAndArrayOfCompsimAverages().0
        
        self.currentMeanOfTen = stats.getCurrentMeanOfTen()
        self.bestMeanOfTen = stats.getBestMeanOfTen()
    }
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                    .ignoresSafeArea()
                
                ScrollView {
                    
                    VStack (spacing: 0) { /// make this lazy???
                        /// the title
                        VStack(spacing: 0) {
                            HStack (alignment: .center) {
                                Text(currentSession.name!)
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                                    .foregroundColor(Color(uiColor: .systemGray))
                                Spacer()
                                
                                Text(puzzle_types[Int(currentSession.scramble_type)].name) // TODO playground
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(Color(uiColor: .systemGray))
                            }
                        }
                        .padding(.top, -6)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        /// everything
                        VStack(spacing: 10) {
                            /// first bunch of blocks
                            if currentSession.session_type != SessionTypes.compsim.rawValue {
                                VStack(spacing: 10) {
                                    HStack (spacing: 10) {
                                        VStack (alignment: .leading, spacing: 0) {
                                            Text("CURRENT STATS")
                                                .font(.system(size: 13, weight: .medium, design: .default))
                                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                .padding(.leading, 12)
                                                .padding(.top, 10)
                                            
                                            VStack (alignment: .leading, spacing: 6) {
                                                HStack {
                                                    VStack (alignment: .leading, spacing: -4) {
                                                        
                                                        Text("AO5")
                                                            .font(.system(size: 13, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray))
                                                            .padding(.leading, 12)
                                                        
                                                        if let currentAo5 = currentAo5 {
                                                            Text(String(formatSolveTime(secs: currentAo5.average ?? 0, penType: currentAo5.totalPen)))
                                                                .font(.system(size: 24, weight: .bold, design: .default))
                                                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                .padding(.leading, 12)
                                                                .modifier(DynamicText())
                                                            
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 20, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor:.systemGray2))
                                                                .padding(.leading, 12)
                                                            
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if currentAo5 != nil {
                                                        presentedAvg = currentAo5
                                                    }
                                                }
                                                
                                                HStack {
                                                    VStack (alignment: .leading, spacing: -4) {
                                                        Text("AO12")
                                                            .font(.system(size: 13, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray))
                                                            .padding(.leading, 12)
                                                        
                                                        if let currentAo12 = currentAo12 {
                                                            Text(String(formatSolveTime(secs: currentAo12.average ?? 0, penType: currentAo12.totalPen)))
                                                                .font(.system(size: 24, weight: .bold, design: .default))
                                                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                .padding(.leading, 12)
                                                                .modifier(DynamicText())
                                                            
                                                            
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 20, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor: .systemGray2))
                                                                .padding(.leading, 12)
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                    
                                                    Spacer()
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if currentAo12 != nil {
                                                        presentedAvg = currentAo12
                                                    }
                                                }
                                                
                                                HStack {
                                                    VStack (alignment: .leading, spacing: -4) {
                                                        Text("AO100")
                                                            .font(.system(size: 13, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray))
                                                            .padding(.leading, 12)
                                                        
                                                        if let currentAo100 = currentAo100 {
                                                            Text(String(formatSolveTime(secs: currentAo100.average ?? 0, penType: currentAo100.totalPen)))
                                                                .font(.system(size: 24, weight: .bold, design: .default))
                                                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                .padding(.leading, 12)
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 20, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor: .systemGray2))
                                                                .padding(.leading, 12)
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                    
                                                    Spacer()
                                                    
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if currentAo100 != nil {
                                                        presentedAvg = currentAo100
                                                    }
                                                }
                                            }
                                            .padding(.bottom, 8)
                                        }
                                        .frame(height: 160)
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .background(Color(uiColor: .systemGray5).clipShape(RoundedRectangle(cornerRadius:16)))
                                        
                                        VStack {
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("SOLVE COUNT")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                        .padding(.bottom, 4)
                                                    
                                                    Text(String(stats.getNumberOfSolves()))
                                                        .font(.system(size: 34, weight: .bold, design: .default))
                                                        .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                }
                                                .padding(.top)
                                                .padding(.bottom, 12)
                                                .padding(.leading, 12)
                                                
                                                Spacer()
                                            }
                                            .frame(height: 75)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                            
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("SESSION MEAN")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                        .padding(.bottom, 4)
                                                    
                                                    
                                                    if sessionMean != nil {
                                                        Text(String(formatSolveTime(secs: sessionMean!)))
                                                            .font(.system(size: 34, weight: .bold, design: .default))
                                                            .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                            .modifier(DynamicText())
                                                        
                                                        
                                                        
                                                    } else {
                                                        Text("-")
                                                            .font(.system(size: 28, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray2))
                                                    }
                                                    
                                                    
                                                }
                                                .padding(.top)
                                                .padding(.bottom, 12)
                                                .padding(.leading, 12)
                                                
                                                Spacer()
                                            }
                                            .frame(height: 75)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                        }
                                        
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                Divider()
                                    .frame(width: UIScreen.screenWidth/2)
                                    .background(Color(uiColor: colourScheme == .light ? .systemGray5 : .systemGray))
                                
                                /// best statistics
                                VStack (spacing: 10) {
                                    HStack (spacing: 10) {
                                        VStack (spacing: 10) {
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("BEST SINGLE")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray5))
                                                        .padding(.bottom, 4)
                                                    
                                                    if let bestSingle = bestSingle {
                                                        Text(String(formatSolveTime(secs: bestSingle.time, penType: PenTypes(rawValue: bestSingle.penalty)!)))
                                                            .font(.system(size: 34, weight: .bold, design: .default))
                                                            .foregroundColor(Color(uiColor: colourScheme == .light ? .white : .black))
                                                    } else {
                                                        Text("-")
                                                            .font(.system(size: 28, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray5))
                                                    }
                                                }
                                                .padding(.top)
                                                .padding(.bottom, 12)
                                                .padding(.leading, 12)
                                                
                                                Spacer()
                                            }
                                            .frame(height: 75)
                                            .background(getGradient(gradientArray: CustomGradientColours.gradientColours, gradientSelected: gradientSelected)                                        .clipShape(RoundedRectangle(cornerRadius:16)))
                                            .onTapGesture {
                                                if bestSingle != nil {
                                                    showBestSinglePopup = true
                                                }
                                            }
                                            
                                            VStack (alignment: .leading, spacing: 0) {
                                                HStack {
                                                    VStack (alignment: .leading, spacing: 0) {
                                                        Text("BEST AO12")
                                                            .font(.system(size: 13, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray))
                                                            .padding(.leading, 12)
                                                        
                                                        if let ao12 = ao12 {
                                                            Text(String(formatSolveTime(secs: ao12.average ?? 0, penType: ao12.totalPen)))
                                                                .font(.system(size: 34, weight: .bold, design: .default))
                                                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                .padding(.leading, 12)
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 28, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor:.systemGray2))
                                                                .padding(.leading, 12)
                                                            
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if ao12 != nil && ao12?.totalPen != .dnf  {
                                                        presentedAvg = ao12
                                                    }
                                                }
                                                
                                                Divider()
                                                    .padding(.leading, 12)
                                                    .padding(.vertical, 4)
                                                
                                                HStack {
                                                    VStack (alignment: .leading, spacing: 0) {
                                                        Text("BEST AO100")
                                                            .font(.system(size: 13, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray))
                                                            .padding(.leading, 12)
                                                        
                                                        if let ao100 = ao100 {
                                                            Text(String(formatSolveTime(secs: ao100.average ?? 0, penType: ao100.totalPen)))
                                                                .font(.system(size: 34, weight: .bold, design: .default))
                                                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                .padding(.leading, 12)
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 28, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor: .systemGray2))
                                                                .padding(.leading, 12)
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if ao100 != nil && ao100?.totalPen != .dnf {
                                                        presentedAvg = ao100
                                                    }
                                                }
                                            }
                                            .frame(height: 130)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                            
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        
                                        VStack (spacing: 10) {
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("BEST AO5")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                        .padding(.bottom, 4)
                                                    
                                                    if let ao5 = ao5 {
                                                        Text(formatSolveTime(secs: ao5.average ?? 0, penType: ao5.totalPen))
                                                            .font(.system(size: 34, weight: .bold, design: .default))
                                                            .gradientForeground(gradientSelected: gradientSelected)
                                                        
                                                        Spacer()
                                                        
                                                        if let accountedSolves = ao5.accountedSolves {
                                                        
                                                            ForEach(accountedSolves, id: \.self) { solve in
                                                                if ao5.trimmedSolves!.contains(solve) {
                                                                    Text("("+formatSolveTime(secs: solve.time,
                                                                                             penType: PenTypes(rawValue: solve.penalty))+")")
                                                                        .font(.system(size: 17, weight: .regular, design: .default))
                                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                                        .multilineTextAlignment(.leading)
                                                                        .padding(.bottom, 2)
                                                                } else {
                                                                    Text(formatSolveTime(secs: solve.time,
                                                                                         penType: PenTypes(rawValue: solve.penalty)))
                                                                        .font(.system(size: 17, weight: .regular, design: .default))
                                                                        .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                        .multilineTextAlignment(.leading)
                                                                        .padding(.bottom, 2)
                                                                }
                                                            }
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 28, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor: .systemGray2))
                                                            
                                                            Spacer()
                                                        }
                                                        
                                                        
                                                        
                                                    } else {
                                                        Text("-")
                                                            .font(.system(size: 28, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray2))
                                                        
                                                        Spacer()
                                                    }
                                                }
                                                .padding(.top, 10)
                                                .padding(.bottom, 10)
                                                .padding(.leading, 12)
                                                
                                                
                                                
                                                Spacer()
                                            }
                                            .frame(height: 215)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                            .onTapGesture {
                                                if ao5 != nil && ao5?.totalPen != .dnf {
                                                    presentedAvg = ao5
                                                }
                                            }
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                Divider()
                                    .frame(width: UIScreen.screenWidth/2)
                                    .background(Color(uiColor: colourScheme == .light ? .systemGray5 : .systemGray))
                            } else {
                                VStack (spacing: 10) {
                                    HStack (spacing: 10) {
                                        VStack (spacing: 10) {
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("CURRENT AVG")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                        .padding(.bottom, 4)
                                                    
                                                    if let currentCompsimAverage = currentCompsimAverage {
                                                        Text(formatSolveTime(secs: currentCompsimAverage.average ?? 0, penType: currentCompsimAverage.totalPen))
                                                            .font(.system(size: 34, weight: .bold, design: .default))
                                                            .foregroundColor(colourScheme == .light ? .black : .white)
                                                            .modifier(DynamicText())
                                                        
                                                        Spacer()
                                                        
                                                        if let accountedSolves = currentCompsimAverage.accountedSolves {
                                                        
                                                            let alltimes = accountedSolves.map{timeWithPlusTwoForSolve($0)}
                                                            ForEach((0...4), id: \.self) { index in
                                                                if timeWithPlusTwoForSolve(accountedSolves[index]) == alltimes.min() || timeWithPlusTwoForSolve(accountedSolves[index]) == alltimes.max() {
                                                                    Text("("+formatSolveTime(secs: accountedSolves[index].time,
                                                                                             penType: PenTypes(rawValue: accountedSolves[index].penalty))+")")
                                                                        .font(.system(size: 17, weight: .regular, design: .default))
                                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                                        .multilineTextAlignment(.leading)
                                                                        .padding(.bottom, 2)
                                                                } else {
                                                                    Text(formatSolveTime(secs: accountedSolves[index].time,
                                                                                         penType: PenTypes(rawValue: accountedSolves[index].penalty)))
                                                                        .font(.system(size: 17, weight: .regular, design: .default))
                                                                        .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                                        .multilineTextAlignment(.leading)
                                                                        .padding(.bottom, 2)
                                                                }
                                                            }
                                                        } else {
                                                            Text("-")
                                                                .font(.system(size: 28, weight: .medium, design: .default))
                                                                .foregroundColor(Color(uiColor: .systemGray2))
                                                            
                                                            Spacer()
                                                        }
                                                        
                                                        
                                                        
                                                    } else {
                                                        Text("-")
                                                            .font(.system(size: 28, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray2))
                                                        
                                                        Spacer()
                                                    }
                                                }
                                                .onTapGesture {
                                                    if currentCompsimAverage != nil && currentCompsimAverage?.totalPen != .dnf  {
                                                        presentedAvg = currentCompsimAverage
                                                    }
                                                }
                                                .padding(.top, 10)
                                                .padding(.bottom, 10)
                                                .padding(.leading, 12)
                                                
                                                
                                                
                                                Spacer()
                                            }
                                            .frame(height: 215)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                            
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("AVERAGES")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                        .padding(.bottom, 4)
                                                    
                                                    
                                                    Text("\(compSimCount)")
                                                        .font(.system(size: 34, weight: .bold, design: .default))
                                                        .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                    
                                                }
                                                .padding(.top)
                                                .padding(.bottom, 12)
                                                .padding(.leading, 12)
                                                
                                                Spacer()
                                            }
                                            .frame(height: 75)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        
                                        
                                        VStack (spacing: 10) {
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("BEST SINGLE")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray))
                                                        .padding(.bottom, 4)
                                                    
                                                    if bestSingle != nil {
                                                        Text(String(formatSolveTime(secs: bestSingle!.time)))
                                                            .font(.system(size: 34, weight: .bold, design: .default))
                                                            .gradientForeground(gradientSelected: gradientSelected)
                                                            .modifier(DynamicText())
                                                        
                                                    } else {
                                                        Text("-")
                                                            .font(.system(size: 28, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray2))
                                                    }
                                                }
                                                .padding(.top)
                                                .padding(.bottom, 12)
                                                .padding(.leading, 12)
                                                
                                                Spacer()
                                            }
                                            .frame(height: 75)
                                            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                            .onTapGesture {
                                                if bestSingle != nil {
                                                    showBestSinglePopup = true
                                                }
                                            }
                                            
                                            HStack {
                                                VStack (alignment: .leading, spacing: 0) {
                                                    Text("BEST AVG")
                                                        .font(.system(size: 13, weight: .medium, design: .default))
                                                        .foregroundColor(Color(uiColor: .systemGray5))
                                                        .padding(.bottom, 4)
                                                    
                                                    if let bestCompsimAverage = bestCompsimAverage {
                                                        Text(formatSolveTime(secs: bestCompsimAverage.average ?? 0, penType: bestCompsimAverage.totalPen))
                                                            .foregroundColor(.white)
                                                            .font(.system(size: 34, weight: .bold, design: .default))
                                                            .modifier(DynamicText())
                                                        
                                                        Spacer()
                                                        
                                                        
                                                        if let accountedSolves = bestCompsimAverage.accountedSolves {
                                                            let alltimes = accountedSolves.map{timeWithPlusTwoForSolve($0)}
                                                            ForEach((0...4), id: \.self) { index in
                                                                if timeWithPlusTwoForSolve(accountedSolves[index]) == alltimes.min() || timeWithPlusTwoForSolve(accountedSolves[index]) == alltimes.max() {
                                                                    Text("("+formatSolveTime(secs: accountedSolves[index].time,
                                                                                             penType: PenTypes(rawValue: accountedSolves[index].penalty))+")")
                                                                        .font(.system(size: 17, weight: .regular, design: .default))
                                                                        .foregroundColor(Color(uiColor: .systemGray5))
                                                                        .multilineTextAlignment(.leading)
                                                                        .padding(.bottom, 2)
                                                                } else {
                                                                    Text(formatSolveTime(secs: accountedSolves[index].time,
                                                                                         penType: PenTypes(rawValue: accountedSolves[index].penalty)))
                                                                        .font(.system(size: 17, weight: .regular, design: .default))
                                                                        .foregroundColor(.white)
                                                                        .multilineTextAlignment(.leading)
                                                                        .padding(.bottom, 2)
                                                                }
                                                            }
                                                            
                                                        }
                                                        
                                                        
                                                        
                                                    } else {
                                                        Text("-")
                                                            .font(.system(size: 28, weight: .medium, design: .default))
                                                            .foregroundColor(Color(uiColor: .systemGray5))
                                                        
                                                        Spacer()
                                                    }
                                                }
                                                .padding(.top, 10)
                                                .padding(.bottom, 10)
                                                .padding(.leading, 12)
                                                
                                                
                                                
                                                Spacer()
                                            }
                                            .frame(height: 215)
                                            .background(getGradient(gradientArray: CustomGradientColours.gradientColours, gradientSelected: gradientSelected)                                        .clipShape(RoundedRectangle(cornerRadius:16)))
                                            .onTapGesture {
                                                if bestCompsimAverage != nil && bestCompsimAverage?.totalPen != .dnf {
                                                    presentedAvg = bestCompsimAverage
                                                }
                                            }
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        
                                        
                                    }
                                    .padding(.horizontal)
                                }
                                
                                StatsDivider()
                                
                                HStack(spacing: 10) {
                                    StatsBlock("TARGET", 75, false, false) {
                                        StatsBlockText(formatSolveTime(secs: (currentSession as! CompSimSession).target, dp: 2), false, false, false, true)
                                    }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    StatsBlock("REACHED", 75, false, false) {
                                        StatsBlockText("\(reachedTargets)/\(compSimCount)", false, false, false, (bestSingle != nil))
                                    }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                                
                                
                                StatsBlock("REACHED TARGETS", compSimCount == 0 ? 150 : 50, true, false) {
                                    if compSimCount != 0 {
                                        ReachedTargets(Float(reachedTargets)/Float(compSimCount))
                                            .padding(.horizontal, 12)
                                            .offset(y: 30)
                                    } else {
                                        Text("not enough solves to\ndisplay graph")
                                            .font(.system(size: 17, weight: .medium, design: .monospaced))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(uiColor: .systemGray))
                                    }
                                }
                                
                                StatsDivider()
                            }
                            
                            
                            /// average phases if multiphase session
                            if SessionTypes(rawValue: currentSession.session_type)! == .multiphase {
                                VStack {
                                    ZStack {
                                        VStack {
                                            HStack {
                                                Text("AVERAGE PHASES")
                                                    .font(.system(size: 13, weight: .medium, design: .default))
                                                    .foregroundColor(Color(uiColor: .systemGray))
                                                Spacer()
                                            }
                                            
                                            if timesBySpeedNoDNFs.count >= 1 {
                                                VStack (spacing: 8) {
                                                    Capsule()
                                                        .frame(height: 10)
                                                    
                                                    ForEach(0...4, id: \.self) { phase in
                                                        HStack (spacing: 16) {
                                                            Circle()
                                                                .frame(width: 10, height: 10)
                                                            
                                                            HStack (spacing: 8) {
                                                                Text("Phase \(phase):")
                                                                    .font(.system(size: 17, weight: .medium))
                                                                
                                                                Text("1.50")
                                                                    .font(.system(size: 17))
                                                                
                                                                Text("(25%)")
                                                                    .foregroundColor(Color(uiColor: .systemGray))
                                                                    .font(.system(size: 17))
                                                            }
                                                            
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 2)
                                                .padding(.top, -2)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(12)
                                        
                                        if timesBySpeedNoDNFs.count == 0 {
                                            Text("not enough solves to\ndisplay graph")
                                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Color(uiColor: .systemGray))
                                        }
                                    }
                                }
                                .frame(height: timesBySpeedNoDNFs.count == 0 ? 150 : 200)
                                .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                .padding(.horizontal)
                                
                                
                                StatsDivider()
                            }
                            
                            
                            if SessionTypes(rawValue: currentSession.session_type)! == .compsim {
                                
                                
                                HStack(spacing: 10) {
                                    StatsBlock("CURRENT MO10 AO5", 75, false, false) {
                                        StatsBlockText(formatSolveTime(secs: currentMeanOfTen!, penType: ((currentMeanOfTen == -1) ? .dnf : .none)), false, false, false, (currentMeanOfTen != nil))
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    StatsBlock("BEST MO10 AO5", 75, false, false) {
                                        StatsBlockText(formatSolveTime(secs: bestMeanOfTen!, penType: ((bestMeanOfTen == -1) ? .dnf : .none)), false, false, false, (bestMeanOfTen != nil))
                                    }
                                }
                                .padding(.horizontal)
                                
                                
                                
                                // mean of 10 calculations
                                HStack (spacing: 10) {
                                    HStack {
                                        VStack (alignment: .leading, spacing: 0) {
                                            Text("CURRENT MO10 AO5")
                                                .font(.system(size: 13, weight: .medium, design: .default))
                                                .foregroundColor(Color(uiColor: .systemGray))
                                                .padding(.bottom, 4)
                                            
                                            if let currentMeanOfTen = currentMeanOfTen {
                                                Text(formatSolveTime(secs: currentMeanOfTen, penType: ((currentMeanOfTen == -1) ? .dnf : .none)))
                                                    .font(.system(size: 34, weight: .bold, design: .default))
                                                    .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                                    
                                            } else {
                                                Text("-")
                                                    .font(.system(size: 28, weight: .medium, design: .default))
                                                    .foregroundColor(Color(uiColor: .systemGray5))

                                            }
                                            
                                        }
                                        .padding(.top)
                                        .padding(.bottom, 12)
                                        .padding(.leading, 12)
                                        
                                        Spacer()
                                    }
                                    .frame(height: 75)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                    
                                    HStack {
                                        VStack (alignment: .leading, spacing: 0) {
                                            Text("BEST MO10 AO5")
                                                .font(.system(size: 13, weight: .medium, design: .default))
                                                .foregroundColor(Color(uiColor: .systemGray))
                                                .padding(.bottom, 4)
                                            
                                            if let bestMeanOfTen = bestMeanOfTen {
                                                Text(formatSolveTime(secs: bestMeanOfTen, penType: ((bestMeanOfTen == -1) ? .dnf : .none)))
                                                    .font(.system(size: 34, weight: .bold, design: .default))
                                                    .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                            } else {
                                                Text("-")
                                                    .font(.system(size: 28, weight: .medium, design: .default))
                                                    .foregroundColor(Color(uiColor: .systemGray5))
                                            }
                                            
                                        }
                                        .padding(.top)
                                        .padding(.bottom, 12)
                                        .padding(.leading, 12)
                                        
                                        Spacer()
                                    }
                                    .frame(height: 75)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:16)))
                                    
                                }
                                .padding(.horizontal)
                                
                                StatsDivider()
                                
                                StatsBlock("TIME TREND", (allCompsimAveragesByDate.count < 2 ? 150 : 300), true, false) {
                                    TimeTrend(data: allCompsimAveragesByDate, title: nil, style: ChartStyle(.white, .black, Color.black.opacity(0.24)))
                                        .frame(width: UIScreen.screenWidth - (2 * 16) - (2 * 12))
                                        .padding(.horizontal, 12)
                                        .offset(y: -5)
                                        .drawingGroup()
                                }
                            
                                StatsBlock("TIME DISTRIBUTION", (allCompsimAveragesByTime.count < 4 ? 150 : 300), true, false) {
                                    TimeDistribution(currentSession: $currentSession, solves: allCompsimAveragesByTime)
                                        .drawingGroup()
                                }
                            } else {
                                StatsBlock("TIME TREND", (timesByDateNoDNFs.count < 2 ? 150 : 300), true, false) {
                                    TimeTrend(data: timesByDateNoDNFs, title: nil, style: ChartStyle(.white, .black, Color.black.opacity(0.24)))
                                        .frame(width: UIScreen.screenWidth - (2 * 16) - (2 * 12))
                                        .padding(.horizontal, 12)
                                        .offset(y: -5)
                                        .drawingGroup()
                                }
                                
                                StatsBlock("TIME DISTRIBUTION", (allCompsimAveragesByTime.count < 4 ? 150 : 300), true, false) {
                                    TimeDistribution(currentSession: $currentSession, solves: timesBySpeedNoDNFs)
                                        .drawingGroup()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Your Solves")
                .safeAreaInset(edge: .bottom, spacing: 0) {RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.clear).frame(height: 50).padding(.top).padding(.bottom, SetValues.hasBottomBar ? 0 : nil)}
                .sheet(item: $presentedAvg) { item in
                    StatsDetail(solves: item, session: currentSession)
                }
                .sheet(isPresented: $showBestSinglePopup) {
                    TimeDetail(solve: bestSingle!, currentSolve: nil, timeListManager: nil) // TODO make delete work from here
                    // maybe pass stats object and make it remove min
                }
            }
        }
    }
}
