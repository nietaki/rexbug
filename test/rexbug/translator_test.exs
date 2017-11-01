defmodule Rexbug.TranslatorTest do

  @invalid_actions_error {:error, :invalid_actions}

  use ExUnit.Case
  import Rexbug.Translator
  doctest Rexbug.Translator

  describe "Translator.translate_actions/1" do
    test "returns correct error on invalid actions" do
      assert @invalid_actions_error == translate_actions(1)
      assert @invalid_actions_error == translate_actions({:foo, :bar})
    end

    test "translates empty actions to an empty charlist" do
      assert {:ok, ''} == translate_actions([])
      assert {:ok, ''} == translate_actions(nil)
      assert {:ok, ''} == translate_actions(false)
    end

    test "translates a valid set of actions to a correct charlist, including the arrow" do
      assert {:ok, ' -> return'} == translate_actions([:return])
      assert {:ok, ' -> return;stack'} == translate_actions([:return, :stack])
      assert {:ok, ' -> stack;return'} == translate_actions([:stack, :return])
    end

    test "dedupes actions" do
      assert {:ok, ' -> return'} == translate_actions([:return, :return])
      assert {:ok, ' -> return;stack'} == translate_actions([:return, :stack, :return, :stack])
    end

    test "returns an error if there's an invalid value in the actions collection" do
      assert @invalid_actions_error == translate_actions([:return, :wat])
      assert @invalid_actions_error == translate_actions([:return, "string"])
    end
  end


  describe "Translator.translate/1" do
    test "translates Foo.Bar.baz right" do
      assert {:ok, '\'Elixir.Foo.Bar\':\'abc\''} == translate("Foo.Bar.abc")
    end

    test "a simple erlang module.fun right" do
      assert {:ok, 'redbug:\'help\''} == translate(":redbug.help")
    end
  end

  describe "Translator.split_to_mfag_and_actions/1" do
    test "a full case" do
      code = "Foo.Bar.xyz(1, :foo, \"bar\")  :: return;stack "
      assert {"Foo.Bar.xyz(1, :foo, \"bar\")", "return;stack"} == split_to_mfag_and_actions(code)
    end

    test "most basic case" do
      assert {":foo", ""} == split_to_mfag_and_actions(":foo")
    end
  end

end
