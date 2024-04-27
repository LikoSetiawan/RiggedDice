//
//  MainView.swift
//  RiggedDice
//
//  Created by Liko Setiawan on 27/04/24.
//

import SwiftUI

struct MainView: View {
    let diceTypes = [4, 6, 8, 10, 12, 20, 100]
    
    @AppStorage("selectedDiceType") var selectedDiceType = 6
    @AppStorage("numberToRoll") var numberToRoll = 4
    
    @State private var currentResult = Dice(type: 0, number: 0)
    
    let timer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    @State private var stoppedDice = 0
    
    let columns: [GridItem] = [
        .init(.adaptive(minimum: 60))
    ]
    
    let savePath = URL.documentsDirectory.appending(path: "SavedRolls.json")
    @State private var savedResults = [Dice]()
    
    var body: some View {
        NavigationStack{
            Form{
                Section{
                    Picker("Type of dice", selection: $selectedDiceType) {
                        ForEach(diceTypes, id: \.self) { type in
                            Text("D\(type)")
                            
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Stepper("Number of dice: \(numberToRoll)", value: $numberToRoll, in: 1...20)
                    
                    Button("Roll Them!", action: rollDice)
                } footer: {
                    LazyVGrid(columns: columns) {
                        ForEach(0..<currentResult.rolls.count, id: \.self) { rollNumber in
                            Text(String(currentResult.rolls[rollNumber]))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .foregroundStyle(.black)
                                .background(.white)
                                .clipShape(.rect(cornerRadius: 10))
                                .shadow(radius: 3)
                                .font(.title)
                                .padding(5)
                            
                        }
                    }
                }
                .disabled(stoppedDice < currentResult.rolls.count)
                
                if savedResults.isEmpty == false {
                    Section("Previous Results") {
                        ForEach(savedResults) { result in
                            VStack(alignment: .leading) {
                                Text("\(result.number) x D\(result.type)")
                                    .font(.headline)
                                Text(result.rolls.map(String.init).joined(separator: ", "))
                            }
                        }
                    }
                }
                
                
            }
            .onReceive(timer) { date in
                updateDice()
            }
            .onAppear(perform: load)
            .sensoryFeedback(.impact, trigger: currentResult.rolls)
        }
    }
    
    func rollDice() {
        currentResult = Dice(type: selectedDiceType, number: numberToRoll)
        stoppedDice = -20
    }
    
    func updateDice() {
        guard stoppedDice < currentResult.rolls.count else { return }
        
        for i in stoppedDice..<numberToRoll {
            if i < 0 { continue }
            currentResult.rolls[i] = Int.random(in: 1...selectedDiceType)
        }
        
        stoppedDice += 1
        
        if stoppedDice == numberToRoll {
            savedResults.insert(currentResult, at: 0)
            save()
        }
        
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(savedResults) {
            try? data.write(to: savePath, options: [.atomic, .completeFileProtection])
        }
    }
    
    func load() {
        if let data = try? Data(contentsOf: savePath) {
            if let results = try? JSONDecoder().decode([Dice].self, from: data) {
                savedResults = results
            }
        }
    }
    
}

#Preview {
    MainView()
}
