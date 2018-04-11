
//
//  LockViewController.m
//  GCD-TestDemo
//
//  Created by hjw on 2018/4/10.
//  Copyright © 2018年 hjw. All rights reserved.
//

#import "LockViewController.h"

@interface LockViewController ()

{
    //3个售票员
    NSThread *thread1;
    NSThread *thread2;
    NSThread *thread3;
    
    NSThread *thread4;
    
    //票的张数
    int num;
    
    
    //锁
    NSLock *lock;
    
    
    //生产者消费者模式
    NSCondition *condition ;
    
    NSTimer *timer;
}
@end

@implementation LockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    num = 10;
    
    //创建锁的对象
    lock = [[NSLock alloc] init];
    
    thread1 = [[NSThread alloc] initWithTarget:self selector:@selector(thread) object:nil];
    thread1.name = @"售票员小花";
    
    thread2 = [[NSThread alloc] initWithTarget:self selector:@selector(thread) object:nil];
    thread2.name = @"售票员小草";
    
    thread3 = [[NSThread alloc] initWithTarget:self selector:@selector(thread) object:nil];
    thread3.name = @"售票员小芳";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(50, 100, 80, 60);
    button.backgroundColor = [UIColor orangeColor];
    [button setTitle:@"售票" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //创建对象
    condition = [[NSCondition alloc] init];
    
    
    thread3 = [[NSThread alloc] initWithTarget:self selector:@selector(thread4) object:nil];
    
    
}

-(void)thread4
{
    NSLog(@"%d",[NSThread isMainThread]);
    //如果要在次线程中添加timer ,那么需要开启一个runloop, 将创建好的timer添加到runloop中,，并且启动runloop，否则定时器不会启动
    timer =[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(changes) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

-(void)changes
{
    if (num==0) {
        [timer invalidate];
        timer = nil;
    }
    NSLog(@"XXXXXX");
}

-(void)startBtn
{
    [thread1 start];
    [thread2 start];
    [thread3 start];
    [thread4 start];
}

-(void)thread
{
    
    while (num>0)
    {
        
        //加锁解锁
        //加锁  **********1.加NSLock锁************
        //[lock lock];
        
        [condition lock];//**************2.加condition锁**************
        
        if (num>0)
        {
            //模拟售票耗时
            [NSThread sleepForTimeInterval:1];
            NSLog(@"当前售票员%@  还剩%d张票",[NSThread currentThread], --num);
        }
        
        [condition unlock];
        
        //解锁
        //[lock unlock];
        
        
        
        //3.加互斥锁
        //        @synchronized(self)
        //        {
        //            if (num>0)
        //            {
        //                //模拟售票耗时
        //                [NSThread sleepForTimeInterval:0.5];
        //                NSLog(@"当前售票员%@  还剩%d张票",[NSThread currentThread], --num);
        //            }
        //        }
        
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
