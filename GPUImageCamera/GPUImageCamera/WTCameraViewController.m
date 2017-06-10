
//  Created by 吴桐 on 16/2/23.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import "WTCameraViewController.h"
#import "GPUImage.h"
#import "WTCameraBarView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "WTTimerView.h"
#import "WTFilterName.h"
#import "WTFilterNameView.h"
//#import "WTEditViewController.h"
#import <MediaPlayer/MediaPlayer.h>
//#import "WTRateView.h"
#import "PICViewController.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface WTCameraViewController ()<WTCameraBarViewDelegate>{
    GPUImageView *primaryView;
    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter, *secondFilter, *terminalFilter, *blurFilter, *vignetteFilter;
    
    GPUImagePicture *gpuPicture1, *gpuPicture2;
}
@property (nonatomic, weak) UIView *functionView;
@property (nonatomic, weak) UIView *gridView;
@property (nonatomic, weak) UIButton *shutterBtn;
@property (nonatomic, weak) UIButton *randmBtn;
@property (nonatomic, weak) UIButton *menuBtn;

//@property (nonatomic, weak) UIButton *flashligthBtn;
//@property (nonatomic, weak) UIButton *timerBtn;

@property (nonatomic, weak) WTCameraBarView *cameraBarView;
@property (nonatomic, weak) WTTimerView *timerView;
@property (nonatomic, weak) WTFilterNameView *filterNameView;
@property (nonatomic, assign) NSInteger shutterTime;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger filterType;
@property (nonatomic, weak) UIImageView *focusView;

@property (nonatomic, assign) AVCaptureFlashMode myFlashMode;


@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic, weak) MPVolumeView *volumeView;
//@property (nonatomic, weak) WTTimerView *timerView;
@end

@implementation WTCameraViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    [stillCamera resumeCameraCapture];
    [self initAudioSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil]; //监听是否触发home键挂起程序.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil]; //监听是否重新进入程序程序.
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
//                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
//    NSLog(@"出现===");
    
}
-(void)initAudioSession{
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(volumeChanged:)
     name:@"AVSystemController_SystemVolumeDidChangeNotification"
     object:nil];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    if (!self.volumeView) {
        // put it somewhere outside the bounds of parent view
        MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 10, 0)];
        self.volumeView = volumeView;
        [self.volumeView sizeToFit];
    }
    
    if (!self.volumeView.superview) {
        [self.view addSubview:self.volumeView];
    }

}
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [stillCamera pauseCameraCapture];
//    [stillCamera stopCameraCapture];

//    printf("applicationDidEnterBackground\n");
}
- (void)applicationWillResignActive:(NSNotification *)notification
{
    [stillCamera pauseCameraCapture];
//    printf("按理说是触发home按下\n");
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [stillCamera resumeCameraCapture];
//    printf("按理说是重新进来后响应\n");
}
- (void)volumeChanged:(NSNotification *)notification{
    if (self.timerView) {
        return;
    }
    
//    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [self.volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    // retrieve system volume
    float systemVolume = volumeViewSlider.value;
    
    // change system volume, the value is between 0.0f and 1.0f
    [volumeViewSlider setValue:systemVolume animated:NO];
    
    // send UI control event to make the change effect right now.
//    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    
    [self shutterBtnClick];
    
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [stillCamera pauseCameraCapture];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    self.myFlashMode = AVCaptureFlashModeOff;
    self.shutterTime = 0;
    [self setupGPUImageView];
    [self setupFunctionView];
    
    
}
- (void)setupFirstPage {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = self.view.bounds;
    imageView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    NSString *imgNameStr = @"firstpage";
    if (kSHeight==480) {
        imgNameStr = @"firstpage480";
    }
    imageView.tag = 110;
    imageView.image = [UIImage imageNamed:imgNameStr];
    [self.view addSubview:imageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hadleFirstPageTap:)];
    [imageView addGestureRecognizer:tap];
    imageView.userInteractionEnabled = YES;
}
- (void)hadleFirstPageTap:(UITapGestureRecognizer *)tap {
    UIImageView *imageView = [self.view viewWithTag:110];
    [imageView removeFromSuperview];
}

