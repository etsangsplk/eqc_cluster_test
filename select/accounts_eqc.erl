-module(accounts_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

-record(state, {org1, org2}).

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
%% Transfer credits between organizations
%%
transfer_pre(#state{org1 = Org1, org2 = Org2}) ->
    Org1 /= undefined andalso Org2 /= undefined.

transfer_args(#state{org1 = Org1, org2 = Org2}) ->
    [Org1, Org2, nat()].

transfer(Org1, Org2, Amount) ->
    OrgId1 = orgs_eqc:org_id(Org1),
    OrgId2 = orgs_eqc:org_id(Org2),
    eqc:format("Transfering ~p from org_id ~p to ~p\n", [Amount, OrgId1, OrgId2]),
    ok.

transfer_next(State, _V, _A) ->
    State#state{org1 = undefined, org2 = undefined}.

%%
%% Communicate with orgs model to select two orgs it has created
%%

pick_orgs_pre(#state{org1 = Org1, org2 = Org2}) ->
    Org1 == undefined andalso Org2 == undefined.

pick_orgs_args(_State) ->
    [].

pick_orgs() ->
    ok.

pick_orgs_callouts(_State, _Args) ->
    ?APPLY(orgs_eqc, pick_org, [?MODULE, picked_org, [org1]]),
    ?APPLY(orgs_eqc, pick_org, [?MODULE, picked_org, [org2]]).

picked_org_next(State, _V, [Org, org1]) ->
    State#state{org1 = Org};
picked_org_next(State, _V, [Org, org2]) ->
    State#state{org2 = Org}.


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
