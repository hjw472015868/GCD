//
//  SyncViewController.m
//  GCD-TestDemo
//
//  Created by hjw on 2018/4/10.
//  Copyright © 2018年 hjw. All rights reserved.
//

#import "SyncViewController.h"

@interface SyncViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    UITableView *_table;
    NSArray *_titleArr;
}

@end

@implementation SyncViewController

//1.执行Main Dispatch Queue时, 使用另外的线程global dispatch queue进行处理, 处理结束后立即使用得到的结果, 可以理解为减一半的dispatch_group_wait
- (void) test1
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        NSLog(@"执行!");
    });
}

//2. 在主线程中执行指定的block.如下, 造成死锁
- (void) test2
{
    dispatch_queue_t queue = dispatch_get_main_queue();
//    dispatch_sync(queue, ^{
//        NSLog(@"死锁");
//    });
    dispatch_async(queue, ^{
        dispatch_sync(queue, ^{
            NSLog(@"死锁");
        });
    });
}


//3.dispatch_apply按指定的次数将制定的block追加到指定的dispatch queue中, 并等待全部处理执行结束
//第一个参数为重复次数
//第二个参数为追击对象的dispatch queue
//第三个参数为追加的处理
- (void)testDispatchApply
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_apply(10, queue, ^(size_t index) {
        NSLog(@"%zu",index);
    });
    
    
    //由于dispatch_apply与dispatch_sync相同都会等待处理执行结束, 因此建议在dispatch_async函数中非同步的执行dispatch_apply函数
    NSMutableArray *arr = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        [arr addObject:@(i)];
    }

    dispatch_async(queue, ^{
        //等待dispatch_apply函数中全部处理执行结束
        dispatch_apply(arr.count, queue, ^(size_t index) {
            //并列处理包含在arr对象的全部对象
            NSLog(@"%zu, %@", index, arr[index]);
        });
    });
    
    
    //dispatch_apply函数的处理全部执行结束
    //在main dispatch queue中非同步执行
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"完成");
    });
}

//    dispatch_suspend  挂起指定的quque
//    dispatch_resume   回复指定的queue
//这些函数对已经执行的处理没有影响, 但是对未执行的处理有影响, 挂起停止位执行的, 回复继续执行



//dispatch semaphore
//持有技术的信号, 该技术是多线程编程中的技术类型信息, 计数为0事等待, 计数为1或大于1,减去1而不等待
- (void)dispatchsemaphore
{
    //生成dispatch_semaphore_t, 参数表示计数的初始值, 这里初始化为1
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull*NSEC_PER_SEC);
    //调用dispatch_semaphore_wait
    long result = dispatch_semaphore_wait(semaphore, time);
    if (result == 0) {
        /*
         由于dispatch semaphore的计数值达到大于等于1,或者在待机中的指定时间内, dispatch semaphore的计数值达到大于等于1, 所以dispatch semaphore的计数值减去1
         可需要进行排他控制的处理
         */
    }else{
        /*
         由于dispatch semaphore的计数值为0
         因此在达到指定时间为止待机
         */
    }
}
//4.dispatch_semaphore_wait和dispatch_semaphore_signal合用
//dispatch_semaphore_wait函数返回0时,可安全的执行需要进行排他控制的处理, 该处理结束时通过dispatch_semaphore_signal的计数值加1
- (void)dispatch_semaphore_waitAndDispatch_semaphore_signal
{
    /****不考虑顺序的情况下给数组添加内容****/
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSMutableArray *arr = [NSMutableArray array];
    /*//这种写法回到吃程序异常结束
    for (int i=0; i<10000;i++) {
        dispatch_async(queue, ^{
            [arr addObject:@(i)];
        });
    }
    */
    //生成dispatch_semaphore_t, 这里初始化为1, 同时只能访问1个
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    for (int i=0; i<10000;i++) {
        dispatch_async(queue, ^{
            //一直等待, dispatch_semaphore_t直到计数值达到或者大于1
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            /*
            由于dispatch semaphore的计数值达到大于等于1
            所以dispatch semaphore的计数值减去1
            dispatch_semaphore_wait函数执行返回
            即执行到此时的dispatch_semaphore的计数值恒为0
            由于可访问的arr类对象的线程只有1个, 因此可安全的进行更新
            */
            [arr addObject:@(i)];
            
            /*
             排除他控处理结束
             所有通过dispatch_semaphore_signal函数将dispatch semaphore的计数值加1
             如果有通过dispatch_semaphore_wait等待dispatch semaphore的技术只增加的线程, 就由最先等待的线程执行
             */
            dispatch_semaphore_signal(semaphore);
        });
    }
}



//5.dispatch_once保证在应用程序中只执行一次的API,经常出现在初始化代码中, 比如单利的创建
- (void)dispatchOnce
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /*
         初始化
         */
    });
}



