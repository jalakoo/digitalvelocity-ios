//
//  Analytics.swift
//  DigitalVelocity
//
//  Created by Jason Koo on 2/22/16.
//  Copyright © 2016 Tealium. All rights reserved.
//

import Foundation
import TealiumIOS

public let asKeyAppName = "app_name"
public let asKeyIsAppActive = "is_app_active"
public let asKeyEventName = "event_name"
public let asKeyEmail = "email"
public let asKeyBeaconId = "beacon_id"
public let asKeyBeaconRssi = "beacon_rssi"
public let asKeyBeaconDetectionDisabled = "beacon_detection_disabled"
public let asKeyParseChannel = "parse_channel"
public let asKeyScreenTitle = "screen_title"
public let asValueEnterPOI = "enter_poi"
public let asValueExitPOI = "exit_poi"
public let asValueInPOI = "in_poi"
public let asValueLaunch = "m_launch"
public let asValueSleep = "m_sleep"
public let asValueTap = "m_tap"
public let asValueWake = "m_wake"
public let asValueViewChange = "m_view"
public let asValueChatSent = "chat_sent"

public let tealiumBGInstanceID = "tealium"
public let tealiumDemoInstanceID = "demo"
public let tealiumDemoUserDefaultsConfigKey = "com.tealium.demo.config"

public let tealiumAccountKey = "account"
public let tealiumProfileKey = "profile"
public let tealiumEnvironmentKey = "environment"
public let tealiumDemoTraceIdKey = "com.tealium.demo.traceId"

class Analytics {
    
    class func updateTealiumDemoInstance(account: String, profile: String, environment: String) -> Bool{
        
        // Enable, disable or update Demo Instance
        let submissionDict  = [tealiumAccountKey : account,
            tealiumProfileKey: profile ,
            tealiumEnvironmentKey: environment] as NSDictionary!
        
        // Stop if no change in demo settings
        if let demoDict = Analytics.currentDemoConfig(){
            
            if (submissionDict.isEqualToDictionary(demoDict)) {
                TEALLog.log("subissiondictionary equals demoDictionary")
                return false
            }
        }
        
        // Save new demo settings
        var savedConfig = [String: AnyObject]()
        
        savedConfig[tealiumDemoUserDefaultsConfigKey] = submissionDict
        
        NSUserDefaults.standardUserDefaults().setValuesForKeysWithDictionary(savedConfig)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Reset demo instance
        Tealium.destroyInstanceForKey(tealiumDemoInstanceID)
        
        setupTealiumDemoInstance()
        
        print(currentDemoConfig)
        
        return true
        
    }
    
    class func updateDemoTraceId(traceId: String?) -> Bool {
        
        // Convert nil to empty string, if needed
        var traceString = ""
        if let traceId = traceId {
            traceString = traceId
        }
        
        // Stop if update trace id equals existing
        if let currentTraceId = self.currentTraceId()  {
            
            if currentTraceId == traceString {
                return false
            }
            
        }
        
        // Enable or disable Trace
        if traceString != ""  {
            Analytics.startTrace(traceString)
            print(traceString)
            
        }else{
            
            Analytics.stopTrace()
        }
        
        // Save update to persistence
        NSUserDefaults.standardUserDefaults().setValue(traceString, forKey: tealiumDemoTraceIdKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        return true
    }
    
    
    // MARK: LIFECYCLE
    
    class func wake(application:UIApplication){
        
        Analytics.track(asValueWake, isView: false, data: nil)
    }
    
    class func sleep(){

        Analytics.track(asValueSleep, isView: false, data: nil)
    }
    
    class func launch(application: UIApplication, launchOptions:[NSObject: AnyObject]?){
        
        // TRACKING
        if (User.sharedInstance.optInTracking){
            
            Analytics.setupTealium()
            
        }
        
        // Kick up prior trace
        if let tid = Analytics.currentTraceId(){
            Analytics.startTrace(tid)
        } else {
            Analytics.stopTrace()
        }
    }
    
    
    // MARK: INIT
    
    class private func setupTealium() {
        
        self.setupTealiumBGInstance()
        self.setupTealiumDemoInstance()
        
    }
    
    private class func setupTealiumBGInstance() {
        
        let account = TEALCredentials.idFor(TealiumAccount)
        let profile = TEALCredentials.idFor(TealiumProfile)
        let env = TEALCredentials.idFor(TealiumEnv)
        
