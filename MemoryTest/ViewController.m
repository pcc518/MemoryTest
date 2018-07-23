//
//  ViewController.m
//  MemoryTest
//
//  Created by huijin on 2018/7/20.
//  Copyright © 2018年 huijin. All rights reserved.
//

#import "ViewController.h"
#import <sys/types.h>
#import <sys/sysctl.h>

#define CRASH_MEMORY_FILE_NAME @"CrashMemory.dat"
#define MEMORY_WARNINGS_FILE_NAME @"MemoryWarnings.dat"

@interface ViewController () {
  
    NSTimer *timer;
    
    int allocatedMB;
    Byte *p[10000];
    uint64_t physicalMemorySize;
    uint64_t userMemorySize;
    
    NSMutableArray *infoLabels;
    NSMutableArray *memoryWarnings;
    
    BOOL initialLayoutFinished;
    BOOL firstMemoryWarningReceived;
}
@property (weak, nonatomic) IBOutlet UILabel *totalMemoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *userMemoryLabel;
@property (weak, nonatomic) IBOutlet UIView *allocatedMemoryView;
@property (weak, nonatomic) IBOutlet UIView *kernelMemoryView;
@property (weak, nonatomic) IBOutlet UIView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    infoLabels = [NSMutableArray new];
    memoryWarnings = [NSMutableArray new];
    
}

- (void)viewDidLayoutSubviews {
    if (!initialLayoutFinished) {
        
        [self refreshMemoryInfo];
        [self refreshUI];
        
        NSString *basePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSInteger crashMemory = [[NSKeyedUnarchiver unarchiveObjectWithFile:[basePath stringByAppendingString:CRASH_MEMORY_FILE_NAME]] intValue];
        if (crashMemory > 0) {
            [self addLabelAtMemoryProgress:crashMemory text:@"Crash" color:[UIColor lightGrayColor]];
        }
        NSArray *lastMemoryWarnings = [NSKeyedUnarchiver unarchiveObjectWithFile:[basePath stringByAppendingPathComponent:MEMORY_WARNINGS_FILE_NAME]];
        if (lastMemoryWarnings) {
            
            for (NSNumber *number in lastMemoryWarnings) {
                
                [self addLabelAtMemoryProgress:[number intValue] text:@"Memory Warning" color:[UIColor redColor]];
            }
        }
        
        initialLayoutFinished = YES;
    }
}

- (void)refreshMemoryInfo {
    
    //get memory info
    int mib[2];
    size_t length;
    mib[0] = CTL_HW;
    
    mib[1] = HW_MEMSIZE;
    length = sizeof(int64_t);
    sysctl(mib, 2, &physicalMemorySize, &length, NULL, 0);
    
    mib[1] = HW_USERMEM;
    length = sizeof(int64_t);
    sysctl(mib, 2, &userMemorySize, &length, NULL, 0);
    
    
}

- (void)refreshUI {
    
    long physicalMemorySizeMB = physicalMemorySize / (1024 * 1024);
    long userMemorySizeMB = userMemorySize / (1024 * 1024);
    
    self.userMemoryLabel.text = [NSString stringWithFormat:@"%ld MB -", userMemorySizeMB];
    self.totalMemoryLabel.text = [NSString stringWithFormat:@"%ld MB -", physicalMemorySizeMB];
    
    
    CGRect rect;
    
    CGFloat userMemoryProgressLength = self.progressView.bounds.size.height * (userMemorySizeMB / (float)physicalMemorySizeMB);
    
    //userMemoryLabel frame
    rect = self.userMemoryLabel.frame;
    rect.origin.y = roundf((self.progressView.bounds.size.height - userMemoryProgressLength) - self.userMemoryLabel.bounds.size.height * 0.5 + self.progressView.frame.origin.y);
    self.userMemoryLabel.frame = rect;
    
    //kernelMemoryView frame
    rect = self.kernelMemoryView.frame;
    rect.size.height = roundf(self.progressView.bounds.size.height - userMemoryProgressLength);
    self.kernelMemoryView.frame = rect;

    //allocatedMemoryView
    rect = self.allocatedMemoryView.frame;
    rect.size.height = roundf(self.progressView.bounds.size.height * (allocatedMB / (float)physicalMemorySizeMB));
    rect.origin.y = self.progressView.bounds.size.height - rect.size.height;
    self.allocatedMemoryView.frame = rect;
    
    
}

- (void)addLabelAtMemoryProgress:(NSInteger)memory text:(NSString*)text color:(UIColor*)color {
    
    CGFloat length = self.progressView.bounds.size.height * (1.0f - memory / (float)(physicalMemorySize / (1024 *1024)));
    
    CGRect rect;
    rect.origin.x = 20;
    rect.size.width = self.progressView.frame.origin.x - rect.origin.x - 5;
    rect.size.height = 20;
    rect.origin.y = roundf(self.progressView.frame.origin.y + length - rect.size.height * 0.5f);
    
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.textAlignment = NSTextAlignmentRight;
    label.text = [NSString stringWithFormat:@"%@ %ld MB -", text, memory];
    label.font = self.totalMemoryLabel.font;
    label.textColor = color;
    
    [infoLabels addObject:label];
    [self.view addSubview:label];
}
- (IBAction)startNewTest:(UIButton *)sender {
    
    [self clearAll];
    firstMemoryWarningReceived = NO;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(allocateMemory) userInfo:nil repeats:YES];
}

- (void)allocateMemory {
    
    p[allocatedMB] = malloc(1024 * 1024);
    memset(p[allocatedMB], 0, 1024 * 1024);
    allocatedMB += 1;
    
    [self refreshMemoryInfo];
    [self refreshUI];
    
    if (firstMemoryWarningReceived) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = paths.firstObject;
        [NSKeyedArchiver archiveRootObject:@(allocatedMB) toFile:[basePath stringByAppendingPathComponent:CRASH_MEMORY_FILE_NAME]];
    }
}

- (void)clearAll {
    
    for (int i = 0; i < allocatedMB; i++) {
        free(p[i]);
    }
    
    allocatedMB = 0;
    
    [infoLabels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [infoLabels removeAllObjects];
    
    [memoryWarnings removeAllObjects];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    firstMemoryWarningReceived = YES;
    
    [self addLabelAtMemoryProgress:allocatedMB text:@"Memory Warning" color:[UIColor lightGrayColor]];
    
    [memoryWarnings addObject:@(allocatedMB)];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    [NSKeyedArchiver archiveRootObject:memoryWarnings toFile:[basePath stringByAppendingPathComponent:MEMORY_WARNINGS_FILE_NAME]];
}

- (void)dealloc {
    
    [timer invalidate];
    [self clearAll];
    
    infoLabels = nil;
    memoryWarnings = nil;
    
    initialLayoutFinished = NO;
}

@end
