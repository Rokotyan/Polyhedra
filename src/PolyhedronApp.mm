#include "cinder/app/AppNative.h"
#include "cinder/gl/gl.h"
#include "cinder/ImageIo.h"
#include "cinder/gl/Texture.h"
#include "cinder/Capture.h"
#include "cinder/params/Params.h"


#include "CinderOpenCv.h"
#include "cinder/audio2/Source.h"
#include "cinder/audio2/Target.h"
#include "cinder/audio2/dsp/Converter.h"
#include "cinder/audio2/SamplePlayer.h"
#include "cinder/audio2/NodeEffect.h"
#include "cinder/audio2/Scope.h"
#include "cinder/audio2/Debug.h"

#include "UVCCameraControl.h"


#include "Timer.h"
#include "Polyhedron.h"

using namespace ci;
using namespace ci::app;
using namespace std;



class PolyhedronApp : public AppNative {
  public:
    void prepareSettings( Settings* settings );
	void setup();
    void update();
	void draw();
    
    void keyDown( KeyEvent event );
    void mouseDown( MouseEvent event );
    void mouseDrag( MouseEvent event );
    void mouseUp( MouseEvent event );
    
    void detectPolyhedron( Polyhedron* poly, cv::Mat cvImage );
    
	gl::Texture                     mTexture;
    
    // Camera
    Capture                         mCamera;
    const int                       mCameraImageWidth  = 640;
    const int                       mCameraImageHeight = 480;
    Surface8u                       mCameraImage;
    gl::TextureRef                  mCameraImageTexture;
    gl::TextureRef                  mThresholdImageTexture;
    cv::Mat                         cvCurrentFrame;
    cv::Mat                         cvThresholdImage;
    Vec2f                           mCam2ImageRatio;
    
    
    // OpenCV Parameters
    float                           cvParamThreshold;
    float                           cvParamMaxVal;
    int                             cvParamThresBlockSize;
    float                           cvParamThresConstant;
    double                          cvParamApprxPrecision;
    int                             cvParamMinContSize;
    int                             cvParamMaxContSize;
    
    int                             cvMinH, cvMinS, cvMinV, cvMaxH, cvMaxS, cvMaxV;
    int                             cvErodeSize, cvDilateSize;
    
    vector< vector< cv::Point > >   cvFoundContours;
    vector< vector< cv::Point > >   cvApproxedContours;
    
    bool                            mColorDetection;
    
    
    // Params
	params::InterfaceGl             mParams;
    params::InterfaceGl             mRegularTetrahedronParams, mDipyramidParams, mPentagonalParams,
                                    mSphenocoronaParams, mAugmentedTetrahedronParams, mGyrobifastigiumParams,
                                    mDurersSolidParams;
    
    // Audio
    audio2::GainRef                 mGain;
    
    // Objects
    Polyhedron                      mRegularTetrahedron, mDipyramid, mPentagonal,
                                    mSphenocorona, mAugmentedTetrahedron, mGyrobifastigium,
                                    mDurersSolid;
    Polyhedron                      mBase1, mBase2, mConnection1, mConnection2, mConnection3;
    
    // Detection Regions
    vector< Rectf >                 mDetectionRegions;
    Vec2f                           mSelectionStart, mSelectionEnd;
    
    // Test Pictures
    vector< Surface8u >             mTestPictures;
    int                             mActiveTestPicture;
    bool                            mTestMode;
    
    // Camera parameters
    UVCCameraControl *      mCameraControl;
    float                   mExposure;
    
    bool                    mStopDetection;
    
    
};

void PolyhedronApp::prepareSettings( Settings* settings ) {
    settings->setWindowSize( 1024, 768 );
    settings->setFrameRate( 15 );
}

