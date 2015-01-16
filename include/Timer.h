//
// TIMER SINGLETON
// ALL FUNCTIONS ARE STATIC
// USES CORE FOUNDATION FUNCTION -> SHOULD WORK ON MACS ANS IOS DEVICES
//
//
// (C) NIKITA ROKOTYAN -> CREATIVE DEVELOPER -> WWW.ROKOTYAN.COM

#ifndef Timer_h
#define Timer_h

#include <CoreFoundation/CoreFoundation.h>
//#include <tr1/functional>
//using namespace std::tr1;

class GameTimer
{
public:
    
    // CONSTRUCTOR AND DESTRUCTOR
    GameTimer();
    ~GameTimer() {};
    
    // FUNCTIONS
    static  void            init();
    static  GameTimer *     get();
    
    static  void            update();
    static  void            draw();
    static  void            setPaused( bool state );
    static  bool            isPaused() { return GameTimer::get()->paused; }
    static  void            setTime( float time);
    static  void            setLimit( double limit ) { GameTimer::get()->limit = limit; }
    static  void            setFunctionToCallWhenLimitReached( std::function< void() > funcPtr ) { GameTimer::get()->functionToCallWhenLimitReached = funcPtr; }
    static  double          get_dt();
    static  double          get_time();
        
    
    // VARIABLES
    // System time
    double                  startTime;
    double                  currentTime;
    double                  prevTime;
    
    // Game time
    double                  time;
    double                  dt;
    
    //
    size_t                  quarterCounter;
    size_t                  prevQuarterNumber;
    bool                    quarterAction;
    
    bool                    paused;
    double                  limit;
    std::function< void() > functionToCallWhenLimitReached;
    //void                    (*functionToCallWhenLimitReached)(void);
    
    
private:
    
    static GameTimer *      sInstance;

};


#endif
