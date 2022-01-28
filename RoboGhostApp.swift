//
//  RoboGhostApp.swift
//  RoboGhost
//
//  Created by Adriano Hernandez on 1/28/22.
//

import SwiftUI
import CoreMotion

// Define constants that will be used to manage our state and how to interact with it
let LOW = 0
let HIGH = 1

let colors = [
    // Stopped
    Color.white,
    Color.green
]

let endpoints = [
    // stopped, forward, backwards, left, right
    "/L/", "/H"
]

let ARDUINO_IP:String = "http://192.168.4.1"

// This is what will be seen
struct ContentView: View {
    // Used for state
    @State var state = LOW
    @State var tics = 0
    
    // Used for rudimentary smoothing
    @State var currState = LOW
    @State var prevState = LOW
    
    @State var url = ARDUINO_IP + endpoints[LOW]
    @State var color = colors[LOW]
    
    // These are used mainly for tracking
    @State var x = 0.0
    @State var y = 0.0
    @State var z = 0.0
    @State var acc = 0.0
    
    let mm = CMMotionManager()
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init() {
        mm.startAccelerometerUpdates()
        mm.accelerometerUpdateInterval = 0.1
    }
    
    var body: some View {
        VStack {
            Text("Endpoint")
            Text("\"\(self.url)\"")
            Text("Acceleration")
            Text("x=\(self.x)")
            Text("y=\(self.y)")
            Text("z=\(self.y)")
            Text("acc=\(self.acc)")
                .onReceive(timer, perform: { _ in
                    if let data = self.mm.accelerometerData {
                        self.x = data.acceleration.x
                        self.y = data.acceleration.y
                        self.z = data.acceleration.z
                        self.acc = sqrt(x*x + y*y + z*z)
                        
                        // Within 10 tics (1 second of acceleration)
                        // You need to keep it accelerating for at least 1 second for it
                        // to trigger (you can do that by moving your arm in a circle.
                        
                        // tics thresh is used to smooth
                        let acc_thresh = 1.035
                        let tics_thresh = 6
                        
                        // Load immediate state so that we can tell if we are
                        // continuning off the previous state
                        self.currState = LOW
                        if self.acc > acc_thresh {
                            self.currState = HIGH
                        }
                        
                        // Update tics (window that we were in this state for)
                        if self.currState == self.prevState {
                            self.tics = self.tics + 1
                        } else {
                            self.tics = 1
                        }
                        
                        // Update the previous state so we can continue to smooth
                        self.prevState = self.currState
                        
                        // If we are ready to change states do so (based on tics)
                        if self.tics >= tics_thresh {
                            self.state = self.currState
                        }
                        
                        // This lets us avoid TCP spamming
                        let justSwapped:Bool = (self.tics == tics_thresh)
                        
                        
                        // Color the app based on the state
                        self.color = colors[self.state]
                        
                        // TCP GET the correct endpoint
                        if justSwapped {
                            self.url = ARDUINO_IP + endpoints[self.state]
                            
                            // please work
                            let req_url = URL(string: self.url)!
                            var request = URLRequest(url: req_url)
                            request.httpMethod = "GET"
                            let conn = NSURLConnection(request: request, delegate:nil, startImmediately: true)
                            // probably do nothing w/ con
                            print("*** URL IS \(self.url)")
                        }
                        
                    }
                })
        }.background(self.color)
    }
}

// This code is just for XCode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@main
struct RoboGhostApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
