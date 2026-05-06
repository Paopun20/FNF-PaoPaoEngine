package funkin.backend.utils;

import haxe.Exception;
import sys.thread.Mutex;

class HxSignalKillUninitializedException extends Exception
{
}

#if cpp
@:cppInclude('signal.h')
@:cppFileCode('
#include <signal.h>

static const int _HX_SIG_QUEUE_SIZE = 32;

static volatile sig_atomic_t _hx_sig_queue[_HX_SIG_QUEUE_SIZE];
static volatile sig_atomic_t _hx_sig_write = 0;
static volatile sig_atomic_t _hx_sig_read = 0;

static void _haxe_signal_trampoline(int sig)
{
    sig_atomic_t next = (_hx_sig_write + 1) % _HX_SIG_QUEUE_SIZE;

    // Drop if full (never block in a signal handler)
    if (next == _hx_sig_read)
        return;

    _hx_sig_queue[_hx_sig_write] = sig;
    _hx_sig_write = next;
}
')
#end
class HxSignalKill
{
	static var _initialized:Bool = false;

	// Thread safety: only one thread dispatches signals
	static var _dispatchMutex:Mutex = new Mutex();

	// main-thread-safe queue
	static var _pendingSignals:Array<Int> = [];
	static var _pendingMutex:Mutex = new Mutex();

	// Callbacks
	public static var onSIGINT:() -> Void = null;
	public static var onSIGTERM:() -> Void = null;

	#if !windows
	public static var onSIGHUP:() -> Void = null;
	public static var onSIGUSR1:() -> Void = null;
	public static var onSIGUSR2:() -> Void = null;
	#end

	#if windows
	public static var onSIGBREAK:() -> Void = null;
	#end

	public static var onSignal:(Int) -> Void = null;

	public static function init():Void
	{
		if (_initialized)
			return;

		_initialized = true;

		#if cpp
		_hookSignals();
		#end
	}

	/**
	 * Poll signals from native queue.
	 * Safe to call from multiple threads.
	 */
	public static function updateSignal():Void
	{
		if (!_initialized)
			throw new HxSignalKillUninitializedException("HxSignalKill is not initialized");

		#if cpp
		// Only one thread drains queue
		if (!_dispatchMutex.tryAcquire())
			return;

		try
		{
			while (true)
			{
				var sig:Int = 0;

				untyped __cpp__('
                    if (_hx_sig_read == _hx_sig_write)
                    {
                        {0} = 0;
                    }
                    else
                    {
                        {0} = _hx_sig_queue[_hx_sig_read];
                        _hx_sig_read = (_hx_sig_read + 1) % _HX_SIG_QUEUE_SIZE;
                    }
                ', sig);

				if (sig == 0)
					break;

				// Push into main-thread queue
				_pendingMutex.acquire();
				_pendingSignals.push(sig);
				_pendingMutex.release();
			}
		}
		catch (e)
		{
		}

		_dispatchMutex.release();
		#end
	}

	/**
	 * Call this ONLY on your main thread (e.g. game loop)
	 */
	public static function dispatchPending():Void
	{
		var signals:Array<Int>;

		_pendingMutex.acquire();
		signals = _pendingSignals.copy();
		_pendingSignals = [];
		_pendingMutex.release();

		for (sig in signals)
		{
			_dispatch(sig);
		}
	}

	static function _dispatch(sig:Int):Void
	{
		// Generic hook first
		if (onSignal != null)
			onSignal(sig);

		switch (sig)
		{
			case 2:
				if (onSIGINT != null)
					onSIGINT();

			case 15:
				if (onSIGTERM != null)
					onSIGTERM();

			#if windows
			case 21:
				if (onSIGBREAK != null)
					onSIGBREAK();
			#else
			case 1:
				if (onSIGHUP != null)
					onSIGHUP();
			case 10:
				if (onSIGUSR1 != null)
					onSIGUSR1();
			case 12:
				if (onSIGUSR2 != null)
					onSIGUSR2();
			#end
		}
	}

	public static function name(sig:Int):String
	{
		return switch sig
		{
			case 2: "SIGINT";
			case 15: "SIGTERM";

			#if windows
			case 21: "SIGBREAK";
			#else
			case 1: "SIGHUP";
			case 10: "SIGUSR1";
			case 12: "SIGUSR2";
			#end

			default: 'SIG($sig)';
		}
	}

	#if cpp
	static function _hookSignals():Void
	{
		untyped __cpp__('
            signal(SIGINT,  _haxe_signal_trampoline);
            signal(SIGTERM, _haxe_signal_trampoline);

            #ifdef _WIN32
                signal(SIGBREAK, _haxe_signal_trampoline);
            #else
                signal(SIGHUP,  _haxe_signal_trampoline);
                signal(SIGUSR1, _haxe_signal_trampoline);
                signal(SIGUSR2, _haxe_signal_trampoline);

                signal(SIGPIPE, SIG_IGN);
            #endif
        ');
	}
	#end
}
