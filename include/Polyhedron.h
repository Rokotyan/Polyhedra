//
//  Polyhedron.h
//  Polyhedron
//
//  Created by Nikita Rokotyan on 09.05.14.
//
//

#pragma once

#include "cinder/audio2/Source.h"
#include "cinder/audio2/Target.h"
#include "cinder/audio2/dsp/Converter.h"
#include "cinder/audio2/SamplePlayer.h"
#include "cinder/audio2/NodeEffect.h"
#include "cinder/audio2/Scope.h"
#include "cinder/audio2/Debug.h"

#include <iostream>

using namespace ci;

class Polyhedron {
public:
    Polyhedron() {};
    Polyhedron( std::string sampleName, Colorf color = Colorf(1,0,0), int hmin = 0, int smin = 0, int vmin = 0, int hmax = 0, int smax = 0, int vmax = 0);
    
    audio2::BufferPlayerRef         getBufferPlayerRef() {return mBufferPlayerRef; }
    
    void                            play();
    void                            pause();
    void                            fadeIn( float sec );
    void                            fadeOut( float sec );
    bool                            isPlaying()  { return mBufferPlayerRef->isEnabled(); }
    float                           getVolume()  { return mGain->getValue(); }
    void                            setVolume( float value )  { return mGain->setValue( value ); }
    bool                            isHanging() { return mHangingState; }
    void                            setHanging( bool hangingState = true ) { mHangingState = hangingState; }
    
    void                            setLoopRegion( double loopBeginTime, double loopEndTime );
    void                            updateLoopRegion();
    
    
    
    audio2::BufferPlayerRef         mBufferPlayerRef;
    audio2::GainRef                 mGain;
    double                          mLoopBeginTime, mLoopEndTime;
    
    Colorf                          mColor;
    Vec3i                           mHSVCriteria;
    int                             Hmin,Smin,Vmin, Hmax, Smax, Vmax;
    
    bool                            mHangingState;
};

