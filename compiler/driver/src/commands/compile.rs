use std::ops::Deref;
use std::path::PathBuf;
use std::sync::Arc;
use std::thread;
use std::time::Instant;

use anyhow::anyhow;

use clap::ArgMatches;

use log::debug;

use liblumen_codegen as codegen;
use liblumen_codegen::linker::{self, LinkerInfo};
use liblumen_codegen::meta::{CodegenResults, ProjectInfo};
use liblumen_session::{CodegenOptions, DebuggingOptions, Options};
use liblumen_util::diagnostics::{CodeMap, Emitter};
use liblumen_util::time::HumanDuration;

use crate::commands::*;
use crate::compiler::prelude::{Compiler as CompilerQueryGroup, *};
use crate::compiler::Compiler;
use crate::task;

const NUM_GENERATED_MODULES: usize = 3;

pub fn handle_command<'a>(
    c_opts: CodegenOptions,
    z_opts: DebuggingOptions,
    matches: &ArgMatches<'a>,
    cwd: PathBuf,
    emitter: Option<Arc<dyn Emitter>>,
) -> anyhow::Result<()> {
    // Extract options from provided arguments
    let options = Options::new(c_opts, z_opts, cwd, &matches)?;
    // Construct empty code map for use in compilation
    let codemap = Arc::new(CodeMap::new());
    // Set up diagnostics
    let diagnostics = create_diagnostics_handler(&options, codemap.clone(), emitter);

    // Initialize codegen backend
    codegen::init(&options)?;

    // Build query database
    let mut db = Compiler::new(codemap, diagnostics);

    // The core of the query system is the initial set of options provided to the compiler
    //
    // The query system will use these options to construct the set of inputs on demand
    db.set_options(Arc::new(options));

    let inputs = db.inputs().unwrap_or_else(abort_on_err);

    // Parse sources
    let num_inputs = inputs.len();
    if num_inputs < 1 {
        db.diagnostics().fatal("No input sources found!").raise();
    }

    let start = Instant::now();
    let mut tasks = inputs
        .iter()
        .cloned()
        .map(|input| {
            debug!("spawning worker for {:?}", input);
            let snapshot = db.snapshot();
            task::spawn(async move {
                let result = snapshot.compile(input);
                if result.is_err() {
                    let diagnostics = snapshot.diagnostics();
                    let input_info = snapshot.lookup_intern_input(input);
                    diagnostics.failed("Failed", format!("{}", input_info.source_name()));
                }
                result
            })
        })
        .collect::<Vec<_>>();

    let options = db.options();
    let mut codegen_results = CodegenResults {
        project_name: options.project_name.clone(),
        modules: Vec::with_capacity(num_inputs + NUM_GENERATED_MODULES),
        windows_subsystem: None,
        linker_info: LinkerInfo::new(),
        project_info: ProjectInfo::new(&options),
    };

    debug!("awaiting results from workers ({} units)", num_inputs);

    let diagnostics = db.diagnostics();
    for task in tasks.drain(..) {
        if let Ok(compiled) = task::join(task).unwrap() {
            codegen_results.modules.push(compiled);
        }
    }

    // Do not proceed to linking if there were compilation errors
    diagnostics.abort_if_errors();

    // Generate LLVM module containing atom table data
    //
    // NOTE: This does not go through the query system, since atoms
    // are not inputs to the query system, but gathered globally during
    // compilation.
    let thread_id = thread::current().id();
    let context = db.llvm_context(thread_id);
    let target_machine = db.get_target_machine(thread_id);
    let atoms = db.take_atoms();
    let symbols = db.take_symbols();
    codegen::generators::run(
        &options,
        &mut codegen_results,
        context.deref(),
        target_machine.deref(),
        atoms,
        symbols,
    )?;

    // Link all compiled objects
    let diagnostics = db.diagnostics();
    if !options.should_link() {
        if options.project_type.requires_link() {
            diagnostics.note("Linker was explicitly disabled, skipping link");
        } else {
            debug!(
                "skipping link because it was not requested and project type does not require it"
            );
        }
    } else {
        if options.project_type.requires_link() {
            if let Err(err) = linker::link_binary(&options, &diagnostics, &codegen_results) {
                diagnostics.error(format!("{}", err));
                return Err(anyhow!("failed to link binary"));
            }
        } else {
            debug!("skipping link because project type does not require it");
        }
    }

    let duration = HumanDuration::since(start);
    diagnostics.success(
        "Finished",
        &format!("built {} in {:#}", options.project_name, duration),
    );
    Ok(())
}
