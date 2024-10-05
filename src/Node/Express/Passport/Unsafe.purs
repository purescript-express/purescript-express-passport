module Node.Express.Passport.Unsafe where

import Prelude

import Data.Argonaut.Core (Json)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn3, Fn4, runFn3, runFn4)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler, runAff_)
import Effect.Exception (Error)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4, EffectFn7, mkEffectFn1, mkEffectFn3, mkEffectFn7, runEffectFn1, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (Foreign, unsafeToForeign)
import Node.Express.Handler (Handler, runHandlerM)
import Node.Express.Passport.Types (Passport, StrategyId)
import Node.Express.Passport.Utils (magicPass)
import Node.Express.Types (HandlerFnInternal_Req_Res_Next, Middleware, Request, Response, NextFnInternal)
import Unsafe.Coerce (unsafeCoerce)

foreign import _getUser :: forall user. EffectFn1 Request (Nullable user)

unsafeGetUser :: forall user. Request -> Effect (Maybe user)
unsafeGetUser req = runEffectFn1 _getUser req <#> Nullable.toMaybe

------------------------------------------------------------------------------------------------------------------------
foreign import _login ::
  forall user.
  EffectFn4
    Request
    user
    LoginOptions
    LogIn__Implementation__Callback
    Unit

type LogIn__Implementation__Callback
  = EffectFn1 (Nullable Error) Unit

type LoginOptions
  = { session :: Boolean }

-- https://github.com/jaredhanson/passport/blob/2327a36e7c005ccc7134ad157b2f258b57aa0912/lib/http/request.js#L13-L14
defaultLoginOptions :: LoginOptions
defaultLoginOptions = { session: true }

unsafeLogIn ::
  forall user.
  user ->
  LoginOptions ->
  Request ->
  Aff (Maybe Error)
unsafeLogIn user options req = makeAff \affCallback -> do
  runEffectFn4
    _login
    req
    user
    options
    (mkEffectFn1 \nullableError ->
      case Nullable.toMaybe nullableError of
           Just error -> affCallback $ Right $ Just error
           Nothing -> affCallback $ Right $ Nothing
    )
  pure nonCanceler

------------------------------------------------------------------------------------------------------------------------

type Authenticate__Implementation__Callback user info
  = EffectFn7 Request Response NextFnInternal (Nullable Error) (Nullable user) (Nullable info) (Nullable Number) Unit

type Authenticate__Implementation__Options
  = { session :: Boolean
    , successRedirect :: Nullable String
    , successMessage :: Foreign
    , successFlash :: Foreign
    , failureRedirect :: Nullable String
    , failureMessage :: Foreign
    , failureFlash :: Foreign
    , assignProperty :: Nullable String
    }

foreign import _authenticateWithoutCallback ::
  Fn3
    Passport
    StrategyId
    Authenticate__Implementation__Options
    HandlerFnInternal_Req_Res_Next

foreign import _authenticateWithCallback ::
  forall user info.
  Fn4
    Passport
    StrategyId
    Authenticate__Implementation__Options
    (Authenticate__Implementation__Callback user info)
    HandlerFnInternal_Req_Res_Next

-- e.g. flash message
data AuthenticationMessage
  = AuthenticationMessage__Custom String
  | AuthenticationMessage__StrategyDefault
  | AuthenticationMessage__Disable

type AuthenticateOptions
  = { session :: Boolean
    , successRedirect :: Maybe String
    , successMessage :: AuthenticationMessage
    , successFlash :: AuthenticationMessage
    , failureRedirect :: Maybe String
    , failureMessage :: AuthenticationMessage
    , failureFlash :: AuthenticationMessage
    , assignProperty :: Maybe String
    -- from https://github.com/jaredhanson/passport/blob/08f57c2e3086955f06f42d9ac7ad466d1f10019c/lib/middleware/authenticate.js#L257
    -- you should set req.sessio.returnTo
    -- like this https://github.com/graphile/bootstrap-react-apollo/blob/fbeab7b9c2a51b48995a19872b71545428091295/server/middleware/installPassportStrategy.js#L7-L26
    , successReturnToOrRedirect :: Maybe String
    }

authenticateOptionsToImplementation :: AuthenticateOptions -> Authenticate__Implementation__Options
authenticateOptionsToImplementation options =
  { session: options.session
  , successRedirect: Nullable.toNullable options.successRedirect
  , successMessage: convertAuthenticationMessage options.successMessage
  , successFlash: convertAuthenticationMessage options.successFlash
  , failureRedirect: Nullable.toNullable options.failureRedirect
  , failureMessage: convertAuthenticationMessage options.failureMessage
  , failureFlash: convertAuthenticationMessage options.failureFlash
  , assignProperty: Nullable.toNullable options.assignProperty
  }

defaultAuthenticateOptions :: AuthenticateOptions
defaultAuthenticateOptions =
  { session: true
  , successRedirect: Nothing
  , successMessage: AuthenticationMessage__Disable
  , successFlash: AuthenticationMessage__Disable
  , failureRedirect: Nothing
  , failureMessage: AuthenticationMessage__Disable
  , failureFlash: AuthenticationMessage__Disable
  , assignProperty: Nothing
  , successReturnToOrRedirect: Nothing
  }

data Authenticate__CustomCallbackResult user
  = Authenticate__CustomCallbackResult__Error Error
  | Authenticate__CustomCallbackResult__AuthenticationError -- user is set to false
  | Authenticate__CustomCallbackResult__Success user

