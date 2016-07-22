-module(users_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

-record(state, {org = undefined, ids = [], users = []}).

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
%% Create a user record (if an Org has been selected)
%%
create_pre(#state{org = Org}) ->
    Org /= undefined.

create_args(#state{org = Org, ids = Ids}) ->
    [Org, ?SUCHTHAT(X, int(), not lists:member(X, Ids))].

create(Org, Id) ->
    OrgId = orgs_eqc:org_id(Org),
    eqc:format("Create user org_id=~p id=~p\n", [OrgId, Id]),
    #{id => Id, org_id => OrgId}.

create_next(State = #state{ids = Ids, users = Users}, User, [_Org, Id]) ->
    State#state{org = undefined, ids = Ids ++ [Id], users = Users ++ [User]}.

%%
%% Communicate with orgs model to select an org is has generated
%%
pick_org_pre(#state{org = Org}) ->
    Org == undefined.

pick_org_args(_State) ->
    [].

pick_org() ->
    ok.

pick_org_callouts(_State, _Args) ->
    ?APPLY(orgs_eqc, pick_org, [?MODULE, picked_org, []]).

picked_org_next(State, _V, [Org]) ->
    State#state{org = Org}.

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
                                         collect(length(Cmds),
                                         aggregate(command_names(Cmds),
                                                   Result==ok)))
                   end
                  )
          ).