- (void)setupFlashlightWith:(UIButton *)btn {
    NSInteger flshlight = [[NSUserDefaults standardUserDefaults] integerForKey:@"flashlight"];
//    NSLog(@"%ld", (long)flshlight);
    
    if (flshlight==0) {
        [btn setImage:[UIImage imageNamed:@"muneBtn0"] forState:UIControlStateNormal];
        self.myFlashMode = AVCaptureFlashModeOff;
    } else if (flshlight==2) {
        [btn setImage:[UIImage imageNamed:@"flashlightAuto"] forState:UIControlStateNormal];
        self.myFlashMode = AVCaptureFlashModeAuto;
    }else if (flshlight==1) {
        [btn setImage:[UIImage imageNamed:@"flashlightOn"] forState:UIControlStateNormal];
        self.myFlashMode = AVCaptureFlashModeOn;
    }
    
//    NSLog(@"%ld", (long)self.myFlashMode);
    if (stillCamera.cameraPosition == AVCaptureDevicePositionBack) {
        [self setFlashMode:(self.myFlashMode)];
    }
}
- (void)setupTimerBtn:(UIButton *)btn {
    if (self.shutterTime==0) {
        [btn setImage:[UIImage imageNamed:@"muneBtn1"] forState:UIControlStateNormal];
    } else if (self.shutterTime==3) {
        [btn setImage:[UIImage imageNamed:@"timer3"] forState:UIControlStateNormal];
    }else if (self.shutterTime==5){
        [btn setImage:[UIImage imageNamed:@"timer5"] forState:UIControlStateNormal];
    }
}
- (void)setupGridBtn:(UIButton *)btn {
    if (self.gridView.isHidden==YES) {
        [btn setImage:[UIImage imageNamed:@"muneBtn2"] forState:UIControlStateNormal];
    }else {
        [btn setImage:[UIImage imageNamed:@"gridPic"] forState:UIControlStateNormal];
    }
}
- (void)setupDoubleClickBtn:(UIButton *)btn {
    NSInteger doubleClick = [[NSUserDefaults standardUserDefaults] integerForKey:@"doubleClick"];
    //0双击开  
    if (doubleClick==0) {
        [btn setImage:[UIImage imageNamed:@"doubleClick"] forState:UIControlStateNormal];
    }else {
        [btn setImage:[UIImage imageNamed:@"muneBtn4"] forState:UIControlStateNormal];
    }
}
#pragma mark -
#pragma mark - setupGPUImageView
- (void)setupFunctionView {
    UIView *gridView = [[UIView alloc] init];
    gridView.backgroundColor = [UIColor clearColor];
    gridView.frame = [[UIScreen mainScreen] bounds];
    [self.view addSubview:gridView];
    self.gridView = gridView;
    
    UIView *gridView1 = [[UIView alloc] init];
    gridView1.frame = CGRectMake(kSWidth/3.0, 0, 1, kSHeight);
    gridView1.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    [gridView addSubview:gridView1];
    UIView *gridView2 = [[UIView alloc] init];
    gridView2.frame = CGRectMake(kSWidth/3.0*2, 0, 1, kSHeight);
    gridView2.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    [gridView addSubview:gridView2];
    UIView *gridView3 = [[UIView alloc] init];
    gridView3.frame = CGRectMake(0, kSHeight/3.0, kSWidth, 1);
    gridView3.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    [gridView addSubview:gridView3];
    UIView *gridView4 = [[UIView alloc] init];
    gridView4.frame = CGRectMake(0, kSHeight/3.0*2, kSWidth, 1);
    gridView4.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    [gridView addSubview:gridView4];
    
    NSInteger viewgrid = [[NSUserDefaults standardUserDefaults] integerForKey:@"viewgrid"];
    if (viewgrid==0) {
        [gridView setHidden:YES];
    }
    
    
    UIView *functionVie = [[UIView alloc] init];
    functionVie.frame = [[UIScreen mainScreen] bounds];
    functionVie.backgroundColor = [UIColor clearColor];
    [self.view addSubview:functionVie];
    
    self.functionView = functionVie;
    
    
    
    //滑动换滤镜
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeChangeFilter:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeChangeFilter:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [functionVie addGestureRecognizer:leftSwipe];
    [functionVie addGestureRecognizer:rightSwipe];
    
    //对焦
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFocus:)];
    [functionVie addGestureRecognizer:tap];
    
