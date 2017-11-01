defmodule Rexbug.TranslatorTest do

  use ExUnit.Case
  import Rexbug.Translator
  doctest Rexbug.Translator


  describe "Translator.translate/1" do
    test "translates Foo.Bar.baz right" do
      assert {:ok, '\'Elixir.Foo.Bar\':\'abc\''} == translate("Foo.Bar.abc")
    end

    test "a simple erlang module.fun right" do
      assert {:ok, 'redbug:\'help\''} == translate(":redbug.help")
    end

    test "just an erlang module" do
      assert {:ok, 'cowboy'} == translate(":cowboy")
    end

    test "just and elixir module" do
      assert {:ok, '\'Elixir.Foo.Bar\''} == translate("Foo.Bar")
    end

    test "actions" do
      assert {:ok, 'cowboy -> return'} == translate(":cowboy :: return")
      assert {:ok, 'cowboy:\'fun\' -> return;stack'} == translate(":cowboy.fun :: return;stack")
    end
  end



  describe "Translator.split_to_mfag_and_actions!/1" do
    test "a full case" do
      code = "Foo.Bar.xyz(1, :foo, \"bar\")  :: return;stack "
      assert {"Foo.Bar.xyz(1, :foo, \"bar\")", "return;stack"} == split_to_mfag_and_actions!(code)
    end

    test "most basic case" do
      assert {":foo", ""} == split_to_mfag_and_actions!(":foo")
    end
  end

end
