{- HLINT ignore "Use explicit module export list" -}
{-# LANGUAGE OverloadedStrings #-}
module Minicute.Transpilers.Constants
  ( module Minicute.Transpilers.Constants
  ) where

import Data.String ( fromString )
import Data.Word
import Minicute.Data.Minicute.Common

import qualified LLVM.AST as AST
import qualified LLVM.AST.Constant as ASTC
import qualified LLVM.AST.Type as ASTT

operandInt :: Word32 -> Int -> AST.Operand
operandInt w n = AST.ConstantOperand (ASTC.Int w (toInteger n))

operandInteger :: Word32 -> Integer -> AST.Operand
operandInteger w n = AST.ConstantOperand (ASTC.Int w n)

operandUserDefinedNGlobal :: Identifier -> AST.Operand
operandUserDefinedNGlobal i = operandNGlobal $ "minicute__user_defined__" <> i <> "__node"

operandNGlobal :: Identifier -> AST.Operand
operandNGlobal (Identifier iStr)
  = AST.ConstantOperand . ASTC.GlobalReference typeNodeNGlobal . fromString $ iStr

operandNodeCreateNInteger :: AST.Operand
operandNodeCreateNInteger = AST.ConstantOperand constantNodeCreateNInteger

operandNodeCreateNStructure :: AST.Operand
operandNodeCreateNStructure = AST.ConstantOperand constantNodeCreateNStructure

operandNodeCreateNStructureFields :: AST.Operand
operandNodeCreateNStructureFields = AST.ConstantOperand constantNodeCreateNStructureFields

operandNodeCreateNApplication :: AST.Operand
operandNodeCreateNApplication = AST.ConstantOperand constantNodeCreateNApplication

operandNodeUpdateNInteger :: AST.Operand
operandNodeUpdateNInteger = AST.ConstantOperand constantNodeUpdateNInteger

operandNodeUpdateNStructure :: AST.Operand
operandNodeUpdateNStructure = AST.ConstantOperand constantNodeUpdateNStructure

operandNodeUpdateNApplication :: AST.Operand
operandNodeUpdateNApplication = AST.ConstantOperand constantNodeUpdateNApplication

operandNodeUpdateNIndirect :: AST.Operand
operandNodeUpdateNIndirect = AST.ConstantOperand constantNodeUpdateNIndirect

operandUtilUnwind :: AST.Operand
operandUtilUnwind = AST.ConstantOperand constantUtilUnwind

operandAddrStackPointer :: AST.Operand
operandAddrStackPointer = AST.ConstantOperand constantAddrStackPointer

operandAddrBasePointer :: AST.Operand
operandAddrBasePointer = AST.ConstantOperand constantAddrBasePointer

operandNodeHeapPointer :: AST.Operand
operandNodeHeapPointer = AST.ConstantOperand constantNodeHeapPointer

constantNodeCreateNInteger :: ASTC.Constant
constantNodeCreateNInteger = ASTC.GlobalReference typeNodeCreateNInteger "minicute__node__create_NInteger"

constantNodeCreateNStructure :: ASTC.Constant
constantNodeCreateNStructure = ASTC.GlobalReference typeNodeCreateNStructure "minicute__node__create_NStructure"

constantNodeCreateNStructureFields :: ASTC.Constant
constantNodeCreateNStructureFields = ASTC.GlobalReference typeNodeCreateNStructureFields "minicute__node__create_NStructureFields"

constantNodeCreateNApplication :: ASTC.Constant
constantNodeCreateNApplication = ASTC.GlobalReference typeNodeCreateNApplication "minicute__node__create_NApplication"

constantNodeUpdateNInteger :: ASTC.Constant
constantNodeUpdateNInteger = ASTC.GlobalReference typeNodeUpdateNInteger "minicute__node__update_NInteger"

constantNodeUpdateNStructure :: ASTC.Constant
constantNodeUpdateNStructure = ASTC.GlobalReference typeNodeUpdateNStructure "minicute__node__update_NStructure"

constantNodeUpdateNApplication :: ASTC.Constant
constantNodeUpdateNApplication = ASTC.GlobalReference typeNodeUpdateNApplication "minicute__node__update_NApplication"

constantNodeUpdateNIndirect :: ASTC.Constant
constantNodeUpdateNIndirect = ASTC.GlobalReference typeNodeUpdateNIndirect "minicute__node__update_NIndirect"

constantUtilUnwind :: ASTC.Constant
constantUtilUnwind = ASTC.GlobalReference typeUtilUnwind "minicute__util__unwind"

constantAddrStackPointer :: ASTC.Constant
constantAddrStackPointer = ASTC.GlobalReference typeInt8PtrPtrPtr "asp"

constantAddrBasePointer :: ASTC.Constant
constantAddrBasePointer = ASTC.GlobalReference typeInt8PtrPtrPtr "abp"

constantNodeHeapPointer :: ASTC.Constant
constantNodeHeapPointer = ASTC.GlobalReference typeInt8PtrPtr "nhp"

typeNodeCreateNInteger :: ASTT.Type
typeNodeCreateNInteger = ASTT.FunctionType typeInt8Ptr [typeInt32] False

typeNodeCreateNStructure :: ASTT.Type
typeNodeCreateNStructure = ASTT.FunctionType typeInt8Ptr [typeInt32, typeInt8Ptr] False

typeNodeCreateNStructureFields :: ASTT.Type
typeNodeCreateNStructureFields = ASTT.FunctionType typeInt8Ptr [typeInt32, typeInt8PtrPtr] False

typeNodeCreateNApplication :: ASTT.Type
typeNodeCreateNApplication = ASTT.FunctionType typeInt8Ptr [typeInt8Ptr, typeInt8Ptr] False

typeNodeUpdateNInteger :: ASTT.Type
typeNodeUpdateNInteger = ASTT.FunctionType ASTT.void [typeInt32, typeInt8Ptr] False

typeNodeUpdateNStructure :: ASTT.Type
typeNodeUpdateNStructure = ASTT.FunctionType ASTT.void [typeInt32, typeInt8Ptr, typeInt8Ptr] False

typeNodeUpdateNApplication :: ASTT.Type
typeNodeUpdateNApplication = ASTT.FunctionType ASTT.void [typeInt8Ptr, typeInt8Ptr, typeInt8Ptr] False

typeNodeUpdateNIndirect :: ASTT.Type
typeNodeUpdateNIndirect = ASTT.FunctionType ASTT.void [typeInt8Ptr, typeInt8Ptr] False

typeUtilUnwind :: ASTT.Type
typeUtilUnwind = ASTT.FunctionType ASTT.void [] False

typeNodeNIntegerPtr :: ASTT.Type
typeNodeNIntegerPtr = ASTT.ptr typeNodeNInteger

typeNodeNInteger :: ASTT.Type
typeNodeNInteger = ASTT.NamedTypeReference "node.NInteger"

typeNodeNGlobal :: ASTT.Type
typeNodeNGlobal = ASTT.NamedTypeReference "node.NGlobal"

typeInt8PtrPtrPtr :: ASTT.Type
typeInt8PtrPtrPtr = ASTT.ptr typeInt8PtrPtr

typeInt8PtrPtr :: ASTT.Type
typeInt8PtrPtr = ASTT.ptr typeInt8Ptr

typeInt8Ptr :: ASTT.Type
typeInt8Ptr = ASTT.ptr typeInt8

typeInt8 :: ASTT.Type
typeInt8 = ASTT.i8

typeInt32PtrPtrPtr :: ASTT.Type
typeInt32PtrPtrPtr = ASTT.ptr typeInt32PtrPtr

typeInt32PtrPtr :: ASTT.Type
typeInt32PtrPtr = ASTT.ptr typeInt32Ptr

typeInt32Ptr :: ASTT.Type
typeInt32Ptr = ASTT.ptr typeInt32

typeInt32 :: ASTT.Type
typeInt32 = ASTT.i32
