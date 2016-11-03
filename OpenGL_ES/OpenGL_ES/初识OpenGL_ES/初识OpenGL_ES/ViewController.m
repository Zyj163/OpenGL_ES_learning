//
//  ViewController.m
//  初识OpenGL_ES
//
//  Created by ddn on 16/8/18.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLfloat squareVertexData[48] =
    {
        0.5f, 0.5f, -0.9f,    0.0f, 0.0f, 1.0f,     1.0f, 1.0f,
        -0.5f, 0.5f, -0.9f,   0.0f, 0.0f, 1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -0.9f,   0.0f, 0.0f, 1.0f,     1.0f, 0.0f,
        0.5f, -0.5f, -0.9f,   0.0f, 0.0f, 1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -0.9f,   0.0f, 0.0f, 1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -0.9f,  0.0f, 0.0f, 1.0f,     0.0f, 0.0f
    };
    
    //使用es2创建context实例
    _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //设置view的context及颜色格式和深度格式
    GLKView *view = (GLKView *)self.view;
    view.context = _context;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    //将此context设置为OpenGL的“当前激活”的“context”，这样，以后所有“GL”的指令均作用在这个context上
    [EAGLContext setCurrentContext:_context];
    
    //发送第一个“GL”指令：激活“深度检测”
    glEnable(GL_DEPTH_TEST);
    
    //创建一个GLK内置的“着色效果”
    _effect = [[GLKBaseEffect alloc]init];
    
    //提供一个光源，光的颜色为绿色
    _effect.light0.enabled = GL_TRUE;
    _effect.light0.diffuseColor = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    
    //声明一个缓冲区的标志符
    GLuint buffer;
    //让OpenGL自动分配一个缓冲区，并且返回这个标志符
    glGenBuffers(1, &buffer);
    //绑定这个缓冲区到当前“Context”
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    //将预先定义的顶点数据复制到缓冲区
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    
    //激活顶点属性,GLKVertexAttribPosition是顶点属性集中“位置Position”属性的索引
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    //顶点属性集中包含五种属性：位置、法线、颜色、纹理0、纹理1，索引值对应0～4

    /**
     *  填充数据
     *
     *  @param GLKVertexAttribPosition 顶点属性索引（这里是位置）
     *  @param 3                       3个分量的矢量
     *  @param GL_FLOAT                类型是浮点
     *  @param GL_FALSE                填充时不需要单位化
     *  @param 8                       在数据数组中每行的跨度是32个字节（4*8=32。从预定义的数组中可看出，每行有8个GL_FLOAT浮点值，而GL_FLOAT占4个字节，因此每一行的跨度是4*8）
     *  @param char                    最后一个参数是一个偏移量的指针，用来确定“第一个数据”将从内存数据块的什么地方开始
     */
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 4*8, (char *)NULL + 0);
    
    //继续复制其他数据，在前面预定义的顶点数据数组中，还包含了法线和纹理坐标，所以参照上面的方法，将剩余的数据分别复制进通用顶点属性中，原则上，必须先“激活”某个索引，才能将数据复制进这个索引表示的内存中。因为纹理坐标只有两个（S和T），所以参数是“2”。
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 4*8, (char *)NULL + 12);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 4*8, (char *)NULL + 24);
}

#pragma mark - delegate method
//这两个方法每帧都执行一次（循环执行），一般执行频率与屏幕刷新率相同（但也可以更改），第一次循环时，先掉用glkView，再掉用update
//一般，将场景数据变化放在“update”中，而渲染代码则放在“glkView”中
- (void)update {
    //修正矩形为正方形，首先计算出屏幕的纵横比（aspect），然后缩放单位矩阵的Y轴，强制将Y轴的单位刻度与X轴保持一致
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4Identity;
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.f, aspect, 1.f);
    _effect.transform.projectionMatrix = projectionMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //清除颜色缓冲区和深度缓冲区中的内容，并且填充淡蓝色背景（默认背景是黑色）
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //“prepareToDraw”方法，是让“效果Effect”针对当前“Context”的状态进行一些配置，它始终把“GL_TEXTURE_PROGRAM”状态定位到“Effect”对象的着色器上。此外，如果Effect使用了纹理，它也会修改“GL_TEXTURE_BINDING_2D”
    [_effect prepareToDraw];
    
    //让OpenGL“画出”两个三角形（拼合为一个正方形）。OpenGL会自动从通用顶点属性中取出这些数据、组装、再用“Effect”内置的着色器渲染
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    /*默认，“Effect”的投影矩阵是一个单位矩阵，它不做任何变换，将场景（-1，-1，-1）到（1，1，1）的立文体范围的物体，投射到屏幕的X：-1，1，Y：-1，1。因此，当屏幕本身是非正方形时，正方形的物体将被拉伸，从而显示为矩形。
    
    实际上，默认的“Effect”模型视图矩阵也是一个单位矩阵。
    
    透视投影中的观察点位于原点（0，0，0），并沿着Z轴的负方向进行观察，就像是从屏幕内部看进去。
     */
}

@end











