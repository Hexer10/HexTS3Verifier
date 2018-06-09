const Bot = require('cmr1-ts3-bot');
const mysql = require('promise-mysql');


/*    EDIT HERE            */


/*      DATABASE SETTINGS             */
const con = mysql.createPool({
    host: '127.0.0.1',          //Database IP
    user: 'root',                //Database User
    password: 'password',               //Database password
    database: 'verify',         //Database name
    connectionLimit: 10
});

/*      BOT SETTINGS             */
const bot = new Bot({
    sid: 1,
    name: 'Verification Bot',   //Name of the BOT
    user: 'serveradmin',             //Query username
    pass: 'password',           //Query password
    host: '127.0.0.1',          //TS3 IP
    port: 10011,                //TS3 Port
    channel: 'Verification Channel', // Channel where the users join to get the message
    verbose: false
});

const verifiedGroup = 'Verificato';  //Group to assign after the verification.







/* DON'T EDIT BELOW THIS LINE */

bot.init((err) => {
    if (err) console.log(err); // Something didn't work
    else console.log("BOT Loaded properly");   // The bot is alive!
});

// Listen for the bot's "ready" event (emitted after succesfull "init")
bot.on('ready', () => {
    // Send a message to the TS3 main server chat
    bot.server.message('Ready for service');
});

// Listen for the bot's "join" event (the bot will automatically join the channel specified)
bot.on('join', channel => {
    // Send a message to the channel that the bot has now joined
    channel.message('Bot enabled! \nType !id to start verifying.');
});

bot.on('unknowncommand', (context) => {
    if (context.client) {
        if (context.msg.slice(0, 1) === '!')
            context.client.message('Unknown command:[color=red] ' + context.msg + "[/color]");
    }
});

bot.on('cliententerchannel', (context) => {
    console.log("ok");
    context.client.message('[b]Hello![/b]\nPlease type in [b]this chat[/b] !id <your id>\nto verify yourself ');
});

bot.clientCommand('!id', (args, context) => {

    //Arg '2' missing
    if (typeof args[1] === 'undefined') {
        context.client.message("We haven't received any code!");
    } else {
        context.client.getDbInfo((err, resp) => {
            if (err) {
                console.error('Unable to get the client id!', err);

                //Check if input is number
            } else if (!isNaN(args[1])) {

                const info = JSON.parse(JSON.stringify(resp));

                // noinspection JSUnusedAssignment
                let stmt = "SELECT * FROM verify_ids WHERE ts3_id = " + info['client_database_id'] + " AND verified = 2";
                con.query(stmt).then(function (rows) {

                    //Or I could just check for the verified group...
                    let result = JSON.parse(JSON.stringify(rows));

                    //Client has already verified one code
                    if (result.length === 1) {

                        context.client.message("You have already verified a code!");

                        //Check if the code is valid
                    } else {
                        stmt = "SELECT * FROM verify_ids WHERE verification_id = " + args[1];
                        con.query(stmt).then(function (rows) {
                            result = JSON.parse(JSON.stringify(rows));
                            if (result.length === 1) {
                                //Client verified successfully
                                if (result[0]['verified'] === 0) {
                                    stmt = "UPDATE verify_ids SET ts3_id = " + info['client_database_id'] + ",verified = 1 WHERE verification_id = " + args[1];
                                    con.query(stmt).then(function () {

                                        context.client.message("Thanks you verifying yourself!\nJoin in our csgo server and type again" +
                                            "\n[b]!verify[/b] to gain you credits!");
                                        console.log(verifiedGroup);
                                        context.client.addToServerGroup(verifiedGroup, (err) => {
                                            if (err) {
                                                console.error("Error occured", err);
                                            }
                                        });
                                    });

                                    //Client was already verified but didn't take his credits
                                } else if (result[0]['verified'] === 1) {
                                    stmt = "SELECT * FROM verify_ids WHERE ts3_id = " + info['client_database_id'] + " AND verification_id = " + args[1];
                                    con.query(stmt).then(function (rows) {
                                        result = JSON.parse(JSON.stringify(rows));
                                        if (result.length === 1) {
                                            context.client.message("To gain your money join in our csgo server and type !verify again!");
                                        } else {
                                            context.client.message("That's not your verification ID!");
                                        }
                                    });

                                    //Code already used
                                } else {
                                    context.client.message("That code is not valid anymore");
                                }

                                //Code doesn't exists
                            } else {
                                context.client.message("Invalid code: " + args[1]);
                            }
                        });
                    }
                });

                //Code is a string
            } else {
                context.client.message("Invalid code: " + args[1]);
            }
        });
    }
});