package funkin.objects;

import animate.internal.RenderTexture;
import flash.geom.ColorTransform;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import funkin.graphics.framebuffer.FixedBitmapData;
import funkin.shaders.CustomShader;
import openfl.display.OpenGLRenderer;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A FlxCamera with additional powerful features:
 * - Added the ability to grab the camera screen as a `BitmapData` and use it as a texture.
 * - Added support for the following blend modes for a sprite through shaders:
 *   - DARKEN
 *   - HARDLIGHT
 *   - LIGHTEN
 *   - OVERLAY
 *   - DIFFERENCE
 * - Elapsed-based `followLerp` to prevent camera snapping at higher framerates
 */
@:nullSafety
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
class PaoPaoCamera extends FlxCamera {
	/**
	 * Whether or not the device supports the OpenGL extension `KHR_blend_equation_advanced`.
	 * If `false`, a shader implementation will be used to render certain blend modes.
	 */
	public static var hasKhronosExtension(get, never):Bool;

	static inline function get_hasKhronosExtension():Bool {
		return true;
	}

	/**
	 * A list of blend modes that require the OpenGL extension `KHR_blend_equation_advanced`.
	 *
	 * NOTE:
	 *  - `LIGHTEN` is supported natively on desktop, but not other platforms.
	 *  - While `DARKEN` is supported natively on desktop, it causes issues with transparency.
	 */
	static final KHR_BLEND_MODES:Array<BlendMode> = [
		DARKEN,
		HARDLIGHT,
		#if !desktop LIGHTEN, #end
		OVERLAY,
		DIFFERENCE,
		// COLORDODGE,
		// COLORBURN,
		// SOFTLIGHT,
		// EXCLUSION,
		// HUE,
		// SATURATION,
		// COLOR,
		// LUMINOSITY
	];

	/**
	 * A list of blend modes that require the shader no matter what.
	 * This is due to these blend modes not being supported on any platform.
	 */
	static final SHADER_REQUIRED_BLEND_MODES:Array<BlendMode> = [INVERT];

	/**
	 * The ID of this camera, used for debugging.
	 */
	public var id:String;

	/**
	 * If `true` the blend shader will try to blend with the cameras underneath it.
	 * This is useful for, say, making a strumline note have a shader-only blend mode like `INVERT`.
	 *
	 * Defaults to `false` since this can impact performance.
	 */
	public var crossCameraBlending:Bool;

	var _blendShader:CustomShader;
	var _backgroundFrame:FlxFrame;

	var _blendRenderTexture:RenderTexture;
	var _backgroundRenderTexture:RenderTexture;

	var _cameraTexture:FixedBitmapData;
	var _cameraMatrix:FlxMatrix;