//6.dispatch I/O
//读取大文件时,可以将文件分成合适的大小并使用queue队列进行读取,
//通过dispatchI/O和dispatch Data可以实现
//读写操作按顺序依次顺序进行。在读或写开始时，操作总是在文件指针位置读或写数据。读和写操作可以在同一个信道上同时进行。
//通过Dispatch I/O读写文件时，使用Global Dispatch Queue将1个文件按某个大小read／write。
//dispatch_async(queue, ^{ /* 读取  0     ～ 8080  字节*/ });
//dispatch_async(queue, ^{ /* 读取  8081  ～ 16383 字节*/ });
//dispatch_async(queue, ^{ /* 读取  16384 ～ 24575 字节*/ });
//dispatch_async(queue, ^{ /* 读取  24576 ～ 32767 字节*/ });
//dispatch_async(queue, ^{ /* 读取  32768 ～ 40959 字节*/ });
//dispatch_async(queue, ^{ /* 读取  40960 ～ 49191 字节*/ });
//dispatch_async(queue, ^{ /* 读取  49192 ～ 57343 字节*/ });
//dispatch_async(queue, ^{ /* 读取  57344 ～ 65535 字节*/ });

/*
 dispatch_io_create 函数生成Dispatch I/O,并指定发生error时用来执行处理的block，以及执行该block的Dispatch Queue。
 dispatch_io_set_low_water 函数设置一次读取的大小
 dispatch_io_read 函数使用Global Dispatch Queue 开始并发读取。每当各个分割的文件块读取结束时，将含有文件块数据的 Dispatch Data(这里指pipedata) 传递给 “dispatch_io_read 函数指定的读取结束时回调用的block”，这个block拿到每一块读取好的Dispatch Data(这里指pipe data)，然后进行合并处理。
 如果想提高文件读取速度，可以尝试使用 Dispatch I/O.
 */
// fd 文件描述符
//channel 通道
//
//offset 对于DISPATCH_IO_RANDOM 类型的通道,此参数指定要读取的信道的偏移量。
//
//          对于DISPATCH_IO_STREAM 类型的通道,此参数将被忽略，数据从当前位置读取。
//
//length 从通道读取的字节数。指定size_max继续读取数据直到达到一个EOF。
//void dispatch_io_set_high_water( dispatch_io_t channel, size_t high_water);
//void dispatch_io_set_low_water( dispatch_io_t channel, size_t low_water);

//异步并行读取文件
- (void)dispatchIO
{
    NSString *path = @"/Users/hujinwei/Desktop/GCD-TestDemo/GCD-TestDemo/hello.rtf";
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_fd_t fd = open(path.UTF8String, O_RDONLY);
    dispatch_io_t io = dispatch_io_create(DISPATCH_IO_RANDOM, fd, queue, ^(int error) {
        close(fd);
    });
    
    off_t currentSize = 0;
    long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil].fileSize;
    size_t offset = 1024*1024;
    dispatch_group_t group = dispatch_group_create();
    NSMutableData *totalData = [[NSMutableData alloc] initWithLength:fileSize];
    for (; currentSize <= fileSize; currentSize += offset) {
        dispatch_group_enter(group);
        dispatch_io_read(io, currentSize, offset, queue, ^(bool done, dispatch_data_t  _Nullable data, int error) {
            if (error == 0) {
                size_t len = dispatch_data_get_size(data);
                if (len > 0) {
                    const void *bytes = NULL;
                    (void)dispatch_data_create_map(data, (const void **)&bytes, &len);
                    [totalData replaceBytesInRange:NSMakeRange(currentSize, len) withBytes:bytes length:len];
                }
            }
            
            if (done) {
                dispatch_group_leave(group);
            }
        });
    }
    
    dispatch_group_notify(group, queue, ^{
        NSString *str = [[NSString alloc] initWithData:totalData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", str);
    });
    
}

//同步读取文件
- (void)syncReadFielForDispathIO
{
    NSString *path = @"/Users/hujinwei/Desktop/GCD-TestDemo/GCD-TestDemo/hello.rtf";
    dispatch_queue_t queue = dispatch_queue_create("queue", NULL);//当设置为并行队列时在读取文件时实际还是串行
    dispatch_fd_t fd = open(path.UTF8String, O_RDONLY, 0);
    dispatch_io_t io = dispatch_io_create(DISPATCH_IO_STREAM, fd, queue, ^(int error) {
        close(fd);
    });
    
    size_t water = 1024*1024;
    dispatch_io_set_low_water(io, water);
    dispatch_io_set_high_water(io, water);
    long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil].fileSize;
    NSMutableData *totalData = [[NSMutableData alloc] init];
    dispatch_io_read(io, 0, fileSize, queue, ^(bool done, dispatch_data_t  _Nullable data, int error) {
        if (error == 0) {
            size_t len = dispatch_data_get_size(data);
            if (len > 0) {
                [totalData appendData:(NSData *)data];
            }
        }
        
        if (done) {
            NSString *str = [[NSString alloc] initWithData:totalData encoding:NSUTF8StringEncoding];
            NSLog(@"%@", str);
        }
    });
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"同步测试";
    _titleArr = @[@"test1",@"test2死锁",@"testDispatchApply",@"dispatch_semaphore_wait和dispatch_semaphore_signal合用", @"dispatchOnce(只调用一次)",@"dispatchIO(异步读文件)",@"syncReadFielForDispathIO(同步读文件)"];
    
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
            [self test1];
            break;
            
        case 1:
            [self test2];
            break;
            
        case 2:
            [self testDispatchApply];
            break;
            
        case 3:
            [self dispatch_semaphore_waitAndDispatch_semaphore_signal];
            break;
            
        case 4:
            [self dispatchOnce];
            break;
            
        case 5://异步读取文件
            [self dispatchIO];
            break;
            
        case 6://同步读取文件
           [self syncReadFielForDispathIO];
            break;
            
       
        default:
            break;
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
