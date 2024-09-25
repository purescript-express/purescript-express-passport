export function _passportStrategyLocal(options, verify) {
  return new (require('passport-local').Strategy)(
    Object.assign({ passReqToCallback: true }, options),
    verify
  );
}
