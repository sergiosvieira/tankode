module Tankode.IPC
  ( setupTankode
  )
where

import Tankode.Data
import Tankode.Show
import PipeRun
import System.IO

-- runs a tankode and initializes necessary fields
setupTankode :: [String] -> IO (Maybe Tank)
setupTankode command = do
  (i,o) <- pun command
  (n:t:b:g:r:u:s:_) <- words <$> hGetLine i
  return $ Just $ tank
    { name = n
    , trackColour   = readColour t
    , bodyColour    = readColour b
    , gunColour     = readColour g
    , radarColour   = readColour r
    , bulletColour  = readColour u
    , scanColour    = readColour s
    , tankode = tk i o
    }
  where
  tk i o (l,s,e,w) = do
    hPutStrLn o $ unwords [showR l, showR s, showMR e, showMR w]
    [a,b,g,r,s] <- words <$> hGetLine i
    return (readR a, readR b, readR g, readR r, readR s)
-- TODO: detect errors (like file not found, could not execute)
-- to do that I'll need to modify `pun`