void PolyhedronApp::setup() {

    mStopDetection = true;
    // App
    GameTimer::init();
    GameTimer::setPaused( true );
    mThresholdImageTexture = gl::Texture().create( mCameraImageWidth, mCameraImageHeight );
    
    
    // Audio
    audio2::Context* ctx    = audio2::Context::master();
    ctx->enable();
    
    
    // Objects
    mBase1                  = Polyhedron( "base_1.wav", Colorf( 1.f, 0, 0 ), 117, 110, 131,223,255,255  );
    mBase2                  = Polyhedron( "base_2.wav", Colorf( 1.f, 0, 0 ), 117, 110, 131,223,255,255  );
    mConnection1            = Polyhedron( "connect_1.wav", Colorf( 1.f, 0, 0 ), 117, 110, 131,223,255,255  );
    mConnection2            = Polyhedron( "connect_2.wav", Colorf( 1.f, 0, 0 ), 117, 110, 131,223,255,255  );
    mConnection3            = Polyhedron( "connect_3.wav", Colorf( 1.f, 0, 0 ), 117, 110, 131,223,255,255  );
    mRegularTetrahedron 	= Polyhedron( "obj_1.wav", Colorf( 1.f, 0, 0 ), 117, 110, 131,223,255,255  );
    mDipyramid              = Polyhedron( "obj_2.wav", Colorf( 0.f, 1, 0 ), 5, 129, 112, 255,255,255  );
    mPentagonal             = Polyhedron( "obj_3.wav", Colorf( 0.f, 0, 1 ), 5, 129, 112, 255,255,255  );
    mSphenocorona           = Polyhedron( "obj_4.wav", Colorf( 1.f, 0.2, 0.8 ), 5, 129, 112, 255,255,255  );
    mAugmentedTetrahedron   = Polyhedron( "obj_5.wav", Colorf( 1.f, 1.f, 0.0 ), 5, 129, 112, 255,255,255  );
    mGyrobifastigium        = Polyhedron( "obj_6.wav", Colorf( 0.f, 0.0, 1.0f ), 5, 129, 112, 255,255,255  );
    mDurersSolid            = Polyhedron( "obj_7.wav", Colorf( 0.3f, 0.3, 0.0 ), 5, 129, 112, 255,255,255  );
    
    
    
    mRegularTetrahedron.play();
    mDipyramid.play();
    mPentagonal.play();
    mSphenocorona.play();
    mAugmentedTetrahedron.play();
    mGyrobifastigium.play();
    mDurersSolid.play();
    mBase1.play();
    mBase2.play();
    
    mConnection1.play();
    mConnection2.play();
    mConnection2.play();
    
    
    mRegularTetrahedron.setVolume( 0.f );
    mDipyramid.setVolume( 0.f );
    mPentagonal.setVolume( 0.f );
    mSphenocorona.setVolume( 0.f );
    mAugmentedTetrahedron.setVolume( 0.f );
    mGyrobifastigium.setVolume( 0.f );
    mDurersSolid.setVolume( 0.f );
    mBase1.setVolume( 0.f );
    mBase2.setVolume( 0.f );
    mConnection1.setVolume( 0.f );
    mConnection2.setVolume( 0.f );
    mConnection3.setVolume( 0.f );
    
    // OpenCV
    cvThresholdImage        = cv::Mat( mCameraImageHeight, mCameraImageWidth, CV_8UC3 );
    mColorDetection         = true;
    cvParamThreshold        = 50.0f;
	cvParamMaxVal           = 255.0f;
    cvParamThresBlockSize   = 9;
	cvParamThresConstant    = -0.015f;
    cvParamApprxPrecision   = 8.0;
    cvParamMinContSize      = 10;
    cvParamMaxContSize      = 200;
    
    cvMinH = 117;
    cvMinS = 110;
    cvMinV = 131;
    cvMaxH = 223;
    cvMaxS = 255;
    cvMaxV = 255;
    
    cvErodeSize = 1;
    cvDilateSize = 9;
    
    // Detection regions
    mSelectionStart = Vec2f( -1, -1 );
    mSelectionEnd = Vec2f( -1, -1 );
    
    // Test Pictures
    mTestMode = true;
    mActiveTestPicture = 0;
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P_new.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P1_1.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P1_2.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P1_3.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P2_1.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P2_2.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P2_3.jpg") ) ) );
    mTestPictures.push_back( Surface8u( loadImage( loadAsset( "TestImages/P2_4.jpg") ) ) );
    
    
    // Camera
    mCameraImage            = Surface8u( mCameraImageWidth, mCameraImageHeight, false );
    mCam2ImageRatio         = Vec2f( getWindowWidth()/float( mCameraImageWidth ), getWindowHeight()/float( mCameraImageHeight ) );
    vector< Capture::DeviceRef > cameraDevices = Capture::getDevices();
    mCamera                 = Capture( mCameraImageWidth, mCameraImageHeight, cameraDevices[0] );
    for ( auto& d : cameraDevices ) {
        console() << d->getName() << endl;
        if ( d->getName() == "HP Deluxe Webcam KQ246AA" )
            mCamera = Capture( mCameraImageWidth, mCameraImageHeight, d );
    }
    
//    UInt32 locationID = 0;
//    Capture::DeviceIdentifier uID = mCamera.getDevice()->getUniqueId();
//    sscanf( uID.c_str(), "0x%8x", &locationID );
//    printf("Unique ID: %s\n",  uID.c_str() );
//    mCameraControl = [[UVCCameraControl alloc] initWithLocationID:locationID];
//	[mCameraControl setAutoExposure:NO];
//    mExposure = 0.5f;
//    
    
    if ( !mTestMode )
        mCamera.start();
    
    
    // Params
    mParams = params::InterfaceGl( "Polyhedon", Vec2i( 240, 140 ) );
    mParams.addParam( "Threshold",          &cvParamThreshold,      "min=0.0 max=255.0 step=1.0" );// keyIncr=] keyDecr=[" );
    mParams.addParam( "Th. Block Size",     &cvParamThresBlockSize, "min=3.0 max=219.0 step=2.0" );
    mParams.addParam( "Th. Constant",       &cvParamThresConstant,  "min=-1.0 max=1.0 step=0.0005" );
    mParams.addParam( "Apprx. Precision",   &cvParamApprxPrecision, "min=0.0 max=100.0 step=0.1" );
    mParams.addParam( "Min. Cont. Size",    &cvParamMinContSize,    "min=0.0 max=250.0 step=1.0" );
    mParams.addParam( "Max. Cont. Size",    &cvParamMaxContSize,    "min=0.0 max=500.0 step=1.0" );
    
    mParams.addParam( "Min H", &cvMinH, "min=0 max=255 step=1" );
    mParams.addParam( "Min S", &cvMinS, "min=0 max=255 step=1" );
    mParams.addParam( "Min V", &cvMinV, "min=0 max=255 step=1" );
    mParams.addParam( "Max H", &cvMaxH, "min=0 max=255 step=1" );
    mParams.addParam( "Max S", &cvMaxS, "min=0 max=255 step=1" );
    mParams.addParam( "Max V", &cvMaxV, "min=0 max=255 step=1" );
    mParams.addParam( "Erode Size", &cvErodeSize, "min=1 max=25 step=1" );
    mParams.addParam( "Dilate Size", &cvDilateSize, "min=1 max=25 step=1" );
    

    mRegularTetrahedronParams = params::InterfaceGl( "Regular Tetrahedron", Vec2i( 160, 180 ) );
    mRegularTetrahedronParams.addParam( "Hmin", &mRegularTetrahedron.Hmin, "min=0 max=255 step=1" );
    mRegularTetrahedronParams.addParam( "Smin", &mRegularTetrahedron.Smin, "min=0 max=255 step=1" );
    mRegularTetrahedronParams.addParam( "Vmin", &mRegularTetrahedron.Vmin, "min=0 max=255 step=1" );
    mDipyramidParams = params::InterfaceGl( "Dipyramid", Vec2i( 160, 180 ) );
    mDipyramidParams.addParam( "Hmin", &mDipyramid.Hmin, "min=0 max=255 step=1" );
    mDipyramidParams.addParam( "Smin", &mDipyramid.Smin, "min=0 max=255 step=1" );
    mDipyramidParams.addParam( "Vmin", &mDipyramid.Vmin, "min=0 max=255 step=1" );
    mPentagonalParams = params::InterfaceGl( "Pentagonal", Vec2i( 160, 180 ) );
    mPentagonalParams.addParam( "Hmin", &mPentagonal.Hmin, "min=0 max=255 step=1" );
    mPentagonalParams.addParam( "Smin", &mPentagonal.Smin, "min=0 max=255 step=1" );
    mPentagonalParams.addParam( "Vmin", &mPentagonal.Vmin, "min=0 max=255 step=1" );
    mSphenocoronaParams = params::InterfaceGl( "Sphenocorona", Vec2i( 160, 180 ) );
    mSphenocoronaParams.addParam( "Hmin", &mSphenocorona.Hmin, "min=0 max=255 step=1" );
    mSphenocoronaParams.addParam( "Smin", &mSphenocorona.Smin, "min=0 max=255 step=1" );
    mSphenocoronaParams.addParam( "Vmin", &mSphenocorona.Vmin, "min=0 max=255 step=1" );
    mAugmentedTetrahedronParams = params::InterfaceGl( "AugmentedTetrahedron", Vec2i( 160, 180 ) );
    mAugmentedTetrahedronParams.addParam( "Hmin", &mAugmentedTetrahedron.Hmin, "min=0 max=255 step=1" );
    mAugmentedTetrahedronParams.addParam( "Smin", &mAugmentedTetrahedron.Smin, "min=0 max=255 step=1" );
    mAugmentedTetrahedronParams.addParam( "Vmin", &mAugmentedTetrahedron.Vmin, "min=0 max=255 step=1" );
    mGyrobifastigiumParams = params::InterfaceGl( "Gyrobifastigium", Vec2i( 160, 180 ) );
    mGyrobifastigiumParams.addParam( "Hmin", &mGyrobifastigium.Hmin, "min=0 max=255 step=1" );
    mGyrobifastigiumParams.addParam( "Smin", &mGyrobifastigium.Smin, "min=0 max=255 step=1" );
    mGyrobifastigiumParams.addParam( "Vmin", &mGyrobifastigium.Vmin, "min=0 max=255 step=1" );
    mDurersSolidParams = params::InterfaceGl( "Durers Solid", Vec2i( 160, 180 ) );
    mDurersSolidParams.addParam( "Hmin", &mDurersSolid.Hmin, "min=0 max=255 step=1" );
    mDurersSolidParams.addParam( "Smin", &mDurersSolid.Smin, "min=0 max=255 step=1" );
    mDurersSolidParams.addParam( "Vmin", &mDurersSolid.Vmin, "min=0 max=255 step=1" );
    
    mRegularTetrahedronParams.addParam( "Hmax", &mRegularTetrahedron.Hmax, "min=0 max=255 step=1" );
    mRegularTetrahedronParams.addParam( "Smax", &mRegularTetrahedron.Smax, "min=0 max=255 step=1" );
    mRegularTetrahedronParams.addParam( "Vmax", &mRegularTetrahedron.Vmax, "min=0 max=255 step=1" );
    mDipyramidParams.addParam( "Hmax", &mDipyramid.Hmax, "min=0 max=255 step=1" );
    mDipyramidParams.addParam( "Smax", &mDipyramid.Smax, "min=0 max=255 step=1" );
    mDipyramidParams.addParam( "Vmax", &mDipyramid.Vmax, "min=0 max=255 step=1" );
    mPentagonalParams.addParam( "Hmax", &mPentagonal.Hmax, "min=0 max=255 step=1" );
    mPentagonalParams.addParam( "Smax", &mPentagonal.Smax, "min=0 max=255 step=1" );
    mPentagonalParams.addParam( "Vmax", &mPentagonal.Vmax, "min=0 max=255 step=1" );
    mSphenocoronaParams.addParam( "Hmax", &mSphenocorona.Hmax, "min=0 max=255 step=1" );
    mSphenocoronaParams.addParam( "Smax", &mSphenocorona.Smax, "min=0 max=255 step=1" );
    mSphenocoronaParams.addParam( "Vmax", &mSphenocorona.Vmax, "min=0 max=255 step=1" );
    mAugmentedTetrahedronParams.addParam( "Hmax", &mAugmentedTetrahedron.Hmax, "min=0 max=255 step=1" );
    mAugmentedTetrahedronParams.addParam( "Smax", &mAugmentedTetrahedron.Smax, "min=0 max=255 step=1" );
    mAugmentedTetrahedronParams.addParam( "Vmax", &mAugmentedTetrahedron.Vmax, "min=0 max=255 step=1" );
    mGyrobifastigiumParams.addParam( "Hmax", &mGyrobifastigium.Hmax, "min=0 max=255 step=1" );
    mGyrobifastigiumParams.addParam( "Smax", &mGyrobifastigium.Smax, "min=0 max=255 step=1" );
    mGyrobifastigiumParams.addParam( "Vmax", &mGyrobifastigium.Vmax, "min=0 max=255 step=1" );
    mDurersSolidParams.addParam( "Hmax", &mDurersSolid.Hmax, "min=0 max=255 step=1" );
    mDurersSolidParams.addParam( "Smax", &mDurersSolid.Smax, "min=0 max=255 step=1" );
    mDurersSolidParams.addParam( "Vmax", &mDurersSolid.Vmax, "min=0 max=255 step=1" );
    
}

