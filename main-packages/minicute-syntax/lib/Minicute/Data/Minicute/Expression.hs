{-# OPTIONS_GHC -fno-warn-missing-pattern-synonym-signatures #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveLift #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
-- |
-- Copyright: (c) 2018-present Junyoung Clare Jang
-- License: BSD 3-Clause
--
-- Types for a miniCUTE expression
module Minicute.Data.Minicute.Expression
  ( module Minicute.Data.Common


  , LetDefinition( .. )
  , MainLetDefinition

  , _letDefinitionBinder
  , _letDefinitionBody


  , MatchCase( .. )
  , MainMatchCase

  , _matchCaseTag
  , _matchCaseArguments
  , _matchCaseBody


  , IsRecursive( isRecursive )
  , pattern Recursive
  , pattern NonRecursive


  , ExpressionType( .. )
  , Annotation

  , ExpressionLevel( .. )


  , Expression( .. )
  , MainExpression
  , pattern EApplication2
  , pattern EApplication3

  , _annotation
  ) where

import Control.Lens.Lens ( lens )
import Control.Lens.TH
import Control.Lens.Tuple
import Control.Lens.Type
import Control.Lens.Wrapped ( _Wrapped )
import Data.Data ( Data(..), Typeable )
import Data.Kind ( Type )
import Data.Text.Prettyprint.Doc.Minicute
import GHC.Generics ( Generic )
import Language.Haskell.TH.Syntax ( Lift )
import Minicute.Data.Common

import qualified Data.Data as Data
import qualified Data.Text.Prettyprint.Doc as PP

-- |
-- A type used to represent a let definition of @expr a@.
newtype LetDefinition t l a
  = LetDefinition (a, Expression t l a)
  deriving ( Generic
           , Typeable
           )
deriving instance (Data a, Typeable t, Typeable l, Data (Expression t l a)) => Data (LetDefinition t l a)
deriving instance (Lift a, Lift (Expression t l a)) => Lift (LetDefinition t l a)
deriving instance (Eq a, Eq (Expression t l a)) => Eq (LetDefinition t l a)
deriving instance (Ord a, Ord (Expression t l a)) => Ord (LetDefinition t l a)
deriving instance (Show a, Show (Expression t l a)) => Show (LetDefinition t l a)

-- |
-- A 'MainLetDefinition' for 'ExpressionMC' with 'Identifier'.
type MainLetDefinition t l = LetDefinition t l Identifier

instance (PrettyMC a, PrettyMC (Expression t l a)) => PrettyMC (LetDefinition t l a) where
  prettyMC _ (LetDefinition (binder, expr))
    = PP.hsep
      [ prettyMC0 binder
      , PP.equals
      , prettyMC0 expr
      ]
  {-# INLINE prettyMC #-}


-- |
-- A type used to represent a match case of @expr a@.
newtype MatchCase t l a
  = MatchCase (Integer, [a], Expression t l a)
  deriving ( Generic
           , Typeable
           )
deriving instance (Data a, Typeable t, Typeable l, Data (Expression t l a)) => Data (MatchCase t l a)
deriving instance (Lift a, Lift (Expression t l a)) => Lift (MatchCase t l a)
deriving instance (Eq a, Eq (Expression t l a)) => Eq (MatchCase t l a)
deriving instance (Ord a, Ord (Expression t l a)) => Ord (MatchCase t l a)
deriving instance (Show a, Show (Expression t l a)) => Show (MatchCase t l a)

-- |
-- A 'MatchCase' for 'ExpressionMC' with 'Identifier'.
type MainMatchCase t l = MatchCase t l Identifier

instance (PrettyMC a, PrettyMC (Expression t l a)) => PrettyMC (MatchCase t l a) where
  prettyMC _ (MatchCase (tag, argBinders, expr))
    = PP.fuse PP.Shallow . PP.hsep
      $ [PP.angles (prettyMC0 tag)]
      <> (prettyMC0 <$> argBinders)
      <> ["->", prettyMC0 expr]
  {-# INLINE prettyMC #-}


-- |
-- @IsRecursive@ represents recursiveness of let/letrec expressions.
newtype IsRecursive = IsRecursive { isRecursive :: Bool }
  deriving ( Generic
           , Typeable
           , Data
           , Lift
           , Eq
           , Ord
           )
-- |
-- Utility pattern for the recursive case of 'IsRecursive'
pattern Recursive :: IsRecursive
pattern Recursive = IsRecursive True
-- |
-- Utility pattern for the non-recursive case of 'IsRecursive'
pattern NonRecursive :: IsRecursive
pattern NonRecursive = IsRecursive False
{-# COMPLETE Recursive, NonRecursive #-}

instance Show IsRecursive where
  showsPrec _ Recursive = showString "Recursive"
  showsPrec _ NonRecursive = showString "NonRecursive"
  {-# INLINE showsPrec #-}


data ExpressionLevel
  = MC -- ^ miniCUTE
  | LLMC -- ^ Lambda lifted miniCUTE
  deriving ( Generic
           , Typeable
           )


data ExpressionType
  = Simple
  | AnnotatedWith Type
  deriving ( Generic
           , Typeable
           )

type family Annotation (e :: ExpressionType) :: Type where
  Annotation 'Simple = ()
  Annotation ('AnnotatedWith ann) = ann

-- |
-- A basic miniCUTE expression of @a@.
data Expression (t :: ExpressionType) (l :: ExpressionLevel) a where
  -- | @5@
  EInteger :: Annotation t -> Integer -> Expression t l a
  -- | @$C{t;a}@
  EConstructor :: Annotation t -> Integer -> Integer -> Expression t l a
  -- | @+@
  EPrimitive :: Annotation t -> Primitive -> Expression t l a
  -- | @v@
  EVariable :: Annotation t -> Identifier -> Expression t l a
  -- | @f 4@
  EApplication :: Annotation t -> Expression t l a -> Expression t l a -> Expression t l a
  -- | @let x = 4 in x@
  ELet :: Annotation t -> IsRecursive -> [LetDefinition t l a] -> Expression t l a -> Expression t l a
  -- | @match $C{1;0} with \<1\> -> 4@
  EMatch :: Annotation t -> Expression t l a -> [MatchCase t l a] -> Expression t l a
  -- | @\\x.x@
  ELambda :: (l ~ 'MC) => Annotation t -> [a] -> Expression t l a -> Expression t l a
  deriving ( Typeable
           )
-- |
-- A utility pattern for 'Expression' of double application.
pattern EApplication2 ann2 ann1 e1 e2 e3 = EApplication ann2 (EApplication ann1 e1 e2) e3
-- |
-- A utility pattern for 'Expression' of triple application.
pattern EApplication3 ann3 ann2 ann1 e1 e2 e3 e4 = EApplication ann3 (EApplication2 ann2 ann1 e1 e2 e3) e4

deriving instance (Typeable t, Data a, Data (Annotation t)) => Data (Expression t 'MC a)
deriving instance (Lift a, Lift (Annotation t)) => Lift (Expression t l a)
deriving instance (Eq a, Eq (Annotation t)) => Eq (Expression t l a)
deriving instance (Ord a, Ord (Annotation t)) => Ord (Expression t l a)
deriving instance (Show a, Show (Annotation t)) => Show (Expression t l a)

instance (Typeable t, Data a, Data (Annotation t)) => Data (Expression t 'LLMC a) where
  gfoldl k z (EInteger ann n) = z EInteger `k` ann `k` n
  gfoldl k z (EConstructor ann tag arity) = z EConstructor `k` ann `k` tag `k` arity
  gfoldl k z (EPrimitive ann prim) = z EPrimitive `k` ann `k` prim
  gfoldl k z (EVariable ann ident) = z EVariable `k` ann `k` ident
  gfoldl k z (EApplication ann e1 e2) = z EApplication `k` ann `k` e1 `k` e2
  gfoldl k z (ELet ann flag lDefs e) = z ELet `k` ann `k` flag `k` lDefs `k` e
  gfoldl k z (EMatch ann e mCases) = z EMatch `k` ann `k` e `k` mCases
  {-# INLINE gfoldl #-}

  gunfold k z c
    = case Data.constrIndex c of
        1 -> k . k . z $ EInteger
        2 -> k . k . k . z $ EConstructor
        3 -> k . k . z $ EPrimitive
        4 -> k . k . z $ EVariable
        5 -> k . k . k . z $ EApplication
        6 -> k . k . k . k . z $ ELet
        7 -> k . k . k . z $ EMatch
        _ -> error "[custom gunfold] invalid constructor index"
  {-# INLINE gunfold #-}

  toConstr (EInteger _ _) = con_EInteger
  toConstr (EConstructor _ _ _) = con_EConstructor
  toConstr (EPrimitive _ _) = con_EPrimitive
  toConstr (EVariable _ _) = con_EVariable
  toConstr (EApplication _ _ _) = con_EApplication
  toConstr (ELet _ _ _ _) = con_ELet
  toConstr (EMatch _ _ _) = con_EMatch
  {-# INLINE toConstr #-}

  dataTypeOf _ = ty_ExpressionLLMC
  {-# INLINE dataTypeOf #-}

{- HLINT ignore con_EInteger "Use camelCase" -}
{- HLINT ignore con_EConstructor "Use camelCase" -}
{- HLINT ignore con_EPrimitive "Use camelCase" -}
{- HLINT ignore con_EVariable "Use camelCase" -}
{- HLINT ignore con_EApplication "Use camelCase" -}
{- HLINT ignore con_ELet "Use camelCase" -}
{- HLINT ignore con_EMatch "Use camelCase" -}
con_EInteger :: Data.Constr
con_EConstructor :: Data.Constr
con_EPrimitive :: Data.Constr
con_EVariable :: Data.Constr
con_EApplication :: Data.Constr
con_ELet :: Data.Constr
con_EMatch :: Data.Constr

con_EInteger = Data.mkConstr ty_ExpressionLLMC "EInteger" [] Data.Prefix
con_EConstructor = Data.mkConstr ty_ExpressionLLMC "EConstructor" [] Data.Prefix
con_EPrimitive = Data.mkConstr ty_ExpressionLLMC "EPrimitive" [] Data.Prefix
con_EVariable = Data.mkConstr ty_ExpressionLLMC "EVariable" [] Data.Prefix
con_EApplication = Data.mkConstr ty_ExpressionLLMC "EApplication" [] Data.Prefix
con_ELet = Data.mkConstr ty_ExpressionLLMC "ELet" [] Data.Prefix
con_EMatch = Data.mkConstr ty_ExpressionLLMC "EMatch" [] Data.Prefix

{- HLINT ignore ty_ExpressionLLMC "Use camelCase" -}
ty_ExpressionLLMC :: Data.DataType
ty_ExpressionLLMC =
  Data.mkDataType "Expression"
  [ con_EInteger
  , con_EConstructor
  , con_EPrimitive
  , con_EVariable
  , con_EApplication
  , con_ELet
  , con_EMatch
  ]

instance (PrettyMC a) => PrettyMC (Expression 'Simple l a) where
  prettyMC _ (EInteger _ n) = prettyMC0 n
  prettyMC _ (EConstructor _ tag arity)
    = PP.hcat
      [ "$C"
      , PP.braces . PP.hcat
        $ [ prettyMC0 tag
          , PP.comma
          , prettyMC0 arity
          ]
      ]
  prettyMC _ (EVariable _ vId) = prettyMC0 vId
  prettyMC _ (EPrimitive _ prim) = prettyMC0 prim
  prettyMC p (EApplication2 _ _ (EPrimitive _ prim) e1 e2)
    | Just primP <- lookup prim binaryPrimitivePrecedenceTable
    = prettyBinaryExpressionPrec p primP (prettyMC0 prim) (`prettyMC` e1) (`prettyMC` e2)
  prettyMC p (EApplication _ e1 e2)
    = prettyWrappedIf (p > miniApplicationPrecedence) PP.parens . PP.align . PP.hcat
      $ [ prettyMC miniApplicationPrecedence e1
        , PP.space
        , prettyMC miniApplicationPrecedence1 e2
        ]
  prettyMC p (ELet _ flag letDefs e)
    = prettyWrappedIf (p > 0) PP.parens . PP.align . PP.vcat
      $ [ keyword
        , prettyIndent . PP.vcat . PP.punctuate PP.semi $ prettyMC0 <$> letDefs
        , "in"
        , prettyIndent . prettyMC0 $ e
        ]
    where
      keyword
        | isRecursive flag = "letrec"
        | otherwise = "let"

      {-# INLINE keyword #-}
  prettyMC p (EMatch _ e matchCases)
    = prettyWrappedIf (p > 0) PP.parens . PP.align . PP.hcat
      $ [ "match"
        , PP.space
        , prettyMC0 e
        , PP.space
        , "with"
        , PP.line
        , prettyIndent . PP.vcat . PP.punctuate PP.semi $ prettyMC0 <$> matchCases
        ]
  prettyMC p (ELambda _ argBinders bodyExpr)
    = prettyWrappedIf (p > 0) PP.parens . PP.align . PP.hcat
      $ [ "\\"
        , PP.hsep $ prettyMC0 <$> argBinders
        , PP.space
        , "->"
        , PP.line
        , prettyIndent . prettyMC0 $ bodyExpr
        ]

instance (PrettyMC ann, PrettyMC a) => PrettyMC (Expression ('AnnotatedWith ann) l a) where
  prettyMC _ (EInteger ann n) = PP.pretty n <> PP.braces (prettyMC0 ann)
  prettyMC _ (EConstructor ann tag arity)
    = PP.hcat
      [ "$C"
      , PP.braces . PP.hcat
        $ [ PP.pretty tag
          , PP.comma
          , PP.pretty arity
          ]
      , PP.braces $ prettyMC0 ann
      ]
  prettyMC _ (EVariable ann vId) = prettyMC0 vId <> PP.braces (prettyMC0 ann)
  prettyMC _ (EPrimitive ann prim) = prettyMC0 prim <> PP.braces (prettyMC0 ann)
  prettyMC _ (EApplication2 ann2 ann1 (EPrimitive annPrim prim) e1 e2)
    | Just primP <- lookup prim binaryPrimitivePrecedenceTable
    = prettyBinaryExpressionPrec miniApplicationPrecedence1 primP primDoc (`prettyMC` e1) (`prettyMC` e2)
      <> PP.braces (prettyMC0 ann1 <> PP.comma PP.<+> prettyMC0 ann2)
    where
      primDoc = prettyMC0 prim <> PP.braces (prettyMC0 annPrim)

      {-# INLINE primDoc #-}
  prettyMC p (EApplication ann e1 e2)
    = prettyWrappedIf (p > miniApplicationPrecedence) PP.parens
      $ ( PP.align . PP.hcat
          $ [ prettyMC miniApplicationPrecedence e1
            , PP.space
            , prettyMC miniApplicationPrecedence1 e2
            ]
        )
        <> PP.braces (prettyMC0 ann)
  prettyMC p (ELet ann flag letDefs e)
    = prettyWrappedIf (p > 0) PP.parens
      $ ( PP.align . PP.vcat
          $ [ keyword
            , prettyIndent . PP.vcat . PP.punctuate PP.semi $ prettyMC0 <$> letDefs
            , "in"
            , prettyIndent $ prettyMC0 e
            ]
        ) <> PP.braces (prettyMC0 ann)
    where
      keyword
        | isRecursive flag = "letrec"
        | otherwise = "let"

      {-# INLINE keyword #-}
  prettyMC p (EMatch ann e matchCases)
    = prettyWrappedIf (p > 0) PP.parens
      $ ( PP.align . PP.hcat
          $ [ "match"
            , PP.space
            , prettyMC0 e
            , PP.space
            , "with"
            , PP.line
            , prettyIndent . PP.vcat . PP.punctuate PP.semi $ prettyMC0 <$> matchCases
            ]
        ) <> PP.braces (prettyMC0 ann)
  prettyMC p (ELambda ann argBinders bodyExpr)
    = prettyWrappedIf (p > 0) PP.parens
      $ ( PP.align . PP.hcat
          $ [ "\\"
            , PP.hsep $ prettyMC0 <$> argBinders
            , "->"
            , PP.space
            , PP.line
            , prettyIndent . prettyMC0 $ bodyExpr
            ]
        ) <> PP.braces (prettyMC0 ann)

-- |
-- A 'Expression' with 'Identifier'.
type MainExpression t l = Expression t l Identifier


makeWrapped ''LetDefinition

-- |
-- 'Lens' to extract the binder of 'LetDefinition'
_letDefinitionBinder :: Lens' (LetDefinition t l a) a
_letDefinitionBinder = _Wrapped . _1
{-# INLINE _letDefinitionBinder #-}

-- |
-- 'Lens' to extract the body expression of 'LetDefinition'
_letDefinitionBody :: Lens (LetDefinition t l a) (LetDefinition t' l' a) (Expression t l a) (Expression t' l' a)
_letDefinitionBody = _Wrapped . _2
{-# INLINE _letDefinitionBody #-}


makeWrapped ''MatchCase

-- |
-- 'Lens' to extract the tag of 'MatchCase'
_matchCaseTag :: Lens' (MatchCase t l a) Integer
_matchCaseTag = _Wrapped . _1
{-# INLINE _matchCaseTag #-}

-- |
-- 'Lens' to extract the arguments of 'MatchCase'
_matchCaseArguments :: Lens' (MatchCase t l a) [a]
_matchCaseArguments = _Wrapped . _2
{-# INLINE _matchCaseArguments #-}

-- |
-- 'Lens' to extract the body expression of 'MatchCase'
_matchCaseBody :: Lens (MatchCase t l a) (MatchCase t' l' a) (Expression t l a) (Expression t' l' a)
_matchCaseBody = _Wrapped . _3
{-# INLINE _matchCaseBody #-}


makeWrapped ''IsRecursive


-- |
-- 'Lens' to extract the annotation of 'AnnotatedExpressionMC'.
_annotation :: Lens' (Expression t l a) (Annotation t)
_annotation = lens getter setter
  where
    getter (EInteger ann _) = ann
    getter (EConstructor ann _ _) = ann
    getter (EVariable ann _) = ann
    getter (EPrimitive ann _) = ann
    getter (EApplication ann _ _) = ann
    getter (ELet ann _ _ _) = ann
    getter (EMatch ann _ _) = ann
    getter (ELambda ann _ _) = ann

    setter (EInteger _ n) ann = EInteger ann n
    setter (EConstructor _ t a) ann = EConstructor ann t a
    setter (EVariable _ v) ann = EVariable ann v
    setter (EPrimitive _ p) ann = EPrimitive ann p
    setter (EApplication _ e1 e2) ann = EApplication ann e1 e2
    setter (ELet _ flag lDefs expr) ann = ELet ann flag lDefs expr
    setter (EMatch _ mCases expr) ann = EMatch ann mCases expr
    setter (ELambda _ argBinders expr) ann = ELambda ann argBinders expr

    {-# INLINE getter #-}
    {-# INLINE setter #-}
{-# INLINE _annotation #-}
