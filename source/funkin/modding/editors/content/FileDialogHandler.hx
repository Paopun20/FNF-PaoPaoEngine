package funkin.modding.editors.content;

import haxe.Exception;
import sys.io.File;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.net.FileFilter;
import flixel.FlxBasic;

class FileDialogHandler extends FlxBasic
{
	var _dialog:FileDialog;

	public function new()
	{
		super();
		_newDialog();
	}

	public var onComplete:Void->Void;
	public var onCancel:Void->Void;
	public var onError:Void->Void;

	public var data:String;
	public var path:String;
	public var completed:Bool = true;

	public function save(?fileName:String = '', ?dataToSave:String = '', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);

		_dialog.onSelect.add(function(selectedPath:String) {
			this.path = selectedPath;
			CoolLog.info('Saved file to: $path');
			_finish();
		});

		_dialog.save(lime.utils.Bytes.ofString(dataToSave), null, fileName);
	}

	public function open(?defaultName:String = null, ?title:String = null, ?filter:Array<FileFilter> = null, ?onComplete:Void->Void, ?onCancel:Void->Void,
			?onError:Void->Void)
	{
		if (!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);

		_dialog.onSelect.add(function(selectedPath:String) {
			this.path = selectedPath;
			this.data = File.getContent(selectedPath);
			CoolLog.info('Loaded file from: $path');
			_finish();
		});

		var filterStr = _buildFilter(filter);
		#if mac filterStr = null; #end
		_dialog.browse(OPEN, filterStr, defaultName, title);
	}

	public function openDirectory(?title:String = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);

		_dialog.onSelect.add(function(selectedPath:String) {
			this.path = selectedPath;
			CoolLog.info('Loaded directory: $path');
			_finish();
		});

		_dialog.browse(OPEN_DIRECTORY, null, null, title);
	}

	function _finish()
	{
		this.completed = true;
		_newDialog();
		if (onComplete != null) onComplete();
	}

	function _startUp(onComplete:Void->Void, onCancel:Void->Void, onError:Void->Void)
	{
		this.onComplete = onComplete;
		this.onCancel = onCancel;
		this.onError = onError;
		this.completed = false;
		this.data = null;
		this.path = null;
	}

	// Lime FileDialog doesn't reuse cleanly after firing, so just make a fresh one
	function _newDialog()
	{
		_dialog = new FileDialog();
		_dialog.onCancel.add(function() {
			this.completed = true;
			_newDialog();
			if (onCancel != null) onCancel();
		});
	}

	function _buildFilter(?filter:Array<FileFilter>):String
	{
		if (filter == null) filter = [new FileFilter('JSON', 'json')];
		return filter.map(f -> StringTools.replace(StringTools.replace(f.extension, "*.", ""), ";", ",")).join(";");
	}

	override function destroy()
	{
		_dialog = null;
		onComplete = null;
		onCancel = null;
		onError = null;
		data = null;
		path = null;
		completed = true;
		super.destroy();
	}
}