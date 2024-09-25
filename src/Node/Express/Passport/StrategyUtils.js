export function _useStrategy(passport, strategyId, strategy) {
  passport.use(strategyId, strategy);
}
