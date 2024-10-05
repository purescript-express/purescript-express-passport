module Node.Express.Passport.Safe where

import Node.Express.Passport.Unsafe (AddDeserializeUser__Callback, AddSerializeUser__Callback, AuthenticateOptions, Authenticate__CustomCallback, LoginOptions, unsafeAddDeserializeUser, unsafeAddSerializeUser, unsafeAuthenticateWithCallback, unsafeAuthenticateWithoutCallback, unsafeGetUser, unsafeLogIn)
import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Exception (Error)
import Node.Express.Passport.Types (Passport, StrategyId)
import Node.Express.Types (Request, Middleware)

getUser :: forall proxy user. proxy user -> Request -> Effect (Maybe user)
getUser _ = unsafeGetUser

login ::
  forall proxy user.
  proxy user ->
  user ->
  LoginOptions ->
  Request ->
  Aff (Maybe Error)
login _ = unsafeLogIn

authenticate ::
  forall proxy user info.
  proxy user ->
  proxy info ->
  Passport ->
  StrategyId ->
  AuthenticateOptions ->
  Maybe (Authenticate__CustomCallback info user) ->
  Middleware
authenticate _ _ passport strategyid options =
  case _ of
       Just onAuthenticate -> unsafeAuthenticateWithCallback passport strategyid options onAuthenticate
       Nothing -> unsafeAuthenticateWithoutCallback passport strategyid options

addSerializeUser ::
  forall proxy user.
  proxy user ->
  Passport ->
  AddSerializeUser__Callback user ->
  Effect Unit
addSerializeUser _ = unsafeAddSerializeUser

addDeserializeUser ::
  forall proxy user.
  proxy user ->
  Passport ->
  AddDeserializeUser__Callback user ->
  Effect Unit
addDeserializeUser _ = unsafeAddDeserializeUser
