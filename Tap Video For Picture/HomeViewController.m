//
//  ViewController.m
//  tapVideoForPicture
//
//  Created by Jacobson on 2/23/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//
//  Software written for the expressed purpose of evaluating
//  Alex Jacobson's software programing skills.
//
//  Any commercial use of this software without the expressed written
//  concent of Alex Jacobson is strictly forbidden
//
// contact: ajacobson50@gmial.com

#define FONT(s) [UIFont fontWithName:@"BrushHandNew" size:s]
#define WATERMARKFONT(s) [UIFont fontWithName:@"Story Book" size:s]

#import "HomeViewController.h"
#import <MediaPlayer/MediaPlayer.h>
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
@property (strong, nonatomic) IBOutlet UIView *progressContainer;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UILabel *HomeTitle;
@property (strong, nonatomic) MPMoviePlayerController *mc;
@property (strong, nonatomic) NSMutableArray *imageArray;
@property (strong, nonatomic) NSIndexPath *oldIndexPath,*currentIndexPath;
@property (strong, nonatomic) UIButton *submitButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndcator;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UILabel *loadingLabel;
@property (strong, nonatomic) UIView *progressBar;

@property float totalTime;
@property CGSize movieDimensions;
@end

@implementation HomeViewController
@synthesize mc,tapView,imageArray,videoView,totalTime,movieDimensions,galleryCollection,allVideos,oldIndexPath,collectionBottomConstraint,submitButton,currentIndexPath,activityIndcator,loadingLabel,timer,progressBar,progressContainer,nextButton,backButton,HomeTitle;

static bool stopped = NO,started = NO,progressStop = NO,videoActive = NO;
static NSString *const reuseIdentifier = @"home";
static int screenWidth = 0, screenHeight = 0,backgroundActive = 0;

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

-(void) loadViewsInit {                                                         // loads all custom made views and tap recognize
    activityIndcator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake((screenWidth/2) - 10,(screenHeight/2) - 10,20,20)];
    activityIndcator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndcator];
    
    loadingLabel               = [[UILabel alloc] initWithFrame:CGRectMake(0,(screenHeight/2) - 70,screenWidth,50)];
    loadingLabel.textAlignment = NSTextAlignmentCenter;                         // loading label
    loadingLabel.font          = FONT(40);
    loadingLabel.text          = @"Loading Video Library";
    loadingLabel.numberOfLines = 0;
    loadingLabel.textColor     = [UIColor whiteColor];
    [self.view addSubview:loadingLabel];
    
    submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];           // animated next button
    [submitButton addTarget:self  action:@selector(submitButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:@"Play" forState:UIControlStateNormal];
    submitButton.titleLabel.font = FONT(34);
    [submitButton sizeToFit];
    [submitButton setBackgroundColor:[UIColor blueColor]];
    [submitButton setTintColor:[UIColor whiteColor]];
    submitButton.frame = CGRectMake(0,screenHeight, screenWidth, 50.0);
    [self.view addSubview:submitButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(extractImage)];
    tap.numberOfTapsRequired    = 1;                                            // sets tap recognizer for image extraction
    [tapView addGestureRecognizer:tap];
    
    progressBar                 = [UIView new];
    progressBar.frame           = CGRectMake(0, 0, 0, progressContainer.frame.size.height);
    progressBar.backgroundColor = [UIColor blueColor];
    [progressContainer addSubview:progressBar];
    
    nextButton.titleLabel.font = FONT(26);                                      // Sets next button font
    backButton.titleLabel.font = FONT(26);                                      // Sets back button font
    HomeTitle.font             = FONT(48);                                      // sets tiltle font
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    imageArray              = [NSMutableArray new];                             // array that stores extracted images
    oldIndexPath            = nil;
    videoActive             = NO;
    tapView.alpha           = 0;
    galleryCollection.alpha = 0.0;
    HomeTitle.alpha         = 1.0;
    [self retriveAllVideos];
}

-(void) movieSetup{                                                             // creates and playes video that is selected
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    progressBar.frame = CGRectMake(0, 0, 0, progressContainer.frame.size.height);
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
    

}

-(void) play{
    [self.mc play];
    [self videoProgresIndicatior];
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
            progressBar.frame = CGRectMake(0, 0, position, progressContainer.frame.size.height);
        }];
    }else
        [timer invalidate];
    
}

-(void) movieActive : (BOOL) movieActive {                                      // sets view alphas
    if (movieActive){
        [UIView animateWithDuration:0.5 animations:^(){
            tapView.alpha           = 1;
            galleryCollection.alpha = 0.0;
            HomeTitle.alpha         = 0.0;
        }];
    }else{
        videoActive = NO;
        [UIView animateWithDuration:0.5 animations:^(){
            tapView.alpha           = 0;
            galleryCollection.alpha = 1.0;
            HomeTitle.alpha         = 1.0;
        }];
    }
}

