-module(init).
-export([start/0]).
-import(erlang, [display/1]).

start() ->
  display(false or false),
  display(false or true).
