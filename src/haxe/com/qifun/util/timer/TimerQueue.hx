package com.qifun.util.timer;
#if (cs && unity)
import dotnet.system.threading.Timer;
import unityengine.MonoBehaviour;
import unityengine.Time;
#elseif java
import java.util.concurrent.ScheduledExecutorService;
import java.lang.Runnable;
import java.lang.System;
#end

import com.qifun.util.ISubscriber;
import de.polygonal.ds.Prioritizable64;
import de.polygonal.ds.PriorityQueue64;
import haxe.Int64;

/**
 这个是`ITimer`实现
**/
private class Timer implements ITimer implements Prioritizable64
{
  public function new(creator:TimerQueue, durationMilliseconds:Int, updater:ITimerUpdater)
  {
    this.duration = durationMilliseconds;
    this.creator = creator;
    this.updater = updater;
  }

  public function onExpired():Void
  {
    if (expiredCallback != null)
    {
      this.expiredCallback();
    }
  }
  
  public function onUpdate():Void
  {
    #if cs
    if (this.updater != null)
    {
      this.updater.update(this.elapsedSeconds, this.durationSeconds);
    }
    #end
  }
  
  public function onFixedUpdate():Void
  {
    if (this.updater != null)
    {
      this.updater.fixedUpdate(this.elapsedMilliseconds, this.durationMilliseconds);
    }
  }
  
  public function expiredTime():Int64 return
  {
    Int64.add(this.startTime, Int64.ofInt(this.duration));
  }
  
  public var elapsedSeconds(get, never):Single;

  private function get_elapsedSeconds():Single return 
  {
   this.elapsedMilliseconds / 1000.0;
  }

  public var durationSeconds(get, never):Single;

  private function get_durationSeconds():Single return
  {
    this.durationMilliseconds / 1000.0;
  }
  
  function cancel():Void
  {
    this.creator.cancelTimer(this);
  }

  //implements ITimer
  public function run(interruptSubscriber:ISubscriber<Void->Void>, expiredCallback:Void->Void):Void
  {
    interruptSubscriber.subscribe(cancel.bind());
    this.expiredCallback = expiredCallback;
    creator.runTimer(this);
  }
  
  public var durationMilliseconds(get, never):Int;
  
  private function get_durationMilliseconds():Int return
  {
    this.duration;
  }
  
  public var elapsedMilliseconds(get, never):Int;

  private function get_elapsedMilliseconds():Int return
  {
    Int64.toInt(Int64.sub(this.creator.currentMilliSeconds,this.startTime));
  }
  
  private var creator:TimerQueue;
  private var expiredCallback:Void->Void;
  private var updater:ITimerUpdater;
  
  public var startTime:Int64; //这个值，在加入到queue中，让queue来改。
  public var duration:Int;
  public var priority:Int64;
  public var position:Int;
}

/**
  这个是`TimerQueue`的实现，用优先队列和`Update`进行。
**/
//@:final
@:nativeGen
@:allow(com.qifun.util.timer.Timer)
class TimerQueue implements ITimerQueue #if (cs && unity) extends MonoBehaviour #end
{
  public function new()
  {
    #if (cs && unity)
    super();
    #end
  }
  
  public var currentMilliSeconds(get, never):Int64;

  function get_currentMilliSeconds():Int64  return
  {
    _currentMilliSeconds;
  }
  
  public var isPaused(get, set):Bool;
  
  private function set_isPaused(value:Bool):Bool return
  {
    _isPaused = value;
  }
  
  private function get_isPaused():Bool return
  {
    this._isPaused;
  }
  
  //实现ITimerQueue
  public function newOneshotTimer(durationMilliseconds:Int):ITimer 
  {    
    var timer :Timer = new Timer(this, durationMilliseconds, null);
    timer.startTime = this.currentMilliSeconds;
    return timer;
  }

  public function newIntervalTimer(durationMilliseconds:Int, updater:ITimerUpdater):ITimer 
  {
    var timer :Timer = new Timer(this, durationMilliseconds, updater);
    timer.startTime = this.currentMilliSeconds;
    return timer;
  }
  
  #if (cs && unity)
  function Update():Void
  {
    if (!isPaused)
    {
      updateTimers();
      for (timer in timerExpireQueue)
      {
        timer.onUpdate();
      }
    }
  }
  #end
  
  public function updateTimers()
  {
    #if (cs && unity)
    this._currentMilliSeconds = Int64.ofInt(Std.int(Time.time * 1000));
    #elseif java
    this._currentMilliSeconds = System.currentTimeMillis();
    #end
    while (!timerExpireQueue.isEmpty())
    {
      var timer:Timer = timerExpireQueue.peek();
      if (Int64.compare(timer.expiredTime(), this.currentMilliSeconds) < 0)
      {
        timer.onExpired();
        timerExpireQueue.dequeue();
      }
      else
      {
        //后头的都比currentMilliSecond大，直接跳出循环了。
        break;
      }
    }
  }
  
  function fixedUpdate():Void
  {
    if (!isPaused)
    {
      for (timer in timerExpireQueue)
      {
        timer.onFixedUpdate();
      }
    }
  }
  
  // 以下函数提供给 Timer 作为友元函数
  private function runTimer(timer:Timer):Void
  {
    #if java
    this.timerScheduler.schedule(
      new ScheduleTimerExpired(this)
      , Int64.ofInt(timer.durationMilliseconds)
      , MILLISECONDS);
    #end
    timer.priority = Int64.neg(timer.expiredTime());
    this.timerExpireQueue.enqueue(timer);
  }
  
  private function cancelTimer(timer:Timer):Void
  {
    this.timerExpireQueue.remove(timer);
  }
  
  #if java
  private var timerScheduler:ScheduledExecutorService;
  #end
  
  private var timerExpireQueue:PriorityQueue64<Timer> = new PriorityQueue64<Timer>();
  private var _currentMilliSeconds:Int64;
  private var _isPaused:Bool = false;
}


/***
  空 `Timer` 的实现
**/
@:nativeGen
@:allow(com.qifun.util.timer.Timer)
class ImmediateTimerQueue extends TimerQueue
{
  public function new(timePeriodMilliSecond:Int)
  {
    super();
    this.timePeriod = timePeriodMilliSecond;
  }
  
  public function run():Void
  {
    this._currentMilliSeconds = Int64.ofInt(0);
    while (!timerExpireQueue.isEmpty())
    {
      for (timer in timerExpireQueue)
      {
        timer.onFixedUpdate();
        if (Int64.compare(timer.expiredTime(), this.currentMilliSeconds) < 0)
        {
          timer.onExpired();
          timerExpireQueue.dequeue();
        }
      }
      this._currentMilliSeconds = Int64.add(this._currentMilliSeconds, Int64.ofInt(this.timePeriod));
    }
  }
  
  private var timePeriod:Int;
}

#if java
private class ScheduleTimerExpired implements Runnable
{
  public function new(timerQueue:TimerQueue)
  {
    this.timerQueue = timerQueue;
  }
  public function run():Void
  {
    this.timerQueue.updateTimers();
  }
  private var timerQueue:TimerQueue;
}
#end