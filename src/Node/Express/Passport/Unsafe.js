export function _addSerializeUser(passport, serializer) {
  passport.serializeUser(serializer)
}

export function _addDeserializeUser(passport, deserializer) {
  passport.deserializeUser(deserializer)
}

export function _authenticate(passport, strategy, options, callback) {
  return
    passport.authenticate(
      strategy,
      options,
      (
        callback ?
        (
          function _authenticateCallback(err, user, info, status) {
            callback(
              err,
              user ? user : null, // can be false
              info ? info : null, // can be false
              status ? status : null // can be false
            )
          }
        ) : null
      )
    )
}

export function _login(req, user, options, done) {
  req.login(user, options, done)
}

export function _getUser(req) {
  if (!(req._passport && req._passport.instance)) {
    throw new Error('passport is not initialized')
  }

  const property = req._passport.instance._userProperty

  if (!property) {
    throw new Error('req._passport.instance._userProperty is empty')
  }

  const user = req[property]

  return user ? user : null // can be false
}