void PolyhedronApp::update() {
    
    mRegularTetrahedron.setHanging( false );
    mDipyramid.setHanging( false );
    mPentagonal.setHanging( false );
    mSphenocorona.setHanging( false );
    mAugmentedTetrahedron.setHanging( false );
    mGyrobifastigium.setHanging( false );
    mDurersSolid.setHanging( false );
    
    if ( mTestMode )
        mCameraImage =  mTestPictures.at( mActiveTestPicture );
    else {
        if( mCamera.checkNewFrame() == false )
            return;
        
        mCameraImage =  mCamera.getSurface();
    }
    
    mCameraImageTexture = gl::Texture::create( mCameraImage );
    cvCurrentFrame = cv::Mat( toOcv( ( mCameraImage ) ) );;
    
    if ( mColorDetection ) {
        cv::cvtColor( cvCurrentFrame, cvCurrentFrame, cv::COLOR_BGR2HSV );
        
        cv::inRange( cvCurrentFrame, cv::Scalar( cvMinH, cvMinS, cvMinV ), cv::Scalar( cvMaxH, cvMaxS, cvMaxV), cvThresholdImage );
        cv::erode( cvThresholdImage, cvThresholdImage, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size( cvErodeSize, cvErodeSize )) );
        cv::dilate( cvThresholdImage, cvThresholdImage, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size( cvDilateSize, cvDilateSize )) );
        mThresholdImageTexture = gl::Texture::create( fromOcv( cvThresholdImage ) );
        
        for ( auto& rect : mDetectionRegions ) {
            cv::Mat currentFrameRegion = cv::Mat( cvCurrentFrame, cv::Range( rect.y1 / mCam2ImageRatio.y, rect.y2  / mCam2ImageRatio.y ), cv::Range( rect.x1 / mCam2ImageRatio.x, rect.x2 / mCam2ImageRatio.x ) );
            
            detectPolyhedron( &mRegularTetrahedron, currentFrameRegion );
            detectPolyhedron( &mDipyramid, currentFrameRegion );
            detectPolyhedron( &mPentagonal, currentFrameRegion );
            detectPolyhedron( &mSphenocorona, currentFrameRegion );
            detectPolyhedron( &mAugmentedTetrahedron, currentFrameRegion );
            detectPolyhedron( &mGyrobifastigium, currentFrameRegion );
            detectPolyhedron( &mDurersSolid, currentFrameRegion );


        }
        cv::cvtColor( cvCurrentFrame, cvCurrentFrame, cv::COLOR_HSV2BGR );
    }

    
    mTexture = gl::Texture( fromOcv( cvCurrentFrame ) );
    
}

