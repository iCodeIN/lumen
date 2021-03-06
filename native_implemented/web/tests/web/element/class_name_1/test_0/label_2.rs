//! ```elixir
//! # label 2
//! # pushed to stack: ()
//! # returned from call: {:ok, document}
//! # full stack: ({:ok, document})
//! # returns: {:ok, body}
//! {:ok, body} = Lumen.Web.Document.body(document)
//! class_name = Lumen.Web.Element.class_name(body)
//! Lumen.Web.Wait.with_return(class_name)
//! ```

use std::convert::TryInto;

use web_sys::Document;

use liblumen_alloc::erts::process::Process;
use liblumen_alloc::erts::term::prelude::*;

use super::label_3;

#[native_implemented::label]
fn result(process: &Process, ok_document: Term) -> Term {
    assert!(
        ok_document.is_boxed_tuple(),
        "ok_document ({:?}) is not a tuple",
        ok_document
    );
    let ok_document_tuple: Boxed<Tuple> = ok_document.try_into().unwrap();
    assert_eq!(ok_document_tuple.len(), 2);
    assert_eq!(ok_document_tuple[0], Atom::str_to_term("ok"));
    let document = ok_document_tuple[1];
    let document_ref_boxed: Boxed<Resource> = document.try_into().unwrap();
    let document_reference: Resource = document_ref_boxed.into();
    let _: &Document = document_reference.downcast_ref().unwrap();

    process.queue_frame_with_arguments(
        liblumen_web::document::body_1::frame().with_arguments(false, &[document]),
    );
    process.queue_frame_with_arguments(label_3::frame().with_arguments(true, &[]));

    Term::NONE
}
