//
//  InterfaceController.swift
//  watchtest WatchKit Extension
//
//  Created by user on 4/28/19.
//  Copyright © 2019 user. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion
import HealthKit


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("Workout error")
    }
    
    func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currenQuery = query
            healthStore.execute(query)
        } else {
            print("cannot start")
        }
    }
    
    func workoutDidEnd(_ date : Date) {
        healthStore.stop(self.currenQuery!)
        session = nil
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
        }
    }
    func startWorkout() {
        
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .crossTraining
        workoutConfiguration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
            session?.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        healthStore.start(self.session!)
    }
    @IBAction func startBtnTapped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            if let workout = self.session {
                healthStore.end(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
            startWorkout()
        }
        
    }
    
    let motionManager = CMMotionManager()
    let wcsession = WCSession.default
    let healthStore = HKHealthStore()
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    // define the activity type and location
    var session : HKWorkoutSession?
    let heartRateUnit = HKUnit(from: "count/min")
    //var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    var currenQuery : HKQuery?
//    var timer: Timer!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        if WCSession.isSupported() {

            wcsession.delegate = self as? WCSessionDelegate
            wcsession.activate()
            print("From Watch WCSession done!")
        }
        
        if HKHealthStore.isHealthDataAvailable() {
            // Add code to use HealthKit here.
            print("HealthKit Available")
            func observerHeartRateSamples() {
                let heartRateSampleType = HKObjectType.quantityType(forIdentifier: .heartRate)
                
                if let observerQuery = observerQuery {
                    healthStore.stop(observerQuery)
                }
                
                let observerQuery = HKObserverQuery(sampleType: heartRateSampleType!, predicate: nil) { (_, _, error) in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    
                    self.fetchLatestHeartRateSample { (sample) in
                        guard let sample = sample else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            let heartRate = sample.quantity.doubleValue(for: self.heartRateUnit)
                            print("Heart Rate Sample: \(heartRate)")
                            self.updateHeartRate(heartRateValue: heartRate)
                        }
                    }
                }
                
                healthStore.execute(observerQuery)
            }
            

        }
        
        motionManager.startAccelerometerUpdates()
//        motionManager.startGyroUpdates()
//        motionManager.startMagnetometerUpdates()
//        motionManager.startDeviceMotionUpdates()
        
        let timer = Timer.scheduledTimer(timeInterval: 3.0,target:self,selector:#selector(updatee),userInfo:nil,repeats: true)
        
    }
    func fetchLatestHeartRateSample(completionHandler: @escaping (_ sample: HKQuantitySample?) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            completionHandler(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType,
                                  predicate: predicate,
                                  limit: Int(HKObjectQueryNoLimit),
                                  sortDescriptors: [sortDescriptor]) { (_, results, error) in
                                    if let error = error {
                                        print("Error: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    completionHandler(results?[0] as? HKQuantitySample)
        }
        
        healthStore.execute(query)
    }
    @objc func updatee() {
        if let accelerometerData = motionManager.accelerometerData {
            print(accelerometerData.acceleration)
            if wcsession.isReachable{
                print("isReachable")
                wcsession.sendMessage(["x":String(accelerometerData.acceleration.x),"y":String(accelerometerData.acceleration.y),"z":String(accelerometerData.acceleration.z)], replyHandler: {replyMessage in print(replyMessage["reply"])}, errorHandler: { (error) in
                    print("Error sending message: %@", error)
                })
            } else {
                print("iPhone is not Reachable")
            }

        }
//        if let gyroData = motionManager.gyroData {
//            print(gyroData)
//        }
//        if let magnetometerData = motionManager.magnetometerData {
//            print(magnetometerData)
//        }
//        if let deviceMotion = motionManager.deviceMotion {
//            print(deviceMotion)
//        }
    }
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    

}
extension InterfaceController: WCSessionDelegate {
    
    // 4: Required stub for delegating session
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
}
