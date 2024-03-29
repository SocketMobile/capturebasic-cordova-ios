/********* CaptureBasicCordova.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <CaptureSDK/CaptureSDK.h>

@interface ResponseBuilder: NSObject {
    NSMutableDictionary* response;
}
-(instancetype)init;
-(ResponseBuilder*)addResult:(long)result;
-(ResponseBuilder*)addResponseType:(NSString*)type;
-(ResponseBuilder*)addName:(NSString*)name;
-(ResponseBuilder*)addString:(NSString*)value withKey:(NSString*)key;
-(ResponseBuilder*)addLong:(long)value withKey:(NSString*)key;
-(ResponseBuilder*)addArray:(NSArray*)value withKey:(NSString*)key;
-(ResponseBuilder*)combineDictionary:(NSDictionary*)dictionary;
-(NSDictionary*)build;
@end

@implementation ResponseBuilder
- (instancetype)init
{
    self = [super init];
    if (self) {
        response = [NSMutableDictionary new];
    }
    return self;
}

-(ResponseBuilder*)addResult:(long)result {
    NSNumber* resultObj = [NSNumber numberWithLong:result];
    NSDictionary* error=[NSDictionary dictionaryWithObjectsAndKeys:
                         resultObj, @"result", nil];
    [response addEntriesFromDictionary:error];
    return self;
}

-(ResponseBuilder*)addResponseType:(NSString*)type {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                         type, @"type",nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addName:(NSString*)name {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                name, @"name",nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addString:(NSString*)value withKey:(NSString*)key {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                value, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addLong:(long)value withKey:(NSString*)key {
    NSNumber* valueObj = [NSNumber numberWithLong:value];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                         valueObj, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addArray:(NSArray*)value withKey:(NSString*)key {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                value, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addDictionary:(NSDictionary*)value withKey:(NSString*)key {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                value, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)combineDictionary:(NSDictionary*)dictionary {
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(NSDictionary*)build {
    return self->response;
}

@end

@interface CaptureBasicCordova : CDVPlugin <SKTCaptureHelperDelegate> {
    // Member variables go here..
    NSString* _callbackId;
    SKTCaptureHelper* _capture;
    NSDictionary* _devices;
}

- (void)useCaptureBasic:(CDVInvokedUrlCommand*)command;
- (void)addCaptureListener:(CDVInvokedUrlCommand*)command;
- (void)getProperty:(CDVInvokedUrlCommand*)command;
- (void)setProperty:(CDVInvokedUrlCommand*)command;
@end

@implementation CaptureBasicCordova

- (void)useCaptureBasic:(CDVInvokedUrlCommand*)command
{
    NSDictionary* args = [command argumentAtIndex: 0];
    NSString* callbackId = command.callbackId;
    SKTAppInfo* appInfo = [SKTAppInfo new];
    if(args.count >= 3){
        appInfo.AppID = [args objectForKey: @"appId"];
        appInfo.AppKey = [args objectForKey: @"appKey"];
        appInfo.DeveloperID = [args objectForKey: @"developerId"];
        _capture = [SKTCaptureHelper sharedInstance];
        [_capture pushDelegate:self];
        [_capture openWithAppInfo:appInfo completionHandler:^(SKTResult result) {
            NSDictionary* response = [[[ResponseBuilder new]
                                       addResult:result]
                                      build];
            if(SKTSUCCESS(result)){
                [self sendJsonFromDictionary:response withCallbackId:callbackId keepCallback:NO];
            }
            else {
                [self sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
            }
        }];
    }
    else {
        [self sendError:(long) SKTCaptureE_INVALIDPARAMETER withCallbackId:callbackId keepCallback:NO];
    }
}

- (void)addCaptureListener:(CDVInvokedUrlCommand*)command {
    self->_callbackId = command.callbackId;
}

- (void)getProperty:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
    if(_capture != nil) {
        __weak CaptureBasicCordova* weakSelf = self;
        NSDictionary* args = [command argumentAtIndex: 0];
        NSString* handle = [args objectForKey: @"handle"];
        SKTCaptureProperty* property = [self getCapturePropertyFromArgs: args];
        SKTCaptureHelperDevice* device = [self getDeviceFromArgs: args];
                SKTCaptureHelperDeviceManager* deviceManager = nil;
        if([device isKindOfClass:[SKTCaptureHelperDeviceManager class]]){
            deviceManager = (SKTCaptureHelperDeviceManager*)device;
        }
        if(deviceManager != nil) {
            [deviceManager getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *property) {
                if(SKTSUCCESS(result)){
                    [weakSelf sendJsonFromProperty:property withHandle:handle withCallbackId:callbackId keepCallback:NO];
                }
                else {
                    [weakSelf sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
                }
            }];
        }
        else if(device != nil) {
            [device getProperty:property
               completionHandler:^(SKTResult result, SKTCaptureProperty *property) {
                if(SKTSUCCESS(result)){
                    [weakSelf sendJsonFromProperty:property withHandle:handle withCallbackId:callbackId keepCallback:NO];
                }
                else {
                    [weakSelf sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
                }
            }];
        }
        else if([CaptureBasicCordova isCaptureProperty:property]){
            [_capture getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *property) {
                if(SKTSUCCESS(result)){
                    [weakSelf sendJsonFromProperty:property withHandle:handle withCallbackId:callbackId keepCallback:NO];
                }
                else {
                    [weakSelf sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
                }
            }];
        }
        else {
            [self sendError:(long) SKTCaptureE_INVALIDHANDLE withCallbackId:callbackId  keepCallback:NO];
        }
    }
    else {
        // return an error
        [self sendError:(long) SKTCaptureE_NOTINITIALIZED withCallbackId:callbackId  keepCallback:NO];
    }
}

- (void)setProperty:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
    if(_capture != nil) {
        __weak CaptureBasicCordova* weakSelf = self;
        NSDictionary* args = [command argumentAtIndex: 0];
        NSString* handle = [args objectForKey: @"handle"];
        SKTCaptureProperty* property = [self getCapturePropertyFromArgs: args];
        SKTCaptureHelperDevice* device = [self getDeviceFromArgs: args];
        SKTCaptureHelperDeviceManager* deviceManager = nil;
        if([device isKindOfClass:[SKTCaptureHelperDeviceManager class]]){
            deviceManager = (SKTCaptureHelperDeviceManager*)device;
        }
        if(deviceManager != nil) {
            [deviceManager setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *property) {
                if(SKTSUCCESS(result)){
                    [weakSelf sendJsonFromProperty:property withHandle:handle withCallbackId:callbackId keepCallback:NO];
                }
                else {
                    [weakSelf sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
                }
            }];
        }
        else if(device != nil) {
            [device setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *property) {
                if(SKTSUCCESS(result)){
                    [weakSelf sendJsonFromProperty:property withHandle:handle withCallbackId:callbackId keepCallback:NO];
                }
                else {
                    [weakSelf sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
                }
            }];
        }
        else if([CaptureBasicCordova isCaptureProperty:property]){
            [_capture setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *property) {
                if(SKTSUCCESS(result)){
                    [weakSelf sendJsonFromProperty:property withHandle:handle withCallbackId:callbackId keepCallback:NO];
                }
                else {
                    [weakSelf sendError:(long) result withCallbackId:callbackId  keepCallback:NO];
                }
            }];
        }
        else {
            [self sendError:(long) SKTCaptureE_INVALIDHANDLE withCallbackId:callbackId  keepCallback:NO];
        }
    }
    else {
        // return an error
        [self sendError:(long) SKTCaptureE_NOTINITIALIZED withCallbackId:callbackId keepCallback:NO];
    }
}

-(SKTCaptureHelperDevice*)getDeviceFromArgs:(NSDictionary*)args {
    SKTCaptureHelperDevice* device = nil;
    NSString* handle = [args objectForKey: @"handle"];
    device = [self getDeviceFromHandle:handle];
    return device;
}

-(SKTCaptureProperty*) getCapturePropertyFromArgs:(NSDictionary*) args {
    NSNumber* propId = [args objectForKey: @"propId"];
    NSNumber* propType = [args objectForKey: @"propType"];
    SKTCaptureProperty* property = [SKTCaptureProperty new];
    property.ID = (SKTCapturePropertyID)propId.longValue;
    property.Type = (enum SKTCapturePropertyType)propType.intValue;
    [self fillProperty:property fromArgs:args];
    return property;
}

-(SKTResult) fillProperty:(SKTCaptureProperty*) property
                 fromArgs:(NSDictionary*)args {

    SKTResult result = SKTCaptureE_NOERROR;
    switch(property.Type) {
        case SKTCapturePropertyTypeNone:
            break;
        case SKTCapturePropertyTypeByte:
        {
            NSNumber* value = [args objectForKey: @"value"];
            property.ByteValue = value.unsignedIntValue;
        }
            break;
        case SKTCapturePropertyTypeUlong:
        {
            NSNumber* value = [args objectForKey: @"value"];
            property.ULongValue = value.unsignedLongValue;
        }
            break;
        case SKTCapturePropertyTypeArray:
        {
            NSArray* value = [args objectForKey: @"value"];
            property.ArrayValue =  [NSKeyedArchiver archivedDataWithRootObject:value];
        }
            break;
        case SKTCapturePropertyTypeString:
            property.StringValue = [args objectForKey: @"value"];
            break;
        case SKTCapturePropertyTypeVersion:
            break;
        case SKTCapturePropertyTypeDataSource:
        {
            NSNumber* number;
            NSDictionary* dataSource = [args objectForKey:@"value"];
            number = [dataSource objectForKey:@"id"];
            property.DataSource.ID = number.unsignedLongValue;
            property.DataSource.Name = [dataSource objectForKey:@"name"];
            number = [dataSource objectForKey:@"flags"];
            property.DataSource.Flags = number.unsignedLongValue;
            number = [dataSource objectForKey:@"status"];
            property.DataSource.Status = number.unsignedLongValue;
        }
            break;
        case SKTCapturePropertyTypeEnum:
            break;
        case SKTCapturePropertyTypeObject:
            break;
        case SKTCapturePropertyTypeLastType:
            break;
        case SKTCapturePropertyTypeNotApplicable:
            break;
    }
    return result;
}

- (void)sendError:(long) result
   withCallbackId:(NSString*) callbackId
     keepCallback:(BOOL) keep {
    NSDictionary* error=[[[[[ResponseBuilder new]
                           addResponseType:@"result"]
                          addName:@"onError"]
                         addResult:result]
                         build];
    [self sendErrorJsonFromDictionary:error
                  withCallbackId:callbackId
                   keepCallback:keep];
}

-(void)sendErrorJsonFromDictionary:(NSDictionary*)dictionary
               withCallbackId:(NSString*)callbackId
                 keepCallback:(BOOL) keep {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];

    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];
    [result setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

-(void)sendJsonFromDictionary:(NSDictionary*)dictionary
               withCallbackId:(NSString*)callbackId
                 keepCallback:(BOOL) keep {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];

    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

-(void)sendJsonFromProperty:(SKTCaptureProperty*)property
                 withHandle:(NSString*) handle
             withCallbackId:(NSString*)callbackId
               keepCallback:(BOOL) keep {
    NSError* error;
    ResponseBuilder* responseBuilder= [ResponseBuilder new];
    [responseBuilder addString:handle withKey:@"handle"];
    [responseBuilder addLong:property.ID withKey:@"propId"];
    [responseBuilder addLong:property.Type withKey:@"propType"];
    switch(property.Type){
       case SKTCapturePropertyTypeNone:
           break;
       case SKTCapturePropertyTypeByte:
            [responseBuilder addLong:property.ByteValue withKey:@"value"];
           break;
        case SKTCapturePropertyTypeUlong:
            [responseBuilder addLong:property.ULongValue withKey:@"value"];
            break;
        case SKTCapturePropertyTypeString:
            [responseBuilder addString:property.StringValue withKey:@"value"];
            break;
        case SKTCapturePropertyTypeArray:
        {
            NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:property.ArrayValue];
            [responseBuilder addArray:array withKey:@"value"];
        }
            break;
        case SKTCapturePropertyTypeDataSource:
        {
            NSDictionary *dataSource = [CaptureBasicCordova convertToDictionaryFromDataSource:property.DataSource];
            [responseBuilder addDictionary:dataSource withKey:@"value"];
        }
            break;
        case SKTCapturePropertyTypeVersion:
        {
            NSDictionary *version = [CaptureBasicCordova convertToDictionaryFromVersion:property.Version];
            [responseBuilder addDictionary:version withKey:@"value"];
        }
            break;
        case SKTCapturePropertyTypeObject:
            break;
        case SKTCapturePropertyTypeEnum:
            break;
        case SKTCapturePropertyTypeLastType:
            break;
        case SKTCapturePropertyTypeNotApplicable:
            break;
    }
    NSDictionary* propertyResult = [responseBuilder build];
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:propertyResult options:NSJSONWritingPrettyPrinted error:&error];

    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}
-(SKTCaptureHelperDevice*)getDeviceFromHandle:(NSString*)handle {
    SKTCaptureHelperDevice* device = nil;
    if (_capture != nil) {
        NSArray* devices = [_capture getDevicesList];
        for (SKTCaptureHelperDevice* d in devices) {
            NSString* h = [CaptureBasicCordova getHandleFromDevice:d];
            if ([h containsString:handle]) {
                device = d;
                break;
            }
        }
        if(device == nil) {
            devices = [_capture getDeviceManagersList];
            for (SKTCaptureHelperDeviceManager* d in devices) {
                NSString* h = [CaptureBasicCordova getHandleFromDevice:d];
                if ([h containsString:handle]) {
                    device = d;
                    break;
                }
            }
        }
    }
    return device;
}

+(NSString*)getHandleFromDevice:(SKTCaptureHelperDevice*)device {
    NSString* handle = [NSString stringWithFormat:@"%ld",(long)device];
    return handle;
}

+(NSString*)getHandleFromDeviceManager:(SKTCaptureHelperDeviceManager*)device {
    NSString* handle = [NSString stringWithFormat:@"%ld",(long)device];
    return handle;
}

+(BOOL)isCaptureProperty:(SKTCaptureProperty*)property {
    BOOL isCapture = FALSE;
    long propertyId = (long)property.ID;
    if ((propertyId & 0x80000000) == 0x80000000){
        isCapture = TRUE;
    }
    return isCapture;
}

+(NSDictionary*)convertToDictionaryFromVersion:(SKTCaptureVersion*) version {
    NSDictionary* result = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%lx",version.Major],@"major",
                            [NSString stringWithFormat:@"%lx",version.Middle],@"middle",
                            [NSString stringWithFormat:@"%lx",version.Minor],@"minor",
                            [NSString stringWithFormat:@"%ld",version.Build],@"build",
                            [NSString stringWithFormat:@"%d",version.Month],@"month",
                            [NSString stringWithFormat:@"%d",version.Day],@"day",
                            [NSString stringWithFormat:@"%d",version.Year],@"year",
                            [NSString stringWithFormat:@"%d",version.Hour],@"hour",
                            [NSString stringWithFormat:@"%d",version.Minute],@"minute",
                             nil];
    return result;
}

+(NSDictionary*)convertToDictionaryFromDataSource:(SKTCaptureDataSource*) dataSource {
    NSDictionary* result = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%ld",dataSource.ID],@"id",
                            [NSString stringWithFormat:@"%@",dataSource.Name],@"name",
                            [NSString stringWithFormat:@"%ld",(long)dataSource.Flags],@"flags",
                            [NSString stringWithFormat:@"%ld",dataSource.Status],@"status",
                             nil];
    return result;
}
#pragma  mark - CaptureBasicHelperDelegate
/**
 * called each time a device connects to the host
 * @param result contains the result of the connection
 * @param deviceInfo contains the device information
 */
