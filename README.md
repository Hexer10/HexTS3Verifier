# HexTS3Verifier
Verify ts3 user's identiy by logining in you ts3 server

This has been tested properly on CSGO & Centos 7.2

## Prerequisites

 * Sourcemod installed
 * Node JS installed
 * ServerQuery access on TS3
 
 
## Option dependences
 
 * Zephyrus store ->  Get credits after verifications

## Installation
 
1. Install firstly the sourcemod plugin, since we need to create the tables
  * [Download](https://codeload.github.com/Hexer10/HexTS3Verifier/zip/master) the repo and upload the addons folder to your `csgo/` directory.
  * Add an entry called `Verify` in the `database.cfg` file. (Locate in `csgo/addons/sourcemod/configs/`).
  * Refresh the plugins. (Change the map or restart the server).
  * Configure the plugin by editing the cfg file:  `csgo/cfg/sorcemod/plugin.HexTSBVerifier.cfg`.
2. Install the node js app.
  * Install the dependences: `npm install cmr1-ts3-bot` and `npm install promise-mysql`.
  * Upload the `app.js` located in the `node` directory in the same folder you've ran the commands.
  * Start the bot: `node app.js`.
  * If you've configurate all properly the bot should now join in the ts3 server.


## FAQ
1. How to leave the bot always open?
  * Install forever: `npm install forever -g`
  * Start the bot: `forever start -o logs.log -e error.log app.js`
  * Two file will be created: `logs.log` where the logs will be store and `error.log` where the error logs will be store.
  * Use: `forever list` to see which processes are running under forever and `forever stop app.js` to stop the bot
