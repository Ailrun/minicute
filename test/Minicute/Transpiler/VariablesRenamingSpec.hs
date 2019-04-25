{- HLINT ignore "Redundant do" -}
module Minicute.Transpiler.VariablesRenamingSpec
  ( spec
  ) where

import Test.Hspec

import Control.Monad
import Data.Tuple.Extra
import Minicute.Transpiler.VariablesRenaming
import Minicute.Types.Minicute.Program

import qualified Data.Set as Set

spec :: Spec
spec = do
  describe "renameVariablesMainL" $ do
    forM_ testCases (uncurry renameVariablesMainLTest)

renameVariablesMainLTest :: TestName -> TestContent -> SpecWith (Arg Expectation)
renameVariablesMainLTest name beforeContent = do
  it ("finds free variables for expressions in " <> name) $ do
    1 `shouldBe` 1

type TestName = String
type TestContent = MainProgramL
type TestCase = (TestName, TestContent)

testCases :: [TestCase]
testCases
  = []
