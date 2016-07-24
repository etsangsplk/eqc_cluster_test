-module(calls_counter_eqc).
-compile([export_all]).

-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

run() ->
    eqc:quickcheck(eqc:testing_time(5, prop_correct())).

check() ->
    eqc:check(prop_correct()).

recheck() ->
    eqc:recheck(prop_correct()).

-record(model, {last_seen = 0, next = 1}).

increment_args(_Model) ->
    [].

increment() ->
    counter_eqc:increment().

increment_callouts(#model{next = Next}, _Args) ->
    ?CALLOUT(counter_eqc, increment, [], Next).

increment_post(#model{last_seen = LastSeen}, [], R) ->
    R > LastSeen. % counter_eqc may also be calling count, check strictly monotonically increasing

increment_next(Model = #model{next = Next}, V, []) ->
    Model#model{last_seen = V, next = Next + 1}.

initial_state() ->
    #model{}.

api_spec() ->
    #api_spec{modules = [#api_module{name = counter_eqc,
                                     functions = [ #api_fun{ name = increment, arity = 0, classify = counter_eqc } ]}]}.

prop_correct() ->
    ?SETUP(fun() ->
                   {ok, Pid} = counter:start_link(),
                   unlink(Pid),
                   eqc_mocking:start_mocking(api_spec()),
                   fun() -> kill_proc(Pid), eqc_mocking:stop_mocking() end
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
