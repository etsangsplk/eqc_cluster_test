-module(cluster_counter_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_cluster.hrl").

run() ->
    eqc:quickcheck(prop_cluster_correct()).

check() ->
    eqc:check(prop_cluster_correct()).

recheck() ->
    eqc:recheck(prop_cluster_correct()).

components() ->
    [counter_eqc, calls_counter_eqc].

api_spec() ->
    eqc_cluster:api_spec(?MODULE).

prop_cluster_correct() ->
    ?SETUP(fun() ->
                   {ok, Pid} = counter:start_link(),
                   unlink(Pid),
                   eqc_mocking:start_mocking(api_spec(), components()),
                   fun() ->
                           counter_eqc:kill_proc(Pid),
                           eqc_mocking:stop_mocking()
                   end
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