	@:nullSafety(Off)
	public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0) {
		super(x, y, width, height, zoom);

		this.id = id;

		_backgroundFrame = new FlxFrame(new FlxGraphic('', null));
		_backgroundFrame.frame = new FlxRect();

		_blendShader = new CustomShader("customBlend");

		_backgroundRenderTexture = new RenderTexture(this.width, this.height);
		_blendRenderTexture = new RenderTexture(this.width, this.height);

		_cameraMatrix = new FlxMatrix();
		_cameraTexture = FixedBitmapData.create(this.width, this.height);

		crossCameraBlending = false;
	}

	/**
	 * Overrides the default `update` to drive camera following via `updateFollowDelta`
	 * instead of FlxCamera's built-in lerp, preventing snapping at high framerates.
	 */
	override public function update(elapsed:Float):Void {
		if (target != null) {
			updateFollowDelta(elapsed);
		}

		updateScroll();
		updateFlash(elapsed);
		updateFade(elapsed);

		flashSprite.filters = (filtersEnabled && filters != null) ? filters : [];

		updateFlashSpritePosition();
		updateShake(elapsed);
	}

	/**
	 * Replicates FlxCamera's deadzone / lead logic, then applies a framerate-independent
	 * exponential lerp using `elapsed` rather than a fixed per-frame multiplier.
	 *
	 * @param elapsed  Time in seconds since the last frame.
	 */
	public function updateFollowDelta(elapsed:Float = 0):Void {
		if (deadzone == null) {
			target.getMidpoint(_point);
			_point.add(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		} else {
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN) {
				if (targetX >= viewRight) {
					_scrollTarget.x += viewWidth;
				} else if (targetX + target.width < viewLeft) {
					_scrollTarget.x -= viewWidth;
				}

				if (targetY >= viewBottom) {
					_scrollTarget.y += viewHeight;
				} else if (targetY + target.height < viewTop) {
					_scrollTarget.y -= viewHeight;
				}

				// Without this we see weird behavior when switching to SCREEN_BY_SCREEN
				// at arbitrary scroll positions.
				bindScrollPos(_scrollTarget);
			} else {
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
					_scrollTarget.x = edge;

				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
					_scrollTarget.x = edge;

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
					_scrollTarget.y = edge;

				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
					_scrollTarget.y = edge;
			}

			if ((target is FlxSprite)) {
				if (_lastTargetPosition == null) {
					_lastTargetPosition = FlxPoint.get(target.x, target.y);
				}
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}
		}

		// Framerate-independent exponential lerp.
		// At 60 fps this converges to roughly the same result as the old
		// per-frame `scroll += delta * followLerp` approach.
		var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1 / 60));
		scroll.x += (_scrollTarget.x - scroll.x) * mult;
		scroll.y += (_scrollTarget.y - scroll.y) * mult;
	}

	override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
			?shader:FlxShader):Void {
		var shouldUseShader:Bool = (!hasKhronosExtension && KHR_BLEND_MODES.contains(blend))
			|| SHADER_REQUIRED_BLEND_MODES.contains(blend);

		if (shouldUseShader) {
			if (crossCameraBlending) {
				var camerasUnderneath:Array<FlxCamera> = FlxG.cameras.list.copy();

				for (i in camerasUnderneath.length - 1...-1) {
					if (i > FlxG.cameras.list.indexOf(this)) {
						camerasUnderneath.remove(camerasUnderneath[i]);
					}
				}

				_cameraTexture.drawCameraScreens(camerasUnderneath);

				for (camera in camerasUnderneath) {
					camera.clearDrawStack();
					camera.canvas.graphics.clear();
				}
			} else {
				_cameraTexture.drawCameraScreen(this);
			}

			_backgroundFrame.frame.set(0, 0, this.width, this.height);

			this.clearDrawStack();
			this.canvas.graphics.clear();

			_blendRenderTexture.init(this.width, this.height);
			_blendRenderTexture.drawToCamera((camera, frameMatrix) -> {
				var pivotX:Float = width / 2;
				var pivotY:Float = height / 2;

				frameMatrix.copyFrom(matrix);
				frameMatrix.translate(-pivotX, -pivotY);
				frameMatrix.scale(this.scaleX, this.scaleY);
				frameMatrix.translate(pivotX, pivotY);
				camera.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
			});
			_blendRenderTexture.render();

			// _blendShader.sourceSwag = _blendRenderTexture.graphic.bitmap;
			// _blendShader.backgroundSwag = _cameraTexture;
			// _blendShader.blendSwag = blend;
			// _blendShader.updateViewInfo(width, height, this);
			_blendShader.hset("sourceSwag", _blendRenderTexture.graphic.bitmap);
			_blendShader.hset("blendSwag", blend);
			_blendShader.hset("uScreenResolution", [width, height]);
			_blendShader.hset("uFrameBounds", [this.viewLeft, this.viewTop, this.viewRight, this.viewBottom]);

			_backgroundFrame.parent.bitmap = _blendRenderTexture.graphic.bitmap;

			var clampedScale:Float = Math.max(1, Lib.current.stage.window.scale);

			_backgroundRenderTexture.init(Std.int(this.width * clampedScale), Std.int(this.height * clampedScale));
			_backgroundRenderTexture.drawToCamera((camera, matrix) -> {
				camera.zoom = this.zoom;
				matrix.scale(clampedScale, clampedScale);
				camera.drawPixels(_backgroundFrame, null, matrix, canvas.transform.colorTransform, null, false, _blendShader);
			});

			_backgroundRenderTexture.render();

			_cameraMatrix.identity();
			_cameraMatrix.scale(1 / (this.scaleX * clampedScale), 1 / (this.scaleY * clampedScale));
			_cameraMatrix.translate(((width - width / this.scaleX) * 0.5), ((height - height / this.scaleY) * 0.5));

			super.drawPixels(_backgroundRenderTexture.graphic.imageFrame.frame, null, _cameraMatrix, null, null, smoothing, null);
		} else {
			super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
		}
	}

	override function startQuadBatch(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, ?blend:BlendMode, smooth:Bool = false,
			?shader:FlxShader):FlxDrawQuadsItem {
		if (hasKhronosExtension && KHR_BLEND_MODES.contains(blend)) {
			var itemToReturn = null;

			if (FlxCamera._storageTilesHead != null) {
				itemToReturn = FlxCamera._storageTilesHead;
				var newHead = FlxCamera._storageTilesHead.nextTyped;
				itemToReturn.reset();
				FlxCamera._storageTilesHead = newHead;
			} else {
				itemToReturn = new FlxDrawQuadsItem();
			}

			if (graphic.isDestroyed)
				throw 'Cannot queue ${graphic.key}. This sprite was destroyed.';

			itemToReturn.graphics = graphic;
			itemToReturn.antialiasing = smooth;
			itemToReturn.colored = colored;
			itemToReturn.hasColorOffsets = hasColorOffsets;
			itemToReturn.blend = blend;
			@:nullSafety(Off)
			itemToReturn.shader = shader;

			itemToReturn.nextTyped = _headTiles;
			_headTiles = itemToReturn;

			if (_headOfDrawStack == null)
				_headOfDrawStack = itemToReturn;
			if (_currentDrawItem != null)
				_currentDrawItem.next = itemToReturn;

			_currentDrawItem = itemToReturn;

			return itemToReturn;
		}

		return super.startQuadBatch(graphic, colored, hasColorOffsets, blend, smooth, shader);
	}

	override function startTrianglesBatch(graphic:FlxGraphic, smoothing:Bool = false, isColored:Bool = false, ?blend:BlendMode, ?hasColorOffsets:Bool,
			?shader:FlxShader):FlxDrawTrianglesItem {
		if (hasKhronosExtension && KHR_BLEND_MODES.contains(blend))
			return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader);

		return super.startTrianglesBatch(graphic, smoothing, isColored, blend, hasColorOffsets, shader);
	}

	override function destroy():Void {
		super.destroy();

		_blendRenderTexture.destroy();
		_backgroundRenderTexture.destroy();

		_cameraTexture.dispose();
	}
}
