let currentContext;

export function create_signal(initalValue) {
    let value = initalValue;
    const observers = [];
    return {value, observers};
}

export function read_signal(signal) {
    if (currentContext && !signal.observers.include(currentContext)) {
        signal.observers.push(current_observer);
    }
    return signal.value;
}

export function update_signal(signal, fun) {
    signal.value = fun(signal.value);
    signal.observers.forEach((observer) => observer());
}

export function create_observer(initalState, fun) {
    let state;
    function execute() {
        const outerContext = currentContext;
        currentContext = execute;
        state = fun(state);
        currentContext = outerContext;
    }
    execute();
}
