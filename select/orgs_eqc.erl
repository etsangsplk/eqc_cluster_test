-module(orgs_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

-record(state, {ids = [], orgs = []}).

%%
%% Helpers to run
%%

run() ->
    eqc:quickcheck(eqc:testing_time(5, prop_correct())).

check() ->
    eqc:check(prop_correct()).

recheck() ->
    eqc:recheck(prop_correct()).

%%
%% Create an organization
%%

create_args(#state{ids = Ids}) ->
    [?SUCHTHAT(X, ?LET(Y, int(), 100000+Y), not lists:member(X, Ids)), utf8()].

create(Id, Name) ->
    Res = #{id => Id, name => Name},
    eqc:format("Create organization ~p\n", [Res]),
    Res.

create_next(State = #state{ids = Ids, orgs = Orgs}, Org, [Id, _Name]) ->
    State#state{ids = Ids ++ [Id], orgs = Orgs ++ [Org]}.

create_post(_State, [Id, Name], R) ->
    eqc_statem:conj([eq(maps:get(name, R), Name),
                     eq(org_id(R), Id)]).
    %% eqc_statem:conj([{name, eq(maps:get(name, R), Name)},
    %%                  {id, eq(org_id(R), Id)}]).

%%
%% Callouts from other models - select an org and tell the caller
%%
pick_org_pre(#state{orgs = Orgs}) ->
    Orgs /= [].

pick_org_callouts(#state{orgs = Orgs}, [Mod, Fun, Args]) ->
    ?MATCH_GEN(Org, elements(Orgs)),
    ?APPLY(Mod, Fun, [Org] ++ Args).

%%
%% Helpers for other models
%%
org_id(Org) ->
    maps:get(id, Org).

%%
%% Property boilerplate
%%

initial_state() ->
    #state{}.

api_spec() ->
    #api_spec{}.

prop_correct() ->
    ?SETUP(fun() ->
                   eqc_mocking:start_mocking(api_spec()),
                   fun() -> eqc_mocking:stop_mocking() end
           end,
           ?FORALL(Cmds,commands(?MODULE),
                   begin {H,S,Result} = run_commands(?MODULE,Cmds),
                         pretty_commands(?MODULE,Cmds,{H,S,Result},
                                         aggregate(command_names(Cmds), Result==ok))
                   end
                  )
          ).
