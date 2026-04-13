package funkin.backend.filesystem;

import haxe.Exception;
import sys.io.File;
import lime.ui.FileDialog as LimeFileDialog;
import lime.utils.Bytes;
import openfl.net.FileFilter;
import flixel.FlxBasic;
import flixel.util.FlxSignal;

/**
 * Wraps Lime's `FileDialog` with a simpler, stateful API.
 *
 * Only one operation may be in progress at a time. Callers can `.add()`
 * listeners to `onComplete` and `onCancel` before calling `save()`, `open()`,
 * or `openDirectory()`, or pass them directly as arguments.
 *
 * Example:
 * ```haxe
 * var dialog = new FileDialog();
 * dialog.onComplete.add(() -> trace(dialog.fileContent));
 * dialog.onCancel.add(() -> trace("Canceled"));
 * dialog.open();
 * ```
 */
class FileDialog extends FlxBasic
{
	/** Dispatched when the active operation completes successfully. */
	public var onComplete:FlxSignal = new FlxSignal();

	/** Dispatched when the user dismisses the dialog without selecting anything. */
	public var onCancel:FlxSignal = new FlxSignal();

	/** Dispatched when an error occurs during a dialog operation. */
	public var onError:FlxSignal = new FlxSignal();

	/** `true` when no file-dialog operation is in progress. */
	public var isIdle:Bool = true;

	/** @deprecated Use `isIdle` instead. */
	public var completed(get, never):Bool;
	inline function get_completed():Bool return isIdle;

	/** Raw text content of the most recently opened file. `null` until a file is opened. */
	public var fileContent:String;

	/** @deprecated Use `fileContent` instead. */
	public var data(get, never):String;
	inline function get_data():String return fileContent;

	/** Filesystem path returned by the most recent dialog operation. */
	public var filePath:String;

	/** @deprecated Use `filePath` instead. */
	public var path(get, never):String;
	inline function get_path():String return filePath;

	var _dialog:LimeFileDialog;

	public function new()
	{
		super();
		_resetDialog();
	}

	/**
	 * Opens a save-file dialog and writes `dataToSave` to the path the user picks.
	 * After saving, `filePath` holds the saved location.
	 *
	 * @param fileName    Suggested filename shown in the dialog.
	 * @param dataToSave  Text content to write to the file.
	 * @param onComplete  One-shot listener added to `this.onComplete` for this call.
	 * @param onCancel    One-shot listener added to `this.onCancel` for this call.
	 */
	public function save(?fileName:String = '', ?dataToSave:String = '', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!isIdle)
			throw new Exception('A file-dialog operation is already in progress.');

		_beginOperation(onComplete, onCancel, onError);

		_dialog.onSave.add(function(savedPath:String)
		{
			this.filePath = savedPath;
			CoolLog.info('Saved file to: $filePath');
			_completeOperation();
		});

		_dialog.save(Bytes.ofString(dataToSave), null, fileName);
	}

	/**
	 * Opens an open-file dialog and loads the selected file's text content.
	 * After loading, `fileContent` holds the text and `filePath` holds the path.
	 * On macOS, the extension filter is ignored (Lime limitation).
	 *
	 * @param defaultPath  Starting directory or suggested filename for the dialog.
	 * @param title        Dialog window title.
	 * @param filter       Extensions to show. Defaults to JSON only.
	 * @param onComplete   One-shot listener added to `this.onComplete` for this call.
	 * @param onCancel     One-shot listener added to `this.onCancel` for this call.
	 */
	public function open(?defaultPath:String = null, ?title:String = null, ?filter:Array<FileFilter> = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!isIdle)
			throw new Exception('A file-dialog operation is already in progress.');

		_beginOperation(onComplete, onCancel, onError);

		_dialog.onSelect.add(function(selectedPath:String)
		{
			this.filePath = selectedPath;
			this.fileContent = File.getContent(selectedPath);
			CoolLog.info('Loaded file from: $filePath');
			_completeOperation();
		});

		// Lime's filter string uses semicolon-separated wildcards, e.g. "*.json;*.txt".
		// macOS does not support extension filtering, so we pass null there.
		var filterStr = #if mac null #else _buildFilterString(filter) #end;
		_dialog.browse(OPEN, filterStr, defaultPath, title);
	}

	/**
	 * Opens a directory-picker dialog.
	 * After selection, `filePath` holds the chosen directory path.
	 *
	 * @param title       Dialog window title.
	 * @param onComplete  One-shot listener added to `this.onComplete` for this call.
	 * @param onCancel    One-shot listener added to `this.onCancel` for this call.
	 */
	public function openDirectory(?title:String = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!isIdle)
			throw new Exception('A file-dialog operation is already in progress.');

		_beginOperation(onComplete, onCancel, onError);

		_dialog.onSelect.add(function(selectedPath:String)
		{
			this.filePath = selectedPath;
			CoolLog.info('Selected directory: $filePath');
			_completeOperation();
		});

		_dialog.browse(OPEN_DIRECTORY, null, null, title);
	}

	/**
	 * Stores one-shot callbacks as signal listeners (if provided), clears results
	 * from any previous operation, and marks the handler as busy.
	 */
	function _beginOperation(onComplete:Void->Void, onCancel:Void->Void, onError:Void->Void)
	{
		if (onComplete != null)
			this.onComplete.addOnce(onComplete);
		if (onCancel != null)
			this.onCancel.addOnce(onCancel);
		if (onError != null)
			this.onError.addOnce(onError);

		this.isIdle = false;
		this.fileContent = null;
		this.filePath = null;
	}

	/** Marks the operation as done and dispatches `onComplete`. */
	function _completeOperation()
	{
		isIdle = true;
		// Lime's FileDialog cannot be cleanly reused after firing, so replace it.
		_resetDialog();
		onComplete.dispatch();
	}

	/**
	 * Allocates a fresh `LimeFileDialog` and wires up its cancel event.
	 * Called on construction and after every operation (success or cancel),
	 * because Lime does not reuse dialogs cleanly after they fire.
	 */
	function _resetDialog()
	{
		_dialog = new LimeFileDialog();
		_dialog.onCancel.add(function()
		{
			isIdle = true;
			_resetDialog();
			onCancel.dispatch();
		});
	}

	/**
	 * Converts an array of `FileFilter`s into the semicolon-separated wildcard
	 * string that Lime expects (e.g. `"*.json;*.txt"`).
	 *
	 * OpenFL's `FileFilter.extension` is already in `"*.ext"` form, so only
	 * joining is needed. Defaults to JSON if no filter is supplied.
	 */
	function _buildFilterString(?filter:Array<FileFilter>):String
	{
		if (filter == null)
			// Bare "json" does not match — the wildcard prefix is required.
			filter = [new FileFilter('Any files', '*.*')];
		return filter.map(f -> f.extension).join(';');
	}

	override function destroy()
	{
		_dialog = null;
		onComplete.destroy();
		onCancel.destroy();
		onError.destroy();
		fileContent = null;
		filePath = null;
		isIdle = true;
		super.destroy();
	}
}
