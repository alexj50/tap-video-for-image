//
//  ViewController.m
//  tapVideoForPicture
//
//  Created by Jacobson on 2/23/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//

#import "HomeViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "GalleryCollectionView.h"
#import "CollectionViewCell.h"
#import "VideoClass.h"

@interface HomeViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet UIView *tapView;
@property (strong, nonatomic) IBOutlet UICollectionView *galleryCollection;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progressWidthCons;
@property (strong, nonatomic) MPMoviePlayerController *mc;
@property (strong, nonatomic) NSMutableArray *imageArray,*allVideos;
@property (strong, nonatomic) NSIndexPath *oldIndexPath,*currentIndexPath;
@property (strong, nonatomic) UIButton *submitButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndcator;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UILabel *loadingLabel;
@property float totalTime;
@property CGSize movieDimensions;
@end

@implementation HomeViewController
@synthesize mc,tapView,imageArray,videoView,totalTime,movieDimensions,galleryCollection,allVideos,oldIndexPath,collectionBottomConstraint,submitButton,currentIndexPath,activityIndcator,loadingLabel,timer,progressWidthCons;
static bool stopped = NO,started = NO,progressStop = NO,videoActive = NO;
static NSString *const reuseIdentifier = @"home";
static int screenWidth = 0, screenHeight = 0;


- (void)viewDidLoad {
    [super viewDidLoad];
    screenWidth  = [[UIScreen mainScreen] bounds].size.width;
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    [self loadViewsInit];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    else
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void) loadViewsInit {
    activityIndcator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake((screenWidth/2) - 10,(screenHeight/2) - 10,20,20)];
    activityIndcator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndcator];
    
    loadingLabel               = [[UILabel alloc] initWithFrame:CGRectMake(0,(screenHeight/2) - 60,screenWidth,40)];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.text          = @"Loading Video Library";
    loadingLabel.textColor     = [UIColor whiteColor];
    [self.view addSubview:loadingLabel];
    
    submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [submitButton addTarget:self  action:@selector(submitButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:@"Next" forState:UIControlStateNormal];
    submitButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [submitButton setBackgroundColor:[UIColor blueColor]];
    [submitButton setTintColor:[UIColor whiteColor]];
    submitButton.frame = CGRectMake(0,screenHeight, screenWidth, 50.0);
    [self.view addSubview:submitButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(extractImage)];
    tap.numberOfTapsRequired    = 1;
    [tapView addGestureRecognizer:tap];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    imageArray   = [NSMutableArray new];
    allVideos    = [NSMutableArray new];
    oldIndexPath = nil;
    [self movieActive:NO];
    [self retriveAllVideos];
}

-(void) movieSetup{
    [self movieActive:YES];
    progressWidthCons.constant = 0;
    progressStop    = NO;
    stopped         = NO;
    started         = NO;
    VideoClass *vid = [allVideos objectAtIndex:currentIndexPath.row];
    
    MPMoviePlayerController *controller = [[MPMoviePlayerController alloc] initWithContentURL:vid.url];
    controller.allowsAirPlay = NO;
    controller.fullscreen    = YES;
    controller.controlStyle  = MPMovieControlStyleNone;
    controller.view.frame    = CGRectMake(0, 0, screenWidth, screenHeight);
    self.mc                  = controller;
    [self.videoView addSubview:self.mc.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.mc];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieNaturalSizeAvailable:)
                                                 name:MPMovieNaturalSizeAvailableNotification
                                               object:mc];
    
    [self performSelector:@selector(playDelay) withObject:nil afterDelay:1];
    [self performSelector:@selector(videoProgresIndicatior) withObject:nil afterDelay:1.5];
}

-(void) playDelay {
    [self.mc play];
}

-(void) videoProgresIndicatior {
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.1f
                                             target: self
                                           selector: @selector(updateProgressBar)
                                           userInfo: nil
                                            repeats: YES];
}

-(void) updateProgressBar {
    if (mc.currentPlaybackTime < mc.duration){
        float position = (mc.currentPlaybackTime/mc.duration) * screenWidth;
        [UIView animateWithDuration:0.1 animations:^(){
            progressWidthCons.constant = position;
            [self.view layoutIfNeeded];
        }];
    }else
        [timer invalidate];
    
}

-(void) movieActive : (BOOL) movieActive {
    if (movieActive){
        tapView.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^(){
            galleryCollection.alpha = 0.0;
        }];
    }else{
        videoActive = NO;
        tapView.hidden = YES;
        [UIView animateWithDuration:0.5 animations:^(){
            galleryCollection.alpha = 1.0;
        }];
    }
}

