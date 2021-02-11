(* This file is derived from
 * https://github.com/mirage/mirage-xen/blob/master/lib/time.ml
 *
 * Copyright (C) 2020 Arm Limited
 * Copyright (C) 2010 Anil Madhavapeddy
 * Copyright (C) 2005-2008 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *                    2009 Jérôme Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See time.ml.LICENSE for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

[@@@warning "-3-9"] (* FIXME Lwt_pqueue *)
open Lwt

type +'a io = 'a Lwt.t

type sleep = {
    time : int64;
    mutable canceled : bool;
    action : unit -> unit;
}

module SleepQueue =
    Lwt_pqueue.Make (struct
        type t = sleep
        let compare { time = t1 } { time = t2 } = compare t1 t2
    end)

(* Threads waiting for a timeout to expire: *)
let sleep_queue = ref SleepQueue.empty

(* Sleepers added since the last iteration of the main loop:

   They are not added immediatly to the main sleep queue in order to
   prevent them from being wakeup immediatly by [restart_threads].
*)
let new_sleeps = ref []

let sleep_ns d =
    let t, u = Lwt.wait () in
    let ns = Int64.add (Icecap.Time.get_time_ns ()) d in
    let sleeper = { time = ns; canceled = false; action = Lwt.wakeup_later u } in
    new_sleeps := sleeper :: !new_sleeps;
    Lwt.on_cancel t (fun _ -> sleeper.canceled <- true);
    t

exception Timeout

let timeout d = sleep_ns d >>= fun () -> Lwt.fail Timeout

let with_timeout d f = Lwt.pick [timeout d; Lwt.apply f ()]

let in_the_past now t = t = 0L || t <= now ()

let rec restart_threads now =
    match SleepQueue.lookup_min !sleep_queue with
    | Some{ canceled = true } ->
        sleep_queue := SleepQueue.remove_min !sleep_queue;
        restart_threads now
    | Some{ time = time; action = action } when in_the_past now time ->
        sleep_queue := SleepQueue.remove_min !sleep_queue;
        action ();
        restart_threads now
    | _ ->
        ()

(* +-----------------------------------------------------------------+
   | Event loop                                                      |
   +-----------------------------------------------------------------+ *)

let rec get_next_timeout () =
  match SleepQueue.lookup_min !sleep_queue with
    | Some{ canceled = true } ->
        sleep_queue := SleepQueue.remove_min !sleep_queue;
        get_next_timeout ()
    | Some{ time = time } ->
        Some time
    | None ->
        None

let select_next () =
    (* Transfer all sleepers added since the last iteration to the main
       sleep queue: *)
    sleep_queue := List.fold_left (fun q e -> SleepQueue.add e q) !sleep_queue !new_sleeps;
    new_sleeps := [];
    get_next_timeout ()
