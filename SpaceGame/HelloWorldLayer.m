//
//  HelloWorldLayer.m
//  SpaceGame
//
//  Created by Chao Xu on 13-10-1.
//  Copyright Chao Xu 2013年. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "CCParallaxNode-Extras.h"
#import "SimpleAudioEngine.h"
#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

#define kNumAsteroids 15
#define kNumLasers 5
// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	
	if( (self=[super init]) ) {
        _batchNode = [CCSpriteBatchNode batchNodeWithFile:@"Sprites.pvr.ccz"];//Creates a CCSpriteBatchNode to batch up all of the drawing of objects from the same large image. Passes in the image name (Sprites.pvr.ccz).
        [self addChild:_batchNode];//
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Sprites.plist"];//Loads the Sprites.plist file, which contains information on where inside the large image each of the smaller images lies. This lets you easily retrieve the sub-images later with spriteWithSpriteFrameName
        
        _ship = [CCSprite spriteWithSpriteFrameName:@"SpaceFlier_sm_1.png"];//Creates a new Sprite using the SpaceFlier_sm_1.png image, which is a sub-image within the large image.
        
        CGSize winSize  = [CCDirector sharedDirector].winSize;//Gets the size of the screen from the CCDirectory
        _ship.position = ccp(winSize.width *0.1,winSize.height *0.5);
       [_batchNode addChild:_ship z:1];
        
        //create the ccparallaxnode
        _backgroundNode = [CCParallaxNode node];
        [self addChild:_backgroundNode z:-1];
        
        //create the sprites we'll add to the ccparallaxnode
        _spacedust1 = [CCSprite spriteWithFile:@"bg_front_spacedust.png"];
        _spacedust2 = [CCSprite spriteWithFile:@"bg_front_spacedust.png"];
        _planetsunrise = [CCSprite spriteWithFile:@"bg_planetsunrise.png"];
        _galaxy = [CCSprite spriteWithFile:@"bg_galaxy.png"];
        _spacialanomaly = [CCSprite spriteWithFile:@"bg_spacialanomaly.png"];
        _spacialanomaly2 = [CCSprite spriteWithFile:@"bg_spacialanomaly2.png"];
        
        //Determine relative movement speeds for space dust adn background
        CGPoint dustSpeed = ccp(0.1, 0.1);
        CGPoint bgSpeed = ccp(0.05, 0.05);
        
        //add Children to ccparallaxNode
        [_backgroundNode addChild:_spacedust1 z:0 parallaxRatio:dustSpeed positionOffset:ccp(0, winSize.height/2)];
        [_backgroundNode addChild:_spacedust2 z:0 parallaxRatio:dustSpeed positionOffset:ccp(_spacedust1.contentSize.width, winSize.height/2)];
        [_backgroundNode addChild:_galaxy z:-1 parallaxRatio:bgSpeed positionOffset:ccp(0, winSize.height * 0.7)];
        [_backgroundNode addChild:_planetsunrise z:-1 parallaxRatio:bgSpeed positionOffset:ccp(600,winSize.height * 0)];
        [_backgroundNode addChild:_spacialanomaly z:-1 parallaxRatio:bgSpeed positionOffset:ccp(900,winSize.height * 0.3)];
        [_backgroundNode addChild:_spacialanomaly2 z:-1 parallaxRatio:bgSpeed positionOffset:ccp(1500,winSize.height * 0.9)];
		[self scheduleUpdate];
        //Particles
        NSArray *starsArray = [NSArray arrayWithObjects:@"Stars1.plist",@"Stars2.plist",@"Stars3.plist",Nil];
        for(NSString *stars in starsArray){
            CCParticleSystemQuad *starsEffect = [CCParticleSystemQuad particleWithFile:stars];
            [self addChild:starsEffect z:1];
        //Accelerometer
            self.isAccelerometerEnabled = YES;
            
        }
        //Adding Asteroids
        _asteroids = [[CCArray alloc]initWithCapacity:kNumAsteroids]; //CCArray is similar to NSArray, but optimized for speed. So it’s good to use in Cocos2D when possible.
        for(int i=0; i<kNumAsteroids;++i){
            //15 asteriods are added to _asteroids
            CCSprite *asteroid = [CCSprite spriteWithSpriteFrameName:@"asteroid.png"];
            asteroid.visible = NO;
            [_batchNode addChild:asteroid];
            [_asteroids addObject:asteroid];
            
        }
        //adding laser
        _shipLasers = [[CCArray alloc]initWithCapacity:kNumLasers];
        for(int i = 0 ;i <kNumLasers;i ++){
            CCSprite *shipLaser = [CCSprite spriteWithSpriteFrameName:@"laserbeam_blue.png"];
            shipLaser.visible = NO;
            [_batchNode addChild:shipLaser];
            [_shipLasers addObject:shipLaser];
        }
        self.isTouchEnabled = YES;
        
        _lives = 3;
        double curTime = CACurrentMediaTime();
        _gameOverTime = curTime + 30;
        
        //adding audios
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"SpaceGame.caf" loop:YES];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"explosion_large.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"laser_ship.caf"];
        	}
	return self;
}
//each touch,shoot a laser
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CCSprite *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) _nextShipLaser = 0;
    
    shipLaser.position = ccpAdd(_ship.position, ccp(shipLaser.contentSize.width/2,0));
    shipLaser.visible = YES;
    [shipLaser stopAllActions];
    [shipLaser runAction:[CCSequence actions:[CCMoveBy actionWithDuration:0.5 position:ccp(winSize.width, 0)],[CCCallFuncN actionWithTarget:self selector:@selector(setInvisible:)], nil]];
    [[SimpleAudioEngine sharedEngine]playEffect:@"laser_ship.caf"];
    
}

