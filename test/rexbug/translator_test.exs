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

    test "both arity and function args provided" do
      assert {:error, _} = translate(":cowboy.foo(1, 2)/3")
    end

    test "arity without a function" do
      assert {:error, _} = translate(":cowboy/3")
    end

    test "args without a function" do
      assert {:error, _} = translate(":cowboy(:wat)")
    end

    test "invalid arg" do
      assert {:error, _} = translate(":cowboy.do_sth(2 + 3)")
    end

    test "errors out on really unexpected input" do
      assert {:error, :invalid_trace_pattern_type} = translate(:wat)
      assert {:error, :invalid_trace_pattern_type} = translate(%{})
      assert {:error, :invalid_trace_pattern_type} = translate({:foo, "bar"})
    end

    test "translates send and receive correctly" do
      assert {:ok, :send} = translate(:send)
      assert {:ok, :send} = translate("send")
      assert {:ok, :receive} = translate(:receive)
      assert {:ok, :receive} = translate("receive")
    end

    test "translates multiple trace patterns correctly" do
      assert {:ok, [:send, '\'ets\'']} = translate([:send, ":ets"])
      assert {:error, :invalid_trace_pattern_type} = translate([:send, ":ets", :wat])
    end
  end

  describe "Translator.translate/1 translating args" do
    test "atoms" do
      assert_args('\'foo\'', ":foo")
      assert_args('\'foo\', \'bar baz\'', ":foo, :\"bar baz\"")
    end

    test "integer literals" do
      assert_args('-5, 255', "-5, 0xFF")
    end

    test "floats aren't handled" do
      assert_args_error("3.14159")
    end

    test "booleans" do
      assert_args('true, false', "true, false")
    end

    test "strings" do
      assert_args('<<"wat">>', "\"wat\"")
      assert_args('<<119, 97, 116, 0>>', "\"wat\0\"")
    end

    test "binaries" do
      assert_args('<<>>', "<<>>")
      assert_args('<<0>>', "<<0>>")
      assert_args('<<119, 97, 116>>', "<<\"wat\">>")
      assert_args('<<1, 119, 97, 116, 0>>', "<<1, \"wat\", 0>>")
      assert_args('<<119, 97, 116, 0>>', "<<\"wat\0\">>")
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


  describe "Translator.translate/1 translating guards" do
    test "a simple is_integer()" do
      res = translate(":erlang.term_to_binary(x) when is_integer(x)")
      assert {:ok, '\'erlang\':\'term_to_binary\'(X) when is_integer(X)'} == res
    end

    test "a simple is_integer() with a helper function" do
      assert_guards('is_integer(X)', "is_integer(x)")
    end

    test "a simple guard negation is_integer() with a helper function" do
      assert_guards('not is_integer(X)', "not is_integer(x)")
    end


    test "alternative of two guards" do
      assert_guards('(is_integer(X) orelse is_float(X))', "is_integer(x) or is_float(x)")
    end

    test "comparison in guards" do
      assert_guards('X =< Y', "x <= y")
    end

    test "complex case" do
      assert_guards('(X =< Y andalso not is_float(X))', "x <= y and not is_float(x)")
    end

    test "another complex case" do
      assert_guards('map_size(X) < 1', "map_size(x) < 1")
    end

    test "invalid guard argument" do
      assert_guards_error("is_integer(x + y)")
    end

    test "invalid guard function" do
      assert_guards_error("not_a_guard_function(x)")
    end

    test "invalid argument for in-guard comparison" do
      assert_guards_error("foo(x) < y")
      assert_guards_error("x >= bar(y)")
    end

    test "invalid guard in multiple guards" do
      assert_guards_error("foo(x) and is_integer(y)")
      assert_guards_error("is_binary(x) and bar(y)")
    end

    test "operator precedence" do
      assert_guards('((is_nil(X) andalso is_nil(Y)) orelse is_nil(Z))', "is_nil(x) and is_nil(y) or is_nil(z)")
      assert_guards('(is_nil(X) orelse (is_nil(Y) andalso is_nil(Z)))', "is_nil(x) or is_nil(y) and is_nil(z)")
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


  defp assert_guards(expected, input) do
    input = ":a.b(x, y, z) when #{input}"
    assert {:ok, '\'a\':\'b\'(X, Y, Z) when ' ++ expected} == translate(input)
  end


  defp assert_guards_error(input) do
    input = ":a.b(x, y, z) when #{input}"
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
