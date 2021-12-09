//
//  SettingsView.swift
//  txmer
//
//  Created by Reagan Bohan on 11/25/21.
//

import SwiftUI
import SwiftUICharts


@available(iOS 15.0, *)
struct SettingsView: View {
    @State var currentCard: SettingsCardInfo = settingsCards[0]
    @State var showingCard = false // TODO try make the above one optional
    
    @Namespace private var namespace
    
    let settingsColumns = [
        GridItem(spacing: 16),
        GridItem()
    ]
    
    
    var body: some View {
        
        if !showingCard {
            NavigationView {
                ZStack {
                    Color(UIColor.systemGray6)
                        .ignoresSafeArea()
                    
                    //NavigationLink("", destination: GeneralSettingsView(), isActive: $showingCard)
                    
                    VStack (spacing: 16) {
                        
                        
                        HStack (spacing: 16) {
                            SettingsCard(currentCard: $currentCard, showingCard: $showingCard, info: settingsCards[0], namespace: namespace)
                            SettingsCard(currentCard: $currentCard, showingCard: $showingCard, info: settingsCards[1], namespace: namespace)
                        }
                        
                        HStack (spacing: 16) {
                            SettingsCard(currentCard: $currentCard, showingCard: $showingCard, info: settingsCards[2], namespace: namespace)
                            SettingsCard(currentCard: $currentCard, showingCard: $showingCard, info: settingsCards[3], namespace: namespace)
                        }
                        
                        
                        Spacer()
                        
                        
                        
                    }
                    .navigationTitle("Settings")
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                            .frame(height: 50)
                            .padding(.top)
                    }
                    .padding([.top, .bottom], 6)
                    .padding(.leading)
                    .padding(.trailing)
                }
            }
        } else {
            SettingsDetail(showingCard: $showingCard, currentCard: $currentCard, namespace: namespace)
        }
    }
}


struct SettingsCard: View {
    @Binding var currentCard: SettingsCardInfo
    @Binding var showingCard: Bool
    var info: SettingsCardInfo
    var namespace: Namespace.ID
    var body: some View {
        VStack {
            HStack {
                Text(info.name)
                    .font(.system(size: 22, weight: .bold))
                    .matchedGeometryEffect(id: info.name, in: namespace)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                Spacer()
            }
            
            Spacer()
            
            HStack {
                                                   
                Image(systemName: info.icon)
                    .font(info.iconStyle)
                    .matchedGeometryEffect(id: info.icon, in: namespace)
                    .padding(12)
                
                Spacer()
            }
        }
        .frame(height: UIScreen.screenHeight/3.5, alignment: .center)
        .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 16)))
        .matchedGeometryEffect(id: "bg " + info.name, in: namespace)
        .onTapGesture {
            withAnimation {
                currentCard = info
                showingCard = true
            }
        }
    }
}

@available(iOS 15.0, *)
struct SettingsDetail: View {
    @Binding var showingCard: Bool
    @Binding var currentCard: SettingsCardInfo
    var namespace: Namespace.ID
    
    var body: some View {
        if showingCard {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()

                VStack {
                        
                    HStack {
                        Text(currentCard.name)
                            .font(.system(size: 22, weight: .bold))
                            .matchedGeometryEffect(id: currentCard.name, in: namespace)
                        
                        Spacer()
                        
                        Image(systemName: currentCard.icon)
                            .font(currentCard.iconStyle)
                            .matchedGeometryEffect(id: currentCard.icon, in: namespace)
                        
                    }
                    .background(Color.white)
                    .matchedGeometryEffect(id: "bg " + currentCard.name, in: namespace)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    
                    switch currentCard.name {
                    case "About":
                        AboutSettingsView()
                    default:
                        Text("hi")
                    }
                    Spacer()
                }
            }
        }
    }
}

