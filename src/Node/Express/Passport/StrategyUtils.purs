module Node.Express.Passport.StrategyUtils where

import Prelude
import Effect (Effect)
import Effect.Uncurried (EffectFn3, runEffectFn3)
import Node.Express.Passport.Types (Passport, PassportStrategy, StrategyId)

foreign import _useStrategy ::
  EffectFn3
    Passport
    StrategyId
    PassportStrategy
    Unit

useStrategy ::
  Passport ->
  StrategyId ->
  PassportStrategy ->
  Effect Unit
useStrategy = runEffectFn3 _useStrategy
