@class MRYHUDView;
@interface SBHUDController : NSObject
@property (nonatomic, retain) MRYHUDView* mryHUD;
@property (nonatomic, retain) NSTimer* displayTimer;
@property (nonatomic, retain) NSTimer* collapseTimer;
+(instancetype)sharedHUDController;
-(void)createMRYHUD;
-(void)showMRYHUD;
-(void)hideMRYHUD;
-(BOOL)isHUDVisible;
@end

CGRect expandedFrame();
CGRect collapsedFrame();

//prefs:
@interface NSUserDefaults (Internal)
-(id)objectForKey:(id)arg1 inDomain:(id)arg2;
@end
BOOL PreferencesBool(NSString* key, BOOL fallback);
CGFloat PreferencesFloat(NSString* key, CGFloat fallback);