import { Passport } from 'passport';

export function getPassport() {
  return new Passport()
}

export function _passportInitialize(passport, options) {
  return passport.initialize(options)
}

export function _passportSession(passport, options) {
  return passport.session(options)
}

export function _isAuthenticated(req) {
  return req.isAuthenticated()
}

export function _logout(req) {
  req.logout()
}
