use super::*;

#[test]
fn with_different_process_with_message_sends_message_when_timer_expires() {
    run!(
        |arc_process| {
            (
                Just(arc_process.clone()),
                milliseconds(),
                strategy::term(arc_process.clone()),
            )
        },
        |(arc_process, milliseconds, message)| {
            let time = arc_process.integer(milliseconds);

            let destination_arc_process = test::process::child(&arc_process);
            let destination = registered_name();

            prop_assert_eq!(
                erlang::register_2::result(
                    arc_process.clone(),
                    destination,
                    destination_arc_process.pid_term(),
                ),
                Ok(true.into())
            );

            let options = options(&arc_process);

            let result = result(arc_process.clone(), time, destination, message, options);

            prop_assert!(
                result.is_ok(),
                "Timer reference not returned.  Got {:?}",
                result
            );

            let timer_reference = result.unwrap();

            prop_assert!(timer_reference.is_boxed_local_reference());

            let timeout_message = arc_process.tuple_from_slice(&[
                Atom::str_to_term("timeout"),
                timer_reference,
                message,
            ]);

            prop_assert!(!has_message(&destination_arc_process, timeout_message));

            // No sleeping is necessary because timeout is in the past and so the timer will
            // timeout at once

            crate::runtime::timer::timeout();

            prop_assert!(has_message(&destination_arc_process, timeout_message));

            Ok(())
        },
    );
}

#[test]
fn with_same_process_with_message_sends_message_when_timer_expires() {
    TestRunner::new(Config::with_source_file(file!()))
        .run(
            &(milliseconds(), strategy::process()).prop_flat_map(|(milliseconds, arc_process)| {
                (
                    Just(milliseconds),
                    Just(arc_process.clone()),
                    strategy::term(arc_process),
                )
            }),
            |(milliseconds, arc_process, message)| {
                let time = arc_process.integer(milliseconds);
                let destination = registered_name();

                prop_assert_eq!(
                    erlang::register_2::result(
                        arc_process.clone(),
                        destination,
                        arc_process.pid_term(),
                    ),
                    Ok(true.into())
                );

                let options = options(&arc_process);

                let result = result(arc_process.clone(), time, destination, message, options);

                prop_assert!(
                    result.is_ok(),
                    "Timer reference not returned.  Got {:?}",
                    result
                );

                let timer_reference = result.unwrap();

                prop_assert!(timer_reference.is_boxed_local_reference());

                let timeout_message = arc_process.tuple_from_slice(&[
                    Atom::str_to_term("timeout"),
                    timer_reference,
                    message,
                ]);

                prop_assert!(!has_message(&arc_process, timeout_message));

                // No sleeping is necessary because timeout is in the past and so the timer will
                // timeout at once

                crate::runtime::timer::timeout();

                prop_assert!(has_message(&arc_process, timeout_message));

                Ok(())
            },
        )
        .unwrap();
}
