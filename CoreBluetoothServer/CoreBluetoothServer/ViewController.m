//
//  ViewController.m
//  CoreBluetoothServer
//
//  Created by 敬洁 on 15/1/27.
//  Copyright (c) 2015年 JingJ. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@property (nonatomic, strong) CBMutableCharacteristic *character1;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // 创建一个Peripheral管理器
    // 我们将当前类作为peripheralManager，因此必须实现CBPeripheralManagerDelegate
    // 第二个参数如果指定为nil，则默认使用主队列
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    
    }

// 实现这个方法来确保本地设备支持BLE
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"Peripheral Manager Did Update State");
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            [self createdServer];
            NSLog(@"CBPeripheralManagerStatePoweredOn");
            break;
            
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"CBPeripheralManagerStatePoweredOff");
            break;
            
        case CBPeripheralManagerStateUnsupported:
            NSLog(@"CBPeripheralManagerStateUnsupported");
            break;
            
        default:
            break;
    }
}

// 创建服务，特征
- (void)createdServer {
    
    CBUUID *characteristicUUID1 = [CBUUID UUIDWithString:@"CD3DEA8C-359F-4E69-A295-C45297789C02"];
//    CBUUID *characteristicUUID2 = [CBUUID UUIDWithString:@"8A5318DC-A717-4FB9-A9C1-716A8B0B136C"];
    
    self.character1 = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID1 properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    
//    CBMutableCharacteristic *character2 = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID2 properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:@"3655296F-96CE-44D4-912D-CD83F06E7E7E"];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
//    service.characteristics = @[character1, character2];    // 组织成树状结构
    service.characteristics = @[self.character1];    // 组织成树状结构
    
    // 发布服务及特性到设备数据库
    [self.peripheralManager addService:service];
}

// 发布服务的回调方法
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Add Service");
    
    if (error)
    {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
    else {
        
        [self sendAdvertising];
    }
}

// 广告服务
- (void)sendAdvertising {
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:@"3655296F-96CE-44D4-912D-CD83F06E7E7E"];
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[serviceUUID]}];
}

// 发送广告的回调
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"Start Advertising");
    
    if (error)
    {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
}

// 对Central端的读写请求作出响应
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    // 查看请求的特性是否是指定的特性
    if ([request.characteristic.UUID isEqual:self.character1.UUID])
    {
        NSLog(@"Request character 1");
        
        // 确保读请求所请求的偏移量没有超出我们的特性的值的长度范围
        // offset属性指定的请求所要读取值的偏移位置
        if (request.offset > self.character1.value.length)
        {
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            return;
        }
        
        // 如果读取位置未越界，则将特性中的值的指定范围赋给请求的value属性。
        request.value = [self.character1.value subdataWithRange:(NSRange){request.offset, self.character1.value.length - request.offset}];
        
        // 对请求作出成功响应
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

// 写请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    CBATTRequest *request = requests[0];
    
    self.character1.value = request.value;
    
    [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

// 发送更新的特性值给订阅的Central端
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic %@", characteristic);
    
    NSData *updatedData = characteristic.value;
    
    // 获取属性更新的值并调用以下方法将其发送到Central端
    // 最后一个参数指定我们想将修改发送给哪个Central端，如果传nil，则会发送给所有连接的Central
    // 将方法返回一个BOOL值，表示修改是否被成功发送，如果用于传送更新值的队列被填充满，则方法返回NO
    BOOL didSendValue = [self.peripheralManager updateValue:updatedData forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:nil];
    
    NSLog(@"Send Success ? %@", (didSendValue ? @"YES" : @"NO"));
}


@end
