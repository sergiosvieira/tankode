import Tankode.Basic

ident :: Id
ident = Id
  { name = "chaser"
  , trackColour  = "blue2"
  , bodyColour   = "blue4"
  , gunColour    = "grey7"
  , radarColour  = "grey1"
  , bulletColour = "grey9"
  , scanColour   = "blue1"
  }

chaser :: Tankode () -- :: Input () -> Output ()
chaser Input {enemy = Just d}
  | d > 1     = Output   1  0 0 0 1 ()
  | d < 1     = Output (-1) 0 0 0 1 ()
  | otherwise = Output   0  0 0 0 1 ()
chaser Input {enemy = Nothing, speed = s}
  | s > 0     = Output (-1) 1 0 0 0 ()
  | s < 0     = Output   1  1 0 0 0 ()
  | otherwise = Output   0  1 0 0 0 ()

main :: IO ()
main = run ident chaser ()
