/// Espera a que terminen [futures] ignorando sus errores (los errores ya se
/// muestran en la UI a través de los providers). Útil para "tirar para
/// actualizar".
Future<void> settle(Iterable<Future<Object?>> futures) async {
  await Future.wait(
    futures.map((f) => f.then<Object?>((v) => v, onError: (Object _) => null)),
  );
}
