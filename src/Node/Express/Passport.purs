module Node.Express.Passport
  ( module Node.Express.Passport
  , module Exports
  ) where

import Node.Express.Passport.Implementation (PassportInitializeOptions, PassportSessionOptions, _isAuthenticated, _logout, _passportInitialize, _passportSession, defaultPassportInitializeOptions, defaultPassportSessionOptions, getPassport, isAuthenticated, logout, passportInitialize, passportSession) as Exports
import Node.Express.Passport.Safe (addDeserializeUser, addSerializeUser, authenticate, getUser, login) as Exports
import Node.Express.Passport.StrategyUtils (_useStrategy, useStrategy) as Exports
import Node.Express.Passport.Types (Passport, PassportStrategy, StrategyId(..)) as Exports
import Node.Express.Passport.Unsafe (AddDeserializeUser__Callback, AddDeserializeUser__Implementation__Deserializer, AddDeserializeUser__Implementation__DeserializerCallback, AddSerializeUser__Callback, AddSerializeUser__Implementation__Serializer, AddSerializeUser__Implementation__SerializerCallback, AuthenticateOptions, Authenticate__CustomCallback, Authenticate__CustomCallbackResult(..), Authenticate__Implementation__Callback, Authenticate__Implementation__Options, AuthenticationMessage(..), DeserializedUser(..), LogIn__Implementation__Callback, LoginOptions, SerializedUser(..), _addDeserializeUser, _addSerializeUser, _authenticateWithCallback, _authenticateWithoutCallback, _getUser, _login, authenticateOptionsToImplementation, authenticate__CustomCallbackToImplementation, convertAuthenticationMessage, defaultAuthenticateOptions, defaultLoginOptions, errorToAuthenticate__CustomCallbackResult, unsafeAddDeserializeUser, unsafeAddSerializeUser, unsafeAuthenticateWithCallback, unsafeAuthenticateWithoutCallback, unsafeGetUser, unsafeLogIn) as Exports
