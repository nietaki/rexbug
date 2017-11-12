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
      assert {:ok, '\'redbug\':\'help\'()'} == translate(":redbug.help()")
      assert {:ok, '\'redbug\':\'help\'()'} == translate(":redbug.help")
    end

    test "errors out in situations when fragments are duplicated (?)" do
      assert {:error, {:invalid_module, _}} = translate(":redbug.one.two()")
      assert {:error, _} = translate(":redbug.one(:foo)(:bar)")
    end

    test "just an erlang module" do
      assert {:ok, '\'cowboy\''} == translate(":cowboy")
    end

    test "just an elixir module" do
      assert {:ok, '\'Elixir.Foo.Bar\''} == translate("Foo.Bar")
    end

    test "actions" do
      assert {:ok, '\'cowboy\' -> return'} == translate(":cowboy :: return")
      assert {:ok, '\'cowboy\':\'fun\'() -> return;stack'} == translate(":cowboy.fun() :: return;stack")
    end

    test "parsing rubbish" do
      assert {:error, _} = translate("ldkjf 'dkf ls;lf sjdkf 4994{}")
    end

    test "literal arity" do
      assert {:ok, '\'cowboy\':\'do_sth\'/5'} == translate(":cowboy.do_sth/5")
    end

    test "whatever arity" do
      assert {:ok, '\'cowboy\':\'do_sth\''} == translate(":cowboy.do_sth/x")
      assert {:ok, '\'cowboy\':\'do_sth\''} == translate(":cowboy.do_sth/really_whatever")
    end

    test "invalid arity" do
      assert {:error, _} = translate(":cowboy.do_sth/(1 + 1)")
    end

    test "invalid arg" do
      assert {:error, _} = translate(":cowboy.do_sth(2 + 3)")
    end
  end

  describe "Translator.translate/1 translating args" do
    test "atoms" do
      assert_args('\'foo\'', ":foo")
      assert_args('\'foo\', \'bar baz\'', ":foo, :\"bar baz\"")
    end

    test "number literals" do
      assert_args('-5, 3.14', "-5, 3.14")
    end

    test "booleans" do
      assert_args('true, false', "true, false")
    end

    test "nil" do
      assert_args('nil', "nil")
    end

    test "variables" do
      assert_args('Foo, _, _els', "foo, _, _els")
    end

    test "lists" do
      assert_args('[1, X], 3', "[1, x], 3")
    end

    test "binaries" do
      assert_args('<<"foo">>', "\"foo\"")
      assert_args('<<102, 111, 111, 0>>', "\"foo\\0\"")
    end

    test "tuples" do
      assert_args('{}', "{}")
      assert_args('{A, B}', "{a, b}")
      assert_args('{_, X, 1}', "{_, x, 1}")
    end

    test "invalid argument in a list" do
      assert_args_error("[3, -a]")
      assert_args_error("[3, -:foo.bar()]")
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


  defp assert_args(expected, input) do
    input = ":a.b(#{input}, 0)"
    assert {:ok, '\'a\':\'b\'(' ++ expected ++ ', 0)'} == translate(input)
  end


  defp assert_args_error(input) do
    input = ":a.b(#{input}, 0)"
    assert {:error, _} = translate(input)
  end


  test "author's assumptions" do
    assert {:{}, _line, []} = Code.string_to_quoted!("{}")
    assert {:{}, _line, [1]} = Code.string_to_quoted!("{1}")
    assert {1, 2} = Code.string_to_quoted!("{1, 2}")
    assert {:{}, _line, [1, 2, 3]} = Code.string_to_quoted!("{1, 2, 3}")
    assert {:{}, _line, [1, 2, 3, 4]} = Code.string_to_quoted!("{1, 2, 3, 4}")
    assert {:{}, _line, [1, 2, 3, 4, 5]} = Code.string_to_quoted!("{1, 2, 3, 4, 5}")
    assert {:{}, _line, [1, 2, 3, 4, 5, 6]} = Code.string_to_quoted!("{1, 2, 3, 4, 5, 6}")
  end

end
