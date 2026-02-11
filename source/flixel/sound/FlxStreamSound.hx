// Original code: https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/audio/FlxStreamSound.hx
package flixel.sound;

import openfl.media.Sound;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end

/**
 * Interface for streaming audio playback.
 *
 * Abstracts the streaming-specific `loadEmbedded` override so that
 * consumers can depend on the interface rather than the concrete class.
 */
interface IFlxStreamSound
{
	/**
	 * Loads an embedded sound asset for streaming playback.
	 *
	 * @param EmbeddedSound The sound asset to load (Sound, Class, or String path)
	 * @param Looped Whether the sound should loop continuously (default: false)
	 * @param AutoDestroy Whether to destroy the sound when it finishes (default: false)
	 * @param OnComplete Optional callback function to execute when playback completes
	 * @return This instance for method chaining
	 */
	public function loadEmbedded(EmbeddedSound:Null<FlxSoundAsset>, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound;
}

/**
 * A custom FlxSound implementation optimized for streaming audio playback.
 *
 * This class extends FlxSound to use OpenFL's `Assets.getMusic()` instead of
 * `Assets.getSound()`, which streams audio data rather than loading it entirely
 * into memory. This provides better performance and reduced memory usage for
 * large audio files.
 */
@:nullSafety
class FlxStreamSound extends FlxSound implements IFlxStreamSound
{
	/**
	 * Creates a new FlxStreamSound instance.
	 */
	public function new()
	{
		super();
	}

	/**
	 * Loads an embedded sound asset for streaming playback.
	 *
	 * This override uses `Assets.getMusic()` to stream the audio file instead of
	 * loading it entirely into memory, which is more efficient for large files.
	 *
	 * @param EmbeddedSound The sound asset to load. Can be:
	 *                      - A Sound object
	 *                      - A Class reference to a Sound
	 *                      - A String path to an asset
	 * @param Looped Whether the sound should loop continuously (default: false)
	 * @param AutoDestroy Whether to destroy the sound when it finishes (default: false)
	 * @param OnComplete Optional callback function to execute when playback completes
	 * @return This FlxStreamSound instance for method chaining
	 *
	 * @note ID3 metadata cannot be extracted from embedded sounds with this method
	 * @note Asset strings are checked against both SOUND and MUSIC asset types
	 */
	override public function loadEmbedded(EmbeddedSound:Null<FlxSoundAsset>, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound
	{
		if (EmbeddedSound == null)
			return this;

		cleanup(true);

		// Handle direct Sound object
		if ((EmbeddedSound is Sound))
		{
			_sound = EmbeddedSound;
		}
		// Handle Sound class reference
		else if ((EmbeddedSound is Class))
		{
			_sound = Type.createInstance(EmbeddedSound, []);
		}
		// Handle asset path string
		else if ((EmbeddedSound is String))
		{
			// Check if asset exists in either SOUND or MUSIC categories
			if (Assets.exists(EmbeddedSound, AssetType.SOUND) || Assets.exists(EmbeddedSound, AssetType.MUSIC))
			{
				// Use getMusic() for streaming instead of getSound() for full loading
				_sound = Assets.getMusic(EmbeddedSound);
			}
			else
			{
				FlxG.log.error('Could not find a Sound asset with an ID of \'$EmbeddedSound\'.');
			}
		}

		// NOTE: ID3 info (artist, title, album, etc.) cannot be extracted from
		// embedded sounds using this streaming approach
		return init(Looped, AutoDestroy, OnComplete);
	}
}
