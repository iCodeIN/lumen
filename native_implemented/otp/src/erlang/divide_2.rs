#[cfg(all(not(target_arch = "wasm32"), test))]
mod test;

use std::convert::TryInto;

use anyhow::*;

use liblumen_alloc::erts::exception::{self, *};
use liblumen_alloc::erts::process::trace::Trace;
use liblumen_alloc::erts::process::Process;
use liblumen_alloc::erts::term::prelude::Term;

/// `//2` infix operator.  Unlike `+/2`, `-/2` and `*/2` always promotes to `float` returns the
/// `float`.
#[native_implemented::function(erlang:/ /2)]
pub fn result(process: &Process, dividend: Term, divisor: Term) -> exception::Result<Term> {
    let dividend_f64: f64 = dividend.try_into().map_err(|_| {
        badarith(
            Trace::capture(),
            Some(anyhow!("dividend ({}) cannot be promoted to a float", dividend).into()),
        )
    })?;
    let divisor_f64: f64 = divisor.try_into().map_err(|_| {
        badarith(
            Trace::capture(),
            Some(anyhow!("divisor ({}) cannot be promoted to a float", divisor).into()),
        )
    })?;

    if divisor_f64 == 0.0 {
        Err(badarith(
            Trace::capture(),
            Some(anyhow!("divisor ({}) cannot be zero", divisor).into()),
        )
        .into())
    } else {
        let quotient_f64 = dividend_f64 / divisor_f64;
        let quotient_term = process.float(quotient_f64);

        Ok(quotient_term)
    }
}
