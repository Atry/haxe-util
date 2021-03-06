package com.qifun.util;
import com.qifun.util.locale.TranslatorTest;
import haxe.unit.TestRunner;

class Main
{

  static function testAll()
  {
    var runner = new TestRunner();
    runner.add(new EqualsAndHashCodeTest());
    runner.add(new TranslatorTest());
    var isSuccess = runner.run();
    if (!isSuccess)
    {
      throw runner.result;
    }
  }

  public static function main()
  {
    // 使用Timer以绕开在main中遇到异常时FlashDevelop调试器无法退出的Bug
    #if flash9
      haxe.Timer.delay(testAll, 0);
    #else
      testAll();
    #end
  }

}
