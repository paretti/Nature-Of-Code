//
//  NOCAccelMoverSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCAccelMoverSketchViewController.h"
#import "NOCShaderProgram.h"
#import "NOCMover2D.h"
#import "NOCGeometryHelpers.h"

@implementation NOCAccelMoverSketchViewController
{
    NOCShaderProgram *_shader;
    NOCMover2D *_mover;
    GLKTextureInfo *_moverTexture;
}

static NSString * NOCShaderNameAccelMover = @"Mover";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiAccelMover";
}

- (IBAction)switchRandomChanged:(id)sender
{
    BOOL isRandom = self.switchRandom.on;
    self.sliderAccelX.enabled = !isRandom;
    self.sliderAccelY.enabled = !isRandom;
}

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    // Trigger the correct view state
    [self switchRandomChanged:nil];
    
    // Load the mover texture.
    UIImage *moverTexImage = [UIImage imageNamed:@"mover"];
    NSError *texError = nil;
    _moverTexture = [GLKTextureLoader textureWithCGImage:moverTexImage.CGImage
                                                 options:nil
                                                   error:&texError];
    if(texError){
        NSLog(@"ERROR: Could not load the texture: %@", texError);
    }
    
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:NOCShaderNameAccelMover];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"texCoord" : @(GLKVertexAttribTexCoord0)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
        UniformMoverTexture
    ];
    
    self.shaders = @{ NOCShaderNameAccelMover : _shader };
    
    // Setup the Mover
    _mover = [[NOCMover2D alloc] initWithSize:GLKVector2Make(0.1, 0.1)
                                     position:GLKVector2Zero
                                         mass:1.0f];
    
}

- (void)update
{
    [super update];

    _mover.maxVelocity = self.sliderMaxRandomAccel.value;
    
    if(self.switchRandom.on){
        GLKVector2 randVec = GLKVector2Random();
        // Tamp down the jitteriness a bit.
        // I'm just eyeballing 0.005 because it feels right,
        // but this could be another slider.
        randVec = GLKVector2Multiply(randVec, GLKVector2Make(0.005, 0.005));
        _mover.acceleration = randVec;
    }else{
        _mover.acceleration = GLKVector2Make(self.sliderAccelX.value,
                                             self.sliderAccelY.value);
    }
    
    // Step w/in the bounds
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    CGRect moverBounds = CGRectMake(-1, -1 / aspect,
                                    2, 2 / aspect);

    [_mover stepInRect:moverBounds shouldWrap:YES];
    
}

- (void)resize
{
    [super resize];
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
    
    [self clear];
    
    [_shader use];
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _moverTexture.name);
    
    // Attach the texture to the shader
    NSNumber *samplerLoc = _shader.uniformLocations[UniformMoverTexture];
    glUniform1i([samplerLoc intValue], 0);
    
    // Create the Model View Projection matrix for the shader
    NSNumber *projMatLoc = _shader.uniformLocations[UniformMVProjectionMatrix];
    
    // Get the model matrix
    GLKMatrix4 modelMat = [_mover modelMatrix];
    
    // Multiply by the projection matrix
    GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, modelMat);
    
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);

    [_mover render];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

- (void)teardown
{
    //..
}

@end
