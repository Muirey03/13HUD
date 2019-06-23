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

@interface SpringBoard : NSObject
-(UIInterfaceOrientation)activeInterfaceOrientation;
@end

CGRect expandedFrame();
CGRect collapsedFrame();

//prefs:
@interface NSUserDefaults (Internal)
-(id)objectForKey:(id)arg1 inDomain:(id)arg2;
@end
BOOL PreferencesBool(NSString* key, BOOL fallback);
CGFloat PreferencesFloat(NSString* key, CGFloat fallback);

//DEBUG:
__attribute__((unused)) static void HUDLog(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString* str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString* logPath = @"/var/tmp/13hud.log";
    NSFileManager* mngr = [NSFileManager defaultManager];
    if (![mngr fileExistsAtPath:logPath])
        [mngr createFileAtPath:logPath contents:[NSData new] attributes:nil];

    NSString* contents = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:nil];
    contents = [contents stringByAppendingString:[NSString stringWithFormat:@"\n%@", str]];
    [contents writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}