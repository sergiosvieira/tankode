-- tankode's logic, in Haskell
-- started by Rudy Matela on 2016-12-22 18:30

import Tankode
import Tankode.Data
import Tankode.Show
import Tankode.Constants
import Colour
import Data.Ratio
import List
import Control.Arrow ((***))
import Random
import Data.Maybe
import System.Console.CmdArgs.Explicit
import System.Environment
import Control.Monad

data Args = Args
  { tankodes :: [String]
  , maxTicks :: Int
  , field    :: Field
  , showHelp :: Bool
  , seed     :: Maybe Int
  , dump     :: Bool

  , drawCharge :: Bool
  , drawHealth :: Bool
  , drawScan :: Bool
  , motionBlur :: Bool
  }

prepareArgs :: Args -> Mode Args
prepareArgs args =
  mode "speculate" args "" (flagArg (\s a -> Right a {tankodes = s:tankodes a}) "")
  [ "ttime-limit" --= \s a -> a {maxTicks = read s * ticksPerSecond}
  , "ssize"       --= \s a -> a {field = let (w,'x':h) = span (/= 'x') s
                                                in makeField (read w % 1) (read h % 1)}
  , " seed"       --= \s a -> a {seed = Just $ read s}
  , "hhelp"       --.   \a -> a {showHelp = True}
  , "ddump"       --.   \a -> a {dump = True}

  -- options passed along to the display program
  , " draw-charge"    --. \a -> a {drawCharge = True}
  , " draw-health"    --. \a -> a {drawHealth = True}
  , " motion-blur"    --. \a -> a {motionBlur = True}
  , " draw-scan"      --. \a -> a {drawScan   = True}
  , " no-draw-charge" --. \a -> a {drawCharge = False}
  , " no-draw-health" --. \a -> a {drawHealth = False}
  , " no-motion-blur" --. \a -> a {motionBlur = False}
  , " no-draw-scan"   --. \a -> a {drawScan   = False}
  ]
  where
  (short:long) --= fun = flagReq  (filter (/= " ") [[short],long]) ((Right .) . fun) "X" ""
  (short:long) --. fun = flagNone (filter (/= " ") [[short],long]) fun                   ""

args :: Args
args = Args
  { tankodes = []
  , maxTicks = 100 * ticksPerSecond
  , field = updateObstacles (++ obstacles) $ makeField 12 8
  , showHelp = False
  , seed = Nothing
  , dump = False
  , drawCharge = False
  , drawHealth = True
  , motionBlur = True
  , drawScan = True
  }
  where
  obstacles =
    [ ((12,8),(12,7),(8,11))
    , ((3,8),(4,8),(4,7)), ((4,7),(4,8),(5,8))
    , ((0,0),(1,0),(0,1))
    , ((7,0),(8,0),(8,1)), ((8,1),(8,0),(9,0))
    , ((5,7/2),(7,9/2),(13/2,5))
    , ((5,7/2),(7,9/2),(11/2,3))
    ]

printSimulation :: Int -> Field -> State -> IO ()
printSimulation maxTicks f ts = do
  putStrLn $ showField f
  putStrLn . unlines $ map showId ts
  printStates maxTicks 0 f ts

printStates :: Int -> Int -> Field -> State -> IO ()
printStates maxTicks n f ts
  | n >= maxTicks = return ()
  | otherwise = do
  putStrLn $ showTick n ts
  printStates maxTicks (n+1) f =<< nextState f ts
  where
  showTick i ts = "tick " ++ show i ++ "\n" ++ showState f ts

mainWith :: Args -> IO ()
mainWith Args{showHelp = True} = print $ helpText [] HelpFormatDefault (prepareArgs args)
mainWith Args{tankodes = []} = putStrLn "must pass at least one tankode"
mainWith args@Args{field = f, tankodes = ts, seed = seed, dump = dump} = do
  gen <- mkNewStdGen seed
-- TODO: make a function places :: Field -> [Loc]
  let poss = startingPositions f gen
  --propagateSIGTERM
  unless dump $ pipeToDisplay args
  tanks <- traverse setupTankode $ map words ts
  let tanks' = zipWith (\t l -> t{loc = l}) (catMaybes tanks) poss
  gen' <- newStdGen
  let hs = startingHeadings gen
  let tanks'' = zipWith (\t h -> t{heading = h}) tanks' hs
  printSimulation (maxTicks args) f tanks''

main :: IO ()
main = do
  mainWith =<< processArgs (prepareArgs args)

pipeToDisplay :: Args -> IO ()
pipeToDisplay args = do
  dn <- dirname <$> getExecutablePath
  pipeTo . concat $
    [ [dn ++ "/" ++ "../display/bin/tankode-display"]
    , ["draw-charge"    |       drawCharge args]
    , ["no-draw-health" | not $ drawHealth args]
    , ["no-motion-blur" | not $ motionBlur args]
    , ["no-draw-scan"   | not $ drawScan   args]
    ]

dirname :: String -> String
dirname = reverse . tail . dropWhile (/= '/') . reverse

mkNewStdGen :: Maybe Int -> IO StdGen
mkNewStdGen Nothing  = newStdGen
mkNewStdGen (Just x) = return $ mkStdGen x