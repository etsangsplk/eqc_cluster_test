%%
%% redbug:start(["users_eqc -> return", "users -> return", "orgs_eqc -> return", "orgs -> return"], [{msgs, 10000}, {print_file, "cluster_eqc.trace"}]).
%%
-module(cluster_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_cluster.hrl").

run() ->
    run(5).

run(Secs) ->
    eqc:quickcheck(eqc:testing_time(Secs, prop_cluster_correct())).

check() ->
    eqc:check(prop_cluster_correct()).

recheck() ->
    eqc:recheck(prop_cluster_correct()).

components() ->
    [orgs_eqc,
     users_eqc,
     projects_eqc,
     accounts_eqc].

api_spec() ->
    eqc_cluster:api_spec(?MODULE).

prop_cluster_correct() ->
    ?SETUP(fun() ->
                   eqc_mocking:start_mocking(api_spec()),
                   fun() -> eqc_mocking:stop_mocking() end
           end,
           ?FORALL(Cmds,commands(?MODULE),
                   begin
                       {H,S,Result} = run_commands(?MODULE,Cmds),
                       pretty_commands(?MODULE,Cmds,{H,S,Result},
                                       aggregate(command_names(Cmds), Result==ok))
                   end
                  )
          ).
