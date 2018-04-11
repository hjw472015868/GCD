//
//  ViewController.m
//  GCD-TestDemo
//
//  Created by hjw on 2018/4/9.
//  Copyright © 2018年 hjw. All rights reserved.
//

#import "ViewController.h"
#import "LockViewController.h"
#import "SyncViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    UITableView *_table;
    NSArray *_titleArr;
}
@end

@implementation ViewController



//1.Serial Dispatch Queue串行队列
- (void) testSerialDispatchQueue
{
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("com.hjw.gcd.mySerialDispatchQueue", NULL);
    dispatch_async(mySerialDispatchQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"AA = %d", i);
        }
    });
    dispatch_async(mySerialDispatchQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"BB = %d", i);
        }
    });
    dispatch_async(mySerialDispatchQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"CC = %d", i);
        }
    });
}

//2. Concurrent Dispatch Queue并行队列
- (void) testConcurrentDispatchQueue
{
    dispatch_queue_t myConcurrentDispatchQueue = dispatch_queue_create("com.hjw.gcd.myConcurrentDispatchQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(myConcurrentDispatchQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"AA = %d", i);
        }
    });
    dispatch_async(myConcurrentDispatchQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"BB = %d", i);
        }
    });
    dispatch_async(myConcurrentDispatchQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"CC = %d", i);
        }
    });
}

//3. dispatch_get_global_queue//拿到的是可用的并行队列
- (void) testGlobaQueue
{
//    [self testConcurrentDispatchQueue];
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"AA = %d", i);
        }
    });
    dispatch_async(globalQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"BB = %d", i);
        }
    });
    dispatch_async(globalQueue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"CC = %d", i);
        }
    });
    
    NSLog(@"XXXX = %d", globalQueue == dispatch_get_main_queue());
    
}


//4.testDispatchSetTargetQueue修改队里的优先级,指向和另一个优先级相同的队列, 也可改变队列的执行方式
- (void)testDispatchSetTargetQueue
{
    dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("com.hjw.gcd.mySerialDispatchQueue", NULL);
    dispatch_queue_t targetQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_set_target_queue(mySerialDispatchQueue, targetQueue);
    
    dispatch_async(mySerialDispatchQueue, ^{
        NSLog(@"我的优先级改了");
    });
}


//5.dispatch_after延时设置
//dispatch_after并不是在指定时间后处理执行, 只是在指定时间追加处理到dispatch queue, 因为main dispatch quque在主线程的runloop中执行, 所以每隔n秒的执行runloop中. block最快在设置的时间执行, 最慢在设置时间+n秒后执行, 并且在main dispatch quque有大量处理追加或主线程的处理本身有延迟时, 这个时间更长
//第一个参数 :指定时间用dispatch_time_t类型的值, 该值可以使用dispatch_time函数或dispatch_walltime函数制作
//第二个参数指定要追加处理的dispatch queue
//第三个参数指定要执行的block
- (void)dispatchAfter
{
    //    NSEC_PER_SEC 毫微秒
    //    NSEC_PER_MSEC 毫秒
    //    ull C语言数字字面量现实表明雷士时使用的字符串, 表示 unsigned long long
    NSLog(@"hehhe");
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3000ull*NSEC_PER_MSEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
        NSLog(@"哈哈哈");
    });
    
    [self getDispatchTimeByDate:[NSDate date]];
}
//制作dispatch_time_t
- (dispatch_time_t)getDispatchTimeByDate:(NSDate *)date
{
    NSTimeInterval interval;
    double second, subsecond;
    struct timespec time;
    dispatch_time_t milestone;
    
    interval = [date timeIntervalSince1970];
    subsecond = modf(interval, &second);
    time.tv_sec = second;
    time.tv_nsec = subsecond*NSEC_PER_MSEC;
    milestone = dispatch_walltime(&time, 0);
    NSLog(@"%llu",milestone);
    return milestone;
}
//16923483248132900520
//16923483202709521056




//6.Dispatch_gruop
- (void) testDispatchGruop
{
    //1.拿到并发队列 queue
    //2.创建gruop
    //3.用gruop的函数去执行queue队列里面的block
    //4.用gruop的notify监管执行完成后的block
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_t gruop = dispatch_group_create();
    
    dispatch_group_async(gruop, queue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"AAA == %d", i);
        }
        NSLog(@"A执行完成");
    });
    dispatch_group_async(gruop, queue, ^{
        for (int i=0; i<1000; i++) {
            NSLog(@"aaa == %d", i);
        }
        NSLog(@"a执行完成");
    });
    dispatch_group_notify(gruop, dispatch_get_main_queue(), ^{
        NSLog(@"执行结束!");
    });
}



