{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE StandaloneDeriving #-}
-- |
-- Copyright: (c) 2018-present Junyoung Clare Jang
-- License: BSD 3-Clause
module Minicute.Control.GMachine.Step
  ( module Minicute.Data.GMachine.State

  , GMachineStepMonadT
  , GMachineStepMonad
  , runGMachineStepT
  , execGMachineStepT
  ) where

import Control.Monad.State ( MonadState, StateT, execStateT, runStateT )
import Control.Monad.Trans ( MonadTrans )
import Data.Data ( Typeable )
import GHC.Generics ( Generic )
import Minicute.Data.GMachine.State

type GMachineStepMonad = GMachineStepMonadT IO

newtype GMachineStepMonadT m a
  = GMachineStepMonadT
    { runGMachineStepMonadT :: StateT GMachineState m a
    }
  deriving ( Generic
           , Typeable
           , Functor
           , Applicative
           , Monad
           , MonadFail
           , MonadTrans
           )

deriving instance (Monad m) => MonadState GMachineState (GMachineStepMonadT m)

runGMachineStepT :: GMachineStepMonadT m a -> GMachineState -> m (a, GMachineState)
runGMachineStepT = runStateT . runGMachineStepMonadT
{-# INLINE runGMachineStepT #-}

execGMachineStepT :: (Monad m) => GMachineStepMonadT m a -> GMachineState -> m GMachineState
execGMachineStepT = execStateT . runGMachineStepMonadT
{-# INLINE execGMachineStepT #-}
