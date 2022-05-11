{-# LANGUAGE LambdaCase
    , MultiParamTypeClasses
    , FunctionalDependencies
    , ScopedTypeVariables
    , TypeApplications
    , DataKinds
    , FlexibleInstances
    , FlexibleContexts
    , RecursiveDo
    , BlockArguments
    , OverloadedStrings
    , ConstraintKinds
    , GADTs
    , PartialTypeSignatures
    , ImplicitParams
    , TemplateHaskell
    , QuasiQuotes #-}

module Montague.Frontend where

import Montague.Frontend.Utils
import Montague.Frontend.Utils.Javascript
import Montague.Frontend.TabDisplay
import Montague.Frontend.Pages.Preferences
import Montague.Frontend.NavBar

import System.Info
import Control.Exception
import Control.Monad
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Language.Javascript.JSaddle (eval, liftJSM)
import Reflex.Dom.Core hiding (button, tabDisplay, Home)
import Montague
import Data.Maybe
import Data.Function
import Data.Functor
import Prelude hiding ((<=), div)
import Control.Applicative
import Control.Monad.Tree
import Montague.Types
import Montague.Lexicon hiding (enumValues)
import Data.Proxy
import Montague.Semantics
import Data.PartialOrd hiding ((==))
import System.Environment
import Control.Lens
import Control.Lens.Operators
import Control.Monad.Trans.Reader
import Control.Monad.IO.Class
import Control.Monad.Fix
import System.Directory
import Data.List
import Control.Monad.Tree

import Montague.Frontend.Route (Route)
import qualified Montague.Frontend.Route as Route

import Montague.Frontend.Pages.Welcome
import Montague.Frontend.Pages.Home
import Montague.Frontend.Pages.Entity
import Montague.Frontend.Pages.Types
import Montague.Frontend.Pages.Schema
import Montague.Frontend.Pages.About
import Montague.Frontend.Pages.Notes
import Montague.Frontend.Pages.KnowledgeBase
import Montague.Frontend.Pages.SchemaManagement

body :: _ => m ()
body = mdo
    -- Setup the application directory.
    montagueDir <- if "android" `isInfixOf` os
        then pure "/data/data/org.bedelibry.app"
        else liftFrontend "/" getHomeDirectory <&> (<> "/.bedelibry")

    -- toastOnErrors $ liftFrontend (Right ()) $ catch
    --     (do createDirectoryIfMissing True montagueDir
    --         pure $ Right ())
    --     (\(e :: SomeException) -> pure $ Left e)

    (topNavEvents, addBtnClicks) <- androidNavBar currentPage prefs Route.pagesWithTabs

    let navEvents = leftmost [
            switch $ current $ leftmost <$> pageNavEvents, 
            topNavEvents, 
            bottomNavEvents]

    (prefs, pageNavEvents) <- elAttr "div" ("data-role" =: "mainview") $ 
        tabDisplay (Route.defaultPage initialPref) navEvents $ do
            hideWelcomePage <- tab Route.Welcome $ welcomePage prefs
        
            maybeParsedSchema <- tab Route.Schema $ schemaPage prefs
                montagueDir

            maybeParsedProgram <- tab Route.KnowledgeBase $ 
                knowledgeBasePage prefs
                    montagueDir

            tab Route.Home $ homePage 
                maybeParsedProgram 
                maybeParsedSchema 
                prefs

            prefs <- tab Route.Preferences $ preferencePage 
                hideWelcomePage 
                prefs 
                montagueDir

            tab (Route.Entities Nothing) $ entityPage 
                -- Only pass in events when on this page.
                (gate (whenPageIs $ Route.Entities Nothing) addBtnClicks)
                prefs 
                maybeParsedSchema

            tab (Route.Types Nothing) $ typePage 
                -- Only pass in events when on this page.
                (gate (whenPageIs $ Route.Types Nothing) addBtnClicks) 
                prefs 
                maybeParsedSchema

            tab Route.Notes notesPage

            tab Route.About aboutPage

            tab Route.SchemaManagement $
                schemaManagementPage
                    montagueDir

            pure prefs

    currentPage <- holdDyn (Route.defaultPage initialPref) navEvents

    -- Helper function to get a dynamic for when a specific route is active.
    let whenPageIs p = current currentPage <&> (== p)

    bottomNavEvents <- iOSNavBar currentPage prefs Route.pagesWithTabs

    prerender (pure ()) $ do
        liftJSM $ eval ("setTimeout(function(){ feather.replace(); }, 50);" :: T.Text)
        pure ()

    initialPref <- sample $ current prefs

    prerender (pure ()) $
        initialPref & stylePref & updateCSS

    prerender (pure never) $ performEvent $ updated (prefs <&> stylePref) <&> 
        updateCSS

    pure ()

updateCSS :: _ => Style -> m ()
updateCSS = \case
    IOS -> do
        modifyLink "css-style"
            "https://sintrastes.github.io/demos/montague/puppertino/newfull.css"
        liftJSM $ eval ("setTimeout(function(){ feather.replace(); }, 50);" :: T.Text)
        pure ()
    Android -> do
        modifyLink "css-style"
            "https://sintrastes.github.io/demos/montague/materialize.min.css"
        liftJSM $ eval ("setTimeout(function(){ feather.replace(); }, 50);" :: T.Text)
        pure ()
    Gtk -> do
        modifyLink "css-style"
            "https://sintrastes.github.io/demos/montague/gtk.css"
        liftJSM $ eval ("setTimeout(function(){ feather.replace(); }, 50);" :: T.Text)
        pure ()
    UbuntuTouch -> do
        modifyLink "css-style"
            "https://sintrastes.github.io/demos/montague/ubuntu-touch.css"
        liftJSM $ eval ("setTimeout(function(){ feather.replace(); }, 50);" :: T.Text)
        pure ()