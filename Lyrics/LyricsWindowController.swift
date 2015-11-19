//
//  LyricsWindowController.swift
//  Lyrics
//
//  Created by Eru on 15/11/9.
//  Copyright © 2015年 Eru. All rights reserved.
//


/************************ IMPORTANT ************************/
/*                                                         */
/*     LyricsWindowController Must Run in Main Thread      */
/*   In other threads may cause some unexpected problems   */
/*                                                         */
/************************ IMPORTANT ************************/

import Cocoa

class LyricsWindowController: NSWindowController {
    
    var backgroundLayer: CALayer!
    var firstLyricsLayer: CATextLayer!
    var secondLyricsLayer: CATextLayer!
    var attrs: [String:AnyObject]!
    var visibleSize: NSSize!
    var visibleOrigin: NSPoint!
    var userDefaults: NSUserDefaults!
    var flag: Bool = true
    
    convenience init() {
        self.init(windowNibName:"LyricsWindow")
        userDefaults = NSUserDefaults.standardUserDefaults()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        NSLog("Init Lyrics window")
        self.window?.backgroundColor=NSColor.clearColor()
        self.window?.opaque=false
        self.window?.hasShadow=false
        self.window?.ignoresMouseEvents=true
        self.window?.level=Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
        self.window?.contentView?.layer=CALayer()
        self.window?.contentView?.wantsLayer=true
        
        if userDefaults.boolForKey(LyricsDisabledWhenSreenShot) {
            self.window?.sharingType=NSWindowSharingType.None
        }
        if userDefaults.boolForKey(LyricsDisplayInAllSpaces) {
            self.window?.collectionBehavior=NSWindowCollectionBehavior.CanJoinAllSpaces
        }
        
        backgroundLayer=CALayer()
        firstLyricsLayer=CATextLayer()
        secondLyricsLayer=CATextLayer()
        
        backgroundLayer.anchorPoint=CGPointZero
        backgroundLayer.position=CGPointMake(0, 0)
        backgroundLayer.cornerRadius=20
        
        firstLyricsLayer.anchorPoint=CGPointZero
        firstLyricsLayer.position=CGPointMake(0, 0)
        firstLyricsLayer.alignmentMode=kCAAlignmentCenter
        
        secondLyricsLayer.anchorPoint=CGPointZero
        secondLyricsLayer.position=CGPointMake(0, 0)
        secondLyricsLayer.alignmentMode=kCAAlignmentCenter
        
        self.window?.contentView?.layer!.addSublayer(backgroundLayer)
        backgroundLayer.addSublayer(firstLyricsLayer)
        backgroundLayer.addSublayer(secondLyricsLayer)
        setAttributes()
        setScreenResolution()
        backgroundLayer.speed=1.1
        displayLyrics("LyricsX", secondLyrics: nil)
        
        let nc:NSNotificationCenter=NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "handleAttributesUpdate", name: LyricsAttributesChangedNotification, object: nil)
        nc.addObserver(self, selector: "handleScreenResolutionChange", name: NSApplicationDidChangeScreenParametersNotification, object: nil)

    }
    