//    //拍照
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapShuttr:)];
    [tap2 setNumberOfTapsRequired:2];
    [functionVie addGestureRecognizer:tap2];
    
    [tap requireGestureRecognizerToFail:tap2];
    
    
    //拍照按钮
    UIButton *shutterBtn = [[UIButton alloc] init];
    shutterBtn.frame = CGRectMake(0, 0, 75/320.0*kSWidth, 75/320.0*kSWidth);
    shutterBtn.center = CGPointMake(kSWidth/2, kSHeight-50/320.0*kSWidth);
    shutterBtn.backgroundColor = [UIColor clearColor];
    [shutterBtn setImage:[UIImage imageNamed:@"shutter"] forState:UIControlStateNormal];
    [shutterBtn setImage:[UIImage imageNamed:@"shutterP"] forState:UIControlStateHighlighted];
    [functionVie addSubview:shutterBtn];
    [shutterBtn addTarget:self action:@selector(shutterBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.shutterBtn = shutterBtn;
    
    //菜单按钮
    UIButton *menuBtn = [[UIButton alloc] init];
    menuBtn.frame = CGRectMake(0, 0, 41/320.0*kSWidth, 41/320.0*kSWidth);
    menuBtn.center = CGPointMake(kSWidth-40/320.0*kSWidth, shutterBtn.centerY);
    menuBtn.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
    menuBtn.backgroundColor = [UIColor clearColor];
    [menuBtn setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
    [functionVie addSubview:menuBtn];
    [menuBtn addTarget:self action:@selector(menuBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    self.menuBtn = menuBtn;
    
    //随机滤镜按钮
    UIButton *randmBtn = [[UIButton alloc] init];
    randmBtn.frame = CGRectMake(0, 0, 41/320.0*kSWidth, 41/320.0*kSWidth);
    randmBtn.center = CGPointMake(40/320.0*kSWidth, shutterBtn.centerY);
    randmBtn.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
    randmBtn.backgroundColor = [UIColor clearColor];
    [randmBtn setImage:[UIImage imageNamed:@"randmBtn"] forState:UIControlStateNormal];
    [functionVie addSubview:randmBtn];
    [randmBtn addTarget:self action:@selector(randmBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    self.randmBtn = randmBtn;
    
    //顶部按钮View
    UIView *topBarView = [[UIView alloc] init];
    topBarView.backgroundColor = [UIColor clearColor];
    topBarView.frame = CGRectMake(21, 12, kSWidth-42, 41);
    [functionVie addSubview:topBarView];
    
    //菜单
    UIButton *menuWindowBtn = [[UIButton alloc] init];
    menuWindowBtn.frame = CGRectMake(0, 0, 41, 41);
    menuWindowBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    menuWindowBtn.backgroundColor = [UIColor clearColor];
    [menuWindowBtn setImage:[UIImage imageNamed:@"menuWindow"] forState:UIControlStateNormal];
    [topBarView addSubview:menuWindowBtn];
    [menuWindowBtn addTarget:self action:@selector(menuWindowBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    
    //网格
    //    UIButton *gridBtn = [[UIButton alloc] init];
    //    gridBtn.frame = CGRectMake(0, 0, 25, 25);
    //    gridBtn.centerX = topBarView.width/3;
    //    gridBtn.backgroundColor = [UIColor clearColor];
    //    [gridBtn setImage:[UIImage imageNamed:@"grid"] forState:UIControlStateNormal];
    //    [topBarView addSubview:gridBtn];
    //    [gridBtn addTarget:self action:@selector(gridBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //定时器
//    UIButton *timerBtn = [[UIButton alloc] init];
//    timerBtn.frame = CGRectMake(0, 0, 41, 41);
//    timerBtn.centerX = topBarView.width/2.0;
//    timerBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
//    timerBtn.backgroundColor = [UIColor clearColor];
//    [timerBtn setImage:[UIImage imageNamed:@"timer"] forState:UIControlStateNormal];
//    [topBarView addSubview:timerBtn];
//    self.timerBtn = timerBtn;
//    [timerBtn addTarget:self action:@selector(timerBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //摄像头
    UIButton *rotateCameraBtn = [[UIButton alloc] init];
    rotateCameraBtn.frame = CGRectMake(0, 0, 41, 41);
    rotateCameraBtn.centerX = topBarView.width-20.5;
    rotateCameraBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    rotateCameraBtn.backgroundColor = [UIColor clearColor];
    [rotateCameraBtn setImage:[UIImage imageNamed:@"rotateCameraB"] forState:UIControlStateNormal];
    [topBarView addSubview:rotateCameraBtn];
    [rotateCameraBtn addTarget:self action:@selector(rotateCameraBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    if (stillCamera.cameraPosition == AVCaptureDevicePositionFront) {
        
        [rotateCameraBtn setImage:[UIImage imageNamed:@"rotateCameraF"] forState:UIControlStateNormal];
    }
    
}

#pragma mark - 滑动换滤镜
- (void)handleSwipeChangeFilter:(UISwipeGestureRecognizer *)swipe {
    if (swipe.direction==UISwipeGestureRecognizerDirectionRight ) {
        self.filterType--;
        if (self.filterType==0) {
            self.filterType = 40;
        }
    }else if (swipe.direction==UISwipeGestureRecognizerDirectionLeft) {
        self.filterType++;
        if (self.filterType==41) {
            self.filterType = 1;
        }
    }
    
    [self changerFilterWith:self.filterType];
    
}

#pragma mark - 点击对焦
- (void)handleTapShuttr:(UITapGestureRecognizer *)tap {
    NSInteger doubleClick = [[NSUserDefaults standardUserDefaults] integerForKey:@"doubleClick"];
    if (doubleClick==1) {
        return;
    }
    [self shutterBtnClick];
}
- (void)handleTapFocus:(UITapGestureRecognizer *)tap {
    if (self.focusView) {
        return;
    }
    
    CGPoint translation = [tap locationInView:self.view];
    
    
    //    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:CGPointMake(translation.x/kSWidth, translation.y/kSHeight)];
//    stillCamera.inputCamera
    if ( stillCamera.inputCamera.focusMode != AVCaptureFocusModeLocked && stillCamera.inputCamera.exposureMode != AVCaptureExposureModeCustom ) {
        [self setFocusCursorWithPoint:translation];
        //        CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.view.layer captureDevicePointOfInterestForPoint:translation];
        //        [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
        
        [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:CGPointMake(translation.y/kSHeight, 1-translation.x/kSWidth) monitorSubjectAreaChange:YES];
    }
    
}
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = stillCamera.inputCamera;
        
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}
- (void)setFocusCursorWithPoint:(CGPoint)point{
    
    UIImageView *focusView = [[UIImageView alloc] init];
    focusView.frame = CGRectMake(0, 0, 60, 60);
    focusView.backgroundColor = [UIColor clearColor];
    [self.functionView addSubview:focusView];
    self.focusView = focusView;

    focusView.animationImages = [NSArray arrayWithObjects:
                                 [UIImage imageNamed:@"focus"],
                                 [UIImage imageNamed:@"focus2"],nil];
    [focusView setAnimationDuration:1.0f];
    [focusView setAnimationRepeatCount:1];
    
    [focusView startAnimating];
    focusView.center=point;
    focusView.transform=CGAffineTransformMakeScale(1.3, 1.3);
    
    [UIView animateWithDuration:1.0 animations:^{
        focusView.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        if (finished) {
            [focusView removeFromSuperview];
            self.focusView = nil;
        }
        
    }];
    
}
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        //        if ([captureDevice isExposureModeSupported:exposureMode]) {
        //            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        //        }
        //        if ([captureDevice isExposurePointOfInterestSupported]) {
        //            [captureDevice setExposurePointOfInterest:point];
        //        }
    }];
}
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice = stillCamera.inputCamera;
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}
- (void)setFlashMode:(AVCaptureFlashMode )flashMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFlashModeSupported:flashMode]) {
            [captureDevice setFlashMode:flashMode];
        }
    }];
}

