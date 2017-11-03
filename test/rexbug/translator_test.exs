defmodule Rexbug.TranslatorTest do

  use ExUnit.Case
  import Rexbug.Translator
  doctest Rexbug.Translator


  describe "Translator.translate/1" do
    test "translates Foo.Bar.baz right" do
      assert {:ok, '\'Elixir.Foo.Bar\':\'abc\'()'} == translate("Foo.Bar.abc")
      assert {:ok, '\'Elixir.Foo.Bar\':\'abc\'()'} == translate("Foo.Bar.abc()")
    end

    test "a simple erlang module.fun right" do
      assert {:ok, 'redbug:\'help\'()'} == translate(":redbug.help()")
      assert {:ok, 'redbug:\'help\'()'} == translate(":redbug.help")
    end

    test "just an erlang module" do
      assert {:ok, 'cowboy'} == translate(":cowboy")
    end

    test "just an elixir module" do
      assert {:ok, '\'Elixir.Foo.Bar\''} == translate("Foo.Bar")
    end

    test "actions" do
      assert {:ok, 'cowboy -> return'} == translate(":cowboy :: return")
      assert {:ok, 'cowboy:\'fun\'() -> return;stack'} == translate(":cowboy.fun() :: return;stack")
    end

    test "parsing rubbish" do
      assert {:error, _} = translate("ldkjf 'dkf ls;lf sjdkf 4994{}")
    end

    test "literal arity" do
      assert {:ok, 'cowboy:\'do_sth\'/5'} == translate(":cowboy.do_sth/5")
    end

    test "whatever arity" do
      assert {:ok, 'cowboy:\'do_sth\''} == translate(":cowboy.do_sth/x")
      assert {:ok, 'cowboy:\'do_sth\''} == translate(":cowboy.do_sth/really_whatever")
    end


    test "invalid arg" do
      assert {:error, _} = translate(":cowboy.do_sth(2 + 3)")
    end
  end

  describe "Translator.translate_options/1" do
    test "returns empty list for an empty list" do
      assert {:ok, []} == translate_options([])
    end

    test "passes through irrelevant options" do
      assert {:ok, [abc: :def, foo: :bar]} == translate_options([abc: :def, foo: :bar])
    end

    test "returns an error for invalid options" do
      assert {:error, :invalid_options} == translate_options(:foo)
      assert {:error, :invalid_options} == translate_options([:foo])
    end

    test "translates the file options right" do
      assert {:ok, [file: 'a.txt', print_file: 'b.txt']} == translate_options(file: "a.txt", print_file: "b.txt")
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


  # defp assert_options(translate)

end