void PolyhedronApp::draw() {
    
    if( !mStopDetection ) {
	mRegularTetrahedron.fadeOut( 4.f );
    mDipyramid.fadeOut( 4.f );
    mPentagonal.fadeOut( 4.f );
    mSphenocorona.fadeOut( 4.f );
    mAugmentedTetrahedron.fadeOut( 4.f );
    mGyrobifastigium.fadeOut( 4.f );
    mDurersSolid.fadeOut( 4.f );
}

    gl::clear();
    gl::color( 255, 255, 255 );
    if ( mTexture && mThresholdImageTexture ) {
//        gl::draw( mCameraImageTexture );
        gl::draw( mTexture, Rectf( 0,0, getWindowWidth(), getWindowHeight() ) );
        gl::draw( mThresholdImageTexture, Rectf( getWindowWidth() - 200, 0, getWindowWidth(), 150 ) );
    }


    if ( mSelectionStart != Vec2f(-1,-1) )
        gl::drawStrokedRect( Rectf( mSelectionStart, mSelectionEnd ) );
    
    if (mDetectionRegions.size() > 0) {
        for ( auto& dr : mDetectionRegions )
            gl::drawStrokedRect( dr );
    }
    
    if (!mStopDetection) {
    if ( mRegularTetrahedron.isHanging() ) {
        gl::color( mRegularTetrahedron.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 70, 10 ), 6 );
        mRegularTetrahedron.fadeOut( 4.f );
    } else mRegularTetrahedron.fadeIn( 4.f );
    
    if ( mDipyramid.isHanging() ) {
        gl::color( mDipyramid.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 60, 10 ), 6 );
        mDipyramid.fadeOut( 4.f );
    } else mDipyramid.fadeIn( 4.f );
    
    if ( mPentagonal.isHanging() ) {
        gl::color( mPentagonal.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 50, 10 ), 6 );
        mPentagonal.fadeOut( 4.f );
        
    } else mPentagonal.fadeIn( 4.f );
    
    if ( mSphenocorona.isHanging() ) {
        gl::color( mSphenocorona.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 40, 10 ), 6 );
        mSphenocorona.fadeOut( 4.f );
    } else mSphenocorona.fadeIn( 4.f );
    
    if ( mAugmentedTetrahedron.isHanging() ) {
        gl::color( mAugmentedTetrahedron.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 30, 10 ), 6 );
        mAugmentedTetrahedron.fadeOut( 4.f );
    } else mAugmentedTetrahedron.fadeIn( 4.f );
    
    if ( mGyrobifastigium.isHanging() ) {
        gl::color( mGyrobifastigium.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 20, 10 ), 6 );
        mGyrobifastigium.fadeOut( 4.f );
    } else mGyrobifastigium.fadeIn( 4.f );
    
    if ( mDurersSolid.isHanging() ) {
        gl::color( mDurersSolid.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 10, 10 ), 6 );
        mDurersSolid.fadeOut( 4.f );
    } else mDurersSolid.fadeIn( 4.f );
    }
    
    
    if ( mRegularTetrahedron.getVolume() != 0 ) {
        gl::color( mRegularTetrahedron.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 70, 20 ), 6 );
    }
    
    if ( mDipyramid.getVolume() != 0 ) {
        gl::color( mDipyramid.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 60, 20 ), 6 );
    }
    if ( mPentagonal.getVolume() != 0) {
        gl::color( mPentagonal.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 50, 20 ), 6 );
    }
    
    if ( mSphenocorona.getVolume() != 0 ) {
        gl::color( mSphenocorona.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 40, 20 ), 6 );
    }
    
    if ( mAugmentedTetrahedron.getVolume() != 0 ) {
        gl::color( mAugmentedTetrahedron.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 30, 20 ), 6 );
    }
    
    if ( mGyrobifastigium.getVolume() != 0 ) {
        gl::color( mGyrobifastigium.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 20, 20 ), 6 );
    }
    
    if ( mDurersSolid.getVolume() != 0 ) {
        gl::color( mDurersSolid.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 10, 20 ), 6 );
    }
    
    
    
    if ( mBase1.getVolume() != 0 ) {
        gl::color( mBase1.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 20, 60 ), 6 );
    }
    if ( mBase2.getVolume() != 0 ) {
        gl::color( mBase2.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 10, 60 ), 6 );
    }
    
    if ( mConnection1.getVolume() != 0 ) {
        gl::color( mConnection1.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 30, 40 ), 6 );
    }
    if ( mConnection2.getVolume() != 0 ) {
        gl::color( mConnection2.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 20, 40 ), 6 );
    }
    if ( mConnection3.getVolume() != 0 ) {
        gl::color( mConnection3.mColor );
        gl::drawSolidCircle( getWindowSize() - Vec2i( 10, 40 ), 6 );
    }




    mParams.draw();
}

