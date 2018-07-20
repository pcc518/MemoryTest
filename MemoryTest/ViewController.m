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
- (IBAction)startNewTest:(UIButton *)sender {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
