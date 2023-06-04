-module(erlang_ffi).
-export([create_signal/1, read_signal/1, update_signal/2, create_observer/2]).

% Runs a signal process
signal_loop(State) ->
    receive
        % Register a new observer
        {register, Observer} -> 
            % Respond with the value
            Observer ! {value, self(), State},
            % Record the observer and monitor it
            put(Observer, observer),
            erlang:monitor(process, Observer),
            % Continue
            signal_loop(State);
        % Update the signal state
        {update, Fun} -> 
            % Calculate the new state
            NewState = Fun(State),
            % Notify the current observers
            Observers = get_keys(observer),
            lists:foreach(fun (Observer) -> Observer ! {updated, self(), NewState} end, Observers),
            % Continue with the new state
            signal_loop(NewState);
        % Remove observers when they go down
        {'DOWN', _, process, Observer, _} ->
            erase(Observer),
            signal_loop(State)
    end.

% Creates a signal process
create_signal(Value) ->
    spawn(fun () -> signal_loop(Value) end).

% Fetchs the value from a signal and subscribes to updates
register_observer(Signal) ->
    % Send the register message
    Signal ! {register, self()},
    % Expect a response containing the value
    receive
        {value, Signal, Value} -> 
            % Cache the value and return it
            put(Signal, Value),
            Value
    end.

% Reads the current value of a signal
read_signal(Signal) ->
    % See if the value is cached
    case get(Signal) of 
        % If not, fetch the value and subscribe to updates
        undefined -> register_observer(Signal);
        % If it is, just return the cached value
        Value -> Value
    end.

% Sends an update function to a signal
update_signal(Signal, Fun) ->
    Signal ! {update, Fun}.
   
% Stops the children of an observer
observer_cleanup() ->
    case get(observers) of
        % Exit if there are no children
        undefined -> ok;
        % Cleanup all the children and errase them
        Observers -> 
            lists:foreach(fun (Observer) -> Observer ! cleanup end, Observers),        
            erase(observers)
    end.

% Runs an observer process
observer_loop(State, Fun) ->
    receive
        % Cleanup the children of the observer and exit
        cleanup -> observer_cleanup();
        % Update the cached value of a signal
        {updated, Signal, Value} ->
            % Cleanup the children (the function will re-create them)
            observer_cleanup(),
            % Cache the new value of the signal
            put(Signal, Value),
            % Apply the function and continue
            observer_loop(Fun(State), Fun)
    end.

% Creates an observer process
create_observer(State, Fun) ->
    % Spawn the process
    Observer = spawn(fun () -> observer_loop(Fun(State), Fun) end),
    % Record the new process in as a child
    case get(observers) of
        undefined -> put(observers, [Observer]);
        Observers -> put(observers, [Observer|Observers])
    end,
    nil.