void PolyhedronApp::detectPolyhedron( Polyhedron* poly, cv::Mat cvImage ) {
    
    cv::Mat thImage;
    
    cv::inRange( cvImage, cv::Scalar( poly->Hmin, poly->Smin, poly->Vmin ), cv::Scalar( poly->Hmax, poly->Smax, poly->Vmax ), thImage );
    cv::erode( thImage, thImage, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size( cvErodeSize, cvErodeSize )) );
    cv::dilate( thImage, thImage, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size( cvDilateSize, cvDilateSize )) );
    
    cv::Moments moments = cv::moments( thImage );
    if ( moments.m00 > 1000000 )
        poly->setHanging();
}

void PolyhedronApp::keyDown( KeyEvent event ) {
    if ( event.getCode() == KeyEvent::KEY_BACKSPACE ) {
        if (mDetectionRegions.size() > 0) {
            mDetectionRegions.pop_back();
        }
    }
    
    if ( event.getChar() == '1' ) {
        if ( mRegularTetrahedron.getVolume() == 0 )
            mRegularTetrahedron.fadeOut( 2.0f );
        else
            mRegularTetrahedron.fadeIn( 2.0f );
    }
    else if ( event.getChar() == '2' ) {
        if ( mDipyramid.getVolume() == 0 )
            mDipyramid.fadeOut( 2.0f );
        else
            mDipyramid.fadeIn( 2.0f );
    }
    else if ( event.getChar() == '3' ) {
        if ( mPentagonal.getVolume() == 0 )
            mPentagonal.fadeOut( 2.0f );
        else
            mPentagonal.fadeIn( 2.0f );
    }
    else if ( event.getChar() == '4' ) {
        if ( mSphenocorona.getVolume() == 0 )
            mSphenocorona.fadeOut( 2.0f );
        else
            mSphenocorona.fadeIn( 2.0f );
    }
    else if ( event.getChar() == '5' ) {
        if ( mAugmentedTetrahedron.getVolume() == 0 )
            mAugmentedTetrahedron.fadeOut( 2.0f );
        else
            mAugmentedTetrahedron.fadeIn( 2.0f );
    }
    else if ( event.getChar() == '6' ) {
        if ( mGyrobifastigium.getVolume() == 0 )
            mGyrobifastigium.fadeOut( 2.0f );
        else
            mGyrobifastigium.fadeIn( 2.0f );
    }
    else if ( event.getChar() == '7' ) {
        if ( mDurersSolid.getVolume() == 0 )
            mDurersSolid.fadeOut( 2.0f );
        else
            mDurersSolid.fadeIn( 2.0f );
    }
    else if ( event.getChar() == 'q' ) {
        if ( mBase1.getVolume() == 0 )
            mBase1.fadeOut( 2.0f );
        else
            mBase1.fadeIn( 2.0f );
    }
    else if ( event.getChar() == 'w' ) {
        if ( mBase2.getVolume() == 0 )
            mBase2.fadeOut( 2.0f );
        else
            mBase2.fadeIn( 2.0f );
    }
    else if ( event.getChar() == 'a' ) {
        if ( mConnection1.getVolume() == 0 )
            mConnection1.fadeOut( 2.0f );
        else
            mConnection1.fadeIn( 2.0f );
    }
    else if ( event.getChar() == 's' ) {
        if ( mConnection2.getVolume() == 0 )
            mConnection2.fadeOut( 2.0f );
        else
            mConnection2.fadeIn( 2.0f );
    }
    else if ( event.getChar() == 'd' ) {
        if ( mConnection3.getVolume() == 0 )
            mConnection3.fadeOut( 2.0f );
        else
            mConnection3.fadeIn( 2.0f );
    }

    
//    if ( event.getChar() == '[' ) {
//        mExposure -= 0.5f;
//        if ( mExposure < 0.5f )
//            mExposure = 0.5f;
//        [ mCameraControl setExposure: mExposure ];
//    }
//    else if ( event.getChar() == ']' ) {
//        mExposure += 0.5f;
//        if ( mExposure > 5.f )
//            mExposure = 5.f;
//        [ mCameraControl setExposure: mExposure ];
//    }
    
    if ( event.getChar() == 'p' ) {
        printf("cvMinH = %d\ncvMinS = %d\ncvMinV = %d\ncvMaxH = %d\ncvMaxS = %d\ncvMaxV = %d\n",
               cvMinH, cvMinS, cvMinV, cvMaxH, cvMaxS, cvMaxV );
    }
}

