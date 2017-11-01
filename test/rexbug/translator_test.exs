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

end