type Authenticate__CustomCallback info user
  = { result :: Authenticate__CustomCallbackResult user
    , info :: Maybe info
    , status :: Maybe Number
    } ->
    Handler

convertAuthenticationMessage :: AuthenticationMessage -> Foreign
convertAuthenticationMessage (AuthenticationMessage__Custom msg) = unsafeToForeign msg
convertAuthenticationMessage AuthenticationMessage__StrategyDefault = unsafeToForeign true
convertAuthenticationMessage AuthenticationMessage__Disable = unsafeToForeign $ Nullable.null

errorToAuthenticate__CustomCallbackResult :: forall user . Nullable Error -> Nullable user -> Authenticate__CustomCallbackResult user
errorToAuthenticate__CustomCallbackResult error nuser =
  case Nullable.toMaybe error of
    Just error' -> Authenticate__CustomCallbackResult__Error error'
    Nothing -> case Nullable.toMaybe nuser of
      Just user' -> Authenticate__CustomCallbackResult__Success user'
      Nothing -> Authenticate__CustomCallbackResult__AuthenticationError

authenticate__CustomCallbackToImplementation :: forall user info . Authenticate__CustomCallback info user -> Authenticate__Implementation__Callback user info
authenticate__CustomCallbackToImplementation onAuthenticate =
   mkEffectFn7 \req res next nerror nuser ninfo nstatus -> do
      let
        (handler :: Handler) = onAuthenticate
            { result: errorToAuthenticate__CustomCallbackResult nerror nuser
            , info: Nullable.toMaybe ninfo
            , status: Nullable.toMaybe nstatus
            }
      runEffectFn3 (runHandlerM handler) req res next

unsafeAuthenticateWithCallback ::
  forall info user.
  Passport ->
  StrategyId ->
  AuthenticateOptions ->
  Authenticate__CustomCallback info user ->
  Middleware

unsafeAuthenticateWithCallback passport strategyid options onAuthenticate =
  runFn4
    _authenticateWithCallback
    passport
    strategyid
    (authenticateOptionsToImplementation options)
    (authenticate__CustomCallbackToImplementation onAuthenticate)

unsafeAuthenticateWithoutCallback ::
  Passport ->
  StrategyId ->
  AuthenticateOptions ->
  Middleware
unsafeAuthenticateWithoutCallback passport strategyid options =
  runFn3
    _authenticateWithoutCallback
    passport
    strategyid
    (authenticateOptionsToImplementation options)

------------------------------------------------------------------------------------------------------------------------
type AddSerializeUser__Implementation__SerializerCallback
  = EffectFn2 (Nullable Error) (Nullable Json) Unit

type AddSerializeUser__Implementation__Serializer user
  = EffectFn3 Request user AddSerializeUser__Implementation__SerializerCallback Unit

foreign import _addSerializeUser ::
  forall user.
  EffectFn2
    Passport
    (AddSerializeUser__Implementation__Serializer user)
    Unit

data SerializedUser
  = SerializedUser__Result (Maybe Json)
  | SerializedUser__Pass

type AddSerializeUser__Callback user
  = Request -> user -> Aff SerializedUser

unsafeAddSerializeUser ::
  forall user.
  Passport ->
  AddSerializeUser__Callback user ->
  Effect Unit
unsafeAddSerializeUser passport serializeAff =
  runEffectFn2
    _addSerializeUser
    passport
    ( mkEffectFn3 \req user callback ->
        runAff_
          ( case _ of
              Left error -> runEffectFn2 callback (Nullable.notNull error) Nullable.null
              Right s -> case s of
                SerializedUser__Result result -> runEffectFn2 callback (Nullable.notNull (unsafeCoerce result)) Nullable.null
                SerializedUser__Pass -> runEffectFn2 callback (Nullable.notNull (unsafeCoerce magicPass)) Nullable.null
          )
          (serializeAff req user)
    )

------------------------------------------------------------------------------------------------------------------------
type AddDeserializeUser__Implementation__DeserializerCallback user
  = EffectFn2 (Nullable Error) (Nullable user) Unit

type AddDeserializeUser__Implementation__Deserializer user
  = EffectFn3 Request Json (AddDeserializeUser__Implementation__DeserializerCallback user) Unit

foreign import _addDeserializeUser :: forall user. EffectFn2 Passport (AddDeserializeUser__Implementation__Deserializer user) Unit

data DeserializedUser user
  = DeserializedUser__Result (Maybe user)
  | DeserializedUser__Pass

type AddDeserializeUser__Callback user
  = Request -> Json -> Aff (DeserializedUser user)

unsafeAddDeserializeUser ::
  forall user.
  Passport ->
  AddDeserializeUser__Callback user ->
  Effect Unit
unsafeAddDeserializeUser passport deserializeAff =
  runEffectFn2
    _addDeserializeUser
    passport
    ( mkEffectFn3 \req user callback ->
        runAff_
          ( case _ of
              Left error -> runEffectFn2 callback (Nullable.notNull error) Nullable.null
              Right s -> case s of
                DeserializedUser__Result result -> runEffectFn2 callback (Nullable.notNull (unsafeCoerce result)) Nullable.null
                DeserializedUser__Pass -> runEffectFn2 callback (Nullable.notNull (unsafeCoerce magicPass)) Nullable.null
          )
          (deserializeAff req user)
    )