-(void)extractImage {                                                           // called when user taps screen to extract image
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        backgroundActive                 = 2;
        VideoClass *vid                  = [allVideos objectAtIndex:currentIndexPath.row];
        AVURLAsset *as                   = [[AVURLAsset alloc] initWithURL:vid.url options:nil];
        AVAssetImageGenerator *ima       = [[AVAssetImageGenerator alloc] initWithAsset:as];
        ima.requestedTimeToleranceBefore = kCMTimeZero;                         // gets exact frame instead of keyframe
        ima.requestedTimeToleranceAfter  = kCMTimeZero;
        NSError *err                     = NULL;
        CMTime time                      = CMTimeMake(mc.currentPlaybackTime * as.duration.timescale, as.duration.timescale);
        CGImageRef imgRef                = [ima copyCGImageAtTime:time actualTime:NULL error:&err];
        UIImage *currentImg              = [[UIImage alloc] initWithCGImage:imgRef];
    
        if (floor(movieDimensions.width) < floor(movieDimensions.height))       // corrects image rotation
            currentImg = [self imageRotatedByDegrees : currentImg deg: 90];

        currentImg = [self addWaterMark:currentImg];
        [imageArray addObject:currentImg];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (backgroundActive == 1) {
                if (imageArray.count > 0)
                    [self performSegueWithIdentifier:@"gallery" sender:nil];    // goes to photo review
                else
                    [self movieActive:NO];
            }
            
            backgroundActive = 0;
        });
    });
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
    
    if (backgroundActive == 2) {
        backgroundActive = 1;
        return;
    }
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
    vc.allVideos              = allVideos;
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

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (void)retriveAllVideos{                                                       // ran on own async thread to collect all the videos
    HomeTitle.alpha = 0.0;
    if (allVideos == nil || allVideos.count == 0)
        allVideos = [NSMutableArray new];                                       // Video object that stores url and keyframe image
    else{
        [activityIndcator stopAnimating];
        [galleryCollection reloadData];
        loadingLabel.hidden = YES;
        [self movieActive:NO];
        return;
    }
    loadingLabel.hidden = NO;
    [activityIndcator startAnimating];

    ALAssetsLibrary *assetLibrary = [HomeViewController defaultAssetsLibrary];
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    ALAssetRepresentation *defaultRepresentation = [asset defaultRepresentation];
                    NSString *uti    = [defaultRepresentation UTI];
                    NSURL *urlTemp   = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
                    VideoClass *temp = [VideoClass new];                        // set video object
                    temp.asset       = asset;
                    temp.url         = urlTemp;
//                    temp.imageData   = [self keyFrame:urlTemp];                 // get first frame
                    [allVideos addObject:temp];
                }
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityIndcator stopAnimating];
                if (allVideos.count == 0) {
                    loadingLabel.text = @"No Videos";
                }else{
                    [self movieActive:NO];
                    [galleryCollection reloadData];
                    loadingLabel.hidden = YES;
                }
            });
        }
    }failureBlock:^(NSError *error){
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
    }];
}

//- (NSData *) keyFrame : (NSURL*) currentUrl{                                    // grabs first frame to display in video picker
//    AVAsset *asset = [[AVURLAsset alloc] initWithURL:currentUrl options:nil];;
//    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
//    imageGenerator.appliesPreferredTrackTransform = YES;
//    CMTime midpoint = CMTimeMake(0, 600);
//    NSError *error = nil;
//    CMTime actualTime;
//    CGImageRef firstFrame = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
//    
//    UIImage *image;
//    NSData *binaryImageData;
//    if (firstFrame != NULL) {
//        image = [[UIImage alloc] initWithCGImage:firstFrame];
//        binaryImageData = UIImageJPEGRepresentation(image, 0.2f);
//        CGImageRelease(firstFrame);
//    }
//    return binaryImageData;
//}

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
    
    [self movieSetup];
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
    cell.cellImage.image     =  [UIImage imageWithCGImage:vid.asset.thumbnail];
    
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
    [UIView animateWithDuration:0.3 animations:^(){
        submitButton.frame = CGRectMake(0,screenHeight - 50, screenWidth, 50.0);
        collectionBottomConstraint.constant = 50.0;
        [self.view layoutIfNeeded];
    }];
}

-(void) submitButtonDown{                                                       // animates next button down
    [UIView animateWithDuration:0.3 animations:^(){
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
    
    [self performSelector:@selector(play) withObject:nil afterDelay:0.8];
}

-(UIImage*) addWaterMark : (UIImage*) backgroundImage {                         // adds custom text watermark to image
    CGSize newSize = CGSizeMake(backgroundImage.size.width, backgroundImage.size.height);
    UIGraphicsBeginImageContext( newSize );
    
    // Use existing opacity as is
    [backgroundImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    UIImage *watermark = [self customWaterMarkImage:backgroundImage.size];
    // Apply supplied opacity if applicable
    [watermark drawInRect:CGRectMake(0,newSize.height - watermark.size.height, watermark.size.width,watermark.size.height) blendMode:kCGBlendModeNormal alpha:0.6];
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

-(UIImage*) customWaterMarkImage : (CGSize) backroundFrame{                     // creates watermark
    int viewHeight               = backroundFrame.height * 0.05;
    UILabel *waterText           = [[UILabel alloc] initWithFrame:CGRectMake(0, backroundFrame.height - viewHeight, backroundFrame.width, viewHeight)];
    waterText.textAlignment      = NSTextAlignmentCenter;
    waterText.font               = WATERMARKFONT(viewHeight * 0.6);
    waterText.minimumScaleFactor = 0.1;
    waterText.text               = @"Alex Jacobson";
    waterText.textColor          = [UIColor whiteColor];
    waterText.backgroundColor    = [UIColor blueColor];
    
    UIGraphicsBeginImageContext(waterText.bounds.size);
    [waterText.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

@end