void PolyhedronApp::mouseDown( MouseEvent event ) {
    
    if ( event.isControlDown() ) {
        int col = event.getPos().x / mCam2ImageRatio.x;
        int row = event.getPos().x / mCam2ImageRatio.y;
   
        cv::cvtColor( cvCurrentFrame, cvCurrentFrame, cv::COLOR_BGR2HSV );
        printf( "%d  %d  %d\n", cvCurrentFrame.ptr( row, col )[0], cvCurrentFrame.ptr( row, col )[1], cvCurrentFrame.ptr( row, col )[2] );
        cv::cvtColor( cvCurrentFrame, cvCurrentFrame, cv::COLOR_HSV2BGR );
        
    }
    
    mSelectionStart = event.getPos();
    mSelectionEnd = event.getPos();
    
}

void PolyhedronApp::mouseDrag( MouseEvent event ) {
    mSelectionEnd = event.getPos();
    
}

void PolyhedronApp::mouseUp( MouseEvent event ) {
    if ( mSelectionEnd != mSelectionStart ) {
        mDetectionRegions.push_back( Rectf( mSelectionStart, mSelectionEnd ) );
    }
    
        mSelectionStart = Vec2f( -1, -1 );
        mSelectionEnd = Vec2f( -1, -1 );
}

CINDER_APP_NATIVE( PolyhedronApp, RendererGl )
