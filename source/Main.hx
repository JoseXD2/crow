package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import openfl.display.BlendMode;
import openfl.text.TextFormat;
import openfl.display.Application;
import flixel.util.FlxColor;
import flixel.FlxG;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import lime.system.System;
using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = states.InitState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	public static var framerate:Int = 60; // How many frames per second the game should run at.
	public static var path:String = System.applicationStorageDirectory;
	#if HAXEFLIXEL_LOGO
	var skipSplash:Bool = false;
	#else
	var skipSplash:Bool = true; // CRINGE! Why would you hide it????
	#end
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));

		
		addChild(new ui.FPSMem(10, 3, 0xFFFFFF));
		
	}

	public static function setFPSCap(cap:Int)
	{
		Main.framerate=cap;
		updateFramerate();
	}

	// thank u forever engine
	// https://github.com/Yoshubs/Forever-Engine/blob/master/source/Main.hx

	public static function updateFramerate(){
		if (Main.framerate > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = Main.framerate;
			FlxG.drawFramerate = Main.framerate;
		}
		else
		{
			FlxG.drawFramerate = Main.framerate;
			FlxG.updateFramerate = Main.framerate;
		}
	}

	public static function adjustFPS(num:Float):Float{
		return num * (60/Main.getFPSCap());
	}

	public static function getFPSCap():Float
	{
		return FlxG.drawFramerate;
	}
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = Main.path + "./crash/" + "FE_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/Yoshubs/Forever-Engine";

		if (!FileSystem.exists(Main.path + "./crash/"))
			FileSystem.createDirectory(Main.path + "./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		var crashDialoguePath:String = "FE-CrashDialog";

		#if windows
		crashDialoguePath += ".exe";
		#end

		if (Assets.exists("./" + crashDialoguePath))
		{
			Sys.println("Found crash dialog: " + crashDialoguePath);

			#if linux
			crashDialoguePath = "./" + crashDialoguePath;
			#end
			new Process(crashDialoguePath, [path]);
		}
		else
		{
			Sys.println("No crash dialog found! Making a simple alert instead...");
			Application.current.window.alert(errMsg, "Error!");
		}

		Sys.exit(1);
	}
}
