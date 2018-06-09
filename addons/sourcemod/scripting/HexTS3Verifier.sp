
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <store>
#define REQUIRE_PLUGIN

#include <multicolors>


#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.00"

#pragma newdecls required
#pragma semicolon 1

char sQuery[1024];
Database g_DB;

ConVar cv_sTeamSpeak;
ConVar cv_sChannel;
ConVar cv_iCredits;

bool bStore;


public Plugin myinfo = 
{
	name = "HexTS3Verifier", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "github.com/Hexer10/HexTS3Verifier"
};

public void OnPluginStart()
{
	CSetPrefix("{lime}[HexVerifier]");
	
	cv_sTeamSpeak = CreateConVar("sm_verifier_ts3_ip", "myts3.net", "TS3 Server IP");
	cv_sChannel = CreateConVar("sm_verifier_ts3_channel", "Verification channel", "The verification channel to join in");
	cv_iCredits = CreateConVar("sm_verifier_credits", "500", "Credits to gain after successfull verification", _, true, 1.0);
	AutoExecConfig();
	
	RegConsoleCmd("sm_verify", Cmd_Verify);
	
	Database.Connect(DBConnectCB, "Verify");
}

public void OnAllPluginsLoaded()
{
	bStore = LibraryExists("store");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "store"))
		bStore = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "store"))
		bStore = false;
}

//Commands
public Action Cmd_Verify(int client, int args)
{
	if (!client)
	{
		CReplyToCommand(client, "In-game only command!");
		return Plugin_Handled;
	}
	
	if (g_DB == null)
	{
		CReplyToCommand(client, "Fetching data...\nTry again later.");
		return Plugin_Handled;
	}
	
	char sAuth[32];
	if (!GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth)))
	{
		CReplyToCommand(client, "Failed to retrive the account ID");
		return Plugin_Handled;
	}
	Format(sQuery, sizeof(sQuery), "SELECT * FROM verify_ids WHERE player_id = '%s'", sAuth);
	g_DB.Query(GetIdCB, sQuery, GetClientUserId(client));
	return Plugin_Handled;
}


//Database
public void DBConnectCB(Database db, const char[] error, any data)
{
	if (db == null)
	{
		SetFailState("Connection failed: %s", error);
	}
	g_DB = db;
	
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS verify_ids(verification_id int,player_id varchar(32) PRIMARY KEY,player_name varchar(32), verified int)");
	g_DB.Query(CreateTableCB, sQuery);
	
}

public void CreateTableCB(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		SetFailState("Failed to create table: %s", error);
	}
	
	//Make columns unique
	//Format(sQuery, sizeof(sQuery), "CREATE UNIQUE INDEX verify_ids_player_id_uindex ON verify_ids (player_id)");
	//g_DB.Query(NullQueryCB, sQuery);	
}


public void GetIdCB(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Query failed: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if (!client)
		return;
	
	if (results.RowCount == 1)
	{
		results.FetchRow();
		
		if (results.FetchInt(3) == 1)
		{
			char sAuth[64];
			GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth));
			
			CPrintToChat(client, "Thanks for verifing you identity!\nYou've gained 1500 credits!");
			Format(sQuery, sizeof(sQuery), "UPDATE verify_ids SET verified=2 WHERE player_id = '%s'", sAuth);
			Store_SetClientCredits(client, Store_GetClientCredits(client) + 1500);
			g_DB.Query(NullQueryCB, sQuery);
			return;
		}
		else if (results.FetchInt(3) == 2)
		{
			CPrintToChat(client, "Your identity is already verified!");
			return;
		}
		
		char sTeamSpeak[32];
		char sChannel[32];
		cv_sTeamSpeak.GetString(sTeamSpeak, sizeof(sTeamSpeak));
		cv_sChannel.GetString(sChannel, sizeof(sChannel));
		
		CPrintToChat(client, "You still need to be verified!");
		CSetPrefix("");
		CPrintToChat(client, "Join on our TeamSpeak 3 Server IP: '%s' And goto the '%S' channel ", sTeamSpeak, sChannel);
		CPrintToChat(client, "once there type '!id <yourid>'");
		CPrintToChat(client, "to get verfied");
		if (cv_iCredits.IntValue > 0 && bStore)
			CPrintToChat(client, "and get %d credits!", cv_iCredits.IntValue);
		CPrintToChat(client, "Your ID it's %d", results.FetchInt(0));
		CSetPrefix("{lime}[HexVerifier]");
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "SELECT random_num FROM (SELECT FLOOR(RAND() * 99999) AS random_num UNION SELECT FLOOR(RAND() * 99999) AS random_num) AS numbers_mst_plus_1 WHERE random_num NOT IN (SELECT verification_id FROM verify_ids) LIMIT 1");
		g_DB.Query(GenRandomCB, sQuery, GetClientUserId(client));
	}
}


public void GenRandomCB(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Failed to generate number: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if (!client)
		return;
	
	results.FetchRow();
	int id = results.FetchInt(0);
	
	char sTeamSpeak[32];
	char sChannel[32];
	cv_sTeamSpeak.GetString(sTeamSpeak, sizeof(sTeamSpeak));
	cv_sChannel.GetString(sChannel, sizeof(sChannel));
		
	CPrintToChat(client, "Join on our TeamSpeak 3 Server IP: '%s' And goto the '%S' channel ", sTeamSpeak, sChannel);
	CSetPrefix("");
	CPrintToChat(client, "once there type '!id <yourid>'");
	CPrintToChat(client, "to get verfied");
	if (cv_iCredits.IntValue > 0 && bStore)
		CPrintToChat(client, "and get %d credits!", cv_iCredits.IntValue);
	CPrintToChat(client, "Your ID it's %d", id);
	CSetPrefix("{lime}[HexVerifier]");
	
	char sAuth[64];
	char sName[32];
	GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth));
	GetClientName(client, sName, sizeof(sName));
	
	Format(sQuery, sizeof(sQuery), "INSERT INTO verify_ids(verification_id, player_id, player_name, verified)\
									VALUES(%d, '%s', '%s', %d)", id, sAuth, sName, 0);									
	
	g_DB.Query(NullQueryCB, sQuery);
	return;
}

public void NullQueryCB(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Query failed: %s", error);
	}
} 