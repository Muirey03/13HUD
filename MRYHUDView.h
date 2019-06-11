@class CCUIContentModuleContainerViewController;
@class CCUIAudioModule;
@interface MRYHUDView : UIView
@property (nonatomic, retain) UIView* containerView;
@property (nonatomic, retain) CCUIAudioModule* audioModule;
@property (nonatomic, retain) CCUIContentModuleContainerViewController* sliderVC;
@property (nonatomic, assign) BOOL expanded;
-(void)setCornerRadius:(CGFloat)arg1;
-(void)collapseAnimated:(BOOL)animated;
-(void)expandAnimated:(BOOL)animated;
@end

@class CCUIContentModuleContentContainerView;
@interface CCUIContentModuleContainerViewController : UIViewController
@property (nonatomic, retain) CCUIContentModuleContentContainerView* contentContainerView;
@property (nonatomic,retain) UIViewController* contentViewController;
-(id)initWithModuleIdentifier:(id)arg1 contentModule:(id)arg2;
@end

@interface CCUIAudioModule : NSObject
-(UIViewController*)contentViewController;
-(UIViewController*)backgroundViewController;
@end

@interface CCUIVolumeSliderView : UIView
@property (nonatomic, assign) CGFloat continuousSliderCornerRadius;
@property (assign,nonatomic) CGFloat value;
@property (nonatomic, assign) BOOL glyphVisible;
@end

@interface CCUIAudioModuleViewController : UIViewController
@end

@interface CCUIContentModuleContentContainerView : UIView
-(void)_setContinuousCornerRadius:(CGFloat)arg1;
@end

@interface CALayer (Internal)
@property (assign) BOOL continuousCorners;
@end

@interface MPVolumeController : NSObject
@property (nonatomic,copy) NSString* volumeAudioCategory;
@property (assign,nonatomic) float volumeValue;
@end

@interface PSUISoundsPrefController : UIViewController
-(BOOL)_canChangeRingtoneWithButtons;
@end

@interface CABackdropLayer : CALayer
@end

@interface UIView (Internal)
-(UIViewController*)_viewControllerForAncestor;
@end