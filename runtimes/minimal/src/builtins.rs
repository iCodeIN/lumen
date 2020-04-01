pub mod receive;

use std::convert::TryInto;
use std::panic;

use liblumen_alloc::erts::term::prelude::*;
use liblumen_alloc::erts::Process;

use lumen_rt_core::process::current_process;
use lumen_rt_core::registry;

extern "Rust" {
    #[link_name = "__scheduler_stop_waiting"]
    fn stop_waiting(proc: &Process);
}

#[export_name = "__lumen_builtin_send"]
pub extern "C" fn builtin_send(to_term: Term, msg: Term) -> Term {
    let result = panic::catch_unwind(|| {
        let decoded_result: Result<Pid, _> = to_term.decode().unwrap().try_into();
        if let Ok(to) = decoded_result {
            let p = current_process();
            let self_pid = p.pid();
            if self_pid == to {
                p.send_from_self(msg);
                return msg;
            } else {
                if let Some(ref to_proc) = registry::pid_to_process(&to) {
                    if let Ok(resume) = to_proc.send_from_other(msg) {
                        if resume {
                            unsafe {
                                stop_waiting(to_proc);
                            }
                        }
                        return msg;
                    }
                }
            }
        }

        Term::NONE
    });
    if let Ok(res) = result {
        res
    } else {
        Term::NONE
    }
}
