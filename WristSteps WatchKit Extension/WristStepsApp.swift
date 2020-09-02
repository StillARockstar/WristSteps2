//
//  WristStepsApp.swift
//  WristSteps WatchKit Extension
//
//  Created by Michael Schoder on 30.08.20.
//

import ClockKit
import SwiftUI
import Combine

@main
struct WristStepsApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(
                    HomeViewProvider(dataProvider: extensionDelegate.dataProvider)
                )
                .embedInNavigation()
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let dataProvider: DataProvider
    private let lifeCycleHandler: LifeCycleHandler
    private var stepCountPublisher: AnyCancellable

    override init() {
        #if TARGET_WATCH
        self.dataProvider = AppDataProvider()
        #else
        self.dataProvider = SimulatorDataProvider()
        #endif
        self.lifeCycleHandler = LifeCycleHandler(dataProvider: self.dataProvider)

        self.stepCountPublisher = dataProvider.healthData.stepCountPublisher
            .removeDuplicates()
            .sink { newValue in
                ComplicationPayload.shared.set(.stepCount, newValue: newValue)
                CLKComplicationServer.sharedInstance().activeComplications?.forEach {
                    CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
                }
                NSLog("New step count: \(newValue)")
            }

        super.init()
    }

    func applicationWillEnterForeground() {
        lifeCycleHandler.appWillEnterForeground()
    }

    func applicationDidEnterBackground() {
        lifeCycleHandler.appDidEnterBackground()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            lifeCycleHandler.handle(task)
        }
    }
}
