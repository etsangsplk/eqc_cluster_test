-module(counter_eqc).
-compile([export_all]).

-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

run() ->
    eqc:quickcheck(eqc:testing_time(5, prop_correct())).

check() ->
    eqc:check(prop_correct()).

recheck() ->
    eqc:recheck(prop_correct()).

-record(model, {next_counter = 1}).

increment_args(_Model) ->
    [].

increment() ->
    counter:increment().

increment_post(#model{next_counter = Expect}, [], R) ->
    eq(R, Expect).

increment_next(Model = #model{next_counter = Next}, _V, []) ->
    Model#model{next_counter = Next + 1}.

initial_state() ->
    #model{}.

api_spec() ->
    #api_spec{}.

prop_correct() ->
    ?SETUP(fun() ->
                   {ok, Pid} = counter:start_link(),
                   unlink(Pid),
                   fun() -> kill_proc(Pid) end
           end,
           ?FORALL(Cmds,commands(?MODULE),
                   begin
                       counter:reset(),
                       {H,S,Result} = run_commands(?MODULE,Cmds),
                       pretty_commands(?MODULE,Cmds,{H,S,Result},
                                       aggregate(command_names(Cmds), Result==ok))
                   end
                  )
          ).

kill_proc(undefined) ->
    ok;
kill_proc(Name) when is_atom(Name) ->
    kill_proc(whereis(Name));
kill_proc(Pid) when is_pid(Pid) ->
    catch exit(Pid, kill),
    Ref = monitor(process, Pid),
    receive
        {'DOWN', Ref, process, _, _} ->
            ok
    after
        5000 ->
            error(no_death)
    end.
