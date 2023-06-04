// A signal is a mutable value. 
pub external type Signal(a)

// Signals can be accessed with `get` and mutated with `update` or `set`.
// An effect is an async function that is re-evaluated each time one of the
// signals which it accesses is mutated.
// An observer is an effect with it's own mutable state.
// Effects and observers encapsulate side-effects with fine-grained reactivity.

if erlang {
  pub external fn create(a) -> Signal(a)
    = "erlang_ffi" "create_signal"

  pub external fn get(Signal(a)) -> a
    = "erlang_ffi" "read_signal"

  pub external fn update(Signal(a), fn(a) -> a) -> a
    = "erlang_ffi" "update_signal"

  pub external fn observer(a, fn(a) -> a) -> Nil
    = "erlang_ffi" "create_observer"
}

if javascript {
  pub external fn create(a) -> Signal(a)
    = "./js_ffi.mjs" "create_signal"

  pub external fn get(Signal(a)) -> a
    = "./js_ffi.mjs" "read_signal"

  pub external fn update(Signal(a), fn(a) -> a) -> a
    = "./js_ffi.mjs" "update_signal"

  pub external fn observer(a, fn(a) -> a) -> Nil
    = "./js_ffi.mjs" "create_observer"
}

pub fn set(signal: Signal(a), value: a) -> a {
  update(signal, fn(_) { value })
}
