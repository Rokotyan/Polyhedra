//
//  Polyhedron.cpp
//  Polyhedron
//
//  Created by Nikita Rokotyan on 09.05.14.
//
//

#include "Polyhedron.h"

Polyhedron::Polyhedron( std::string sampleName, Colorf color, int hmin, int smin, int vmin, int hmax, int smax, int vmax ) {
    ci::audio2::SourceFileRef fileRef = ci::audio2::load( ci::app::loadAsset( sampleName ) );
    mBufferPlayerRef = ci::audio2::Context::master()->makeNode( new cinder::audio2::BufferPlayer );
    mBufferPlayerRef->loadBuffer( fileRef );
    mBufferPlayerRef->setLoopEnabled();
    
    audio2::Context* ctx    = audio2::Context::master();
    mGain                   = ctx->makeNode( new audio2::Gain );
    
    mBufferPlayerRef >> mGain >> ctx->getOutput();
    
    mColor       = color;
//    mHSVCriteria = hsvCriteria;
    Hmin = hmin;
    Smin = smin;
    Vmin = vmin;
    Hmax = hmax;
    Smax = smax;
    Vmax = vmax;
    
    mHangingState = false;
}

void Polyhedron::play() {
    mBufferPlayerRef->start();
    
}

void Polyhedron::pause() {
    mBufferPlayerRef->stop();
    
}

void Polyhedron::fadeIn( float sec ) {
    mGain->getParam()->applyRamp( 0.f, sec );
}

void Polyhedron::fadeOut( float sec ) {
    mGain->getParam()->applyRamp( 0.5f, sec );
}

void Polyhedron::setLoopRegion( double loopBeginTime, double loopEndTime ) {
    mLoopBeginTime = loopBeginTime;
    mLoopEndTime = loopEndTime;
    
    mBufferPlayerRef->setLoopEndTime( mLoopEndTime );
    mBufferPlayerRef->setLoopBeginTime( mLoopBeginTime );
    mBufferPlayerRef->setLoopEnabled();
}