// MARK: - set lyrics properties
    
    func setAttributes() {
        let bkColor:NSColor = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.objectForKey(LyricsBackgroundColor) as! NSData) as! NSColor
        let textColor:NSColor = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.objectForKey(LyricsTextColor) as! NSData) as! NSColor
        let textSize:CGFloat = CGFloat(userDefaults.floatForKey(LyricsFontSize))
        let font:NSFont = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: textSize)!
        
        attrs=[NSFontAttributeName:font]
        
        backgroundLayer.backgroundColor = bkColor.CGColor
        
        firstLyricsLayer.foregroundColor = textColor.CGColor
        firstLyricsLayer.fontSize = textSize
        firstLyricsLayer.font = font
        
        secondLyricsLayer.foregroundColor = textColor.CGColor
        secondLyricsLayer.fontSize = textSize
        secondLyricsLayer.font = font
        
        if userDefaults.boolForKey(LyricsShadowModeEnable) {
            let shadowColor:NSColor = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.objectForKey(LyricsShadowColor) as! NSData) as! NSColor
            let shadowRadius:CGFloat = CGFloat(userDefaults.floatForKey(LyricsShadowRadius))
            firstLyricsLayer.shadowColor = shadowColor.CGColor
            firstLyricsLayer.shadowRadius = shadowRadius
            firstLyricsLayer.shadowOpacity = 1
            firstLyricsLayer.shadowOffset = CGSizeMake(0,0)
            
            secondLyricsLayer.shadowColor = shadowColor.CGColor
            secondLyricsLayer.shadowRadius = shadowRadius
            secondLyricsLayer.shadowOpacity = 1
            secondLyricsLayer.shadowOffset = CGSizeMake(0,0)
        } else {
            firstLyricsLayer.shadowOpacity = 0
            secondLyricsLayer.shadowOpacity = 0
        }
    }
    
    func setScreenResolution() {
        // Only this method can run in background thread
        let visibleFrame:NSRect=(NSScreen.mainScreen()?.visibleFrame)!
        visibleSize=visibleFrame.size
        visibleOrigin=visibleFrame.origin
        self.window?.setFrame(CGRectMake(0, 0, visibleSize.width, visibleSize.height), display: true)
        firstLyricsLayer.contentsScale=(NSScreen.mainScreen()?.backingScaleFactor)!
        secondLyricsLayer.contentsScale=firstLyricsLayer.contentsScale
        NSLog("Screen Visible Res Changed to:(%f,%f) O:(%f,%f)", visibleSize.width,visibleSize.height,visibleOrigin.x,visibleOrigin.y)
    }

