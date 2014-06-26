{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
module Main where

import Shelly
import Data.Monoid
import Data.Text as T

default (T.Text)

config_text_no_admin = "{config, pkgs, ...}:\n\
\{\n\
\  require = [ ./config-at-bootstrap.nix ../../users/admin.nix ];\n\
\}\n"

config_text = "{config, pkgs, ...}:\n\
\{\n\
\  require = [ ./config-at-bootstrap.nix ../../standard-nixpath.nix ];\n\
\}\n"

nix_configs = ( "https://github.com/coreyoconnor/nix_configs.git"
              , "HEAD"
              )

main = shelly $ verbosely $ do
    host <- T.strip <$> run "uname" ["-n"]
    let bootstrap_config_dir = fromText $ "/home/admin/tmp/computers/" <> host
    rm_rf bootstrap_config_dir
    mkdir_p bootstrap_config_dir
    mapM_ (\f -> cp_r f bootstrap_config_dir) =<< ls "/etc/nixos/"
    mv (bootstrap_config_dir </> "configuration.nix")
       (bootstrap_config_dir </> "config-at-bootstrap.nix")
    writefile (bootstrap_config_dir </> "configuration.nix") config_text
    run_ "git" ["clone", (fst nix_configs), "/home/admin/nix_configs"]
    let nix_configs_dir = "/home/admin/nix_configs"
    chdir (fromText nix_configs_dir) $ do
        run_ "git" ["submodule", "init"]
        run_ "git" ["submodule", "foreach", "git", "submodule", "init"]
        run_ "git" ["submodule", "update", "--recursive"]
        cp_r bootstrap_config_dir (fromText $ nix_configs_dir <> "/computers/")
        let new_NIX_PATH =  "nixos=" <> nix_configs_dir <> "/nixpkgs/nixos"
                         <> ":nixpkgs=" <> nix_configs_dir <> "/nixpkgs"
                         <> ":nixos-config=" <> nix_configs_dir
                                             <> "/computers/" <> host <> "/configuration.nix"
                         <> ":services=/etc/nixos/services"
        setenv "NIX_PATH" new_NIX_PATH
        echo $ "reconfiguring using NIX_PATH " <> new_NIX_PATH
        run_ "sudo" ["nixos-rebuild", "switch"]
    return ()

