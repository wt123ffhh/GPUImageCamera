//
//  PICViewController.m
//  GPUImageCamera
//
//  Created by 吴桐 on 2017/6/9.
//  Copyright © 2017年 wtWork. All rights reserved.
//

#import "PICViewController.h"
#import <Photos/Photos.h>

@interface PICViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PICViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.imageView.image = self.image;
}
- (IBAction)saveBtnClick {
    [self loadImageFinished:self.image];
}
- (void)loadImageFinished:(UIImage *)image
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        NSLog(@"success = %d, error = %@", success, error);
        
    }];
}

@end