//Accelerometer
//make thing more smoothy
-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
    #define kFilteringFactor 0.1
    #define kRestAccelX -0.6
    #define kShipMaxPointsPerSec (winSize.height*0.5)
    #define kMaxDiffX 0.2
    
    UIAccelerationValue rollingX,rollingY,rollingZ;
    rollingX = (acceleration.x * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
    rollingY = (acceleration.y * kFilteringFactor) + (rollingY * (1.0 - kFilteringFactor));
    rollingZ = (acceleration.z * kFilteringFactor) + (rollingZ * (1.0 - kFilteringFactor));
    
    float accelX = acceleration.x - rollingX;
    float accelY = acceleration.y - rollingY;
    float accelZ = acceleration.z - rollingZ;
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    float accelDiff = accelX - kRestAccelX;
    float accelFraction = accelDiff / kMaxDiffX;
    float pointsPerSec = kShipMaxPointsPerSec * accelFraction;
    _shipPointsPerSecY = pointsPerSec;
    
}

//asteriods
-(float)randomValueBetween:(float)low andValue:(float)high{
    return (((float)arc4random()/0xFFFFFFFFu)*(high - low)) + low;
}
//To move the space dust and backgrounds, all you need to do is move the parallax node itself. For every Y points we move the parallax node, the dust will move 0.1Y points, and the backgrounds will move 0.05Y points.
//To move the parallax node, you’ll simply update the position every frame according to a set velocity. 
-(void)update:(ccTime)dt{
    CGPoint backgroundScrollVel = ccp(-1000, 0);
    _backgroundNode.position = ccpAdd(_backgroundNode.position, ccpMult(backgroundScrollVel, dt));
    
    //Continuous Scrolling
    NSArray *spaceDusts = [NSArray arrayWithObjects:_spacedust1,_spacedust2, nil];
    for(CCSprite *spaceDust in spaceDusts){
        if ([_backgroundNode convertToWorldSpace:spaceDust.position].x< -spaceDust.contentSize.width) {
            [_backgroundNode incrementOffset:ccp(2*spaceDust.contentSize.width,0) forChild:spaceDust];
        }
        NSArray *backgrounds = [NSArray arrayWithObjects:_planetsunrise, _galaxy, _spacialanomaly, _spacialanomaly2, nil];
        for (CCSprite *background in backgrounds) {
            if ([_backgroundNode convertToWorldSpace:background.position].x < -background.contentSize.width) {
                [_backgroundNode incrementOffset:ccp(2000,0) forChild:background];
            }
        }
    }
    
    //accelerometer
    CGSize winSize = [CCDirector sharedDirector].winSize;
    float maxY = winSize.height - _ship.contentSize.height/2;
    float minY = _ship.contentSize.height/2;
    float newY = _ship.position.y + (_shipPointsPerSecY *dt);
    newY = MIN(MAX(newY, minY), maxY);
    _ship.position = ccp(_ship.position.x, newY);
    
    //asteriods
    double curTime = CACurrentMediaTime();
    //We use an instance variable (_nextAsteroidSpawn) to tell us the time to spawn an asteroid next. We always check this in the update loop.
    if (curTime > _nextAsteroidSpawn) {
        float randSecs = [self randomValueBetween:0.20 andValue:1.0];
        _nextAsteroidSpawn = randSecs + curTime;
        float randY = [self randomValueBetween:0.0 andValue:winSize.height];
        float randDuration = [self randomValueBetween:2.0 andValue:10.0];
        CCSprite *asteroid = [_asteroids objectAtIndex:_nextAsteroid];
        _nextAsteroid++;
        if (_nextAsteroid >= _asteroids.count) _nextAsteroid = 0;
        [asteroid stopAllActions];
        asteroid.position = ccp(winSize.width+asteroid.contentSize.width/2, randY);
        asteroid.visible = YES;
        [asteroid runAction:[CCSequence actions:[CCMoveBy actionWithDuration:randDuration position:ccp(-winSize.width-asteroid.contentSize.width, 0)],[CCCallFuncN actionWithTarget:self selector:@selector(setInvisible:)], nil]];
    }
    
    //Collision Detection
    for(CCSprite *asteroid in _asteroids){
        if (!asteroid.visible) continue;
        
        for(CCSprite *shipLaser in _shipLasers){
            if(!shipLaser.visible) continue;
            
            if(CGRectIntersectsRect(shipLaser.boundingBox, asteroid.boundingBox)){
                [[SimpleAudioEngine sharedEngine]playEffect:@"explosion_large.caf"];
                shipLaser.visible = NO;
                asteroid.visible = NO;
                continue;
            }
        }
        if(CGRectIntersectsRect(_ship.boundingBox, asteroid.boundingBox)){
            [[SimpleAudioEngine sharedEngine] playEffect:@"explosion_large.caf"];
            asteroid.visible = NO;
            [_ship runAction:[CCBlink actionWithDuration:1.0 blinks:9]];
            _lives --;
        }
    }
    
    //win,lose detection
    if (_lives <= 0) {
        [_ship stopAllActions];
        _ship.visible = FALSE;
        [self unscheduleUpdate];
        [self setTouchEnabled:false];
        [self endScene:kEndReasonLose];
        
    }

}
-(void)restartTapped:(id)sender{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionZoomFlipX transitionWithDuration:0.5 scene:[HelloWorldLayer scene]]];
}
-(void)endScene:(EndReason)endReason{
    if (_gameOver) return;
    _gameOver = true;
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    NSString *message;
    if (endReason == kEndReasonWin) {
        message = @"You win!";
    } else if (endReason == kEndReasonLose) {
        message = @"You lose!";
    }
    
    CCLabelBMFont *label;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        label = [CCLabelBMFont labelWithString:message fntFile:@"Arial.fnt"];
    } else {
        label = [CCLabelBMFont labelWithString:message fntFile:@"Arial.fnt"];
    }
    label.scale = 0.1;
    label.position = ccp(winSize.width/2, winSize.height * 0.6);
    [self addChild:label];
    
    CCLabelBMFont *restartLabel;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        restartLabel = [CCLabelBMFont labelWithString:@"Restart" fntFile:@"Arial.fnt"];
    } else {
        restartLabel = [CCLabelBMFont labelWithString:@"Restart" fntFile:@"Arial.fnt"];
    }
    
    CCMenuItemLabel *restartItem = [CCMenuItemLabel itemWithLabel:restartLabel target:self selector:@selector(restartTapped:)];
    restartItem.scale = 0.1;
    restartItem.position = ccp(winSize.width/2, winSize.height * 0.4);
    
    CCMenu *menu = [CCMenu menuWithItems:restartItem, nil];
    menu.position = CGPointZero;
    [self addChild:menu];
    
    [restartItem runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
    [label runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
    
}
//Notice that we add all 15 asteroids to the batch node as soon as the game starts, but set them all to invisible. If they’re invisible we treat them as inactive.
-(void)setInvisible:(CCNode *)node{
    node.visible = NO;
}
// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
