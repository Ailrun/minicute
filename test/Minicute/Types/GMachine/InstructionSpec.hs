{- HLINT ignore "Redundant do" -}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
module Minicute.Types.GMachine.InstructionSpec
  ( spec
  ) where

import Test.Hspec

import Control.Monad
import Data.Tuple.Extra
import Minicute.Types.GMachine.Instruction
import Minicute.Types.Minicute.Program
import Minicute.Utils.TH

spec :: Spec
spec = do
  describe "transpileProgram" $ do
    forM_ testCases (uncurry3 transpileProgramTest)

transpileProgramTest :: TestName -> TestBeforeContent -> TestAfterContent -> SpecWith (Arg Expectation)
transpileProgramTest name beforeContent afterContent = do
  it ("transpile " <> name <> " into valid GMachine program") $ do
    transpileProgram beforeContent `shouldBe` afterContent

type TestName = String
type TestBeforeContent = MainProgram
type TestAfterContent = GMachineProgram
type TestCase = (TestName, TestBeforeContent, TestAfterContent)

testCases :: [TestCase]
testCases
  = [ ( "empty program"
      , [qqMiniMain|
        |]
      , [
        ]
      )

    , ( "program with constant top-level definition"
      , [qqMiniMain|
                   f = 5;
                   g = $C{9;0}
        |]
      , [ ( "f"
          , 0
          , [ IPushBasicValue 5
            , IUpdateAsInteger 0
            , IReturn
            ]
          )
        , ( "g"
          , 0
          , [ IPushBasicValue 9
            , IUpdateAsConstructor 0
            , IReturn
            ]
          )
        ]
      )

    , ( "program with an argument"
      , [qqMiniMain|
                   f x = x;
        |]
      , [ ( "f"
          , 1
          , [ ICopyArgument 0
            , IEval
            , IUpdate 2
            , IPop 2
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with arguments"
      , [qqMiniMain|
                   f x y = y x;
                   g a b c = a c b
        |]
      , [ ( "f"
          , 2
          , [ ICopyArgument 1
            , ICopyArgument 1
            , IMakeApplication
            , IEval
            , IUpdate 3
            , IPop 3
            , IUnwind
            ]
          )
        , ( "g"
          , 3
          , [ ICopyArgument 0
            , ICopyArgument 3
            , IMakeApplication
            , ICopyArgument 2
            , IMakeApplication
            , IEval
            , IUpdate 4
            , IPop 4
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with a simple application"
      , [qqMiniMain|
                   f = g 4;
                   g x = x;
        |]
      , [ ( "f"
          , 0
          , [ IMakeGlobal "g"
            , IMakeInteger 4
            , IMakeApplication
            , IEval
            , IUpdate 1
            , IPop 1
            , IUnwind
            ]
          )
        , ( "g"
          , 1
          , [ ICopyArgument 0
            , IEval
            , IUpdate 2
            , IPop 2
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with a constructor application"
      , [qqMiniMain|
                   f = $C{1;1} 4;
                   g x = $C{3;2} x
        |]
      , [ ( "f"
          , 0
          , [ IMakeConstructor 1 1
            , IMakeInteger 4
            , IMakeApplication
            , IEval
            , IUpdate 1
            , IPop 1
            , IUnwind
            ]
          )
        , ( "g"
          , 1
          , [ IMakeConstructor 3 2
            , ICopyArgument 1
            , IMakeApplication
            , IEval
            , IUpdate 2
            , IPop 2
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with an arithmetic operation"
      , [qqMiniMain|
                   f = 2 + 3
        |]
      , [ ( "f"
          , 0
          , [ IPushBasicValue 2
            , IPushBasicValue 3
            , IPrimitive POAdd
            , IUpdateAsInteger 0
            , IReturn
            ]
          )
        ]
      )

    , ( "program with multiple arithmetic operations"
      , [qqMiniMain|
                   f = 2 + 3 * 4 + 7
        |]
      , [ ( "f"
          , 0
          , [ IPushBasicValue 2
            , IPushBasicValue 3
            , IPushBasicValue 4
            , IPrimitive POMul
            , IPrimitive POAdd
            , IPushBasicValue 7
            , IPrimitive POAdd
            , IUpdateAsInteger 0
            , IReturn
            ]
          )
        ]
      )

    , ( "program with a arithmetic operation in an application"
      , [qqMiniMain|
                   f = g (3 * 4);
                   g x = x;
        |]
      , [ ( "f"
          , 0
          , [ IMakeGlobal "g"
            , IMakeGlobal "*"
            , IMakeInteger 3
            , IMakeApplication
            , IMakeInteger 4
            , IMakeApplication
            , IMakeApplication
            , IEval
            , IUpdate 1
            , IPop 1
            , IUnwind
            ]
          )
        , ( "g"
          , 1
          , [ ICopyArgument 0
            , IEval
            , IUpdate 2
            , IPop 2
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with a let expression returning an integer"
      , [qqMiniMain|
                   f = let
                         x = 4
                       in
                         3
        |]
      , [ ( "f"
          , 0
          , [ IMakeInteger 4
            , IPushBasicValue 3
            , IUpdateAsInteger 1
            , IReturn
            ]
          )
        ]
      )

    , ( "program with a let expression of a definition"
      , [qqMiniMain|
                   f = let
                         x = 4
                       in
                         x
        |]
      , [ ( "f"
          , 0
          , [ IMakeInteger 4
            , ICopyArgument 0
            , IEval
            , IUpdate 2
            , IPop 2
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with a let expression of definitions"
      , [qqMiniMain|
                   f = let
                         x = 4;
                         y = 3
                       in
                         x * y
        |]
      , [ ( "f"
          , 0
          , [ IMakeInteger 4
            , IMakeInteger 3
            , ICopyArgument 1
            , IEval
            , IPushExtractedValue
            , ICopyArgument 0
            , IEval
            , IPushExtractedValue
            , IPrimitive POMul
            , IUpdateAsInteger 2
            , IReturn
            ]
          )
        ]
      )

    , ( "program with a let expression in an arithmetic expression"
      , [qqMiniMain|
                   f = 5 + (let
                              x = 4
                            in
                              x)
        |]
      , [ ( "f"
          , 0
          , [ IPushBasicValue 5
            , IMakeInteger 4
            , ICopyArgument 0
            , IEval
            , IPushExtractedValue
            , IPop 1
            , IPrimitive POAdd
            , IUpdateAsInteger 0
            , IReturn
            ]
          )
        ]
      )

    , ( "program with a letrec expression with a definition"
      , [qqMiniMain|
                   f = letrec
                         x = 4
                       in
                         x
        |]
      , [ ( "f"
          , 0
          , [ IMakePlaceholders 1
            , IMakeInteger 4
            , IUpdate 1
            , ICopyArgument 0
            , IEval
            , IUpdate 2
            , IPop 2
            , IUnwind
            ]
          )
        ]
      )

    , ( "program with a letrec expression with definitions"
      , [qqMiniMain|
                   f = letrec
                         x = 2 + y;
                         y = x - 3;
                       in
                         x / y
        |]
      , [ ( "f"
          , 0
          , [ IMakePlaceholders 2
            , IMakeGlobal "+"
            , IMakeInteger 2
            , IMakeApplication
            , ICopyArgument 1
            , IMakeApplication
            , IUpdate 2
            , IMakeGlobal "-"
            , ICopyArgument 2
            , IMakeApplication
            , IMakeInteger 3
            , IMakeApplication
            , IUpdate 2
            , ICopyArgument 1
            , IEval
            , IPushExtractedValue
            , ICopyArgument 0
            , IEval
            , IPushExtractedValue
            , IPrimitive PODiv
            , IUpdateAsInteger 2
            , IReturn
            ]
          )
        ]
      )
    ]
