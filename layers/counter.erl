-module(counter).
-compile([export_all]).

-record(state, {counter = 0}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

increment() ->
    gen_server:call(?MODULE, increment).

reset() ->
    gen_server:call(?MODULE, reset).


init([]) ->
    {ok, #state{}}.

handle_call(increment, _From, State = #state{counter = Counter}) ->
    Result = Counter + 1,
    {reply, Result, State#state{counter = Result}};
handle_call(reset, _From, _State) ->
    {reply, ok, #state{}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