#pragma mark - setupGPUImageView
- (void)setupGPUImageView {
    CGRect mainScreenFrame = [[UIScreen mainScreen] bounds];
    
    primaryView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
    primaryView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    [self.view addSubview:primaryView];
    
    if (kSHeight<=480) {
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    }else {
        
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    }
    
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    stillCamera.horizontallyMirrorFrontFacingCamera = YES;
    stillCamera.horizontallyMirrorRearFacingCamera = NO;
    
//    [stillCamera addTarget:primaryView];
//    [stillCamera startCameraCapture];
//    return;

    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"rotateCamera"]==0) {
        [stillCamera rotateCamera];
    }
    
    NSInteger filterNum = [[NSUserDefaults standardUserDefaults] integerForKey:@"filterType"];
    if (filterNum==0) {
        filterNum = 1;
    }
    self.filterType = filterNum;
    
    blurFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
    [(GPUImageGaussianSelectiveBlurFilter *)blurFilter setAspectRatio:0.8];
    
    vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"vignette"]==1) {//没有
        [(GPUImageVignetteFilter *)vignetteFilter setVignetteStart:1.0];
        [(GPUImageVignetteFilter *)vignetteFilter setVignetteEnd:1.0];
    }
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"blur"]==1) {//有
        [(GPUImageGaussianSelectiveBlurFilter *)blurFilter setExcludeCircleRadius:135/320.0];
    }else {
        [(GPUImageGaussianSelectiveBlurFilter *)blurFilter setExcludeCircleRadius:320/320.0];
    }
    
    [self changerFilterWith:self.filterType];
    
    
}