        let config = TEALConfiguration.init(account: account, profile: profile, environment: env)
        
        Tealium.newInstanceForKey(tealiumBGInstanceID, configuration: config)
    }
    
    private class func setupTealiumDemoInstance() {
        
        guard let demoConfig = self.currentDemoConfig()else{
            
            return
        }
        
        guard let account = demoConfig[tealiumAccountKey] as? String else {
            
            // TODO: error handling
            
            return
        }
        
        guard let profile = demoConfig[tealiumProfileKey] as? String else {
            
            // TODO: error handling
            
            return
        }
        
        guard let environment = demoConfig[tealiumEnvironmentKey] as? String else {
            
            // TODO: error handling
            
            return
        }
        
        let config = TEALConfiguration.init(account: account, profile: profile, environment: environment)
        
        Tealium.newInstanceForKey(tealiumDemoInstanceID, configuration: config)
        
        
    }

    
    // MARK: ACCESSORS
    
    
    class func currentDemoInstance() -> Tealium? {
        
        // For testing
        
        return Tealium.instanceForKey(tealiumDemoInstanceID)
        
    }
    
    
    class func currentDemoConfig()-> [NSObject: AnyObject]? {
        
        let userPreferences = NSUserDefaults.standardUserDefaults()
        
        guard let demoConfig = userPreferences.dictionaryForKey(tealiumDemoUserDefaultsConfigKey)  else {
            
            // TODO: error handling
            
            return nil
        }
        return demoConfig
    }
    
    class func currentTraceId() -> String? {
        
        let userPreferences = NSUserDefaults.standardUserDefaults()
        
        guard let traceId = userPreferences.valueForKey(tealiumDemoTraceIdKey) as? String else {
            
            // TODO: error handling
            
            return nil
        }
        return traceId
        
    }
    
    class func destroyDemoInstance() {
        
        // For testing
        
        Tealium.destroyInstanceForKey(tealiumDemoInstanceID)

    }
    
    
    // MARK: TRACE
    
    class func startTrace(traceId:String){
        guard let demoInstance = Tealium.instanceForKey(tealiumDemoInstanceID) else{
            return
        }
        
        demoInstance.joinTraceWithToken(traceId)
    }
    
    class func stopTrace(){
        guard let demoInstance = Tealium.instanceForKey(tealiumDemoInstanceID) else{
            return
        }
        demoInstance.leaveTrace()
    }
    
    
    // MARK: TRACKING
    
    class func trackView(viewController: UIViewController){
        Analytics.trackView(viewController, data: nil)
    }
    
    class func trackView(viewController: UIViewController, data: [NSObject : AnyObject]?){
        if let t = viewController.restorationIdentifier{
            Analytics.track(t, isView:  true, data: data)
        }
    }
    
    class func trackEvent(title: String) {
        Analytics.track(title, isView: false, data: nil)
    }
    
    class func track(title: String, isView: Bool, data: [NSObject: AnyObject]?) {
        
        // Stop check
        if (!User.sharedInstance.optInTracking){
            print("All tracking manually disabled.")
            return
        }
        
        var trackData = [NSObject : AnyObject]()
        
        if let data = data {
            trackData.addEntriesFrom(data)
        }
        
        trackData.addEntriesFrom(self.additionalTrackData())
        
        guard let tealiumInstance = Tealium.instanceForKey(tealiumDemoInstanceID)else{
            
            //            print("demo instance doesn't exist")
            
            return
        }
        
        if isView == true {
            tealiumInstance.trackViewWithTitle(title, dataSources: trackData)
        } else {
            tealiumInstance.trackEventWithTitle(title, dataSources: trackData)
        }
        
    }
    
    private class func additionalTrackData() -> [NSObject : AnyObject] {
        
        var trackData = [ String: AnyObject]()
        
        if let email = User.sharedInstance.email{
            trackData.updateValue(email, forKey: asKeyEmail)
        }
        
        trackData.updateValue(ph.userParseChannel, forKey: asKeyParseChannel)
        
        trackData.updateValue("Digital Velocity", forKey: asKeyAppName)
        
        var state = "false"
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Active{
            state = "true"
        }
        trackData.updateValue(state, forKey: asKeyIsAppActive)
        
        if TEALBeaconsManager.isBeaconDetectionDisabled(){
            trackData.updateValue("true", forKey: asKeyBeaconDetectionDisabled)
        }
        
        return trackData
    }

    
}