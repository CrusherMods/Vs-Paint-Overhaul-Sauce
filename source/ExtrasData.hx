package;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef ExtraFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

class ExtrasData {
	public static var weeksLoaded:Map<String, ExtrasData> = new Map<String, ExtrasData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';
	
	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createExtraFile():ExtraFile {
		var ExtraFile:ExtraFile = {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return ExtraFile;
	}

	// HELP: Is there any way to convert a ExtraFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(ExtraFile:ExtraFile, fileName:String) {
		songs = ExtraFile.songs;
		weekCharacters = ExtraFile.weekCharacters;
		weekBackground = ExtraFile.weekBackground;
		weekBefore = ExtraFile.weekBefore;
		storyName = ExtraFile.storyName;
		weekName = ExtraFile.weekName;
		freeplayColor = ExtraFile.freeplayColor;
		startUnlocked = ExtraFile.startUnlocked;
		hiddenUntilUnlocked = ExtraFile.hiddenUntilUnlocked;
		hideStoryMode = ExtraFile.hideStoryMode;
		hideFreeplay = ExtraFile.hideFreeplay;
		difficulties = ExtraFile.difficulties;

		this.fileName = fileName;
	}

	public static function reloadExtraFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var disabledMods:Array<String> = [];
		var modsListPath:String = 'modsList.txt';
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		if(FileSystem.exists(modsListPath))
		{
			var stuff:Array<String> = CoolUtil.coolTextFile(modsListPath);
			for (i in 0...stuff.length)
			{
				var splitName:Array<String> = stuff[i].trim().split('|');
				if(splitName[1] == '0') // Disable mod
				{
					disabledMods.push(splitName[0]);
				}
				else // Sort mod loading order based on modsList.txt file
				{
					var path = haxe.io.Path.join([Paths.mods(), splitName[0]]);
					//trace('trying to push: ' + splitName[0]);
					if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(splitName[0]) && !disabledMods.contains(splitName[0]) && !directories.contains(path + '/'))
					{
						directories.push(path + '/');
						//trace('pushed Directory: ' + splitName[0]);
					}
				}
			}
		}

		var modsDirectories:Array<String> = Paths.getModDirectories();
		for (folder in modsDirectories)
		{
			var pathThing:String = haxe.io.Path.join([Paths.mods(), folder]) + '/';
			if (!disabledMods.contains(folder) && !directories.contains(pathThing))
			{
				directories.push(pathThing);
				//trace('pushed Directory: ' + folder);
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('extras/extrasList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'extras/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:ExtraFile = getExtraFile(fileToCheck);
					if(week != null) {
						var ExtraFile:ExtrasData = new ExtrasData(week, sexList[i]);

						#if MODS_ALLOWED
						if(j >= originalLength) {
							ExtraFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}
						#end

						if(ExtraFile != null && (isStoryMode == null || (isStoryMode && !ExtraFile.hideStoryMode) || (!isStoryMode && !ExtraFile.hideFreeplay))) {
							weeksLoaded.set(sexList[i], ExtraFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'extras/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'extrasList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(sys.FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:ExtraFile = getExtraFile(path);
			if(week != null)
			{
				var ExtraFile:ExtrasData = new ExtrasData(week, weekToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					ExtraFile.folder = directory.substring(Paths.mods().length, directory.length-1);
					#end
				}
				if((PlayState.isStoryMode && !ExtraFile.hideStoryMode) || (!PlayState.isStoryMode && !ExtraFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, ExtraFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getExtraFile(path:String):ExtraFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getExtraFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():ExtrasData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:ExtrasData = null) {
		Paths.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}

	public static function loadTheFirstEnabledMod()
	{
		Paths.currentModDirectory = '';
		
		#if MODS_ALLOWED
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = CoolUtil.listFromString(File.getContent("modsList.txt"));
			var foundTheTop = false;
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1" && !foundTheTop)
				{
					foundTheTop = true;
					Paths.currentModDirectory = dat[0];
				}
			}
		}
		#end
	}
}