//6.1 dispatch_group_wait
- (void) testDispatchGruopWithWait
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t gruop = dispatch_group_create();
    dispatch_group_async(gruop, queue, ^{
        for (int i=0; i<10000; i++) {
            NSLog(@"AAA == %d", i);
        }
        NSLog(@"A执行完成");
    });
    dispatch_group_async(gruop, queue, ^{
        for (int i=0; i<10000; i++) {
            NSLog(@"aaa == %d", i);
        }
        NSLog(@"a执行完成");
    });
    //DISPATCH_TIME_FOREVER, 以为这永久等待,, 这里这么设置,必定全部执行结束, time返回值恒为0
    //3ull*NSEC_PER_SEC指定等待时间间隔为3秒
    //dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER);
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3ull*NSEC_PER_SEC);

    long result = dispatch_group_wait(gruop, time);
    
    //这个rusult会在3秒后, 执行下面的代码, 其实类似于串行, 要等gruop执行完了,才会走会面的代码
    NSLog(@"result = %ld", result);
    if (result == 0) {
        NSLog(@"全部执行完!");
    }else{
        NSLog(@"dispatch gruop中某个线程还在执行中");
    }
//     DISPATCH_TIME_NOW,则不用任何等到即可判断属于dispatch_gruop的处理是否执行结束
//     long result1 = dispatch_group_wait(gruop, DISPATCH_TIME_NOW);
}



//7.dispatch_barrier_async结合并发队列,实现高效率的数据库访问和文件访问
//使用dispatch_barrier_async函数会等待追加到concurrent dispatch queue上的并行执行的处理全部结束之后, 再将指定的处理追加到该concurrent dispatch queue中,然后在由dispatch_barrier_async函数追加的处理执行完毕后,concurrent dispatch queue才恢复一般的动作,追加到该concurrent dispatch queue的处理又开始并执行
- (void) testDispatchBarrierAsync
{
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t queue = dispatch_queue_create("com.hjw.gcd.dispatchBarrierAsync", DISPATCH_QUEUE_CONCURRENT);
    NSInteger intger  = 0;
    NSMutableArray *arr = [NSMutableArray array];
    while (intger<20000) {
        [arr addObject:@(intger)];
        intger++;
    }
    
    
    dispatch_async(queue, ^{
        for (int i=0; i<5000; i++) {
            NSLog(@"a = %@", arr[i]);
        }
    });
    
    dispatch_async(queue, ^{
        for (int i=5000; i<10000; i++) {
            NSLog(@"b = %@", arr[i]);
        }
    });
    
    //*****在这里写这个阻碍函数, 之前的先执行完, 然后执行这个代码块里面的代码,最后再去执行后面的queue里面的block代码块
    dispatch_barrier_async(queue, ^{
        NSInteger num = 0;
        while (num<10) {
            [arr addObject:[NSString stringWithFormat:@"INSERT = %ld", num]];
            num++;
        }
    });
    
    
    dispatch_async(queue, ^{
        for (int i=10000; i<15000; i++) {
            NSLog(@"c = %@", arr[i]);
        }
    });
    
    dispatch_async(queue, ^{
        for (int i=15000; i<arr.count; i++) {
            NSLog(@"d = %@", arr[i]);
        }
    });
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"异步线程";
    
    _titleArr = @[@"Serial Dispatch Queue(串行)",@"Concurrent Dispatch Queue(并行)",@"dispatch_get_global_queue(并行)",@"dispatch_set_target_queue(设置优先级)",@"dispatch_after(延时设置)",@"dispatchGruop(调度)",@"testDispatchGruopWithWait(wait调度)",@"testDispatchBarrierAsync(阻碍是读写)",@"去加锁界面",@"去同步界面"];
    
    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64) style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.tableFooterView = [UIView new];
    [self.view addSubview:_table];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_titleArr count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = _titleArr[indexPath.row];
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self testSerialDispatchQueue];
            break;
            
        case 1:
            [self testConcurrentDispatchQueue];
            break;
            
        case 2:
            [self testGlobaQueue];
            break;
            
        case 3:
            [self testDispatchSetTargetQueue];
            break;
            
        case 4:
            [self dispatchAfter];
            break;
            
        case 5:
            [self testDispatchGruop];
            break;
            
        case 6:
            [self testDispatchGruopWithWait];
            break;
            
        case 7:
            [self testDispatchBarrierAsync];
            break;
            
        case 8:
            [self goToLockTest];
            break;
            
        case 9:
            [self goToSyncTest];
            break;
            
        default:
            break;
    }
}




#pragma mark - 去加锁的界面
- (void)goToLockTest
{
    LockViewController *lockVc = [[LockViewController alloc] init];
    [self.navigationController pushViewController:lockVc animated:YES];
}

#pragma mark - 去同步的界面
- (void)goToSyncTest
{
    SyncViewController *syncVc = [[SyncViewController alloc] init];
    [self.navigationController pushViewController:syncVc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