#pragma mark - 按钮反馈
#pragma mark -
- (void)menuWindowBtnClick {
    UIView *menuWindow = [[UIView alloc] init];
    menuWindow.frame = [[UIScreen mainScreen] bounds];
    menuWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.85];
    [self.view addSubview:menuWindow];
    menuWindow.alpha = 0;
    
    UIButton *clossBtn = [[UIButton alloc] init];
    clossBtn.frame = CGRectMake(0, kSHeight-23-49, 49, 49);
    clossBtn.centerX = kSWidth/2.0;
    clossBtn.centerY = self.shutterBtn.centerY;
    clossBtn.backgroundColor = [UIColor clearColor];
    [menuWindow addSubview:clossBtn];
    [clossBtn setImage:[UIImage imageNamed:@"windowCloose"] forState:UIControlStateNormal];
    [clossBtn addTarget:self action:@selector(menuWindowClose:) forControlEvents:UIControlEventTouchUpInside];
    
    for (int i=0; i<5; i++) {
        UIButton *btn = [[UIButton alloc] init];
        btn.frame = CGRectMake(0, 100, 68, 68);
        btn.center = CGPointMake((i%3+1)*(68+(kSWidth-68*3.0)/4.0)-34, kSHeight/4.0+(i-i%3)/3*(68+66+10));
        btn.backgroundColor = [UIColor clearColor];
        btn.tag = 120+i;
        [menuWindow addSubview:btn];
        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"muneBtn%d", i]] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(menuWindowSubBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(0, 0, 100, 15);
        label.center = CGPointMake(btn.centerX, btn.centerY+34+20);
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor whiteColor];
        [menuWindow addSubview:label];
        
        switch (i) {
            case 0:
                label.text = @"Flash";
                [self setupFlashlightWith:btn];
                break;
            case 1:
                label.text = @"Timer";
                [self setupTimerBtn:btn];
                break;
            case 2:
                label.text = @"Grid";
                [self setupGridBtn:btn];
                break;
            case 3:
                label.text = @"Help";
                break;
            case 4:
                label.text = @"dbl-click";
                [self setupDoubleClickBtn:btn];
                break;
            case 5:
                label.text = @"Rate";
                break;
                
            default:
                break;
                
        }
        
    }
    
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        menuWindow.alpha = 0.85;
    } completion:^(BOOL finished) {
        
    }];
}
- (void)menuWindowSubBtnClick:(UIButton *)btn {
    switch (btn.tag-120) {
        case 0:
            [self flashlightBtnClick:btn];
            break;
        case 1:
            [self timerBtnClick:btn];
            break;
        case 2:
            [self gridBtnClick:btn];
            break;
        case 3:
            [self setupFirstPage];
            break;
        case 4:
            [self doubleClickBtn:btn];
            break;
        case 5:
//            [self rateBtnClick:btn];
            break;
            
        default:
            break;
    }
}
- (void)menuWindowClose:(UIButton *)btn {
    [btn.superview removeFromSuperview];
}
- (void)rateBtnClick:(UIButton *)btn {
//    [btn.superview removeFromSuperview];
//    
//    WTRateView *rateView = [[WTRateView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    [self.view addSubview:rateView];
}
- (void)shutterBtnClick {
    if (self.shutterTime==0) {
        [self shutterTakePhoto];
    }else {
        WTTimerView *timerView = [[WTTimerView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:timerView];
        timerView.curTimer = self.shutterTime;
        self.timerView = timerView;
        [timerView setTimeLabelText:self.shutterTime];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
        
    }
    
    
}
- (void)timerAction:(NSTimer *)timer {
    self.timerView.curTimer--;
    if (self.timerView.curTimer==0) {
        [timer invalidate];
        timer = nil;
        [self shutterTakePhoto];
        [self.timerView removeFromSuperview];
        self.timerView = nil;
    }else {
        
        [self.timerView setTimeLabelText:self.timerView.curTimer];
    }
    
    
}

- (void)shutterTakePhoto {
    if (self.focusView) {
        [self.focusView removeFromSuperview];
        self.focusView = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.filterType forKey:@"filterType"];
    
    if (self.cameraBarView) {
        if (self.cameraBarView.vignetteBtn.selected == NO) {
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"vignette"];
        }else {
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"vignette"];
        }
        
        if (self.cameraBarView.blurBtn.selected == NO) {
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"blur"];
        }else {
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"blur"];
        }
    }
    
    if (stillCamera.cameraPosition == AVCaptureDevicePositionFront) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"rotateCamera"];
    }else if (stillCamera.cameraPosition == AVCaptureDevicePositionBack){
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"rotateCamera"];
    }
    
    
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:blurFilter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        PICViewController *picVC = [[PICViewController alloc] init];
        picVC.image = processedImage;
        [self.navigationController pushViewController:picVC animated:NO];
        
        
