
#include "Timer.h"
#include <iostream>

GameTimer*	GameTimer::sInstance = 0;

GameTimer::GameTimer()
{
    startTime   = ::CFAbsoluteTimeGetCurrent();
    currentTime = startTime;
    prevTime    = startTime;
    time        = 0.0;
    dt          = 0.0;
    paused      = false;
    limit       = 0;
    functionToCallWhenLimitReached = NULL;
    
    quarterCounter = 0;
    prevQuarterNumber = 0;
    quarterAction  = false;
}

void GameTimer::init()
{
    delete sInstance;
    sInstance = new GameTimer;
}

GameTimer* GameTimer::get()
{
    return sInstance; 
}

void GameTimer::update()
{
    GameTimer* GameTimer = GameTimer::get();
    if ( GameTimer->paused == false )
    {
        // Get current time and calculate dt using prevTime
        GameTimer->currentTime = ::CFAbsoluteTimeGetCurrent();
        GameTimer->dt = GameTimer->currentTime - GameTimer->prevTime;
        
        // calculate game time
        GameTimer->time += GameTimer->dt; 
        
        // set prevTime
        GameTimer->prevTime = GameTimer->currentTime;
        
        // count Quarters
        GameTimer->quarterCounter = (int)floor( (GameTimer->currentTime - floor( GameTimer->currentTime )) / 0.25f );
        if ( GameTimer->quarterCounter == 4 ) GameTimer->quarterCounter = 0;
        if ( GameTimer->prevQuarterNumber - GameTimer->quarterCounter != 0 ) 
        {
            GameTimer->prevQuarterNumber = GameTimer->quarterCounter;
            GameTimer->quarterAction = true;
        }
        
        if ( GameTimer->limit != 0 && GameTimer->time > GameTimer->limit ) {
            //GameTimer->paused = true;
            GameTimer->time = 0;
            if (GameTimer->functionToCallWhenLimitReached != NULL )
                GameTimer->functionToCallWhenLimitReached();
        }
    }
    
}

void GameTimer::draw()
{
    GameTimer* GameTimer = GameTimer::get();
    if ( GameTimer->quarterAction ) {
        std::cout << GameTimer->quarterCounter << std::endl;
        GameTimer->quarterAction = false;
    }
    
}

void GameTimer::setPaused( bool state )
{
    GameTimer* GameTimer = GameTimer::get();
    if ( ( GameTimer->paused == true ) && ( state == false ) )
    {
        GameTimer->currentTime = ::CFAbsoluteTimeGetCurrent();
        GameTimer->prevTime = GameTimer->currentTime;
        
        GameTimer->paused = false;
    }
    else {
        GameTimer->paused = state;
        GameTimer->dt = 0;
    }
}

void GameTimer::setTime(float newTime )
{
    GameTimer* GameTimer = GameTimer::get();
    GameTimer->time = newTime;
}

double GameTimer::get_dt()
{
    return GameTimer::get()->dt;
}

double GameTimer::get_time()
{
    return GameTimer::get()->time;
}