type task = unit -> unit

type t = {
  run_async: (unit -> unit) -> unit;
  shutdown: wait:bool -> unit -> unit;
  size: unit -> int;
  num_tasks: unit -> int;
}

exception Shutdown

let[@inline] run_async (self : t) f : unit = self.run_async f
let[@inline] shutdown (self : t) : unit = self.shutdown ~wait:true ()

let[@inline] shutdown_without_waiting (self : t) : unit =
  self.shutdown ~wait:false ()

let[@inline] num_tasks (self : t) : int = self.num_tasks ()
let[@inline] size (self : t) : int = self.size ()

let run_wait_block self (f : unit -> 'a) : 'a =
  let q = Bb_queue.create () in
  run_async self (fun () ->
      try
        let x = f () in
        Bb_queue.push q (Ok x)
      with exn ->
        let bt = Printexc.get_raw_backtrace () in
        Bb_queue.push q (Error (exn, bt)));
  match Bb_queue.pop q with
  | Ok x -> x
  | Error (exn, bt) -> Printexc.raise_with_backtrace exn bt

module For_runner_implementors = struct
  let create ~size ~num_tasks ~shutdown ~run_async () : t =
    { size; num_tasks; shutdown; run_async }

  module Suspend_ = Suspend_
end