-(void)didNotifyArrivalForDevice:(SKTCaptureHelperDevice *)device
                      withResult:(SKTResult)result{
    NSLog(@"didNotifyArrivalForDevice: %@ Result: %ld", device.friendlyName, result);
    NSString* callbackId = self->_callbackId;

    NSString* handle = [CaptureBasicCordova getHandleFromDevice:device];
    NSDictionary* deviceArrival =
        [[[[[[[[ResponseBuilder new]
                        addName:@"deviceArrival"]
                addResponseType:@"deviceType"]
                      addString:handle withKey:@"deviceHandle"]
                      addString:device.friendlyName withKey: @"deviceName"]
                        addLong:(long)device.deviceType withKey: @"deviceType"]
                        addResult:(long)result]
                                 build];

    [self sendJsonFromDictionary:deviceArrival withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time a device disconnect from the host
 * @param deviceRemoved contains the device information
 */
 -(void) didNotifyRemovalForDevice:(SKTCaptureHelperDevice*) deviceRemoved
                        withResult:(SKTResult)result {
    NSString* callbackId = self->_callbackId;
    NSString* handle = [CaptureBasicCordova getHandleFromDevice: deviceRemoved];
    NSDictionary* deviceRemoval =
        [[[[[[[[ResponseBuilder new]
        addName:@"deviceRemoval"]
        addResponseType:@"deviceType"]
        addString:deviceRemoved.friendlyName withKey:@"deviceName"]
        addLong:deviceRemoved.deviceType withKey:@"deviceType"]
        addString:handle withKey:@"deviceHandle"]
        addResult:(long)result]
        build ];

    [self sendJsonFromDictionary:deviceRemoval withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time a device manager connects to the host
 * @param result contains the result of the connection
 * @param deviceInfo contains the device information
 */
-(void)didNotifyArrivalForDeviceManager:(SKTCaptureHelperDeviceManager *)device
                      withResult:(SKTResult)result{
    NSLog(@"didNotifyArrivalForDeviceManager: %@ Result: %ld", device.friendlyName, result);
    NSString* callbackId = self->_callbackId;

    NSString* handle = [CaptureBasicCordova getHandleFromDeviceManager:device];
    NSDictionary* deviceManagerArrival =
        [[[[[[[[ResponseBuilder new]
                        addName:@"deviceManagerArrival"]
                addResponseType:@"deviceType"]
                      addString:handle withKey:@"deviceHandle"]
                      addString:device.friendlyName withKey: @"deviceName"]
                        addLong:(long)device.deviceType withKey: @"deviceType"]
                        addResult:(long)result]
                                 build];

    [self sendJsonFromDictionary:deviceManagerArrival withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time a device manager disconnect from the host
 * @param deviceRemoved contains the device information
 */
 -(void) didNotifyRemovalForDeviceManager:(SKTCaptureHelperDeviceManager*) deviceRemoved
                        withResult:(SKTResult)result {
    NSString* callbackId = self->_callbackId;
    NSString* handle = [CaptureBasicCordova getHandleFromDeviceManager: deviceRemoved];
    NSDictionary* deviceManagerRemoval =
        [[[[[[[[ResponseBuilder new]
        addName:@"deviceManagerRemoval"]
        addResponseType:@"deviceType"]
        addString:deviceRemoved.friendlyName withKey:@"deviceName"]
        addLong:deviceRemoved.deviceType withKey:@"deviceType"]
        addString:handle withKey:@"deviceHandle"]
        addResult:(long)result]
        build ];

    [self sendJsonFromDictionary:deviceManagerRemoval withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time CaptureBasic is reporting an error
 * @param result contains the error code
 */
-(void) didReceiveError:(SKTResult)error withMessage:(NSString *)message{
    NSLog(@"didReceiveError error: %ld", error);
    NSString* callbackId = self->_callbackId;
    NSDictionary* errorResult=
        [[[[[ResponseBuilder new]
            addResponseType:@"error"]
            addName:@"onError"]
            addResult:error]
            build];

    [self sendJsonFromDictionary:errorResult withCallbackId:callbackId keepCallback:YES];
}

/**
 * called when CaptureBasic initialization has been completed
 * @param result contains the initialization result
 */
-(void)listenerDidStart{
    NSString* callbackId = self->_callbackId;
    NSDictionary* initComplete =
        [[[[[ResponseBuilder new]
           addName:@"initializeComplete"]
           addResponseType:@"result"]
           addResult:(long)SKTCaptureE_NOERROR]
           build];
    [self sendJsonFromDictionary:initComplete withCallbackId:callbackId keepCallback:YES];
}

/**
 * called when CaptureBasic has been terminated. This will be
 * the last message received from CaptureBasic
 */
-(void) didTerminateWithResult:(SKTResult)result{
    NSString* callbackId = self->_callbackId;
    NSDictionary* captureTerminated =
    [[[[[ResponseBuilder new]
       addName:@"captureBasicTerminated"]
       addResponseType:@"result"]
       addResult:result]
     build];

    [self sendJsonFromDictionary:captureTerminated withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time CaptureBasic receives decoded data from scanner
 * @param result is ESKT_NOERROR when decodedData contains actual
 * decoded data. The result can be set to ESKT_CANCEL when the
 * end-user cancels a SoftScan operation
 * @param device contains the device information from which
 * the data has been decoded
 * @param decodedData contains the decoded data information
 */
-(void) didReceiveDecodedData:(SKTCaptureDecodedData *)decodedData
                   fromDevice:(SKTCaptureHelperDevice *)device
                   withResult:(SKTResult)result{
    NSString* callbackId = self->_callbackId;
    NSString* handle = [CaptureBasicCordova getHandleFromDevice: device];
    NSInteger len = (int)decodedData.DecodedData.length;
    const unsigned char* pData = decodedData.DecodedData.bytes;
    NSMutableArray* dataArray = [[NSMutableArray alloc]initWithCapacity:len];
    for(int i = 0; i< len; i++){
        NSNumber* num = [NSNumber numberWithUnsignedChar:(unsigned char)pData[i]];
        [dataArray addObject:num];
    }
    NSDictionary* decodedDataDictionary=[[[[[[[[[[ResponseBuilder new]
        addName:@"decodedData"]
        addResponseType:@"decodedData"]
        addString:device.friendlyName withKey:@"deviceName"]
        addLong:device.deviceType withKey:@"deviceType"]
        addString:handle withKey:@"deviceHandle"]
        addArray:dataArray withKey:@"decodedData"]
        addLong:decodedData.DataSourceID withKey:@"dataSourceId"]
        addString:decodedData.DataSourceName withKey:@"dataSourceName"]
        build];
    [self sendJsonFromDictionary:decodedDataDictionary withCallbackId:callbackId keepCallback:YES];
}


@end