-(void)extractImage {
    VideoClass *vid = [allVideos objectAtIndex:currentIndexPath.row];
    AVURLAsset *as                   = [[AVURLAsset alloc] initWithURL:vid.url options:nil];
    AVAssetImageGenerator *ima       = [[AVAssetImageGenerator alloc] initWithAsset:as];
    ima.requestedTimeToleranceBefore = kCMTimeZero;
    ima.requestedTimeToleranceAfter  = kCMTimeZero;
    NSError *err                     = NULL;
    CMTime time                      = CMTimeMake(mc.currentPlaybackTime * as.duration.timescale, as.duration.timescale);
    CGImageRef imgRef                = [ima copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *currentImg              = [[UIImage alloc] initWithCGImage:imgRef];
    
    if (floor(movieDimensions.width) < floor(movieDimensions.height))
            currentImg = [self imageRotatedByDegrees : currentImg deg: 90];

    [imageArray addObject:currentImg];
}

- (void) moviePlayBackDidFinish:(NSNotification*)notification {
    progressStop = YES;
    [self stopMovie:nil];
}

- (void) movieNaturalSizeAvailable:(NSNotification*)notification {
    movieDimensions = mc.naturalSize;
}

-(IBAction) stopMovie:(id)sender  {
    if (stopped) 
        return;
    stopped = YES;
    [self.mc stop]; 
    [self.mc setContentURL:nil];
    [self.mc.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    if (imageArray.count > 0)
        [self performSegueWithIdentifier:@"gallery" sender:nil];
    else
        [self movieActive:NO];
}
- (IBAction)backButton:(id)sender {
    if (stopped)
        return;
    stopped = YES;
    [self.mc stop];
    [self.mc setContentURL:nil];
    [self.mc.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self movieActive:NO];
    [imageArray removeAllObjects];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    GalleryCollectionView *vc = [segue destinationViewController];
    vc.imageArray             = imageArray;
}

- (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees{
    UIView *rotatedViewBox   = [[UIView alloc] initWithFrame:CGRectMake(0,0,oldImage.size.width, oldImage.size.height)];
    CGAffineTransform t      = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize       = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    CGContextRotateCTM(bitmap, (degrees * M_PI / 180));
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self stopMovie:nil];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Error:"
                                                   message: @"Ran out of memory"
                                                  delegate: self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
}

- (void)retriveAllVideos{
    loadingLabel.hidden = NO;
    [activityIndcator startAnimating];
    allVideos = [NSMutableArray new];
    ALAssetsLibrary *assetLibrary = [ALAssetsLibrary new];
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    ALAssetRepresentation *defaultRepresentation = [asset defaultRepresentation];
                    NSString *uti    = [defaultRepresentation UTI];
                    NSURL *urlTemp   = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
                    VideoClass *temp = [VideoClass new];
                    temp.url         = urlTemp;
                    temp.imageData   = [self keyFrame:urlTemp];
                    [allVideos addObject:temp];
                }
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityIndcator stopAnimating];
                if (allVideos.count == 0) {
                    loadingLabel.text = @"You do not have any videos on your phone";
                }else{
                    [galleryCollection reloadData];
                    loadingLabel.hidden = YES;
                }
            });
        }
    }failureBlock:^(NSError *error){
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
    }];
}

- (NSData *) keyFrame : (NSURL*) currentUrl{
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:currentUrl options:nil];;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime midpoint = CMTimeMake(0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
    
    UIImage *image;
    NSData *binaryImageData;
    if (halfWayImage != NULL) {
        image = [[UIImage alloc] initWithCGImage:halfWayImage];
        binaryImageData = UIImageJPEGRepresentation(image, 0.2f);
        CGImageRelease(halfWayImage);
    }
    return binaryImageData;
}

#pragma mark <UICollectionViewDataSource>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    currentIndexPath = indexPath;
    VideoClass *vid = [allVideos objectAtIndex:indexPath.row];
    if (oldIndexPath == nil) {
        vid.selected = YES;
        oldIndexPath = indexPath;
        [galleryCollection reloadItemsAtIndexPaths:@[indexPath]];
    }else
    if (oldIndexPath == indexPath) {
        if (vid.selected)
            vid.selected = NO;
        else
            vid.selected = YES;
        oldIndexPath = indexPath;
        [galleryCollection reloadItemsAtIndexPaths:@[indexPath]];
    }else{
        VideoClass *old = [allVideos objectAtIndex:oldIndexPath.row];
        old.selected    = NO;
        vid.selected    = YES;
        [galleryCollection reloadItemsAtIndexPaths:@[indexPath,oldIndexPath]];
        oldIndexPath = indexPath;
    }

    if (vid.selected)
        [self submitButtonUp];
    else
        [self submitButtonDown];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return allVideos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    VideoClass *vid          = [allVideos objectAtIndex:indexPath.row];
    cell.cellImage.image     = [UIImage imageWithData:vid.imageData];
    
    if(vid.selected)
        cell.selectedView.alpha = 0.5;
    else
        cell.selectedView.alpha = 0.0;
    
    return cell;
}

-(void) submitButtonUp{
    [UIView animateWithDuration:0.5 animations:^(){
        submitButton.frame = CGRectMake(0,screenHeight - 50, screenWidth, 50.0);
        collectionBottomConstraint.constant = 50.0;
        [self.view layoutIfNeeded];
    }];
}

-(void) submitButtonDown{
    [UIView animateWithDuration:0.5 animations:^(){
        submitButton.frame = CGRectMake(0,screenHeight, screenWidth, 50.0);
        collectionBottomConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
    }];
}

-(void) submitButtonAction {
    VideoClass *vid = [allVideos objectAtIndex:currentIndexPath.row];
    vid.selected    = NO;
    [galleryCollection reloadItemsAtIndexPaths:@[currentIndexPath]];
    [self submitButtonDown];
    [self movieActive:true];
    [UIView animateWithDuration:0.5 animations:^(){
        galleryCollection.alpha = 0.0;
    } completion:^(BOOL finished){
        [self movieSetup];
    }];
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int cellWidth = screenWidth/3.2;
    return CGSizeMake(cellWidth, cellWidth);
}

@end