//        WTEditViewController *editViewController = [[WTEditViewController alloc] init];
//        editViewController.eidtImage = processedImage;
//        [self.navigationController pushViewController:editViewController animated:NO];
        
    }];
    
//    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)randmBtnClick:(UIButton *)btn {
    int randType = arc4random_uniform(40)+1;
    
    self.filterType = randType;
    
    [self changerFilterWith:randType];
}
- (void)menuBtnClick:(UIButton *)btn {
    
    if (!self.cameraBarView) {
        WTCameraBarView *cameraBarView = [[WTCameraBarView alloc] initWithFrame:CGRectMake(0, kSHeight, kSWidth, 100*kSScale)];
        cameraBarView.delegate = self;
        [self.functionView addSubview:cameraBarView];
        self.cameraBarView = cameraBarView;
        [cameraBarView filterSelcWith:self.filterType];
        
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"vignette"]==1) {//没有
            cameraBarView.vignetteBtn.selected = NO;
        }else {
            cameraBarView.vignetteBtn.selected = YES;
        }
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"blur"]==1) {//有
            cameraBarView.blurBtn.selected = YES;
        }else {
            cameraBarView.blurBtn.selected = NO;
        }
        
    }
    
    if (self.cameraBarView.y<kSHeight) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.shutterBtn.alpha = 1.0;
            self.randmBtn.alpha = 1.0;
            self.menuBtn.center = CGPointMake(kSWidth-40/320.0*kSWidth, self.shutterBtn.centerY);
            self.cameraBarView.y = kSHeight;
            [self.menuBtn setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            
        }];
        
    }else {
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            
            self.shutterBtn.alpha = 0.0;
            self.randmBtn.alpha = 0.0;
            self.menuBtn.centerY = kSHeight-130*kSScale ;
            self.cameraBarView.y = kSHeight-100*kSScale;
            [self.menuBtn setImage:[UIImage imageNamed:@"menu2"] forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            
        }];
    }
    
    
}
- (void)flashlightBtnClick:(UIButton *)btn {
//    NSLog(@"%ld", (long)self.myFlashMode);
    if (self.myFlashMode==AVCaptureFlashModeOff) {
        [btn setImage:[UIImage imageNamed:@"flashlightAuto"] forState:UIControlStateNormal];
        self.myFlashMode = AVCaptureFlashModeAuto;
    } else if (self.myFlashMode==AVCaptureFlashModeAuto) {
        [btn setImage:[UIImage imageNamed:@"flashlightOn"] forState:UIControlStateNormal];
        self.myFlashMode = AVCaptureFlashModeOn;
    }else if (self.myFlashMode==AVCaptureFlashModeOn) {
        [btn setImage:[UIImage imageNamed:@"muneBtn0"] forState:UIControlStateNormal];
        self.myFlashMode = AVCaptureFlashModeOff;
    }
    
    if (stillCamera.cameraPosition == AVCaptureDevicePositionBack) {
        [self setFlashMode:(self.myFlashMode)];
    }
    
    NSInteger flashlight;
    switch (self.myFlashMode) {
        case AVCaptureFlashModeOff:
            flashlight = 0;
            break;
        case AVCaptureFlashModeAuto:
            flashlight = 2;
            break;
        case AVCaptureFlashModeOn:
            flashlight = 1;
            break;
            
        default:
            break;
    }
//    NSLog(@"%ld", (long)self.myFlashMode);
    [[NSUserDefaults standardUserDefaults] setInteger:flashlight forKey:@"flashlight"];
}
- (void)doubleClickBtn:(UIButton *)btn {
    NSInteger doubleClick = [[NSUserDefaults standardUserDefaults] integerForKey:@"doubleClick"];
    if (doubleClick==0) {
        [btn setImage:[UIImage imageNamed:@"muneBtn4"] forState:UIControlStateNormal];
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"doubleClick"];
    }else {
        [btn setImage:[UIImage imageNamed:@"doubleClick"] forState:UIControlStateNormal];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"doubleClick"];
    }
    
}
- (void)gridBtnClick:(UIButton *)btn {
    if (self.gridView.isHidden==YES) {
        [self.gridView setHidden:NO];
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"viewgrid"];
        [btn setImage:[UIImage imageNamed:@"gridPic"] forState:UIControlStateNormal];
    }else {
        [self.gridView setHidden:YES];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"viewgrid"];
        [btn setImage:[UIImage imageNamed:@"muneBtn2"] forState:UIControlStateNormal];
    }
}
- (void)timerBtnClick:(UIButton *)btn {
    if (self.shutterTime==0) {
        self.shutterTime = 3;
        [btn setImage:[UIImage imageNamed:@"timer3"] forState:UIControlStateNormal];
    }else if (self.shutterTime==3) {
        self.shutterTime = 5;
        [btn setImage:[UIImage imageNamed:@"timer5"] forState:UIControlStateNormal];
    }else {
        self.shutterTime = 0;
        [btn setImage:[UIImage imageNamed:@"muneBtn1"] forState:UIControlStateNormal];
    }
}
- (void)rotateCameraBtnClick:(UIButton *)btn {
    [stillCamera rotateCamera];
    if (stillCamera.cameraPosition == AVCaptureDevicePositionBack) {
        
        [btn setImage:[UIImage imageNamed:@"rotateCameraB"] forState:UIControlStateNormal];
        
        [self setFlashMode:(self.myFlashMode)];
    }else {
        
        [btn setImage:[UIImage imageNamed:@"rotateCameraF"] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - WTCameraBarViewDelegate
- (void)cameraBarClose {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.shutterBtn.alpha = 1.0;
    self.menuBtn.alpha = 1.0;
    self.cameraBarView.y = kSHeight;
    [UIView commitAnimations];
}
- (void)cameraBarBlurBtnClickWithSelc:(BOOL)selc {
    if (selc) {
        [(GPUImageGaussianSelectiveBlurFilter *)blurFilter setExcludeCircleRadius:135/320.0];
    }else {
        [(GPUImageGaussianSelectiveBlurFilter *)blurFilter setExcludeCircleRadius:320/320.0];
    }
}
- (void)cameraBarVignetteBtnClickWithSelc:(BOOL)selc {
    if (selc) {
        [(GPUImageVignetteFilter *)vignetteFilter setVignetteStart:0.3];
        [(GPUImageVignetteFilter *)vignetteFilter setVignetteEnd:0.75];
    }else {
        [(GPUImageVignetteFilter *)vignetteFilter setVignetteStart:1.0];
        [(GPUImageVignetteFilter *)vignetteFilter setVignetteEnd:1.0];
    }
}

- (void)cameraBarFliterClick:(NSInteger)number {
    if (self.filterType==number) {
        return;
    }
    self.filterType = number;
    
    [self changerFilterWith:number];
}
- (void)changerFilterWith:(NSInteger)number {
    if (self.filterNameView==nil) {
        WTFilterNameView *filterNameView = [[WTFilterNameView alloc] initWithFrame:CGRectMake(0, kSHeight/4.0, kSWidth, 200)];
        [self.functionView addSubview:filterNameView];
        filterNameView.userInteractionEnabled = NO;
        self.filterNameView = filterNameView;
    }
    
    [self.filterNameView showFilterLabel:number];
    self.cameraBarView.selcNumber = number;
    if (self.cameraBarView) {
        [self.cameraBarView filterSelcWith:number];
    }
    
    
    [filter removeAllTargets];
    [gpuPicture1 removeAllTargets];
    [gpuPicture2 removeAllTargets];
    [stillCamera removeAllTargets];
    
    if (number==0) {
        [stillCamera addTarget:vignetteFilter];
        
        [vignetteFilter addTarget:blurFilter];
        [blurFilter addTarget:primaryView];
        [stillCamera startCameraCapture];
        return;
    }
    
    switch (number) {
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 12:
        case 13:
        case 14:
        case 6:
        case 8:
        case 9:
        case 10:
        case 17:
        case 19:
        case 20:
        case 21:
        case 23:
        case 24:
        case 30:
        case 34:
        case 35:
        case 36:
        case 37:
        case 38:
        case 39:
            [self filterWithOnePic:number];
            break;
            
        case 11:
        case 18:
        case 26:
        case 27:
        case 28:
        case 33:
        case 40:
            [self filterWithTwoPic:number];
            break;
            
            
        case 7:
        case 15:
        case 16:
        case 22:
        case 25:
        case 29:
        case 31:
        case 32:
            [self filterJustBlend:number];
            break;
            
        default:
            break;
    }
    
    
}


- (void)filterJustBlend:(NSInteger)number {
    
    UIImage *filterImg2 = [UIImage imageNamed:[NSString stringWithFormat:@"filter%02d", (int)number]];
    
    gpuPicture2 = [[GPUImagePicture alloc] initWithImage:filterImg2];
    filter = [[GPUImageLightLeakBlendFilter alloc] init];
    
    
    [stillCamera addTarget:filter];
    [gpuPicture2 addTarget:filter];
    [gpuPicture2 processImage];
    
    [filter addTarget:vignetteFilter];
    [vignetteFilter addTarget:blurFilter];
    [blurFilter addTarget:primaryView];
    [stillCamera startCameraCapture];
}

- (void)filterWithOnePic:(NSInteger)number {
    UIImage *filterImg = [UIImage imageNamed:[NSString stringWithFormat:@"filter%02d.png", (int)number]];
    gpuPicture1 = [[GPUImagePicture alloc] initWithImage:filterImg];
    
    if (filterImg.size.height>10) {
        filter = [[GPUImageLookupFilter alloc] init];
        
        [stillCamera addTarget:filter];
        [gpuPicture1 addTarget:filter];
        
        [gpuPicture1 processImage];
        [filter addTarget:vignetteFilter];
        [vignetteFilter addTarget:blurFilter];
        [blurFilter addTarget:primaryView];
        [stillCamera startCameraCapture];
    }else {
        IFCharmesFilter *toneFilter = [[IFCharmesFilter alloc] init];
        [stillCamera addTarget:toneFilter atTextureLocation:0];
        [gpuPicture1 addTarget:toneFilter atTextureLocation:1];
        
        [toneFilter addTarget:vignetteFilter];
        [vignetteFilter addTarget:blurFilter];
        [blurFilter addTarget:primaryView];
        [stillCamera startCameraCapture];
    }
}

- (void)filterWithTwoPic:(NSInteger)number {
    UIImage *filterImg = [UIImage imageNamed:[NSString stringWithFormat:@"filter%02ds", (int)number]];
    gpuPicture1 = [[GPUImagePicture alloc] initWithImage:filterImg];
    
    UIImage *filterImg2 = [UIImage imageNamed:[NSString stringWithFormat:@"filter%02d", (int)number]];
    
    gpuPicture2 = [[GPUImagePicture alloc] initWithImage:filterImg2];
    secondFilter = [[GPUImageLookupFilter alloc] init];
    filter = [[GPUImageLightLeakBlendFilter alloc] init];
    
    [stillCamera addTarget:secondFilter];
    [gpuPicture2 addTarget:secondFilter];
    [gpuPicture2 processImage];
    [secondFilter addTarget:filter];
    [gpuPicture1 addTarget:filter];
    [gpuPicture1 processImage];
    
    [filter addTarget:vignetteFilter];
    [vignetteFilter addTarget:blurFilter];
    [blurFilter addTarget:primaryView];
    [stillCamera startCameraCapture];
}


@end