// MARK: - display lyrics
    
    func displayLyrics(firstLyrics:NSString?, secondLyrics:NSString?) {
        if (firstLyrics==nil) || (firstLyrics?.isEqualToString(""))! {
            // first Lyrics empty means it's instrument time
            
            flag = true
            backgroundLayer.speed=0.2
            firstLyricsLayer.speed = 0.2
            secondLyricsLayer.speed = 0.2
            
            firstLyricsLayer.frame = NSMakeRect(backgroundLayer.frame.size.width/3, 0, 0, 0)
            secondLyricsLayer.frame = NSMakeRect(backgroundLayer.frame.size.width/3, 0, 0, 0)
            firstLyricsLayer.string = ""
            secondLyricsLayer.string = ""
            firstLyricsLayer.hidden=true
            secondLyricsLayer.hidden=true
            backgroundLayer.hidden=true
        }
        else if (secondLyrics==nil) || (secondLyrics?.isEqualToString(""))! {
            // One-Line Mode or sencond lyrics is instrument time
            
            flag = true
            backgroundLayer.speed = 0.8
            firstLyricsLayer.speed = 0.8
            secondLyricsLayer.speed = 0.8
            
            secondLyricsLayer.string = ""
            firstLyricsLayer.hidden = false
            secondLyricsLayer.hidden = true
            backgroundLayer.hidden = false
            
            let strSize:NSSize = firstLyrics!.sizeWithAttributes(attrs)
            let x:CGFloat
            let y:CGFloat
            
            if userDefaults.boolForKey(LyricsUseAutoLayout) {
                let frameSize = NSMakeSize(strSize.width+50, strSize.height)
                x = visibleOrigin.x+(visibleSize.width-frameSize.width)/2
                y = visibleOrigin.y+CGFloat(userDefaults.integerForKey(LyricsHeightFromDockToLyrics))
                
                backgroundLayer.frame=CGRectMake(x, y, frameSize.width, frameSize.height)
                firstLyricsLayer.frame=CGRectMake(0, 0, frameSize.width, frameSize.height)
            } else {
                
                let frameSize = NSMakeSize(CGFloat(userDefaults.integerForKey(LyricsConstWidth)), CGFloat(userDefaults.integerForKey(LyricsConstHeight)))
                x = CGFloat(userDefaults.integerForKey(LyricsConstToLeft))
                y = CGFloat(userDefaults.integerForKey(LyricsConstToBottom))
                
                backgroundLayer.frame=CGRectMake(x, y, frameSize.width, frameSize.height)
                firstLyricsLayer.frame=CGRectMake(0, (frameSize.height-strSize.height)/2, frameSize.width, strSize.height)
            }
            
            firstLyricsLayer.string=firstLyrics
        }
        else {
            // Two-Line Mode
            backgroundLayer.speed = 0.8
            firstLyricsLayer.speed = 0.8
            secondLyricsLayer.speed = 0.8
            
            firstLyricsLayer.hidden=false
            secondLyricsLayer.hidden=false
            backgroundLayer.hidden=false
            
            var size2nd:NSSize=secondLyrics!.sizeWithAttributes(attrs)
            size2nd.width=size2nd.width+50
            size2nd.height=size2nd.height*0.9
            secondLyricsLayer.string=secondLyrics
            
            var size1st:NSSize=firstLyrics!.sizeWithAttributes(attrs)
            size1st.width=size1st.width+50
            size1st.height=size1st.height*0.9
            firstLyricsLayer.string=firstLyrics
            
            var width: CGFloat
            var height: CGFloat
            let x: CGFloat
            let y: CGFloat
            var rect1st: CGRect
            var rect2nd: CGRect
            
            if size1st.width>=size2nd.width {
                width=size1st.width
                rect1st=CGRectMake(0, size2nd.height, size1st.width, size1st.height)
                rect2nd=CGRectMake(0, 0, size1st.width, size2nd.height)
            }
            else {
                width=size2nd.width
                rect1st=CGRectMake(0, size2nd.height, size2nd.width, size1st.height)
                rect2nd=CGRectMake(0, 0, size2nd.width, size2nd.height)
            }
            
            if userDefaults.boolForKey(LyricsUseAutoLayout) {
                x = visibleOrigin.x+(visibleSize.width-width)/2
                y = visibleOrigin.y+CGFloat(userDefaults.integerForKey(LyricsHeightFromDockToLyrics))
                height=size1st.height+size2nd.height
                
            } else {
                x = CGFloat(userDefaults.integerForKey(LyricsConstToLeft))
                y = CGFloat(userDefaults.integerForKey(LyricsConstToBottom))
                width = CGFloat(userDefaults.integerForKey(LyricsConstWidth))
                height = CGFloat(userDefaults.integerForKey(LyricsConstHeight))
                
                rect1st.origin.x += (width-rect1st.size.width)/2
                rect1st.origin.y = height/2
                rect2nd.origin.x += (width-rect2nd.size.width)/2
                rect2nd.origin.y = height/2-rect2nd.size.height
            }
            
            backgroundLayer.frame = CGRectMake(x, y, width, height)
            
            if flag {
                firstLyricsLayer.string = firstLyrics
                secondLyricsLayer.string = secondLyrics
                firstLyricsLayer.frame = rect1st
                secondLyricsLayer.frame = rect2nd
                
            } else {
                firstLyricsLayer.string = secondLyrics
                secondLyricsLayer.string = firstLyrics
                firstLyricsLayer.frame = rect2nd
                secondLyricsLayer.frame = rect1st
            }
            
            flag = !flag
        }
    }

//MARK: - Notification Methods
    
    func handleAttributesUpdate() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.setAttributes()
            
            //reflash lyrics
            self.displayLyrics(self.firstLyricsLayer.string as? NSString, secondLyrics: self.secondLyricsLayer.string as? NSString)
        }
    }
    
    func handleScreenResolutionChange() {
        setScreenResolution()
        
        //reflash lyrics
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.displayLyrics(self.firstLyricsLayer.string as? NSString, secondLyrics: self.secondLyricsLayer.string as? NSString)
        }
    }

}
