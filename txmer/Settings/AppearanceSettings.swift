import SwiftUI


struct settingsBlocks: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3))
    }
}

enum asKeys: String {
    case accentColour, overrideDM, dmBool, staticGradient, gradientSelected
}


struct AppearanceSettingsView: View {
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
//    @State private var accentColour: Color = .indigo
    let accentColours: [Color] = [.cyan, .blue, .indigo, .purple, .red]
    
    @State var showThemeOptions: Bool = false
    
    private let columns = [
        GridItem(spacing: 16),
        GridItem(spacing: 16)
    ]
    
    @AppStorage(asKeys.overrideDM.rawValue) private var overrideSystemAppearance: Bool = false
    @AppStorage(asKeys.dmBool.rawValue) private var darkMode: Bool = false
    
    @AppStorage(asKeys.staticGradient.rawValue) private var staticGradient: Bool = true
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    
    var body: some View {
        VStack(spacing: 16) {
            VStack {
                HStack {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AccentColor"))
                    Text("Colours")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    
                    Spacer()
                }
                .padding([.horizontal, .top], 10)
                .padding(.bottom)
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Accent Colour")
                            .font(.system(size: 17, weight: .medium))
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        HStack(spacing: 6) {
                            ForEach(accentColours, id: \.self) { colour in
                                ZStack {
                                    
                                    Circle()
                                        .strokeBorder(colour.opacity(0.25), lineWidth: (colour == accentColour) ? 2 : 0)
//                                            .strokeBorder(colour.opacity(0.25), lineWidth: 2)
                                        .frame(width: 31, height: 31)
                                     
                                    
                                    
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(colour)
                                        .font(.system(size: 24))
                                        .shadow(color: (colour == accentColour) ? .black.opacity(0.16) : .clear, radius: 6, x: 0, y: 2)
                                        .drawingGroup()
                                        .onTapGesture {
                                            accentColour = colour
                                        }
    //                                    .padding(.horizontal, 3)
                                    
                                    if colour == accentColour {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            ColorPicker("", selection: $accentColour, supportsOpacity: false)
                            
                        }
                        .padding(.bottom, 4)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            Text("Theme")
                                .font(.system(size: 17, weight: .medium))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(uiColor: .systemGray3))
                                .rotationEffect(.degrees(showThemeOptions ? 90 : 0))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showThemeOptions.toggle()
                            }
                            
                        }
                        .padding(.horizontal)
                        
                        
                        if !showThemeOptions {
                            Text("Customise the app theme and gradients.\nYou can also add a custom background image if you wish.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(uiColor: .systemGray))
                                .multilineTextAlignment(.leading)
                                .padding(.leading)
                                .padding(.bottom, 12)
                                .padding(.top, 10)
                                .padding(.trailing)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                
                                
                                
                                
                                HStack {
                                    Toggle(isOn: $staticGradient) {
                                        Text("Use Static Gradient")
                                            .font(.system(size: 17, weight: .medium))
                                    }
                                        .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                                    
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                
                                Text("By default, the gradient is dynamic and changes throughout the day. If turned off, the gradient will only be of static colours.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(uiColor: .systemGray))
                                    .multilineTextAlignment(.leading)
                                    .padding(.leading)
                                    .padding(.bottom, 12)
                                    .padding(.trailing)
                                
                                if staticGradient {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(CustomGradientColours.gradientColours, id: \.self) { gradient in
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
//                                                Rectangle()
                                                    .fill(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .topLeading, endPoint: .bottomTrailing))
                                                    .frame(height: 50)
                                                    .onTapGesture {
                                                        gradientSelected = CustomGradientColours.gradientColours.firstIndex(of: gradient)!
                                                        let _ = NSLog("\(gradient)")
                                                    }
                                                if CustomGradientColours.gradientColours[gradientSelected] == gradient {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 15, weight: .black))
                                                        .foregroundColor(.white)
                                                }
                                                
                                                    
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom)

                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: Color.black.opacity(colourScheme == .light ? 0.06 : 0), radius: 6, x: 0, y: 3))
            
            VStack {
                HStack {
                    Image(systemName: "command")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AccentColor"))
                    Text("System Settings")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    
                    Spacer()
                }
                .padding([.horizontal, .top], 10)
                .padding(.bottom)
                
                VStack(spacing: 0) {
                    HStack {
                        Toggle(isOn: $overrideSystemAppearance) {
                            Text("Override System Appearance")
                                .font(.system(size: 17, weight: .medium))
                        }
                            .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    if overrideSystemAppearance {
                        HStack {
                            Toggle(isOn: $darkMode) {
                                Text("Dark Mode")
                                    .font(.system(size: 17, weight: .medium))
                            }
                                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                        }
                        .padding(.horizontal)
                    }
                        
                        
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    
                    HStack(alignment: .center) {
                        Text("App Icon")
                            .font(.system(size: 17, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(uiColor: .systemGray3))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .onTapGesture {
                        print("go to app icon selection page")
                    }
                    
                    
                    
                }
                
            }
            .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: Color.black.opacity(colourScheme == .light ? 0.06 : 0), radius: 6, x: 0, y: 3))
        }
        .padding(.horizontal)
        .preferredColorScheme(overrideSystemAppearance ? darkMode ? .dark : .light : nil)
    }
}
