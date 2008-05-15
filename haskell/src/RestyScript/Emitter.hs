module RestyScript.Emitter (
    emitSql
) where

import RestyScript.AST
import Data.List (intercalate)
import Text.Printf (printf)

quote :: Char -> String -> String
quote sep s = [sep] ++ quoteChars s ++ [sep]
              where quoteChars (x:xs) =
                        if x == sep || x == '\\'
                            then x : x : quoteChars xs
                            else case lookup x escapes of
                                Just r -> r ++ quoteChars xs
                                Nothing -> x : quoteChars xs
                    quoteChars [] = ""

quoteLiteral :: String -> String
quoteLiteral = quote '\''

quoteIdent :: String -> String
quoteIdent = quote '"'

emitSqlForList ls = intercalate ", " $ map emitSql ls

emitSql :: SqlVal -> String
emitSql (String s) = quoteLiteral s
emitSql (Variable v) = "?"
emitSql (FuncCall f args) = (quoteIdent f) ++
                                  "(" ++ (emitSqlForList args) ++ ")"
emitSql (QualifiedColumn model col) = (emitSql model) ++ "." ++ (emitSql col)

emitSql (Select cols) = "select " ++ (emitSqlForList cols)
emitSql (From models) = "from " ++ (emitSqlForList models)
emitSql (Where cond) = "where " ++ (emitSql cond)
emitSql (OrderBy pairs) = "order by " ++ (emitSqlForList pairs)
emitSql (GroupBy col) = "group by " ++ emitSql col
emitSql (Limit lim) = "limit " ++ emitSql lim
emitSql (Offset offset) = "offset " ++ emitSql offset

emitSql (OrderPair col dir) = (emitSql col) ++ " " ++ dir
emitSql (Model model) = emitSql model
emitSql (Column col) = emitSql col
emitSql (Symbol name) = quoteIdent name
emitSql (Integer int) = show int
emitSql (Float float) = printf "%0f" float
emitSql (Or a b) = "(" ++ (emitSql a) ++ " or " ++  (emitSql b) ++ ")"
emitSql (And a b) = "(" ++ (emitSql a) ++ " and " ++ (emitSql b) ++ ")"
emitSql (Compare op lhs rhs) = (emitSql lhs) ++ " " ++ op ++ " " ++ (emitSql rhs)
emitSql (Alias col alias) = (emitSql col) ++ " as " ++ (emitSql alias)
emitSql Null = ""
emitSql AnyColumn = "*"

escapes :: [(Char, String)]
escapes = zipWith ch "\b\n\f\r\t" "bnfrt"
    where ch a b = (a, '\\':[b])

