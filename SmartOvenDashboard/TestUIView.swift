//
//  TestUIView.swift
//  SmartOvenDashboard
//
//

import SwiftUI

struct Thing: Identifiable, Hashable {
    let id = UUID()
    let name: String
}


struct TestUIView: View {
    let things: [Thing] = [
        Thing(name: "One"),
        Thing(name: "Two"),
        Thing(name: "Three")
    ]
    @State var selectedThingId: UUID?
    
    var body: some View {

        NavigationSplitView {
            NavigationStack {
                sidebar
            }
            .navigationDestination(for: Thing.ID.self) { id in
                DetailView(selectedThingId: id)
            }
        } detail: {
        }
    }
    
    var sidebar: some View {
        ScrollView(.vertical) {
            LazyVStack {
                
                ForEach(things) { thing in
                    NavigationLink("Thing: \(thing.name) \( selectedThingId == thing.id ? "selected" : "" )",
                                   value: thing.id)
                }
                
                SomeOtherViewHere()
                
                NavigationLink("Navigate to something else", value: things[1].id)
            }
        }
    }
    
}

struct DetailView: View {
    let selectedThingId: Thing.ID?
    var body: some View {
        if let selectedThingId {
            Text("There is a thing ID: \(selectedThingId)")
        } else {
            Text("There is no thing.")
        }
    }
}

struct SomeOtherViewHere: View {
    var body: some View {
        Text("Some other view")
    }
}

#Preview {
    TestUIView()
}
