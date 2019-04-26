{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
module Minicute.Data.PrintSequence
  ( PrintSequence

  , toString

  , printNothing
  , printNewline
  , printString
  , printIndented
  , printAppend

  , printShowable
  , printConcat
  , printIntersperse
  , printConditionalParentheses
  ) where

import Data.Data
import Data.List
import GHC.Generics
import Minicute.Data.String

data PrintSequence
  = PrintNothing
  | PrintNewline
  | PrintString String
  | PrintIndented PrintSequence
  | PrintAppend PrintSequence PrintSequence
  deriving ( Generic
           , Typeable
           , Data
           , Eq
           , Ord
           , Show
           , Read
           )

toString :: PrintSequence -> String
toString ps = concat (flatten initialFgs [(ps, initialFls)])
{-# INLINEABLE toString #-}

printNothing :: PrintSequence
printNothing = PrintNothing
{-# INLINEABLE printNothing #-}

printNewline :: PrintSequence
printNewline = PrintNewline
{-# INLINEABLE printNewline #-}

printString :: String -> PrintSequence
printString = printIntersperse printNewline . fmap PrintString . lines . toUnix
{-# INLINEABLE printString #-}

printIndented :: PrintSequence -> PrintSequence
printIndented = PrintIndented
{-# INLINEABLE printIndented #-}

printAppend :: PrintSequence -> PrintSequence -> PrintSequence
printAppend PrintNothing = id
printAppend s1 = PrintAppend s1
infixr 9 `printAppend`
{-# INLINEABLE printAppend #-}

printShowable :: (Show a) => a -> PrintSequence
printShowable = printString . show
{-# INLINEABLE printShowable #-}

printConcat :: (Foldable t) => t PrintSequence -> PrintSequence
printConcat = foldl' printAppend PrintNothing
{-# INLINEABLE printConcat #-}

printIntersperse :: PrintSequence -> [PrintSequence] -> PrintSequence
printIntersperse = (printConcat .) . intersperse
{-# INLINEABLE printIntersperse #-}

printConditionalParentheses :: Bool -> PrintSequence -> PrintSequence
printConditionalParentheses withParenthesis ps
  | withParenthesis = printString "(" `printAppend` ps `printAppend` printString ")"
  | otherwise = ps
{-# INLINEABLE printConditionalParentheses #-}

flatten :: FlattenGlobalState -> [(PrintSequence, FlattenLocalState)] -> [String]
flatten _ [] = []
flatten fgs ((PrintNothing, _) : pss) = flatten fgs pss
flatten _ ((PrintNewline, fls) : pss) = flsCreateNewline fls : flatten (flsToFgs fls) pss
flatten fgs ((PrintString str, _) : pss) = str : flatten (fgsUpdateColumn fgs str) pss
flatten fgs ((PrintIndented ps, _) : pss) = flatten fgs ((ps, fgsToFls fgs) : pss)
flatten fgs ((PrintAppend ps1 ps2, fls) : pss) = flatten fgs ((ps1, fls) : (ps2, fls) : pss)

type FlattenGlobalState = Int -- ^ Current column

initialFgs :: FlattenGlobalState
initialFgs = 0
{-# INLINEABLE initialFgs #-}

fgsUpdateColumn :: FlattenGlobalState -> String -> FlattenGlobalState
fgsUpdateColumn fgs s = fgs + length s
{-# INLINEABLE fgsUpdateColumn #-}

type FlattenLocalState = Int -- ^ Indentation for specific sequence

initialFls :: FlattenLocalState
initialFls = 0
{-# INLINEABLE initialFls #-}

flsCreateNewline :: FlattenLocalState -> String
flsCreateNewline fls = "\n" <> replicate fls ' '
{-# INLINEABLE flsCreateNewline #-}

fgsToFls :: FlattenGlobalState -> FlattenLocalState
fgsToFls fgs = fgs
{-# INLINEABLE fgsToFls #-}

flsToFgs :: FlattenLocalState -> FlattenGlobalState
flsToFgs fls = fls
{-# INLINEABLE flsToFgs #-}