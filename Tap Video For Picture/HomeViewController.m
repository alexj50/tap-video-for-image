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
    screenWidth  = [[UIScreen mainScreen] bounds].size.width;                   // gets screen width
    screenHeight = [[UIScreen mainScreen] bounds].size.height;                  // sets screen height
    [self loadViewsInit];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) // hides status bar
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    else
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (BOOL)prefersStatusBarHidden {                                                // called to hide the staus bar
    return YES;
}

-(void) loadViewsInit {                                                         // loads all custom made views and tap recognizer
    activityIndcator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake((screenWidth/2) - 10,(screenHeight/2) - 10,20,20)];
    activityIndcator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndcator];
    
    loadingLabel               = [[UILabel alloc] initWithFrame:CGRectMake(0,(screenHeight/2) - 60,screenWidth,40)];
    loadingLabel.textAlignment = NSTextAlignmentCenter;                         // loading label
    loadingLabel.text          = @"Loading Video Library";
    loadingLabel.textColor     = [UIColor whiteColor];
    [self.view addSubview:loadingLabel];
    
    submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];           // animated next button
    [submitButton addTarget:self  action:@selector(submitButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:@"Next" forState:UIControlStateNormal];
    submitButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [submitButton setBackgroundColor:[UIColor blueColor]];
    [submitButton setTintColor:[UIColor whiteColor]];
    submitButton.frame = CGRectMake(0,screenHeight, screenWidth, 50.0);
    [self.view addSubview:submitButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(extractImage)];
    tap.numberOfTapsRequired    = 1;                                            // sets tap recognizer for image extraction
    [tapView addGestureRecognizer:tap];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    imageArray   = [NSMutableArray new];                                        // array that stores extracted images
    allVideos    = [NSMutableArray new];                                        // Video object that stores url and keyframe image
    oldIndexPath = nil;
    [self movieActive:NO];
    [self retriveAllVideos];
}

-(void) movieSetup{                                                             // creates and playes video that is selected
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self                      // called when playback is done
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.mc];
    
    [[NSNotificationCenter defaultCenter] addObserver:self                      // called to set global frame of video
                                             selector:@selector(movieNaturalSizeAvailable:)
                                                 name:MPMovieNaturalSizeAvailableNotification
                                               object:mc];
    
    [self performSelector:@selector(playDelay) withObject:nil afterDelay:1];    // need delay to allow system to start video
    [self performSelector:@selector(videoProgresIndicatior) withObject:nil afterDelay:1.5];
}

-(void) playDelay {
    [self.mc play];
}

-(void) videoProgresIndicatior {                                                // runs on a loop to animate custom progress indicator
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.1f
                                             target: self
                                           selector: @selector(updateProgressBar)
                                           userInfo: nil
                                            repeats: YES];
}

-(void) updateProgressBar {                                                     // handles progress bar animations
    if (mc.currentPlaybackTime < mc.duration){
        float position = (mc.currentPlaybackTime/mc.duration) * screenWidth;
        [UIView animateWithDuration:0.1 animations:^(){
            progressWidthCons.constant = position;
            [self.view layoutIfNeeded];
        }];
    }else
        [timer invalidate];
    
}

-(void) movieActive : (BOOL) movieActive {                                      // sets view alphas
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

-(void)extractImage {                                                           // called when user taps screen to extract image
    VideoClass *vid = [allVideos objectAtIndex:currentIndexPath.row];
    AVURLAsset *as                   = [[AVURLAsset alloc] initWithURL:vid.url options:nil];
    AVAssetImageGenerator *ima       = [[AVAssetImageGenerator alloc] initWithAsset:as];
    ima.requestedTimeToleranceBefore = kCMTimeZero;                             // gets exact frame instead of keyframe
    ima.requestedTimeToleranceAfter  = kCMTimeZero;
    NSError *err                     = NULL;
    CMTime time                      = CMTimeMake(mc.currentPlaybackTime * as.duration.timescale, as.duration.timescale);
    CGImageRef imgRef                = [ima copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *currentImg              = [[UIImage alloc] initWithCGImage:imgRef];
    
    if (floor(movieDimensions.width) < floor(movieDimensions.height))           // corrects image rotation
            currentImg = [self imageRotatedByDegrees : currentImg deg: 90];

    [imageArray addObject:currentImg];
}

- (void) moviePlayBackDidFinish:(NSNotification*)notification {                 // observer called when movie stopped
    progressStop = YES;
    [self stopMovie:nil];
}

- (void) movieNaturalSizeAvailable:(NSNotification*)notification {              // observer called to set movie demenisions
    movieDimensions = mc.naturalSize;
}

-(IBAction) stopMovie:(id)sender  {                                             // stops movie and resets movie player for new movie
    if (stopped) 
        return;
    stopped = YES;
    [self.mc stop]; 
    [self.mc setContentURL:nil];
    [self.mc.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    if (imageArray.count > 0)
        [self performSegueWithIdentifier:@"gallery" sender:nil];                // goes to photo review
    else
        [self movieActive:NO];
}
- (IBAction)backButton:(id)sender {                                             // cancel video go back to video gallery
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {          // send video array to next view
    GalleryCollectionView *vc = [segue destinationViewController];
    vc.imageArray             = imageArray;
}

- (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees{     // fixes image rotation issues
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

- (void)didReceiveMemoryWarning {                                               // handles if user taps to many times and takes up all
                                                                                // the memory
    [super didReceiveMemoryWarning];
    [self stopMovie:nil];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Error:"
                                                   message: @"Ran out of memory"
                                                  delegate: self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
}

- (void)retriveAllVideos{                                                       // ran on own async thread to collect all the videos
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
                    VideoClass *temp = [VideoClass new];                        // set video object
                    temp.url         = urlTemp;
                    temp.imageData   = [self keyFrame:urlTemp];                 // get first frame
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

- (NSData *) keyFrame : (NSURL*) currentUrl{                                    // grabs first frame to display in video picker
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:currentUrl options:nil];;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime midpoint = CMTimeMake(0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef firstFrame = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
    
    UIImage *image;
    NSData *binaryImageData;
    if (firstFrame != NULL) {
        image = [[UIImage alloc] initWithCGImage:firstFrame];
        binaryImageData = UIImageJPEGRepresentation(image, 0.2f);
        CGImageRelease(firstFrame);
    }
    return binaryImageData;
}

#pragma mark <UICollectionViewDataSource>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{// toggles highlighted cell
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {// sections in gallery
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section { // how many videos are there
    return allVideos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath { //assembles the collection cell
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    VideoClass *vid          = [allVideos objectAtIndex:indexPath.row];
    cell.cellImage.image     = [UIImage imageWithData:vid.imageData];
    
    if(vid.selected)
        cell.selectedView.alpha = 0.5;
    else
        cell.selectedView.alpha = 0.0;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{                                                                               // dynamically sets cell sizes for iphone screen
    int cellWidth = screenWidth/3.2;
    return CGSizeMake(cellWidth, cellWidth);
}


-(void) submitButtonUp{                                                         // animates next button up
    [UIView animateWithDuration:0.5 animations:^(){
        submitButton.frame = CGRectMake(0,screenHeight - 50, screenWidth, 50.0);
        collectionBottomConstraint.constant = 50.0;
        [self.view layoutIfNeeded];
    }];
}

-(void) submitButtonDown{                                                       // animates next button down
    [UIView animateWithDuration:0.5 animations:^(){
        submitButton.frame = CGRectMake(0,screenHeight, screenWidth, 50.0);
        collectionBottomConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
    }];
}

-(void) submitButtonAction {                                                    // when user hits submit
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

@end
