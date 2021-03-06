package com.qifun.util.locale;

import haxe.macro.*;
using com.qifun.util.locale.Translator;

class TranslatorTest extends haxe.unit.TestCase {

	macro static function setupLocale():Expr
	{
		Compiler.define("locale", "zh_CN.UTF-8");
		return macro null;
	}

	macro static function setupTranslation():Expr
	{
		Translator.addTranslationFile("zh_CN.UTF-8", "com/qifun/util/locale/test-translation.zh_CN.UTF-8.json");
		return macro null;
	}

	#if !macro
	public function test()
	{
		assertEquals({ var who = "World".translate(); Translator.translate('Hello, $who!'); }, "Hello, World!");
		setupTranslation();
		assertEquals({ var who = "World".translate(); Translator.translate('Hello, $who!'); }, "Hello, World!");
		#if run_time_translation
			Translator.runTimeLocale = "zh_CN.UTF-8";
			assertEquals({ var who = "World".translate(); Translator.translate('Hello, $who!'); }, "世界，你好！");
			Translator.runTimeLocale = null;
			assertEquals({ var who = "World".translate(); Translator.translate('Hello, $who!'); }, "Hello, World!");
		#else
			setupLocale();
			assertEquals({ var who = "World".translate(); Translator.translate('Hello, $who!'); }, "世界，你好！");
		#end
	}
	#end

}
